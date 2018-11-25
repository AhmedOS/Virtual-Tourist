//
//  MapVC.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/17/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {
    
    let photosCollectionSegueID = "showPhotos"
    
    var allMapPins: [MapPin]!
    var selectedPin: MapPin?
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupMapPins()
        selectedPin = nil
    }
    
    @IBAction func handleLongPress(_ sender: Any) {
        let gestureRecognizer = sender as! UILongPressGestureRecognizer
        if gestureRecognizer.state != .began {
            return
        }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addCoordinate(touchMapCoordinate, pin: nil)
    }
    
    func setupMapPins() {
        mapView.removeAnnotations(mapView.annotations)
        allMapPins = ModelManager.shared().getAllPins()
        for pin in allMapPins {
            let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
            addCoordinate(coordinate, pin: pin)
        }
    }
    
    func addCoordinate(_ coordinate: CLLocationCoordinate2D, pin: MapPin?) {
        var mapPin: MapPin!
        if pin == nil {
            mapPin = MapPin(context: ModelManager.shared().viewContext)
            mapPin.latitude = Float(coordinate.latitude)
            mapPin.longitude = Float(coordinate.longitude)
            mapPin.images = [String]()
            ModelManager.shared().saveContext()
        }
        else {
            mapPin = pin
        }
        let annotation = FancyPointAnnotation()
        annotation.coordinate = coordinate
        annotation.pin = mapPin
        annotation.title = "Tap to View Photos"
        mapView.addAnnotation(annotation)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == photosCollectionSegueID {
            let vc = segue.destination as! PhotosCollectionVC
            vc.pin = selectedPin
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            selectedPin = (view.annotation as! FancyPointAnnotation).pin
            performSegue(withIdentifier: photosCollectionSegueID, sender: self)
        }
    }
}
