//
//  MapBoxDelegate.swift
//  MapsIndoorsMapbox
//
//  Created by Malte Myhlendorph on 16/05/2023.
//  Copyright © 2023 MapsPeople A/S. All rights reserved.
//

import Foundation
import MapboxMaps
import MapsIndoorsCore

class MapboxWorldTransitionHandler: GestureManagerDelegate {
    
    weak var mapProviderDelegate: MPMapProviderDelegate?
    var originalMapViewDelegate: GestureManagerDelegate?
    
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didBegin gestureType: MapboxMaps.GestureType) {
        mapProviderDelegate?.cameraWillMove()
    }
    
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gestureType: MapboxMaps.GestureType, willAnimate: Bool) {
        mapProviderDelegate?.cameraChangedPosition()
        if gestureType == .pan {
            mapProviderDelegate?.cameraIdle()
        }
    }
    
    func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEndAnimatingFor gestureType: MapboxMaps.GestureType) {
        mapProviderDelegate?.cameraIdle()
    }
    
}
