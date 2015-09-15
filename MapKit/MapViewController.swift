//
//  MapViewController.swift
//  MapKit
//
//  Created by Yariv (Home) on 9/10/15.
//  Copyright (c) 2015 LearnSwiftLA. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
    }
    
    @IBAction func addPin(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            let tapPoint = gesture.locationInView(mapView) // let vs. var
            let coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            
            // Note: Model object - represents data
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(coordinate.latitude), \(coordinate.longitude)"
            mapView.addAnnotation(annotation)
            mapView.showAnnotations([annotation], animated: true)
            
            // Note: Optional
            reverseGeocode(annotation) { placemark in
                annotation.subtitle = annotation.title
                annotation.title = placemark.name
                
                self.mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
    @IBAction func centerOnUserLocation(sender: UIBarButtonItem) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showAnnotations([mapView.userLocation], animated: true)
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func search(sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    // Note: use enums for tags
    private enum CalloutAction: Int {
        case Delete = 1
        case Navigate = 2
    }
    
    // Note: return an optional clousre async with default value
    private func reverseGeocode(annotation: MKAnnotation, completion: (CLPlacemark -> Void)? = nil) {
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, _) in
            if let placemark = placemarks?.first as? CLPlacemark {
                completion?(placemark) // Note: Using optional closure
            }
        }
    }
}

// Note: Use extensions for protocols
extension MapViewController: MKMapViewDelegate {
    // Note: Model vs. View in MVC
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // Do not create a custom annotation view for User Location
        if annotation.isKindOfClass(MKUserLocation.self) { return nil }
        
        let reuseIdentifier = "PinView"
        let pinView: MKPinAnnotationView // Note: declare a constant without initialization
        
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView {
            // Dequeued an annotation view
            pinView = annotationView
            pinView.annotation = annotation
        } else {
            // Create a new annotation view
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.draggable = true
            
            let deleteButton = UIButton.buttonWithType(.System) as! UIButton
            deleteButton.setTitle("❌", forState: .Normal)
            deleteButton.sizeToFit()
            deleteButton.tag = CalloutAction.Delete.rawValue
            pinView.rightCalloutAccessoryView = deleteButton
            
            let navigateButton = UIButton.buttonWithType(.System) as! UIButton
            navigateButton.setTitle("🚘", forState: .Normal)
            navigateButton.sizeToFit()
            navigateButton.tag = CalloutAction.Navigate.rawValue
            pinView.leftCalloutAccessoryView = navigateButton
        }
        
        // Prepare the annotation view (color, callout, etc.)
        // if annotation == ... then change color
        pinView.pinColor = .Red
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if let action = CalloutAction(rawValue: control.tag) {
            switch action {
            case .Delete:
                mapView.removeAnnotation(view.annotation)
                
            case .Navigate:
                if let annotation = view.annotation {
                    reverseGeocode(annotation) { placemark in
                        let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                        item.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                }
            }
        }
    }
    
    // Note: Optional code, if we have time
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            if let annotation = view.annotation as? MKPointAnnotation {
                reverseGeocode(annotation) { placemark in
                    annotation.subtitle = annotation.title
                    annotation.title = placemark.name
                }
            }
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // Note: match multiple values
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            navigationItem.leftBarButtonItem?.enabled = true
            mapView.showsUserLocation = true
            
        case .Denied, .Restricted:
            navigationItem.leftBarButtonItem?.enabled = false
            
        case .NotDetermined:
            break
        }
    }
}

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let text = searchBar.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if !text.isEmpty {
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = text
            request.region = mapView.region
            
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler { (response, error) in
                if response.mapItems.count > 0 {
                    if let item = response.mapItems.first as? MKMapItem {
                        let annotation = item.placemark
                        self.mapView.addAnnotation(annotation)
                        self.mapView.showAnnotations([annotation], animated: true)
                        self.mapView.selectAnnotation(annotation, animated: true)
                    }
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}