import Foundation
import MapsIndoorsCore
import MapboxMaps

class MBPositionPresenter: MPPositionPresenter {
    
    private weak var map: MapboxMap?
    
    required init(map: MapboxMap?) {
        self.map = map
    }
    
    private let SRC_BLUEDOT_CIRCLE = "SOURCE_MP_BLUEDOT_CIRCLE"
    private let SRC_BLUEDOT_MARKER = "SOURCE_MP_BLUEDOT_MARKER"
    private let LAYER_BLUEDOT_CIRCLE = "LAYER_MP_BLUEDOT_CIRCLE"
    private let LAYER_BLUEDOT_MARKER = "LAYER_MP_BLUEDOT_MARKER"
    
    private let BLUEDOT_ICON_ID = "MP_BLUEDOT_ICON"
    private let BLUEDOT_CIRCLE_SIZE_ID = "MP_BLUEDOT_CIRLCE_SIZE"
 
    func apply(position: CLLocationCoordinate2D,
               markerIcon: UIImage,
               markerBearing: Double,
               markerOpacity: Double,
               circleRadiusMeters: Double,
               circleFillColor: UIColor,
               circleStrokeColor: UIColor,
               circleStrokeWidth: Double) {
        guard let map else { return }

        DispatchQueue.main.async { [self] in
            addSourcesAndLayersIfNotPresent()
            do {
                try map.style.updateLayer(withId: LAYER_BLUEDOT_CIRCLE, type: CircleLayer.self) { circleLayer in
                    circleLayer.visibility = .constant(.visible)
                    circleLayer.circleColor = .constant(StyleColor(circleFillColor))
                    circleLayer.circleOpacity = .constant(1-circleFillColor.cgColor.alpha)
                    circleLayer.circleStrokeColor = .constant(StyleColor(circleStrokeColor))
                    circleLayer.circleStrokeOpacity = .constant(1-circleStrokeColor.cgColor.alpha)
                    circleLayer.circleStrokeWidth = .constant(circleStrokeWidth)
                }
                
                try map.style.updateLayer(withId: LAYER_BLUEDOT_MARKER, type: SymbolLayer.self) { markerLayer in
                    markerLayer.visibility = .constant(.visible)
                    markerLayer.iconOpacity = .constant(markerOpacity)
                    markerLayer.iconRotate = .constant(markerBearing)
                    markerLayer.iconImage = .expression(Exp(.image) { Exp(.literal) { BLUEDOT_ICON_ID } })
                    markerLayer.iconRotationAlignment = .constant(.map)
                    markerLayer.iconPitchAlignment = .constant(.map)
                    markerLayer.iconAllowOverlap = .constant(true)
                    markerLayer.textAllowOverlap = .constant(true)
                }
                
                let circleSize = circleRadiusMeters / (cos(position.latitude * (.pi / 180)) * 0.019)
                var bluedotFeature = Feature.init(geometry: .point(Point(position)))
                bluedotFeature.properties = [BLUEDOT_CIRCLE_SIZE_ID: .number(circleSize)]

                try map.style.updateGeoJSONSource(withId: SRC_BLUEDOT_MARKER, geoJSON: GeoJSONObject.feature(bluedotFeature))
                try map.style.updateGeoJSONSource(withId: SRC_BLUEDOT_CIRCLE, geoJSON: GeoJSONObject.feature(bluedotFeature))

                try map.style.addImage(markerIcon, id: BLUEDOT_ICON_ID, sdf: false)
                
            } catch {
                MPLog.mapbox.error("Error attempting to update blue dot layers: " + error.localizedDescription)
            }
        }
        
    }
    
    func clear() {
        guard let map else { return }

        DispatchQueue.main.async { [self] in
            do {
                var circleLayer: CircleLayer? = try map.style.layer(withId: LAYER_BLUEDOT_CIRCLE) as? CircleLayer
                circleLayer?.visibility = .constant(.none)
                
                var markerLayer: SymbolLayer? = try map.style.layer(withId: LAYER_BLUEDOT_MARKER) as? SymbolLayer
                markerLayer?.visibility = .constant(.none)
            } catch { }
        }
    }
    
    private func addSourcesAndLayersIfNotPresent() {
        guard let map else { return }

        do {
            if map.style.sourceExists(withId: SRC_BLUEDOT_CIRCLE) == false {
                var source = GeoJSONSource()
                source.data = .featureCollection(FeatureCollection(features: []))
                try map.style.addSource(source, id: SRC_BLUEDOT_CIRCLE)
            }
            
            if map.style.layerExists(withId: LAYER_BLUEDOT_CIRCLE) == false {
                var circleLayer = CircleLayer(id: LAYER_BLUEDOT_CIRCLE)
                circleLayer.source = SRC_BLUEDOT_CIRCLE
                circleLayer.circlePitchAlignment = .constant(.map)
                circleLayer.circlePitchScale = .constant(.map)

                let stops: [Double: Exp] = [
                    1: Exp(.product) {
                        MBRenderer.zoom22Scale
                        Exp(.get) { Exp(.literal) { BLUEDOT_CIRCLE_SIZE_ID } }
                    }
                    ,
                    22: Exp(.get) { Exp(.literal) { BLUEDOT_CIRCLE_SIZE_ID } }
                ]
                
                circleLayer.circleRadius = .expression(
                     Exp(.interpolate) {
                         Exp(.exponential) { 2 }
                         Exp(.zoom)
                         stops
                     }
                )
                try map.style.addLayer(circleLayer, layerPosition: .default)
            } else {
                try map.style.moveLayer(withId: LAYER_BLUEDOT_CIRCLE, to: .default)
            }
            
            if map.style.sourceExists(withId: SRC_BLUEDOT_MARKER) == false {
                var source = GeoJSONSource()
                source.data = .featureCollection(FeatureCollection(features: []))
                try map.style.addSource(source, id: SRC_BLUEDOT_MARKER)
            }
            
            if map.style.layerExists(withId: LAYER_BLUEDOT_MARKER) == false {
                var markerLayer = SymbolLayer(id: LAYER_BLUEDOT_MARKER)
                markerLayer.source = SRC_BLUEDOT_MARKER
                try map.style.addLayer(markerLayer, layerPosition: .above(LAYER_BLUEDOT_CIRCLE))
            } else {
                try map.style.moveLayer(withId: LAYER_BLUEDOT_MARKER, to: .above(LAYER_BLUEDOT_CIRCLE))
            }
            
        } catch {
            MPLog.mapbox.error("Error attempting to create blue dot sources and layers: " + error.localizedDescription)
        }
        
    }

}
