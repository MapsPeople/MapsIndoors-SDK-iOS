//
//  GMCameraPositionModel.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Malte Myhlendorph on 02/06/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

/**
 #GMSCameraPosition Class Reference
 An immutable class that aggregates all camera position parameters.
 Inherited by GMSMutableCameraPosition.
 */

class GMCameraPosition: MPCameraPosition {
    
    func camera(target: CLLocationCoordinate2D, zoom: Float) -> MPCameraPosition? {
        let googleMutableCameraPosition = GMSMutableCameraPosition(target: target, zoom: zoom)
        return GMCameraPosition(cameraPosition: googleMutableCameraPosition)
    }
    
    var target: CLLocationCoordinate2D {
        get {
            googleCameraPosition?.target ?? CLLocationCoordinate2D()
        }
    }
    
    var zoom: Float {
        get {
            googleCameraPosition?.zoom ?? 0
        }
    }
    
    var bearing: CLLocationDirection {
        get {
            googleCameraPosition?.bearing ?? 0
        }
    }
    
    var viewingAngle: Double {
        get {
            googleCameraPosition?.viewingAngle ?? 0
        }
    }
    
    weak var googleCameraPosition: GMSCameraPosition?
    
    required public init(cameraPosition: GMSCameraPosition?) {
        googleCameraPosition = cameraPosition
    }
}
