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
        guard gesture.state == .Began else { return }
        
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
    
    // Note: return an optional clousre async with default value
    private func reverseGeocode(annotation: MKAnnotation, completion: (CLPlacemark -> Void)? = nil) {
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, _) in
            guard let placemark = placemarks?.first else { return }
            completion?(placemark) // Note: Using optional closure
        }
    }
}

// Note: use enums for tags
private enum CalloutAction: Int {
    case Delete = 1
    case Navigate = 2
}

// Note: Use extensions for protocols

// MARK:- MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    // Note: Model vs. View in MVC
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Keep the default annotation view for User Location
        guard !annotation.isKindOfClass(MKUserLocation.self) else { return nil }
        
        let reuseIdentifier = "PinView"
        let pinView: MKPinAnnotationView // Note: declare a constant without initialization
        
        // Note: Use defer to prepare the annotation view before it's instantiated
        defer {
            // Prepare the annotation view (color, callout, etc.)
            // for example: if annotation == ... then change color
            pinView.pinColor = .Red
        }
        
        // Note: Use a nested utility functions
        func buttonWithTitle(title: String, type: CalloutAction) -> UIButton {
            let button = UIButton(type: .System)
            button.setTitle(title, forState: .Normal)
            button.sizeToFit()
            button.tag = type.rawValue
            return button
        }
        
        // Initialize the annotation view (dequeue or allocate)
        //
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
            
            pinView.rightCalloutAccessoryView = buttonWithTitle("❌", type: .Delete)
            pinView.leftCalloutAccessoryView = buttonWithTitle("🚘", type: .Navigate)
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let action = CalloutAction(rawValue: control.tag) else { return }
        
        switch action {
        case .Delete:
            guard let annotation = view.annotation else { return }
            mapView.removeAnnotation(annotation)
            
        case .Navigate:
            guard let annotation = view.annotation else { return }
            
            reverseGeocode(annotation) { placemark in
                let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                item.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            }
        }
    }
    
    // Note: Optional code, if we have time
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        guard newState == .Ending, let annotation = view.annotation as? MKPointAnnotation
            else { return }
        
        reverseGeocode(annotation) { placemark in
            annotation.subtitle = annotation.title
            annotation.title = placemark.name
        }
    }
}

// MARK:- CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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

// MARK:- UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // Note: use defer to dismiss the search controller even if the guard returns
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        guard let text = searchBar.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            where !text.isEmpty else { return }
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler { (response, error) in
            guard let item = response?.mapItems.first else { return }
            
            let annotation = item.placemark
            self.mapView.addAnnotation(annotation)
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
}