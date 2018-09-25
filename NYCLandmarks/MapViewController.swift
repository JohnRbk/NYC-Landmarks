//
//  ViewController.swift
//  NYCLandmarks
//
//  Created by John Robokos on 9/19/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import Mapbox
import XCGLogger

class MapViewController: UIViewController {
    let log = XCGLogger.default
    
    @IBOutlet weak var mapView: MGLMapView!

    @IBOutlet var popupView: Popup!

    var newYork: MGLCoordinateBounds?

    @IBOutlet weak var panelTopConstraint: NSLayoutConstraint!
    
    enum Events: String {
        
        case updateFavorites = "updateFavorites"
        
        var notification: Notification.Name {
            return Notification.Name(rawValue: self.rawValue )
        }
    }
    
    // Clear up notifications. As of OS9, this may no longer be needed
    // https://developer.apple.com/library/content/releasenotes/Foundation/RN-Foundation/index.html#//apple_ref/doc/uid/TP30000742
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.updateFavorites(_:)), name: MapViewController.Events.updateFavorites.notification, object: nil)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        self.mapView.showsUserLocation = true
        self.popupView.safeLayoutGuide = self.view.safeAreaLayoutGuide
        self.popupView.mapViewController = self
        self.view.addSubview(self.popupView)
        self.mapView.delegate = self

        // New York's bounds
        let padding = 1.0
        let ne = CLLocationCoordinate2D(latitude: 40.9137 + padding, longitude: -73.7206 + padding)
        let sw = CLLocationCoordinate2D(latitude: 40.5029 - padding, longitude: -74.2546 - padding)

        self.newYork = MGLCoordinateBounds(sw: sw, ne: ne)
    }

    @objc @IBAction func handleMapTap(sender: UITapGestureRecognizer) {        

        let screenPoint = sender.location(in: self.mapView)

        let styleLayers: Set = ["landmark", "landmark-dots"]

        let features = mapView.visibleFeatures(at: screenPoint,
                                               styleLayerIdentifiers: styleLayers)

        var selectedFeature: MGLFeature?

        if features.isEmpty == false {
            selectedFeature = features.first
        } else {
            for i in 1...10 {
                // Why multiply by zoom?  When far away from the US, we don't want to select a massive area
                // When zoomed in close, we want to make sure the rectangle is a bit bigger
                let delta: CGFloat = CGFloat(i) * CGFloat(mapView.zoomLevel)
                let rect = CGRect(x: screenPoint.x - delta/2, y: screenPoint.y - delta/2, width: delta, height: delta)
                let features = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: styleLayers)
                if features.isEmpty == false {
                    selectedFeature = features.first
                    break
                }
            }
        }

        if let landmark = selectedFeature,
            let id = landmark.attribute(forKey: "FID") as? Int {

            if let l = self.mapView.style?.layer(withIdentifier: "landmark-selected") as? MGLSymbolStyleLayer {
                l.predicate = NSPredicate(format: "FID == %i", id)

                self.popupView.show(withAttributes: landmark.attributes)
                self.panelTopConstraint.constant = -135 // move panel under popup
            }

        }

    }
    
    @objc func updateFavorites(_ notification: Notification) {
        
        let favorites = Favorites.default.allFavorites()
        
        if favorites.isEmpty {
            return
        }
        
        if let l = mapView.style?.layer(withIdentifier: "landmark-favorites") as? MGLSymbolStyleLayer {
            l.predicate = NSPredicate(format: "FID IN %@", favorites)
        } else {
            fatalError("unable to find style: landmark-favorites")
        }
    }

    @IBAction func locateMe(_ sender: Any) {
        let status = CLLocationManager.authorizationStatus()
        let badStatuses = [CLAuthorizationStatus.denied,
                           CLAuthorizationStatus.notDetermined,
                           CLAuthorizationStatus.restricted]

        if let userLoc = mapView.userLocation,
            badStatuses.contains(status) == false,
            CLLocationCoordinate2DIsValid(userLoc.coordinate) {

            self.mapView.setCenter(userLoc.coordinate,
                                   zoomLevel: 15,
                                   animated: true)

        } else {
            print("User has not allowed CoreLocation auth")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? DetailViewController,
            let popup = sender as? Popup,
            segue.identifier == "DetailViewSegue" {
            dest.attributes = popup.attributes
        }
     }

}
