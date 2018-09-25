//
//  MapViewController+MapDelegate.swift
//  NYCLandmarks
//
//  Created by John Robokos on 9/21/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import Mapbox
import XCGLogger

extension MapViewController: MGLMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        self.updateFavorites(Notification(name: Events.updateFavorites.notification))
    }
    
    func mapView(_ mapView: MGLMapView, shouldChangeFrom oldCamera: MGLMapCamera, to newCamera: MGLMapCamera) -> Bool {
        
        // Get the current camera to restore it after.
        let currentCamera = mapView.camera
        
        // From the new camera obtain the center to test if it’s inside the boundaries.
        let newCameraCenter = newCamera.centerCoordinate
        
        // Set the map’s visible bounds to newCamera.
        mapView.camera = newCamera
        let newVisibleCoordinates = mapView.visibleCoordinateBounds
        
        // Revert the camera.
        mapView.camera = currentCamera
        
        // Test if the newCameraCenter and newVisibleCoordinates are inside NY.
        let inside = MGLCoordinateInCoordinateBounds(newCameraCenter, self.newYork!)
        let intersects = MGLCoordinateInCoordinateBounds(newVisibleCoordinates.ne, self.newYork!) && MGLCoordinateInCoordinateBounds(newVisibleCoordinates.sw, self.newYork!)
        
        return inside && intersects
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        self.popupView.hide()
        self.panelTopConstraint.constant = 0
    }
}
