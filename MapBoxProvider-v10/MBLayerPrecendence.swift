import Foundation
import MapboxMaps
import MapsIndoorsCore

fileprivate typealias LayerId = Constants.LayerIDs
/**
 * This class is responsible for rendering content in the desired order
 * The `LayerIDs` defined in the struct `Constants` contains the unique IDs by which the layers were rendered specifically on Mapbox
 * The static functions can be used from anywhere
 */
class MBLayerPrecendence {
    
    private weak var style: Style?
    
    required init(style: Style?) {
        self.style = style
    }
    
    func updateLayerOrder() {
        guard let style else { return }
        MBLayerPrecendence.reArrangeMPLayers(style: style)
    }
    
    func moveLayer(layerId: String, referenceLayerId: String, isAbove: Bool) -> Bool {
        guard let style else { return false }

        return MBLayerPrecendence.moveLayer(style: style, layerId: layerId, referenceLayerId: referenceLayerId, isAbove: isAbove)
    }
    
    static func moveLayer(style: Style, layerId: String, referenceLayerId: String, isAbove: Bool) -> Bool {
        if !(style.imageExists(withId: layerId)) || !(style.imageExists(withId: referenceLayerId)) {
            return false
        }
        do {
            try style.moveLayer(withId: layerId, to: isAbove ? .above(referenceLayerId) : .below(referenceLayerId))
            return true
        } catch {
            MPLog.mapbox.error("Error moving layer \(layerId): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Arranges the order of MP layers back to their default state
    static func reArrangeMPLayers(style: Style) {
        let layerOrder = [    LayerId.tileLayer: LayerPosition.below(LayerId.markerLayer),
                              LayerId.markerLayer: LayerPosition.above(LayerId.tileLayer),
                              LayerId.polygonFillLayer: LayerPosition.above(LayerId.markerLayer),
                              LayerId.polygonLineLayer: LayerPosition.above(LayerId.polygonFillLayer),
                              LayerId.model2DLayer: LayerPosition.above(LayerId.polygonLineLayer),
                              LayerId.circleLayer: LayerPosition.above(LayerId.model2DLayer),
                              LayerId.blueDotLayer: LayerPosition.above(LayerId.circleLayer)]
        
        for (layerId, position) in layerOrder {
            if style.layerExists(withId: layerId) {
                do {
                    try style.moveLayer(withId: layerId, to: position)
                } catch {
                    MPLog.mapbox.error("Error moving layer \(layerId): \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// May use this when moving layer position with respect to index
    static func arrangeMPLayers(style: Style) {
        let layerCollection = style.styleManager.getStyleLayers()
        
        let layerOrder = [LayerId.tileLayer, LayerId.markerLayer, LayerId.polygonFillLayer, LayerId.polygonLineLayer, LayerId.model2DLayer, LayerId.circleLayer, LayerId.blueDotLayer]
        
        for layer in layerCollection {
            guard let index = layerOrder.firstIndex(of: layer.id) else {
                continue
            }
            
            for i in index+1..<layerOrder.count {
                let nextLayerId = layerOrder[i]
                if style.layerExists(withId: nextLayerId) {
                    do {
                        try style.moveLayer(withId: layer.id, to: .above(nextLayerId))
                        break
                    } catch {
                        MPLog.mapbox.error("Error moving layer \(layer.id): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
