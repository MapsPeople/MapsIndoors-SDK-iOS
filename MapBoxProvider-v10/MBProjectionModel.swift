import Foundation
import MapsIndoorsCore
import MapboxMaps

class MBProjectionModel: MPProjection {
    
    private weak var view: MapView?
    
    required init(view: MapView?) {
        self.view = view
    }
    
    var visibleRegion: MPGeoRegion {
        @MainActor
        get {
            guard let view else { return MPGeoRegion(nearLeft: CLLocationCoordinate2D(), farLeft: CLLocationCoordinate2D(), farRight: CLLocationCoordinate2D(), nearRight: CLLocationCoordinate2D()) }
            
            // Using the view's frame, we can derive latlngs for each corner of the camera view
            let farLeft = view.mapboxMap.coordinate(for:    CGPoint(x: 0,                   y: 0))
            let farRight = view.mapboxMap.coordinate(for:   CGPoint(x: view.frame.width,    y: 0))
            let nearLeft = view.mapboxMap.coordinate(for:   CGPoint(x: 0,                   y: view.frame.height))
            let nearRight = view.mapboxMap.coordinate(for:  CGPoint(x: view.frame.width,    y: view.frame.height))
            return MPGeoRegion(nearLeft: nearLeft, farLeft: farLeft, farRight: farRight, nearRight: nearRight)
        }
    }

    @MainActor
    func coordinateFor(point: CGPoint) async -> CLLocationCoordinate2D {
        return view?.mapboxMap.coordinate(for: point) ?? CLLocationCoordinate2D()
    }
    
    @MainActor
    func pointFor(coordinate: CLLocationCoordinate2D) async -> CGPoint {
        return view?.mapboxMap.point(for: coordinate) ?? .zero
    }

}
