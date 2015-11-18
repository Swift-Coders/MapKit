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

extension MapViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
}

class MapViewController: UIViewController {
    
    @IBOutlet private weak var mapView: MKMapView!
    
    private let locationManager = CLLocationManager()
    private var votes = Set<Vote>()
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        guard #available(iOS 9.0, *) else { return }
        mapView.showsCompass = true
        mapView.showsScale = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        segue.destinationViewController.popoverPresentationController?.delegate = self
        
        if let gesture = sender as? UIGestureRecognizer
         , let popoverController = segue.destinationViewController.popoverPresentationController {
            let tapPoint = gesture.locationInView(mapView)
            popoverController.sourceRect = CGRect(origin: tapPoint, size: CGSizeZero)
        }
    }
    
    // MARK: Map Actions
    
    @IBAction private func pickCandidate(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .Began else { return }
        performSegueWithIdentifier(.PickCandidate, sender: gesture)
    }
    
    // Unwind Segue
    @IBAction func candidateSelected(segue: UIStoryboardSegue) {
        guard let candidateContainer = segue.sourceViewController as? CandidateContainer
            , let candidate = candidateContainer.candidate
            , let tapPoint = segue.sourceViewController.popoverPresentationController?.sourceRect.origin
            else { return }
        
        addVote(candidate: candidate, location: tapPoint)
    }
    
    private func addVote(candidate candidate: Candidate, location: CGPoint) {
        let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
        let vote = Vote(candidate: candidate, coordinate: coordinate)
        
        vote.reverseGeocode { placemark in
            vote.placemark = placemark
            vote.subtitle = placemark.name
            self.mapView.selectAnnotation(vote, animated: true)
        }
        addVote(vote)
    }
    
    private func addVote(vote: Vote) {
        votes.insert(vote)
        
        mapView.addAnnotation(vote)
        mapView.showAnnotations([vote], animated: false)
    }
    
    private func remoteVote(vote: Vote) {
        votes.remove(vote)
        mapView.removeAnnotation(vote)
    }
    
    @IBAction private func openToolbox(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Summary", style: .Default) { action in
            self.showVoteSummary(self.votes)
        })
        alert.addAction(UIAlertAction(title: "Votes 1 Mile Around Me", style: .Default) { action in
            let votes = try? self.votesAround()
            self.showVoteSummary(votes ?? [])
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func countVotes<C: CollectionType where C.Generator.Element == Vote>(votes: C, party: Party) -> Int {
        return votes.filter { $0.candidate.party == party }.count
        //return votes.reduce(0) { $0 + ($1.candidate.party == party ? 1 : 0) } // another solution
    }
    
    private func showVoteSummary<C: CollectionType where C.Generator.Element == Vote>(votes: C) {
        let democrats = countVotes(votes, party: .Democrat)
        let republicans = countVotes(votes, party: .Republican)
        
        let results = "\(democrats) votes for the \(Party.Democrat.rawValue) party\n\(republicans) votes for the \(Party.Republican.rawValue) party"
        let alert = UIAlertController(title: "Vote Summary", message: results, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Close", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    enum MapError: String, ErrorType {
        case NoUserLocation = "User Location Cannot Be Determined"
    }
    
    private func votesAround(distace: CLLocationDistance = 1600.0) throws -> [Vote] {
        guard let userLocation = mapView.userLocation.location else { throw MapError.NoUserLocation }
        return votes.filter { $0.location.distanceFromLocation(userLocation) < distace }
    }
    
    @IBAction private func centerOnUserLocation(sender: UIBarButtonItem) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showAnnotations([mapView.userLocation], animated: true)
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK:- MKAnnotation

extension MKAnnotation {
    private func reverseGeocode(completion: (CLPlacemark -> Void)? = nil) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, _) in
            guard let placemark = placemarks?.first else { return }
            completion?(placemark)
        }
    }
}

// MARK:- MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKindOfClass(MKUserLocation.self) else { return nil }
        guard let vote = annotation as? Vote else { return nil }
        
        let reuseIdentifier = "PinView"
        let pinView: MKPinAnnotationView
        
        defer {
            if #available(iOS 9.0, *) {
                pinView.pinTintColor = vote.candidate.preferredColor
            } else {
                switch vote.candidate.party {
                case .Democrat: pinView.pinColor = .Purple
                case .Republican: pinView.pinColor = .Red
                }
            }
        }
        
        func buttonWithTitle(title: String, type: CalloutAction) -> UIButton {
            let button = UIButton(type: .System)
            button.setTitle(title, forState: .Normal)
            button.sizeToFit()
            button.tag = type.rawValue
            return button
        }
        
        // Boilerplate
        //
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView {
            pinView = annotationView
            pinView.annotation = annotation
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.draggable = false
            
            pinView.rightCalloutAccessoryView = buttonWithTitle("❌", type: .Delete)
            pinView.leftCalloutAccessoryView = buttonWithTitle("🚘", type: .Navigate)
        }
        return pinView
    }
    
    private enum CalloutAction: Int {
        case Delete = 1
        case Navigate = 2
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation else { return }
        
        switch CalloutAction(rawValue: control.tag) {
        case .Delete?:
            mapView.removeAnnotation(annotation)
            
        case .Navigate?:
            let location = CLLocation(annotation: annotation)
            let isWalkingDistance = mapView.userLocation.location?.isWalkingDistanceFromLocation(location) ?? false
            
            annotation.reverseGeocode { placemark in
                let mode = isWalkingDistance ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeDriving
                let item = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                item.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: mode])
            }
        default: break
        }
    }
}

// MARK:- CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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

// MARK:- CLLocation

extension CLLocation {
    func isWalkingDistanceFromLocation(location: CLLocation) -> Bool {
        let walkingDistance: CLLocationDistance = 400
        
        return distanceFromLocation(location) <= walkingDistance
    }
    
    convenience init(annotation: MKAnnotation) {
        self.init(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
    }
}

// MARK:- SegueHandlerType

extension MapViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case PickCandidate
    }
}