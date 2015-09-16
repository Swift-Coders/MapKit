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
    
    @IBOutlet private weak var mapView: MKMapView! // TODO: 1.
    
    private let locationManager = CLLocationManager() // TODO: 11
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self // TODO: 11
    }
    
    // TODO: 2.
    @IBAction func addPin(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .Began else { return }
        
        let tapPoint = gesture.locationInView(mapView) // View (MapView) coordinate space
        let coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView) // Map (CoreLocation) coordinate space
        
        // Note: Model object - represents data
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "\(coordinate.latitude), \(coordinate.longitude)"
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
        
        // TODO: 9
        reverseGeocode(annotation) { placemark in
            annotation.subtitle = annotation.title
            annotation.title = placemark.name
            
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // TODO: 11.
    @IBAction func centerOnUserLocation(sender: UIBarButtonItem) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showAnnotations([mapView.userLocation], animated: true)
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // TODO: 7.
    @IBAction func search(sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    // TODO: 9.1
    // Note: return an optional clousre async with default value
    private func reverseGeocode(annotation: MKAnnotation, completion: (CLPlacemark -> Void)? = nil) {
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, _) in
            guard let placemark = placemarks?.first else { return }
            completion?(placemark) // Note: Using optional closure
        }
    }
}

// Note: Use extensions for protocols

// MARK:- MKMapViewDelegate

// TODO: 3.
extension MapViewController: MKMapViewDelegate {
    // Note: Model vs. View in MVC
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        // TODO: 4.
        // Keep the default annotation view for User Location
        guard !annotation.isKindOfClass(MKUserLocation.self) else { return nil }
        
        let reuseIdentifier = "PinView"
        let pinView: MKPinAnnotationView // Note: declare a constant without initialization
        
        // TODO: 9.
        // Note: Use defer to prepare the annotation view before it's instantiated
        defer {
            // Prepare the annotation view (color, callout, etc.)
            let location = CLLocation(annotation: annotation)
            let navigateButton = pinView.leftCalloutAccessoryView as? UIButton
            let navigateButtonTitle: String
            
            if let result = mapView.userLocation.location?.isWalkingDistanceFromLocation(location)
                where result
            {
                pinView.pinColor = .Green
                navigateButtonTitle = "🚶"
            } else {
                pinView.pinColor = .Red
                navigateButtonTitle = "🚘"
            }
            navigateButton?.setTitle(navigateButtonTitle, forState: .Normal)
            navigateButton?.sizeToFit()
        }
        
        // TODO: 8.2
        // Note: Use a nested utility functions, could also be an extension on UIButton
        func buttonWithTitle(title: String, type: CalloutAction) -> UIButton {
            let button = UIButton(type: .System)
            button.setTitle(title, forState: .Normal)
            button.sizeToFit()
            button.tag = type.rawValue
            return button
        }
        
        // Boilerplate code
        
        // TODO: 5.
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
            pinView.draggable = true // TODO: 10.1
            
            pinView.rightCalloutAccessoryView = buttonWithTitle("❌", type: .Delete) // TODO: 6.
            pinView.leftCalloutAccessoryView = buttonWithTitle("🚘", type: .Navigate) // TODO: 8.
        }
        return pinView
    }
    
    // TODO: 8.1
    // Note: use enums for tags
    private enum CalloutAction: Int {
        case Delete = 1
        case Navigate = 2
    }
    
    // TODO: 6.1
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let action = CalloutAction(rawValue: control.tag)
            , let annotation = view.annotation else { return }
        
        switch action {
        case .Delete:
            mapView.removeAnnotation(annotation) // TODO: 6.2
            
            // TODO: 8.3
        case .Navigate:
            let location = CLLocation(annotation: annotation)
            guard let isWalkingDistance = mapView.userLocation.location?.isWalkingDistanceFromLocation(location) else { return }
            
            reverseGeocode(annotation) { placemark in
                let mode = isWalkingDistance ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeDriving
                let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                item.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: mode])
            }
        }
    }
    
    // TODO: 10.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        guard newState == .Ending, let annotation = view.annotation as? MKPointAnnotation
            else { return }
        
        reverseGeocode(annotation) { placemark in
            annotation.title = placemark.name
            annotation.subtitle = "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)"
        }
    }
}

// MARK:- CLLocationManagerDelegate

// TODO: 11.
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

// TODO: 7.1
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

// MARK:- CLLocation

// TODO: 9.
extension CLLocation {
    func isWalkingDistanceFromLocation(location: CLLocation) -> Bool {
        let walkingDistance: CLLocationDistance = 400
        
        return distanceFromLocation(location) <= walkingDistance
    }
    
    convenience init(annotation: MKAnnotation) {
        self.init(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
    }
}