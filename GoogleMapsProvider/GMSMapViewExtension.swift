import Foundation
import MapsIndoorsCore
import GoogleMaps

@objc public extension GMSMapView {
    
    /// Returns the index of an MP Layer as a `NSRange` used to render content on  map engine `GoogleMaps`
    /// - Parameter mpLayer: `MPLayer` type as Google Maps `Overlay`a.k.a layer used to render MapsIndoors content internally. Use the dot`.` notation
    /// - Returns: `NSRange`. Use the returned NSRange to filter or manipulate the content that falls within this range of Z indices. For the `2D Model` you will get `1200000` and `5001` meaning everything from `1200000` to `1205000` is `2DModel`` zIndex`
    /// - Example:
    ///   for zIndex in range.location..<NSMaxRange(range) {
    ///             // Do something with the content at this Z index
    ///         }
   
    @objc func getMapsIndoorsGoogleMapsIndexRange(for mpLayer: MPLayer) -> NSRange {
        return extractedFunc(mpLayer)
    }
    
    fileprivate func extractedFunc(_ mpLayer: MPLayer) -> NSRange {
        let (startIndex, endIndex): (Int, Int)
        switch mpLayer {
        case .MAPSINDOORS_ALL_LAYERS_RANGE:
            startIndex = MapOverlayZIndex.startMapsIndoorOverlays.rawValue
            endIndex = MapOverlayZIndex.endMapsIndoorOverlays.rawValue
        case .MARKER_RANGE:
            startIndex = MapOverlayZIndex.startMarkerOverlay.rawValue
            endIndex = MapOverlayZIndex.endMarkerOverlay.rawValue
        case .POLYGONS_RANGE:
            startIndex = MapOverlayZIndex.startPolygonsRange.rawValue
            endIndex = MapOverlayZIndex.endPolygonsRange.rawValue
        case .BUILDING_OUTLINE_HIGHLIGHT_RANGE:
            startIndex = MapOverlayZIndex.buildingOutlineHighlight.rawValue
            endIndex = MapOverlayZIndex.locationOutlineHighlight.rawValue
        case .LOCATION_OUTLINE_HIGHLIGHT_RANGE:
            startIndex = MapOverlayZIndex.locationOutlineHighlight.rawValue
            endIndex = MapOverlayZIndex.directionsOverlays.rawValue
        case .DIRECTIONS_RANGE:
            startIndex = MapOverlayZIndex.directionsOverlays.rawValue
            endIndex = MapOverlayZIndex.positioningAccuracyCircle.rawValue
        case .MODEL_2D_RANGE:
            startIndex = MapOverlayZIndex.startModel2DRange.rawValue
            endIndex = MapOverlayZIndex.endModel2DRange.rawValue
        case .BLUEDOT_RANGE:
            startIndex = MapOverlayZIndex.positioningAccuracyCircle.rawValue
            endIndex = MapOverlayZIndex.userLocationMarker.rawValue
        }
        
        let range = NSRange(location: startIndex, length: endIndex - startIndex + 1)

        return range
    }
}
/**
 *
 * The `zIndex` ranges used to render MapsIndoors content on Google Maps
 * `MAPSINDOORS_ALL_LAYERS_RANGE` will return a range in which all the MapsIndoors content is placed between
 * `MARKER_RANGE` will return a range in which all the MapsIndoors markers are placed between. Of type `GMSMarker`
 * `POLYGONS_RANGE` will return a range in which all the MapsIndoors Polygons are placed between. Of type `GMSPolygon`
 * `BUILDING_OUTLINE_HIGHLIGHT_RANGE` will return a range in which the building outline is placed between
 * `LOCATION_OUTLINE_HIGHLIGHT_RANGE`  will return a range in which the location outline is placed between
 * `DIRECTIONS_RANGE` will return a range in which the directions renderer line is placed between
 * `MODEL_2D_RANGE` will return a range in which all the 2D Models are placed between. Of type `GMSOverlay`
 * `BLUEDOT_RANGE` will return a range in which both the bluedot and the accuracy circle is placed. Blue dot is a `GMSMarker` whereas accuracy circle is `GMSCircle`
 *
 */

@objc public enum MPLayer: Int {
    case MAPSINDOORS_ALL_LAYERS_RANGE
    case MARKER_RANGE
    case POLYGONS_RANGE
    case BUILDING_OUTLINE_HIGHLIGHT_RANGE
    case LOCATION_OUTLINE_HIGHLIGHT_RANGE
    case DIRECTIONS_RANGE
    case MODEL_2D_RANGE
    case BLUEDOT_RANGE
}

fileprivate extension MapOverlayZIndex {
    /// Returns tuple as range for content
    /// - Returns: `start`content is placed between and `end`
    func getRange() -> (start: Int, end: Int) {
        let start = self.rawValue
        var end = start
        
        switch self {
        case .startMapsIndoorOverlays:
            end = MapOverlayZIndex.endMapsIndoorOverlays.rawValue
        case .startMarkerOverlay:
            end = MapOverlayZIndex.endMarkerOverlay.rawValue
        case .startPolygonsRange:
            end = MapOverlayZIndex.endPolygonsRange.rawValue
        case .startModel2DRange:
            end = MapOverlayZIndex.endModel2DRange.rawValue
        case .positioningAccuracyCircle:
            end = MapOverlayZIndex.userLocationMarker.rawValue
        default:
            break
        }
        
        return (start, end)
    }
}
