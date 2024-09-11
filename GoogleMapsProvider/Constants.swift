/// The Z indices for MP specific`Overlays` a.k.a. Layers a.k.a. Content
enum MapOverlayZIndex: Int {
    case startMapsIndoorOverlays = 1000000
    case endMapsIndoorOverlays  = 1499999
    
    case startFloorPlanRange = 1000001
    case endFloorPlanRange = 1199999
    
    case startPolygonsRange = 1200000
    case endPolygonsRange = 1202000
    
    case startModel2DRange = 1202001
    case endModel2DRange = 1205000
    
    case buildingOutlineHighlight = 1300000
    case locationOutlineHighlight  = 1300010
    case directionsOverlays        = 1300020
    
    case startMarkerOverlay = 1300100
    case endMarkerOverlay = 1300500
    
    // For the user location or `blue dot, starting index will be `positioningAccuracyCircle`and ending index will be `userLocationMarker`
    case positioningAccuracyCircle = 1300510
    case userLocationMarker = 1300520
}
