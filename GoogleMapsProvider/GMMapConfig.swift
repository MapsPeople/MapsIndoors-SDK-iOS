import Foundation
import MapsIndoorsCore
import GoogleMaps

/// Extending MPMapConfig with an initializer for Google Maps
@objc public extension MPMapConfig {

    @objc convenience init(gmsMapView: GMSMapView, googleApiKey: String) {
        self.init()
        self.mapProvider = GoogleMapProvider(mapView: gmsMapView, googleApiKey: googleApiKey)
    }
    
}
