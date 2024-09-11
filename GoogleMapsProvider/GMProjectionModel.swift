//
//  GMProjectionModel.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Malte Myhlendorph on 02/06/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

/**
#GMSProjection Class Reference
Defines a mapping between Earth coordinates (CLLocationCoordinate2D) and coordinates in the map's view (CGPoint).
*/

class GMProjection: MPProjection {
    
    private let projection: GMSProjection?

    required init(projection: GMSProjection?) {
        self.projection = projection
    }
    
    var visibleRegion: MPGeoRegion {
        @MainActor
        get async {
            MPGeoRegion(nearLeft: projection?.visibleRegion().nearLeft ?? CLLocationCoordinate2D(),
                        farLeft: projection?.visibleRegion().farLeft ?? CLLocationCoordinate2D(),
                        farRight: projection?.visibleRegion().farRight ?? CLLocationCoordinate2D(),
                        nearRight: projection?.visibleRegion().nearRight ?? CLLocationCoordinate2D())
        }
    }

    @MainActor
    func coordinateFor(point: CGPoint) async -> CLLocationCoordinate2D {
        return projection?.coordinate(for: point) ?? CLLocationCoordinate2D()
    }
    
    @MainActor
    func pointFor(coordinate: CLLocationCoordinate2D) async -> CGPoint {
        return projection?.point(for: coordinate) ?? .zero
    }
    
}
