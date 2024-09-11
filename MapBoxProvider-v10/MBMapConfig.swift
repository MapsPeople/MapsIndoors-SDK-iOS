import Foundation
import MapboxMaps
import MapsIndoorsCore

/// Extending MPMapConfig with an initializer for Mapbox
@objc public extension MPMapConfig {

    convenience init(mapBoxView: MapView, accessToken: String) {
        self.init()
        let mapboxProvider = MapBoxProvider(mapView: mapBoxView, accessToken: accessToken)
        self.mapProvider = mapboxProvider
    }
    
}
