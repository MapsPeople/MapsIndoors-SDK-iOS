//
//  GMCameraUpdate.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Malte Myhlendorph on 21/06/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

class GMCameraUpdate: MPCameraUpdate {
    
    private weak var googleCameraUpdate: GMSCameraUpdate!

    public init(cameraUpdate: GMSCameraUpdate) {
        googleCameraUpdate = cameraUpdate
    }
    
    func fitBounds(_ bounds: MPGeoBounds) -> MPCameraUpdate {
        let googleBound = GMSCoordinateBounds(coordinate: bounds.northEast, coordinate: bounds.southWest)
        let googleFitBounds = GMSCameraUpdate.fit(googleBound)
        return GMCameraUpdate(cameraUpdate: googleFitBounds)
    }
    
    func fitBoundsWithPadding(_ bounds: MPGeoBounds, padding: CGFloat) -> MPCameraUpdate {
        let googleBound = GMSCoordinateBounds(coordinate: bounds.northEast, coordinate: bounds.southWest)
        let googleFitBoundsWithPadding = GMSCameraUpdate.fit(googleBound, withPadding: padding)
        return GMCameraUpdate(cameraUpdate: googleFitBoundsWithPadding)
    }
    
    func fitBoundsWithEdgeInserts(_ bounds: MPGeoBounds, edgeInsets: UIEdgeInsets) -> MPCameraUpdate {
        let googleBound = GMSCoordinateBounds(coordinate: bounds.northEast, coordinate: bounds.southWest)
        let googleFitBoundsWithEdgeInsets = GMSCameraUpdate.fit(googleBound, with: edgeInsets)
        return GMCameraUpdate(cameraUpdate: googleFitBoundsWithEdgeInsets)
    }
    
}
