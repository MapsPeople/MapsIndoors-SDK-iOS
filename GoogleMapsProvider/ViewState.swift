import Foundation
import GoogleMaps
@_spi(Private) import MapsIndoorsCore
import UIKit

/**
  This enum defines which state changeing operations we have.
  There exists a state operation for each mutable characteristic of a view model's features (marker, polygon)
 */
enum StateOperation {
    case MARKER_VISIBLITY
    case MARKER_ICON
    case MARKER_POSITION
    case MARKER_ANCHOR
    case MARKER_CLICKABLE
    
    case POLYGON_VISIBILITY
    case POLYGON_FILL_COLOR
    case POLYGON_STROKE_COLOR
    case POLYGON_STROKE_WIDTH
    case POLYGON_GEOMETRY
    case POLYGON_CLICKABLE
    
    case FLOORPLAN_VISIBILITY
    case FLOORPLAN_STROKE_COLOR
    case FLOORPLAN_STROKE_WIDTH
    case FLOORPLAN_FILL_COLOR
    case FLOORPLAN_GEOMETRY
    
    case INFO_WINDOW
    
    case MODEL2D_VISIBILITY
    case MODEL2D_IMAGE
    case MODEL2D_POSITION
    case MODEL2D_BEARING
    case MODEL2D_CLICKABLE
}

enum MarkerState {
    case UNDEFINED
    case INVISIBLE
    case VISIBLE_ICON
    case VISIBLE_LABEL
    case VISIBLE_ICON_LABEL
    
    var isVisible: Bool {
        return !(self == .INVISIBLE)
    }
    
    var isIconVisible: Bool {
        return self == .VISIBLE_ICON || self == .VISIBLE_ICON_LABEL
    }
    
    var isLabelVisible: Bool {
        return self == .VISIBLE_LABEL || self == .VISIBLE_ICON_LABEL
    }
}

enum Model2DState {
    case UNDEFINED
    case INVISIBLE
    case VISIBLE
    
    var isVisible: Bool {
        return !(self == .INVISIBLE || self == .UNDEFINED)
    }
}

enum Constants {
    static let kMetersPerPixel = 0.014 // at 44°
}

enum PolygonState {
    case UNDEFINED
    case INVISIBLE
    case VISIBLE
    
    var isVisible: Bool {
        return self == .VISIBLE
    }
}

/**
 This class is responsible for hosting map features (markers, polygons, etc.) and compare against a view model.
 If the "on-map" state of a feature differs from that of the view model, we compute a set of operations required to make the two states equal.
 */
class ViewState {
    
    static let DEBUG_DRAW_IMAGE_BORDER = false

    private weak var map: GMSMapView!
    let id: String
    
    var lastTimeTag = CFAbsoluteTimeGetCurrent()

    // This is a dictionary because state operations are idempotent so we only ever need to execute one
    private var deltaOperations = MPThreadSafeDictionary<StateOperation, (GMSMapView) -> Void>(queueLabel: "MapsIndoors.GoogleViewStateOperationsQueue")

    var marker: GMSMarker
    private var polygons = [GMSPolygon]()
    private var floorPlanPolygons = [GMSPolygon]()
    private var overlay2D: GMSGroundOverlay
    private var InfoWindowAnchorPoint: CGPoint?
    
    private let is2dModelsEnabled: Bool
    
    private let isFloorPlanEnabled: Bool
    
    var shouldShowInfoWindow: Bool = false {
        didSet {
            deltaOperations[.INFO_WINDOW] = { [self] map in
                if shouldShowInfoWindow && map.selectedMarker != marker {
                    map.selectedMarker = marker
                    if let anchor = InfoWindowAnchorPoint {
                        marker.infoWindowAnchor = anchor
                    }
                }
                if shouldShowInfoWindow == false {
                    if let selected = map.selectedMarker {
                        if selected == marker {
                            map.selectedMarker = nil
                        }
                    }
                }
            }
        }
    }
    
    // Area of the underlying MapsIndoors Geometry (not necessarily related to the rendered geometry)
    var poiArea: Double = 0.0
    
    private var imageBundle: IconLabelBundle?
    private var model2dBundle: Model2DBundle?
    
    // Enables forced rendering (for selection & highlight) - collision logic checks this flag
    var forceRender = false
    
    var infoWindowText: String?
    
    // MARK: Marker
    var markerState: MarkerState = .UNDEFINED {
        didSet {
            switch self.markerState {
                case .VISIBLE_ICON_LABEL:
                    self.markerIcon = self.imageBundle?.both?.withDebugBox()
                case .VISIBLE_ICON:
                    self.markerIcon = self.imageBundle?.icon?.withDebugBox()
                case .VISIBLE_LABEL:
                    self.markerIcon = self.imageBundle?.label?.withDebugBox()
                case .UNDEFINED:
                    fallthrough
                case .INVISIBLE:
                    break
            }
            
            deltaOperations[.MARKER_VISIBLITY] = { map in
                switch self.markerState {
                    case .VISIBLE_ICON_LABEL:
                        fallthrough
                    case .VISIBLE_ICON:
                        fallthrough
                    case .VISIBLE_LABEL:
                        if self.marker.icon == nil {
                            self.marker.icon = UIImage()
                        }
                        self.marker.map = map
                    case .UNDEFINED:
                        fallthrough
                    case .INVISIBLE:
                        self.marker.map = nil
                }
            }
        }
    }
    
    var markerAnchor: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            deltaOperations[.MARKER_ANCHOR] = { map in
                guard self.marker.groundAnchor != self.markerAnchor else { return }
                self.marker.groundAnchor = self.markerAnchor
            }
        }
    }
    
    var markerPosition: CLLocationCoordinate2D? {
        didSet {
            deltaOperations[.MARKER_POSITION] = { map in
                guard let markerPosition = self.markerPosition, self.marker.position != markerPosition else { return }
                self.marker.position = markerPosition
            }
        }
    }
    
    var markerIcon: UIImage? {
        didSet {
            deltaOperations[.MARKER_ICON] = { map in
                guard self.marker.icon != self.markerIcon && self.markerIcon != nil else { return }
                self.marker.icon = self.markerIcon
            }
        }
    }
    
    var markerClickable: Bool = false {
        didSet {
            deltaOperations[.MARKER_CLICKABLE] = { map in
                self.marker.isTappable = self.markerClickable
            }
        }
    }
    
    // MARK: floorPlan
    var floorPlanState: PolygonState = .UNDEFINED {
        didSet {
            deltaOperations[.FLOORPLAN_VISIBILITY] = { map in
                switch self.floorPlanState {
                    case .VISIBLE:
                        for wall in self.floorPlanPolygons {
                            wall.map = map
                        }
                    case .UNDEFINED:
                        fallthrough
                    case .INVISIBLE:
                        for wall in self.floorPlanPolygons {
                            wall.map = nil
                        }
                }
            }
        }
    }
    
    var floorPlanStrokeColor: UIColor? {
        didSet {
            deltaOperations[.FLOORPLAN_STROKE_COLOR] = { map in
                for floorPlan in self.floorPlanPolygons {
                    floorPlan.strokeColor = self.floorPlanStrokeColor
                }
            }
        }
    }
    
    var floorPlanStrokeWidth: Double? {
        didSet {
            deltaOperations[.FLOORPLAN_STROKE_WIDTH] = { map in
                for floorPlan in self.floorPlanPolygons {
                    floorPlan.strokeWidth = CGFloat(self.floorPlanStrokeWidth ?? 0.0)
                }
            }
        }
    }
    
    var floorPlanFillColor: UIColor? {
        didSet {
            deltaOperations[.FLOORPLAN_FILL_COLOR] = { map in
                for floorPlan in self.floorPlanPolygons {
                    floorPlan.fillColor = self.floorPlanFillColor
                }
            }
        }
    }
    
    var floorPlanGeometries: [GMSPath]? {
        didSet {
            deltaOperations[.FLOORPLAN_GEOMETRY] = { map in
                let upper = Double(MapOverlayZIndex.endFloorPlanRange.rawValue)
                let lower = Double(MapOverlayZIndex.startFloorPlanRange.rawValue)
                let zindex = (abs(upper - self.poiArea).truncatingRemainder(dividingBy: lower) + lower) - 1 // -1 to ensure it is rendered below regular polygon geometry
                
                guard let floorPlanGeometries = self.floorPlanGeometries, zindex.isFinite, zindex.isNaN == false else { return }
                for geometry in floorPlanGeometries {
                    if self.floorPlanPolygons.contains(where: { $0.path?.encodedPath() == geometry.encodedPath() }) { continue }
                    
                    let floorPlanPolygon = GMSPolygon(path: geometry)
                    
                    // To avoid having the polygon briefly with its default blue color, before our logic updates it (causes flashing) - we set a transparent color here
                    floorPlanPolygon.fillColor = self.floorPlanFillColor ?? .red.withAlphaComponent(0.0)
                    floorPlanPolygon.strokeColor = self.floorPlanStrokeColor ?? .red.withAlphaComponent(0.0)
                    floorPlanPolygon.strokeWidth = self.floorPlanStrokeWidth ?? 0.0
                    floorPlanPolygon.zIndex = Int32(Int(zindex))
                    self.floorPlanPolygons.append(floorPlanPolygon)
 
                    // In order for the updated geometry to be reflected, we need to remove/re-add the map
                    if self.floorPlanState.isVisible {
                        floorPlanPolygon.map = map
                    }
                }
            }
        }
    }
    
    // MARK: Polygon
    var polygonState: PolygonState = .UNDEFINED {
        didSet {
            deltaOperations[.POLYGON_VISIBILITY] = { map in
                weak var weakSelf = self
                for polygon in self.polygons {
                    polygon.userData = weakSelf
                }
                switch self.polygonState {
                    case .VISIBLE:
                        for polygon in self.polygons {
                            polygon.map = map
                        }
                    case .UNDEFINED:
                        fallthrough
                    case .INVISIBLE:
                        for polygon in self.polygons {
                            polygon.map = nil
                        }
                }
            }
        }
    }
    
    var polygonFillColor: UIColor? {
        didSet {
            deltaOperations[.POLYGON_FILL_COLOR] = { map in
                for polygon in self.polygons {
                    polygon.fillColor = self.polygonFillColor
                }
            }
        }
    }
    
    var polygonStrokeColor: UIColor? {
        didSet {
            deltaOperations[.POLYGON_STROKE_COLOR] = { map in
                for polygon in self.polygons {
                    polygon.strokeColor = self.polygonStrokeColor
                }
            }
        }
    }
    
    var polygonStrokeWidth: Double? {
        didSet {
            deltaOperations[.POLYGON_STROKE_WIDTH] = { map in
                for polygon in self.polygons {
                    polygon.strokeWidth = CGFloat(self.polygonStrokeWidth ?? 0.0)
                }
            }
        }
    }
    
    var polygonGeometries: [GMSPath]? {
        didSet {
            deltaOperations[.POLYGON_GEOMETRY] = { map in
                let upper = Double(MapOverlayZIndex.endPolygonsRange.rawValue)
                let lower = Double(MapOverlayZIndex.startPolygonsRange.rawValue)
                let zindex = abs(upper - self.poiArea).truncatingRemainder(dividingBy: lower) + lower
                
                guard let polygonGeometries = self.polygonGeometries, zindex.isFinite, zindex.isNaN == false else { return }
                for geometry in polygonGeometries {
                    if self.polygons.contains(where: { $0.path?.encodedPath() == geometry.encodedPath() }) { continue }
                    
                    let polygon = GMSPolygon(path: geometry)
                    
                    // To avoid having the polygon briefly with its default blue color, before our logic updates it (causes flashing) - we set a transparent color here
                    polygon.fillColor = self.polygonFillColor ?? .red.withAlphaComponent(0.0)
                    polygon.strokeColor = self.polygonStrokeColor ?? .red.withAlphaComponent(0.0)
                    polygon.strokeWidth = self.polygonStrokeWidth ?? 0.0
                    polygon.zIndex = Int32(Int(zindex))
                    self.polygons.append(polygon)
 
                    // In order for the updated geometry to be reflected, we need to remove/re-add the map
                    if self.polygonState.isVisible {
                        polygon.map = map
                    }
                }
            }
        }
    }
    
    var polygonClickable: Bool = false {
        didSet {
            deltaOperations[.POLYGON_CLICKABLE] = { map in
                for polygon in self.polygons {
                    polygon.isTappable = self.polygonClickable
                }
            }
        }
    }
    
    // MARK: 2D Model
    private var model2DState: Model2DState = .UNDEFINED {
        didSet {
            if oldValue != model2DState {
                deltaOperations[.MODEL2D_VISIBILITY] = { map in
                    switch self.model2DState {
                    case .VISIBLE:
                        self.overlay2D.map = map
                    case .UNDEFINED:
                        fallthrough
                    case .INVISIBLE:
                        self.overlay2D.map = nil
                    }
                }
            }
        }
    }
    
    private var model2DPosition: CLLocationCoordinate2D? {
        didSet {
            deltaOperations[.MODEL2D_POSITION] = { map in
                guard let model2DPosition = self.model2DPosition, self.overlay2D.position != model2DPosition else { return }
                self.overlay2D.position = model2DPosition
            }
        }
    }
    
    private var model2DImage: UIImage? {
        didSet {
            deltaOperations[.MODEL2D_IMAGE] = { map in
                self.overlay2D.bounds = self.model2dBounds
                self.overlay2D.icon = self.model2DImage
                
                let upper = Double(MapOverlayZIndex.endModel2DRange.rawValue)
                let lower = Double(MapOverlayZIndex.startModel2DRange.rawValue)
                let zindex = abs(upper - self.poiArea).truncatingRemainder(dividingBy: lower) + lower
                self.overlay2D.zIndex = Int32(zindex)
            }
        }
    }
    
    private var model2DBearing: Double? {
        didSet {
            if oldValue != model2DBearing {
                deltaOperations[.MODEL2D_BEARING] = { map in
                    self.overlay2D.bearing = Double(self.model2DBearing ?? 0.0)
                }
            }
        }
    }
    
    var model2DClickable: Bool = false {
        didSet {
            deltaOperations[.MODEL2D_CLICKABLE] = { map in
                self.overlay2D.isTappable = self.model2DClickable
            }
        }
    }
    
    var iconSize = CGSize.zero
    var labelSize = CGSize.zero
    
    @MainActor
    var bounds: CGRect? {
        get async {
            guard markerState.isVisible && markerPosition != nil && self.markerIcon != nil else { return nil }
            var rect: CGRect?
            if let markerPos = markerPosition {
                let p = map.projection.point(for: markerPos)
                if let size = imageBundle?.getSize(state: markerState) {
                    let x = p.x - (size.width*markerAnchor.x)
                    let y = p.y - (size.height*markerAnchor.y)
                    rect = CGRect(x: x, y: y, width: size.width, height: size.height)
                }
            }
            return rect
        }
    }
    
    var model2DWidthMeters = 0.0
    var model2DHeightMeters = 0.0
    
    var model2dBounds: GMSCoordinateBounds? {
        if let model2DSouthWest = self.model2DPosition {
            let model2DSouthEast = GMSGeometryOffset(model2DSouthWest, model2DWidthMeters, 90)
            let model2DNorthEast = GMSGeometryOffset(model2DSouthEast, model2DHeightMeters, 0)
            return GMSCoordinateBounds(coordinate: model2DSouthWest, coordinate: model2DNorthEast)
        }
        return nil
    }
    
    @MainActor
    required init(viewModel: any MPViewModel, map: GMSMapView, is2dModelEnabled: Bool, isFloorPlanEnabled: Bool) async {
        self.id = viewModel.id
        self.map = map
        
        marker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        marker.zIndex = Int32(MapOverlayZIndex.startMarkerOverlay.rawValue)
        overlay2D = GMSGroundOverlay(bounds: nil, icon: nil)
        polygons = [GMSPolygon]()
        
        self.is2dModelsEnabled = is2dModelEnabled
        self.isFloorPlanEnabled = isFloorPlanEnabled
        
        weak var weakSelf = self
        marker.userData = weakSelf
        overlay2D.userData = weakSelf
    }
    
    func calculateMarkerAnchor(markerSize: Double, iconSize: Double, anchor: Double) -> Double {
        return  (iconSize * anchor) / markerSize
    }

    /**
     Computes the set of state operations required to have the view state's properties reflect those in the view model.
     This is done by assigning model values to the view state's corresponding property. Upon each property assignment, it check
     whether the value has changed - and a function is created to accommodate this change property and reflect the changes on corresponding map feature.
     */
    func computeDelta(newModel: any MPViewModel) {
        lastTimeTag = CFAbsoluteTimeGetCurrent()
        infoWindowText = newModel.marker?.properties[.markerLabelInfoWindow] as? String
        markerState = newModel.markerState
        if markerState.isVisible || markerState == .UNDEFINED {
            if let bundle = newModel.iconLabelBundle {
                if let image = bundle.both {
                    markerIcon = image
                }
                self.imageBundle = bundle
                self.iconSize = bundle.iconSize
                self.labelSize = bundle.labelSize
                self.markerClickable = newModel.marker?.properties[.clickable] as? Bool ?? false
                
                if newModel.marker?.properties[.isCollidable] as? Bool ?? true == false {
                    self.forceRender = true
                } else {
                    self.forceRender = false
                }
                
                if let size = bundle.getSize(state: .VISIBLE_ICON_LABEL) {
                    
                    let anchorX = calculateMarkerAnchor(markerSize: size.width, iconSize: bundle.iconSize.width, anchor: 0.5)
                    
                    if self.markerState.isIconVisible && self.markerState.isLabelVisible {
                        self.markerAnchor = CGPoint(x: anchorX, y: 0.5)
                        self.InfoWindowAnchorPoint = CGPoint(x: anchorX, y: 0)
                        DispatchQueue.main.async {
                            if newModel.marker?.properties[.isCollidable] as? Bool == false {
                                if self.markerState.isLabelVisible || self.markerState.isIconVisible {
                                    self.InfoWindowAnchorPoint = CGPoint(x: anchorX, y: 0)
                                }
                            }
                        }
                    } else if self.markerState.isIconVisible {
                        self.markerAnchor = CGPoint(x: 0.5, y: 0.5)
                    }
                    
                    if self.markerState.isIconVisible && self.markerState.isLabelVisible {
                        DispatchQueue.main.async {
                            self.marker.infoWindowAnchor = CGPoint(x: anchorX, y: 0)
                        }
                        
                        if let iconPlacement = newModel.marker?.properties[.markerIconPlacement] as? String,
                           let labelPlacement = newModel.marker?.properties[.labelAnchor] as? String {
                            
                            switch iconPlacement {
                            case "bottom":
                                switch labelPlacement {
                                case "top":
                                    self.markerAnchor = CGPoint(x: 0.5, y: ratio(a: labelSize.height, b: iconSize.height))
                                default:
                                    self.markerAnchor = CGPoint(x: anchorX, y: 1.0)
                                }
                            case "top":
                                self.markerAnchor = CGPoint(x: anchorX, y: 0.0)
                            case "left":
                                self.markerAnchor = CGPoint(x: 0.0, y: 0.5)
                            case "right":
                                self.markerAnchor = CGPoint(x: anchorX * 2, y: 0.5)
                            case "center":
                                fallthrough
                            default:
                                self.markerAnchor = CGPoint(x: anchorX, y: 0.5)
                            }
                        }
                        
                    } else if self.markerState.isIconVisible {
                        DispatchQueue.main.async {
                            self.marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0)
                        }
                        
                        if let iconPlacement = newModel.marker?.properties[.markerIconPlacement] as? String {
                            switch iconPlacement {
                            case "bottom":
                                self.markerAnchor = CGPoint(x: 0.5, y: 1.0)
                            case "top":
                                self.markerAnchor = CGPoint(x: 0.5, y: 0.0)
                            case "left":
                                self.markerAnchor = CGPoint(x: 0.0, y: 0.5)
                            case "right":
                                self.markerAnchor = CGPoint(x: 1.0, y: 0.5)
                            case "center":
                                fallthrough
                            default:
                                self.markerAnchor = CGPoint(x: 0.5, y: 0.5)
                            }
                        }
                    }
                }
                
            }
            markerPosition = newModel.markerPosition
            if let area = newModel.marker?.properties[.markerGeometryArea] {
                self.poiArea = area as? Double ?? 0.0
            }
            
        }
        
        self.shouldShowInfoWindow = newModel.showInfoWindow

        polygonState = newModel.polygonState
        if polygonState.isVisible || polygonState == .UNDEFINED {
            if let fillColor = newModel.polygonFillColor {
                polygonFillColor = fillColor
            }
            if let strokeColor = newModel.polygonStrokeColor {
                polygonStrokeColor = strokeColor
            }
            if let strokeWidth = newModel.polygonStrokeWidth {
                polygonStrokeWidth = strokeWidth
            }
            polygonGeometries = newModel.polygonGeometries
            self.polygonClickable = newModel.polygon?.properties[.clickable] as? Bool ?? false
        }
        
        if isFloorPlanEnabled {
            floorPlanState = newModel.floorPlanState
            if floorPlanState.isVisible || floorPlanState == .UNDEFINED {
                floorPlanStrokeColor = newModel.floorPlanStrokeColor
                floorPlanStrokeWidth = newModel.floorPlanStrokeWidth
                floorPlanFillColor = newModel.floorPlanFillColor
                floorPlanGeometries = newModel.floorPlanGeometries
            }
        }
        
        if is2dModelsEnabled {
            model2DState = newModel.model2DState
            if model2DState.isVisible || model2DState == .UNDEFINED {
                if let bundle = newModel.model2DBundle {
                    if let image = bundle.icon {
                        model2DImage = image
                    }
                    self.model2dBundle = bundle
                    self.model2DWidthMeters = bundle.widthMeters
                    self.model2DHeightMeters = bundle.heightMeters
                }
                
                if let position = newModel.model2DPosition {
                    model2DPosition = position
                }
                
                if let bearing = newModel.model2DBearing {
                    model2DBearing = bearing
                }
                
                self.model2DClickable = newModel.model2D?.properties[.clickable] as? Bool ?? false
            }
        }
    }
    
    private func ratio(a: Double, b: Double) -> Double {
        return min(a, b)/max(a, b)
    }
    
    /**
     Executes the set of state operations, computed to "catch up" with the state of the latest view model
     */
    @MainActor
    func applyDelta() async {
        
        let renderOperationsInOrder : [StateOperation] = [
            .MARKER_ANCHOR,
            .MARKER_ICON,
            .MARKER_VISIBLITY,
            .MARKER_POSITION,
            .MARKER_CLICKABLE,
            .INFO_WINDOW,
            .POLYGON_STROKE_WIDTH,
            .POLYGON_FILL_COLOR,
            .POLYGON_STROKE_COLOR,
            .POLYGON_VISIBILITY,
            .POLYGON_GEOMETRY,
            .POLYGON_CLICKABLE,
            .FLOORPLAN_STROKE_WIDTH,
            .FLOORPLAN_STROKE_COLOR,
            .FLOORPLAN_VISIBILITY,
            .FLOORPLAN_GEOMETRY,
            .MODEL2D_IMAGE,
            .MODEL2D_BEARING,
            .MODEL2D_VISIBILITY,
            .MODEL2D_POSITION,
            .MODEL2D_CLICKABLE
        ]
        
        let _ = await withTaskGroup(of: Void.self) { group -> Void in
            for op in deltaOperations.values {
                _ = group.addTaskUnlessCancelled(priority: .high) {
                    Task { @MainActor in
                        op(self.map)
                    }
                }
            }
        }
        /*
        for operationType in renderOperationsInOrder {
            if let operation = deltaOperations[operationType] {
                operation(self.map)
                deltaOperations.remove(key: operationType)
            }
        }
         */

    }

    /**
    Removes all map features from the mapview
     */
    @MainActor
    func destroy() async {
        marker.icon = nil
        marker.map = nil
        overlay2D.icon = nil
        overlay2D.map = nil
        for polygon in polygons {
            polygon.map = nil
        }
        for polygon in floorPlanPolygons {
            polygon.map = nil
        }
        deltaOperations.removeAll()
    }
    
}

class Model2DBundle {
    let icon: UIImage?
    
    let widthMeters: Double
    let heightMeters: Double
    
    required init(icon: UIImage?, widthMeters: Double, heightMeters: Double) {
        self.icon = icon
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
    }
    
}

class IconLabelBundle {
    let icon: UIImage?
    let label: UIImage?
    let iconSize: CGSize
    let labelSize: CGSize
    var both: UIImage?
    
    required init(icon: UIImage?, label: UIImage?, labelPosition: MPLabelPosition = .right) {
        self.icon = icon
        self.label = label
        self.iconSize = icon?.size ?? CGSize.zero
        self.labelSize = label?.size ?? CGSize.zero
        if let compiled = compile(icon: icon, label: label, position: labelPosition) {
            self.both = compiled
        }
    }
    
    func getSize(state: MarkerState) -> CGSize? {
        switch state {
        case .INVISIBLE:
            return nil
        case .VISIBLE_ICON:
            return iconSize
        case .VISIBLE_LABEL:
            return labelSize
        case .VISIBLE_ICON_LABEL:
            return both?.size
        default:
            return nil
        }
    }
    
    private func compile(icon: UIImage?, label: UIImage?, position: MPLabelPosition) -> UIImage? {
        let respectDistance = CGFloat(3)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false // true = no alpha channel, for debugging
        
        // Early return if neither are set
        guard let icon = icon, let label = label else {
            return icon?.withDebugBox() ?? label?.withDebugBox()
        }
        
        let box: CGRect
        switch position {
        case .top, .bottom:
            let width = max(icon.size.width, label.size.width)
            let height = icon.size.height + label.size.height + respectDistance
            box = CGRect(x: 0, y: 0, width: width, height: height)
        case .left, .right:
            let width = icon.size.width + label.size.width + respectDistance
            let height = max(icon.size.height, label.size.height)
            box = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        guard box.size != .zero else { return nil }
        
        let renderer = UIGraphicsImageRenderer(size: box.size, format: format)
        return renderer.image { ctx in
            switch position {
            case .top:
                icon.draw(at: CGPoint(x: (box.width - icon.size.width) / 2, y: label.size.height + respectDistance))
                label.draw(at: CGPoint(x: (box.width - label.size.width) / 2, y: 0))
            case .bottom:
                icon.draw(at: CGPoint(x: (box.width - icon.size.width) / 2, y: 0))
                label.draw(at: CGPoint(x: (box.width - label.size.width) / 2, y: icon.size.height + respectDistance))
            case .left:
                icon.draw(at: CGPoint(x: label.size.width + respectDistance, y: (box.height - icon.size.height) / 2))
                label.draw(at: CGPoint(x: 0, y: (box.height - label.size.height) / 2))
            case .right:
                icon.draw(at: CGPoint(x: 0, y: (box.height - icon.size.height) / 2))
                label.draw(at: CGPoint(x: icon.size.width + respectDistance, y: (box.height - label.size.height) / 2))
            }
        }.withDebugBox()
    }
}

/**
 Convenience extensions for view models, useful in the ViewState class' logic
 */
extension MPViewModel {
    
    var markerState: MarkerState {
        if let feature = marker {
            let hasLabel = feature.properties[.markerLabel] != nil
            let hasIcon = (data[.icon] as? UIImage) != nil
            if hasIcon && hasLabel {
                return .VISIBLE_ICON_LABEL
            }
            if hasIcon {
                return .VISIBLE_ICON
            }
            if hasLabel {
                return .VISIBLE_LABEL
            }
        }
        return .INVISIBLE
    }
    
    var markerPosition: CLLocationCoordinate2D? {
        if let point = marker?.geometry.coordinates as? MPPoint {
            return point.coordinate
        }
        return nil
    }
    
    var polygonState: PolygonState {
        if let feature = polygon {
            let hasGeometry = polygonGeometries.isEmpty == false
            let hasArea = feature.properties[.polygonArea] as? Double != nil
            if hasGeometry && hasArea {
                return .VISIBLE
            } else {
                return .INVISIBLE
            }
        }
        return .INVISIBLE
    }
    
    var polygonGeometries: [GMSPath] {
        var geometries = [GMSPath]()
        
        if polygon?.geometry.type == .Polygon {
            for polygon in (polygon?.geometry.coordinates as! [[MPPoint]]) {
                let path = GMSMutablePath()
                for pathPoint in polygon {
                    path.add(pathPoint.coordinate)
                }
                geometries.append(path)
            }
        }
        
        if polygon?.geometry.type == .MultiPolygon {
            for polygons in (polygon?.geometry.coordinates as! [MPPolygonGeometry]) {
                for polygon in polygons.coordinates {
                    let path = GMSMutablePath()
                    for pathPoint in polygon {
                       path.add(pathPoint.coordinate)
                    }
                    geometries.append(path)
                }
            }
        }
        
        return geometries
    }
    
    var floorPlanState: PolygonState {
        let hasfloorPlan = floorPlanGeometries.isEmpty == false
        if hasfloorPlan {
            return .VISIBLE
        } else {
            return .INVISIBLE
        }
    }
    
    var floorPlanGeometries: [GMSPath] {
        var geometries = [GMSPath]()
        
        if floorPlanExtrusion?.geometry.type == .Polygon {
            for polygon in (floorPlanExtrusion?.geometry.coordinates as! [[MPPoint]]) {
                let path = GMSMutablePath()
                for pathPoint in polygon {
                    path.add(pathPoint.coordinate)
                }
                geometries.append(path)
            }
        }
        
        if floorPlanExtrusion?.geometry.type == .MultiPolygon {
            for polygons in (floorPlanExtrusion?.geometry.coordinates as! [MPPolygonGeometry]) {
                for polygon in polygons.coordinates {
                    let path = GMSMutablePath()
                    for pathPoint in polygon {
                       path.add(pathPoint.coordinate)
                    }
                    geometries.append(path)
                }
            }
        }
        
        return geometries
    }
    
    var floorPlanFillColor: UIColor? {
        if let colorHex = floorPlanExtrusion?.properties[.floorPlanFillColorAlpha] as? String {
            return UIColor(hex: colorHex)
        }
        return nil
    }
    
    var floorPlanStrokeColor: UIColor? {
        if let colorHex = floorPlanExtrusion?.properties[.floorPlanStrokeColorAlpha] as? String {
            return UIColor(hex: colorHex)
        }
        return nil
    }
    
    var floorPlanStrokeWidth: Double? {
        return floorPlanExtrusion?.properties[.floorPlanStrokeWidth] as? Double
    }
    
    var polygonFillColor: UIColor? {
        if let colorHex = polygon?.properties[.polygonFillcolorAlpha] as? String {
            return UIColor(hex: colorHex)
        }
        return nil
    }
    
    var polygonStrokeColor: UIColor? {
        if let colorHex = polygon?.properties[.polygonStrokeColorAlpha] as? String {
            return UIColor(hex: colorHex)
        }
        return nil
    }
    
    var polygonStrokeWidth: Double? {
        return polygon?.properties[.polygonStrokeWidth] as? Double
    }
    
    var iconLabelBundle: IconLabelBundle? {
        let labelImage = computedLabelImage
        let iconImage = data[.icon] as? UIImage
        
        var labelPosition: MPLabelPosition = .right
        
        if let position = self.marker?.properties[.labelAnchor] as? String {
            labelPosition = switch position {
            case "left":
                    .right
            case "top":
                    .bottom
            case "bottom":
                    .top
            default:
                    .left
            }
        }
        
        return IconLabelBundle(icon: iconImage, label: labelImage, labelPosition: labelPosition)
    }
    
    // MARK: 2D Model
    
    var model2DBundle: Model2DBundle? {
        return Model2DBundle(icon: computedImage,
                             widthMeters: (model2D?.properties[.model2DWidth] as? Double) ?? 0,
                             heightMeters: (model2D?.properties[.model2DHeight] as? Double) ?? 0)
    }
    
    var model2DState: Model2DState {
        if let hasIcon = (data[.model2D] as? UIImage) {
            if  hasIcon != nil as UIImage? {
                return .VISIBLE
            } else {
                return .INVISIBLE
            }
        }
        return .INVISIBLE
    }
    
    var model2DPosition: CLLocationCoordinate2D? {
        if let point = model2D?.geometry.coordinates as? MPPoint {
            return point.coordinate
        }
        return nil
    }
    
    var model2DBearing: Double? {
        if let bearing = model2D?.properties[.model2dBearing] as? Double {
            return Double(bearing)
        }
        return nil
    }
    
    //for 2D Model
    var computedImage: UIImage? {
        switch model2DState {
        case .UNDEFINED:
            fallthrough
        case .INVISIBLE:
            return nil
        case .VISIBLE:
            if let image = data[.model2D] as? UIImage {
                return image
            } else { return nil }
        }
    }
    
    private var computedLabelImage: UIImage? {
        let format = UIGraphicsImageRendererFormat.preferred()
        let opacity = marker?.properties[.labelOpacity] as? Bool
        format.opaque = opacity ?? false
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        var attrs: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]

        guard let string = (marker?.properties[.markerLabel] as? String),
              let fontSize = marker?.properties[.labelSize] as? Int,
              let fontName = marker?.properties[.labelFont] as? String,
              let fontColor = marker?.properties[.labelColor] as? String,
              let fontOpacity = marker?.properties[.labelOpacity] as? Double,
              let haloWidth = marker?.properties[.labelHaloWidth] as? Int,
              let haloColor = marker?.properties[.labelHaloColor] as? String,
              let haloBlur = marker?.properties[.labelHaloBlur] as? Int else { return nil }

        attrs[.font] = UIFont(name: fontName, size: CGFloat(fontSize))
        attrs[.foregroundColor] = UIColor(hex: fontColor)?.withAlphaComponent(CGFloat(fontOpacity))
        attrs[.strokeColor] = UIColor(hex: haloColor)?.withAlphaComponent(1)
        attrs[.strokeWidth] = -haloWidth
        let shadow = NSShadow()
        shadow.shadowBlurRadius = CGFloat(haloBlur)
        shadow.shadowOffset = .zero
        shadow.shadowColor = UIColor(hex: haloColor)?.withAlphaComponent(1)
        attrs[.shadow] = shadow

        let size = labelSplitAndSizing(string: string, width: Double(marker?.properties[.labelMaxWidth] as? UInt ?? UInt.max), att: attrs)
        guard size != .zero else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            string.draw(with: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height)), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }
    }
    
    func labelSplitAndSizing (string: String, width: Double, att: [NSAttributedString.Key: Any]) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                     options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                             attributes: att,
                                                             context: nil).size
    }
}

fileprivate extension UIImage {
    func withDebugBox(color: UIColor = .red) -> UIImage {
        guard ViewState.DEBUG_DRAW_IMAGE_BORDER == true else { return self }
        let size = CGSize(width: (size.width), height: size.height)
        guard size != .zero else { return self }
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            draw(at: CGPoint(x: 0, y: 0))
            let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            UIColor.red.setStroke()
            ctx.stroke(rectangle)
        }
        return img
    }
    
    func resizeImage(scaleSize: CGFloat) -> UIImage? {
        
        var size = self.size
        
        guard self.size.width <= scaleSize && self.size.height  <= scaleSize else {
            return self
        }
        
        let scaleFactor = scaleSize / max(size.width, size.height)
        size.width *= scaleFactor
        size.height *= scaleFactor
        
        let rendererFormat = UIGraphicsImageRendererFormat.preferred()
        rendererFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        
        return renderer.image { rendererContext in
            draw(in: CGRect(origin: CGPoint.zero, size: size))
        }
    }
    
    private func fillColor(_ color: UIColor) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(context.format.bounds)
            draw(in: context.format.bounds, blendMode: .destinationIn, alpha: 1.0)
        }
    }
}

// MARK: Temporarily here
/// The different positions to place label of an MPLocation on the map.
@objc enum MPLabelPosition: Int, Codable {
    /// Will place labels on top.
    case top

    /// Will place labels on bottom.
    case bottom

    /// Will place labels on left.
    case left
    
    /// Will place labels on right.
    case right
}
