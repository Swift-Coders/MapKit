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

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
    }
    
    @IBAction func addPin(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            let tapPoint = gesture.locationInView(mapView) // let vs. var
            let coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
            
            // Model object - represents data
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(coordinate.latitude), \(coordinate.longitude)"
            mapView.addAnnotation(annotation)
            
            // Optional
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, _) in
                if let placemark = placemarks?.first as? CLPlacemark {
                    annotation.subtitle = annotation.title
                    annotation.title = placemark.name
                }
            }
        }
    }
    
    // Model vs. View in MVC
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // Do not create a custom annotation view for User Location
        if annotation.isKindOfClass(MKUserLocation.self) { return nil }
        
        let reuseIdentifier = "PinView"
        let pinView: MKPinAnnotationView
        
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView {
            // Dequeued an annotation view
            pinView = annotationView
            pinView.annotation = annotation
        } else {
            // Create a new annotation view
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            
            let button = UIButton.buttonWithType(.System) as! UIButton
            button.setTitle("❌", forState: .Normal)
            button.sizeToFit()
            pinView.rightCalloutAccessoryView = button
        }

        // Prepare the annotation view (color, callout, etc.)
        // if annotation == ... then change color
        pinView.pinColor = .Purple
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        mapView.removeAnnotation(view.annotation)
    }
}