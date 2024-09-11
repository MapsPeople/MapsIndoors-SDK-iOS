import Foundation
import GoogleMaps
import MapsIndoorsCore

class GMPositionPresenter: MPPositionPresenter {
    
    private weak var map: GMSMapView!
    
    private var marker: GMSMarker
    private var circle: GMSCircle
    
    required init(map: GMSMapView) {
        self.map = map
        
        self.marker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        self.circle = GMSCircle(position: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 0)
        
        self.marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        self.marker.isFlat = true
        self.marker.zIndex = Int32(MapOverlayZIndex.userLocationMarker.rawValue)
        self.circle.zIndex = Int32(MapOverlayZIndex.positioningAccuracyCircle.rawValue)
    }
    
    func apply(position: CLLocationCoordinate2D,
               markerIcon: UIImage,
               markerBearing: Double,
               markerOpacity: Double,
               circleRadiusMeters: Double,
               circleFillColor: UIColor,
               circleStrokeColor: UIColor,
               circleStrokeWidth: Double
    ) {
        DispatchQueue.main.async {
            self.marker.position = position
            self.marker.icon = markerIcon
            self.marker.rotation = markerBearing
            self.marker.opacity = Float(markerOpacity)

            self.circle.position = position
            self.circle.radius = circleRadiusMeters
            self.circle.fillColor = circleFillColor
            self.circle.strokeColor = circleStrokeColor
            self.circle.strokeWidth = circleStrokeWidth

            if self.marker.map == nil {
                self.marker.map = self.map
            }
            
            if self.circle.map == nil {
                self.circle.map = self.map
            }
        }
    }
    
    func clear() {
        DispatchQueue.main.async { [self] in
            self.marker.map = nil
            self.circle.map = nil
        }
    }
    
}
