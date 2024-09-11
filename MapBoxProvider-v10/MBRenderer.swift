//
//  MBRenderer.swift
//  MapsIndoorsMapbox
//
//  Created by Frederik Hansen on 14/09/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
@_spi(Experimental) import MapboxMaps
@_spi(Private) import MapsIndoorsCore
import UIKit

fileprivate class InfoWindowTapRecognizer: UITapGestureRecognizer {
    var modelId = String()
}

class MBRenderer {
    
    /// The scale of an object relative to being zoomed out to zoom level 1 (from zoom level 22) 1/(2^22)
    static let zoom22Scale: Double = 1/pow(2, 22)
    
    private weak var map: MapboxMap?
    private var _geoJsonSource: GeoJSONSource?
    private var _geoJsonSourceNoCollision: GeoJSONSource?
    private var _model3dGeoJsonSource: GeoJSONSource?
    private var _extrusionGeoJsonSource: GeoJSONSource?
    private weak var mapView: MapView?
    
    // Dictionary to store created info windows
    private var infoWindows = MPThreadSafeDictionary<String, UIView>()
    
    private weak var provider: MapBoxProvider?
    
    private var _lastModels = Set<AnyHashable>()
    private var lock = UnfairLock()
    
    init(mapView: MapView?, provider: MapBoxProvider) {
        self.map = mapView?.mapboxMap
        self.provider = provider
        self.mapView = mapView
        DispatchQueue.main.async { [self] in
            do {
                try setupGeoJsonSource()
                try setupLayersInOrder()
                try configureFlatLabelsLayer()
                try configureMarkerLayer(layerId: Constants.LayerIDs.markerLayer)
                try configureMarkerLayer(layerId: Constants.LayerIDs.markerNoCollisionLayer)
                try configurePolygonLayers()
                try configureFloorPlanLayer()
                try configure2DModelLayer()
                try configure3DModelLayer()
                try configureWallExtrusionLayer()
                try configureFeatureExtrusionLayer()
            } catch {
                MPLog.mapbox.error("Error setting up some layer/source: \(error.localizedDescription)")
            }
        }
    }

    private func setupLayersInOrder() throws {
        // Tile layer is added in `MBTileProvider`
        
        // Polygon
        var polygonFillLayer = FillLayer(id: Constants.LayerIDs.polygonFillLayer)
        polygonFillLayer.source = Constants.SourceIDs.geoJsonSource
        var polygonLineLayer = LineLayer(id: Constants.LayerIDs.polygonLineLayer)
        polygonLineLayer.source = Constants.SourceIDs.geoJsonSource
        
        // Floor Plan
        var floorPlanFillLayer = FillLayer(id: Constants.LayerIDs.floorPlanFillLayer)
        floorPlanFillLayer.source = Constants.SourceIDs.geoJsonSource
        var floorPlanLineLayer = LineLayer(id: Constants.LayerIDs.floorPlanLineLayer)
        floorPlanLineLayer.source = Constants.SourceIDs.geoJsonSource
        
        // Flat Labels
        var flatLabelsLayer = SymbolLayer(id: Constants.LayerIDs.flatLabelsLayer)
        flatLabelsLayer.source = Constants.SourceIDs.geoJsonSource
        
        // Markers
        var markerLayer = SymbolLayer(id: Constants.LayerIDs.markerLayer)
        markerLayer.source = Constants.SourceIDs.geoJsonSource
        
        var markerNonCollisionlayer = SymbolLayer(id: Constants.LayerIDs.markerNoCollisionLayer)
        markerNonCollisionlayer.source = Constants.SourceIDs.geoJsonNoCollisionSource
        
        // 2D Models
        var model2DLayer = SymbolLayer(id: Constants.LayerIDs.model2DLayer)
        model2DLayer.source = Constants.SourceIDs.geoJsonSource
        
        // 3D Models
        var model3DLayer = ModelLayer(id: Constants.LayerIDs.model3DLayer)
        model3DLayer.source = Constants.SourceIDs.geoJsonSource3dModels
        
        // Circle
        var circleLayer = CircleLayer(id: Constants.LayerIDs.circleLayer)
        circleLayer.source = Constants.SourceIDs.blueDotSource
        
        // Wall extrusion layer
        var wallExtrusionLayer = FillExtrusionLayer(id: Constants.LayerIDs.wallExtrusionLayer)
        wallExtrusionLayer.source = Constants.SourceIDs.geoJsonSourceExtrusions
        
        // Feature extrusion layer
        var featureExtrusionLayer = FillExtrusionLayer(id: Constants.LayerIDs.featureExtrusionLayer)
        featureExtrusionLayer.source = Constants.SourceIDs.geoJsonSourceExtrusions

        var blueDotLayer = SymbolLayer(id: Constants.LayerIDs.blueDotLayer)
        blueDotLayer.source = Constants.SourceIDs.blueDotSource
        
        var routeAnimatedLayer = LineLayer(id: Constants.LayerIDs.animatedLineLayer)
        routeAnimatedLayer.source = Constants.SourceIDs.animatedLineSource
        
        var routeLineLayer = LineLayer(id: Constants.LayerIDs.lineLayer)
        routeLineLayer.source = Constants.SourceIDs.lineSource
        
        var routeMarkerLayer = SymbolLayer(id: Constants.LayerIDs.routeMarkerLayer)
        routeMarkerLayer.source = Constants.SourceIDs.routeMarkerSource
        
        // Sorted (first is bottom-most layer)
        let layersInAscendingOrder = [
            polygonFillLayer,
            polygonLineLayer,
            floorPlanFillLayer,
            floorPlanLineLayer,
            model2DLayer,
            flatLabelsLayer,
            routeLineLayer,
            routeAnimatedLayer,
            model3DLayer,
            wallExtrusionLayer,
            featureExtrusionLayer,
            markerLayer,
            markerNonCollisionlayer,
            circleLayer,
            blueDotLayer,
            routeMarkerLayer
        ] as [Layer]
        
        for layer in layersInAscendingOrder {
            try map?.style.addLayer(layer)
        }
    }
    
    private func setupGeoJsonSource() throws {
        guard let map else { return }
        
        _geoJsonSource = GeoJSONSource()
        _geoJsonSource?.data = .empty
        _geoJsonSource?.tolerance = 0.1
        try map.style.addSource(_geoJsonSource!, id: Constants.SourceIDs.geoJsonSource)
        
        _geoJsonSourceNoCollision = GeoJSONSource()
        _geoJsonSourceNoCollision?.data = .empty
        _geoJsonSourceNoCollision?.tolerance = 0.1
        try map.style.addSource(_geoJsonSourceNoCollision!, id: Constants.SourceIDs.geoJsonNoCollisionSource)
        
        _model3dGeoJsonSource = GeoJSONSource()
        _model3dGeoJsonSource?.data = .empty
        try map.style.addSource(_model3dGeoJsonSource!, id: Constants.SourceIDs.geoJsonSource3dModels)
        
        _extrusionGeoJsonSource = GeoJSONSource()
        _extrusionGeoJsonSource?.data = .empty
        _extrusionGeoJsonSource?.tolerance = 0.1
        try map.style.addSource(_extrusionGeoJsonSource!, id: Constants.SourceIDs.geoJsonSourceExtrusions)
    }
    
    // MARK: Layers: adding and setting properties
    private func configureMarkerLayer(layerId: String) throws {
        try map?.style.updateLayer(withId: layerId, type: SymbolLayer.self) { layerUpdate in
            layerUpdate.iconImage = .expression(Exp(.switchCase) {
                Exp(.eq) {
                    Exp(.get) { Key.hasImage.rawValue }
                    true
                }
                Exp(.get) { Key.markerId.rawValue }
                ""
            })
            layerUpdate.iconAnchor = .expression(Exp(.get) { Key.markerIconPlacement.rawValue })
            
            // Only set the text if it's a floating label
            layerUpdate.textField = .expression(Exp(.switchCase) {
                Exp(.eq) {
                    Exp(.get) { Key.labelType.rawValue }
                    Exp(.literal) { MPLabelType.floating.rawValue }
                }
                Exp(.get) { Key.markerLabel.rawValue }
                ""
            })
            
            layerUpdate.textAnchor = .expression(Exp(.get) { Key.labelAnchor.rawValue })
            layerUpdate.textJustify = .constant(TextJustify.left)
            layerUpdate.textOffset = .expression(Exp(.get) { Key.labelOffset.rawValue })
            layerUpdate.symbolSortKey = .expression(Exp(.get) { Key.markerGeometryArea.rawValue })
            layerUpdate.textMaxWidth = .expression(Exp(.get) { Key.labelMaxWidth.rawValue })
            layerUpdate.textFont = .constant(["Open Sans Bold", "Arial Unicode MS Regular"])
            layerUpdate.textLetterSpacing = .constant(-0.01)
            
            // text styling
            layerUpdate.textSize = .expression(Exp(.get) { Key.labelSize.rawValue })
            layerUpdate.textColor = .expression(Exp(.get) { Key.labelColor.rawValue })
            layerUpdate.textOpacity = .expression(Exp(.get) { Key.labelOpacity.rawValue })
            layerUpdate.textHaloColor = .expression(Exp(.get) { Key.labelHaloColor.rawValue })
            layerUpdate.textHaloWidth = .expression(Exp(.get) { Key.labelHaloWidth.rawValue })
            layerUpdate.textHaloBlur = .expression(Exp(.get) { Key.labelHaloBlur.rawValue })
            
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.marker.rawValue }
            }
        }
    }
    
    private func configureFlatLabelsLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.flatLabelsLayer, type: SymbolLayer.self) { layerUpdate in
            
            layerUpdate.textField = .expression(Exp(.get) { Key.markerLabel.rawValue })
            layerUpdate.textAnchor = .constant(TextAnchor.center)
            layerUpdate.textJustify = .constant(TextJustify.center)
            layerUpdate.symbolSortKey = .expression(Exp(.get) { Key.markerGeometryArea.rawValue })
            layerUpdate.textMaxWidth = .expression(Exp(.get) { Key.labelMaxWidth.rawValue })
            
            layerUpdate.textColor = .expression(Exp(.get) { Key.labelColor.rawValue })
            layerUpdate.textOpacity = .expression(Exp(.get) { Key.labelOpacity.rawValue })
            layerUpdate.textHaloColor = .expression(Exp(.get) { Key.labelHaloColor.rawValue })
            layerUpdate.textHaloWidth = .expression(Exp(.get) { Key.labelHaloWidth.rawValue })
            layerUpdate.textHaloBlur = .expression(Exp(.get) { Key.labelHaloBlur.rawValue })
            
            layerUpdate.textFont = .constant(["Open Sans Bold", "Arial Unicode MS Regular"])
            layerUpdate.textLetterSpacing = .constant(-0.01)
            
            layerUpdate.iconAllowOverlap = .constant(true)
            layerUpdate.textAllowOverlap = .constant(true)
            layerUpdate.iconOptional = .constant(false)
            layerUpdate.textOptional = .constant(false)
            layerUpdate.textPitchAlignment = .constant(.map)
            layerUpdate.textRotationAlignment = .constant(.map)
            layerUpdate.symbolPlacement = .constant(.point)
            
            layerUpdate.textRotate = .expression(Exp(.get) { Key.labelBearing.rawValue })
            
            let stops: [Double: Exp] = [
                1: Exp(.product) {
                    Exp(.literal) { MBRenderer.zoom22Scale }
                    Exp(.get) { Key.labelSize.rawValue }
                },
                22: Exp(.product) {
                    Exp(.literal) { 1 }
                    Exp(.get) { Key.labelSize.rawValue }
                },
                23: Exp(.product) {
                    Exp(.literal) { 2 }
                    Exp(.get) { Key.labelSize.rawValue }
                },
                24: Exp(.product) {
                    Exp(.literal) { 4 }
                    Exp(.get) { Key.labelSize.rawValue }
                },
                25: Exp(.product) {
                    Exp(.literal) { 8 }
                    Exp(.get) { Key.labelSize.rawValue }
                }
            ]
            
            layerUpdate.textSize = .expression(
                Exp(.interpolate) {
                    Exp(.exponential) { 2 }
                    Exp(.zoom)
                    stops
                }
            )
            
            layerUpdate.filter = Exp(.all) {
                Exp(.eq) {
                    Exp(.get) { Key.type.rawValue }
                    Exp(.literal) { MPRenderedFeatureType.marker.rawValue }
                }
                Exp(.eq) {
                    Exp(.get) { Key.labelType.rawValue }
                    Exp(.literal) { MPLabelType.flat.rawValue }
                }
            }
        }
    }
    
    private func configurePolygonLayers() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.polygonFillLayer, type: FillLayer.self) { layerUpdate in
            layerUpdate.fillColor = .expression(Exp(.get) { Key.polygonFillcolor.rawValue })
            layerUpdate.fillOpacity = .expression(Exp(.get) { Key.polygonFillOpacity.rawValue })
            layerUpdate.fillSortKey = .expression(Exp(.subtract) { Exp(.get) { Key.polygonArea.rawValue } })
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.polygon.rawValue }
            }
        }

        try map?.style.updateLayer(withId: Constants.LayerIDs.polygonLineLayer, type: LineLayer.self) { layerUpdate in
            layerUpdate.lineColor = .expression(Exp(.get) { Key.polygonStrokeColor.rawValue })
            layerUpdate.lineOpacity = .expression(Exp(.get) { Key.polygonStrokeOpacity.rawValue })
            layerUpdate.lineWidth = .expression(Exp(.get) { Key.polygonStrokeWidth.rawValue })
            layerUpdate.lineJoin = .constant(.round)
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.polygon.rawValue }
            }
        }
    }
    
    
    private func configureFloorPlanLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.floorPlanFillLayer, type: FillLayer.self) { layerUpdate in
            layerUpdate.fillColor = .expression(Exp(.get) { Key.floorPlanFillColor.rawValue })
            layerUpdate.fillOpacity = .expression(Exp(.get) { Key.floorPlanFillOpacity.rawValue })
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.floorplan.rawValue }
            }
        }

        try map?.style.updateLayer(withId: Constants.LayerIDs.floorPlanLineLayer, type: LineLayer.self) { layerUpdate in
            layerUpdate.lineColor = .expression(Exp(.get) { Key.floorPlanStrokeColor.rawValue })
            layerUpdate.lineOpacity = .expression(Exp(.get) { Key.floorPlanStrokeOpacity.rawValue })
            layerUpdate.lineWidth = .expression(Exp(.get) { Key.floorPlanStrokeWidth.rawValue })
            layerUpdate.lineJoin = .constant(.round)
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.floorplan.rawValue }
            }
        }
    }
    
    private func configure2DModelLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.model2DLayer, type: SymbolLayer.self) { layerUpdate in
            layerUpdate.iconAllowOverlap = .constant(true)
            layerUpdate.textAllowOverlap = .constant(true)
            layerUpdate.iconImage = .expression(Exp(.get) { Key.model2dId.rawValue})
            layerUpdate.iconRotate = .expression(Exp(.get) { Key.model2dBearing.rawValue})
            layerUpdate.iconPitchAlignment = .constant(.map)
            layerUpdate.iconRotationAlignment = .constant(.map)
            
            let stops: [Double: Exp] = [
                1: Exp(.product) {
                    Exp(.literal) { MBRenderer.zoom22Scale }
                    Exp(.get) { Key.model2DScale.rawValue }
                },
                22: Exp(.product) {
                    Exp(.literal) { 1 }
                    Exp(.get) { Key.model2DScale.rawValue }
                },
                23: Exp(.product) {
                    Exp(.literal) { 2 }
                    Exp(.get) { Key.model2DScale.rawValue }
                },
                24: Exp(.product) {
                    Exp(.literal) { 4 }
                    Exp(.get) { Key.model2DScale.rawValue }
                },
                25: Exp(.product) {
                    Exp(.literal) { 8 }
                    Exp(.get) { Key.model2DScale.rawValue }
                }
            ]
            
            layerUpdate.iconSize = .expression(
                Exp(.interpolate) {
                    Exp(.exponential) { 2 }
                    Exp(.zoom)
                    stops
                }
            )
            
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.model2d.rawValue }
            }
        }
    }
    
    private func configure3DModelLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.model3DLayer, type: ModelLayer.self) { layerUpdate in
            layerUpdate.modelId = .expression(Exp(.get) { Key.model3dId.rawValue })
            layerUpdate.modelScale = .expression(Exp(.get) { Key.model3DScale.rawValue })
            layerUpdate.modelRotation = .expression(Exp(.get) { Key.model3DRotation.rawValue })
            layerUpdate.modelType = .constant(.common3d)
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.model3d.rawValue }
            }
        }
    }
    
    private func configureWallExtrusionLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.wallExtrusionLayer, type: FillExtrusionLayer.self) { layerUpdate in
            layerUpdate.fillExtrusionColor = .expression(Exp(.get) { Key.wallExtrusionColor.rawValue })
            layerUpdate.fillExtrusionHeight = .expression(Exp(.get) { Key.wallExtrusionHeight.rawValue })
            layerUpdate.filter = Exp(.any) {
                Exp(.eq) {
                    Exp(.get) { Key.type.rawValue }
                    Exp(.literal) { MPRenderedFeatureType.wallExtrusion.rawValue }
                }
            }
        }
    }
    
    private func configureFeatureExtrusionLayer() throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.featureExtrusionLayer, type: FillExtrusionLayer.self) { layerUpdate in
            layerUpdate.fillExtrusionColor = .expression(Exp(.get) { Key.featureExtrusionColor.rawValue })
            layerUpdate.fillExtrusionHeight = .expression(Exp(.get) { Key.featureExtrusionHeight.rawValue })
            layerUpdate.filter = Exp(.eq) {
                Exp(.get) { Key.type.rawValue }
                Exp(.literal) { MPRenderedFeatureType.featureExtrusion.rawValue }
            }
        }
    }
    
    var isFeatureExtrusionsEnabled = false
    
    var isWallExtrusionsEnabled = false
    
    var is2dModelsEnabled = false
    
    var isFloorPlanEnabled = false
    
    var featureExtrusionOpacity: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                do {
                    try self.map?.style.updateLayer(withId: Constants.LayerIDs.featureExtrusionLayer, type: FillExtrusionLayer.self) { layer in
                        layer.fillExtrusionOpacity = .constant(self.featureExtrusionOpacity)
                    }
                } catch { }
            }
        }
    }
    
    var wallExtrusionOpacity: Double = 0 {
        didSet {
            DispatchQueue.main.async {
                do {
                    try self.map?.style.updateLayer(withId: Constants.LayerIDs.wallExtrusionLayer, type: FillExtrusionLayer.self) { layer in
                        layer.fillExtrusionOpacity = .constant(self.wallExtrusionOpacity)
                    }
                } catch { }
            }
        }
    }

    var collisionHandling: MPCollisionHandling = .allowOverLap {
        didSet {
            DispatchQueue.main.async {
                self.configureForCollisionHandling(overlap: self.collisionHandling)
            }
        }
    }
    
    // MARK: Collision handling
    struct MBOverlapSettings {
        var iconAllowOverlap: Bool
        var textAllowOverlap: Bool
        var iconOptional: Bool
        var textOptional: Bool
    }

    private func configureForCollisionHandling(overlap: MPCollisionHandling) {
        let settings: MBOverlapSettings

        switch overlap {
        case .removeIconFirst:
            settings = MBOverlapSettings(iconAllowOverlap: false, textAllowOverlap: false, iconOptional: true, textOptional: false)
        case .removeLabelFirst:
            settings = MBOverlapSettings(iconAllowOverlap: false, textAllowOverlap: false, iconOptional: false, textOptional: true)
        case .removeIconAndLabel:
            settings = MBOverlapSettings(iconAllowOverlap: false, textAllowOverlap: false, iconOptional: false, textOptional: false)
        case .allowOverLap:
            settings = MBOverlapSettings(iconAllowOverlap: true, textAllowOverlap: true, iconOptional: false, textOptional: false)
        }

        do {
            try updateLayerOverlapSettings(settings)
        } catch {
            MPLog.mapbox.error("Error updating layer: \(error.localizedDescription)")
        }
    }

    private func updateLayerOverlapSettings(_ settings: MBOverlapSettings) throws {
        try map?.style.updateLayer(withId: Constants.LayerIDs.markerLayer, type: SymbolLayer.self) { layer in
            layer.iconAllowOverlap = .constant(settings.iconAllowOverlap)
            layer.textAllowOverlap = .constant(settings.textAllowOverlap)
            layer.iconOptional = .constant(settings.iconOptional)
            layer.textOptional = .constant(settings.textOptional)
        }

        try map?.style.updateLayer(withId: Constants.LayerIDs.markerNoCollisionLayer, type: SymbolLayer.self) { layer in
            layer.iconAllowOverlap = .constant(true)
            layer.textAllowOverlap = .constant(true)
            layer.iconOptional = .constant(false)
            layer.textOptional = .constant(false)
        }
    }
    
    // MARK: Label position
    /*
     TODO: Wrong implementation apporach - commenting out for now
    var labelPosition: MPLabelPosition = .right {
        didSet {
            self.configureForLabelPosition(position: self.labelPosition)
        }
    }
    
    private func configureForLabelPosition(position: MPLabelPosition) {
        let anchor: TextAnchor
        
        switch position {
        case .bottom:
            anchor = .top
        case .left:
            anchor = .left
        case .top:
            anchor = .bottom
        case .right:
            anchor = .right
        }
        
        do {
            if map.style.layerExists(withId: Constants.LayerIDs.markerLayer) {
                try map.style.updateLayer(withId: Constants.LayerIDs.markerLayer, type: SymbolLayer.self) { layer in
                    layer.textAnchor = .constant(anchor)
                }
            }
            if map.style.layerExists(withId: Constants.LayerIDs.markerNoCollisionLayer) {
                try map.style.updateLayer(withId: Constants.LayerIDs.markerNoCollisionLayer, type: SymbolLayer.self) { layer in
                    layer.textAnchor = .constant(anchor)
                }
            }
        } catch {
            MPLog.mapbox.error("Error updating layer: \(error.localizedDescription)")
        }
    }
     */
    
    // MARK: Rendering and updating source
    
    var customInfoWindow: MPCustomInfoWindow?
    private static let infoWindowPrefix = "viewAnnotation"
    
    private func setupInfoWindowTapRecognizer(infoWindowView: UIView, modelId: String) {
        let recognizer = InfoWindowTapRecognizer(target: self, action: #selector(self.onInfoWindowTapped(sender:)))
        recognizer.modelId = modelId
        infoWindowView.addGestureRecognizer(recognizer)
    }
    
    @objc private func onInfoWindowTapped(sender: InfoWindowTapRecognizer) {
        provider?.onInfoWindowTapped(locationId: sender.modelId)
    }
    
    func render(models: [any MPViewModel]) {
        Task.detached(priority: .userInitiated) { [self] in
            let models = await withTaskGroup(of: ([Feature], [Feature], [Feature], [Feature]).self) { group -> [([Feature], [Feature], [Feature], [Feature])] in
                lock.locked { removeOldModels(models: models) }
                for model in models {
                    _ = group.addTaskUnlessCancelled(priority: .high) { [self] in
                        lock.locked { _ = _lastModels.insert(model) }
                        updateInfoWindow(for: model)
                        updateImage(for: model)
                        update2DModel(for: model)
                        update3DModel(for: model)
                                            
                        var features = [Feature]()
                        var featuresNonCollision = [Feature]()
                        var featuresExtrusions = [Feature]()
                        var features3DModels = [Feature]()
                        
                        if let marker = model.markerFeature {
                            if model.marker?.properties[.isCollidable] as? Bool ?? true == false {
                                featuresNonCollision.append(marker)
                                features.append(marker)
                            } else {
                                features.append(marker)
                            }
                        }
                        
                        if let polygon = model.polygonFeature {
                            features.append(polygon)
                        }
                        
                        if let floorPlan = model.floorPlanFeature, isFloorPlanEnabled {
                            features.append(floorPlan)
                        }
                        
                        if let model2D = model.model2DFeature, is2dModelsEnabled {
                            features.append(model2D)
                        }
                        
                        if let model3D = model.model3DFeature {
                            features3DModels.append(model3D)
                        }
                        
                        if let wallExtrusionLayer = model.wallExtrusionFeature, isWallExtrusionsEnabled {
                            featuresExtrusions.append(wallExtrusionLayer)
                        }
                        
                        if let featureExtrusionLayer = model.featureExtrusionFeature, isFeatureExtrusionsEnabled {
                            featuresExtrusions.append(featureExtrusionLayer)
                        }
                        
                        return (features, featuresNonCollision, featuresExtrusions, features3DModels)
                    }
                }
                
                let res = await group.reduce(into: [([Feature], [Feature], [Feature], [Feature])]() ) { result, feature in result.append(feature) }

                return res
            }
            
            var features = [Feature]()
            var featuresNonCollision = [Feature]()
            var featuresExtrusions = [Feature]()
            var features3DModels = [Feature]()
            features.reserveCapacity(models.count)
            featuresNonCollision.reserveCapacity(models.count)
            featuresExtrusions.reserveCapacity(models.count)
            features3DModels.reserveCapacity(models.count)
            
            for x in models {
                features.append(contentsOf: x.0)
                featuresNonCollision.append(contentsOf: x.1)
                featuresExtrusions.append(contentsOf: x.2)
                features3DModels.append(contentsOf: x.3)
            }
            
            self.updateGeoJSONSource(features: features, nonCollisionFeatures: featuresNonCollision, featuresExtrusions: featuresExtrusions, features3DModels: features3DModels)
        }
    }
    
    private func removeOldModels(models: [any MPViewModel]) {
        let modelsNoLongerInView = _lastModels.subtracting(models as! [AnyHashable])
        for model in modelsNoLongerInView {
            if let viewModel = model as? (any MPViewModel) {
                removeInfoWindow(for: viewModel)
                removeOldIconImage(for: viewModel)
                removeOld2DModelImage(for: viewModel)
            }
        }
        _lastModels.removeAll(keepingCapacity: false)
    }
    
    private func removeInfoWindow(for model: any MPViewModel) {
        DispatchQueue.main.async {
            if let annotationView = self.mapView?.viewAnnotations.view(forId: MBRenderer.infoWindowPrefix + model.id) {
                self.mapView?.viewAnnotations.remove(annotationView)
            }
        }
    }
    
    private func removeOldIconImage(for model: any MPViewModel) {
        map?.style.safeRemoveImage(id: model.id)
    }
    
    private func removeOld2DModelImage(for model: any MPViewModel) {
        if let model2dId = model.model2D?.id {
            map?.style.safeRemoveImage(id: model2dId)
        }
    }
    
    private func updateInfoWindow(for model: any MPViewModel) {
        if model.showInfoWindow {
            if let point = model.marker?.geometry.coordinates as? MPPoint, let location = MPMapsIndoors.shared.locationWith(locationId: model.id) {
                createOrUpdateInfoWindow(for: model, at: point, location: location)
            }
        } else {
            removeInfoWindow(for: model)
            infoWindows.remove(key: model.id)
        }
    }
    
    private func createOrUpdateInfoWindow(for model: any MPViewModel, at point: MPPoint, location: MPLocation) {
        DispatchQueue.main.async { [self] in
            var yOffset = 0.0
            var xOffset = 0.0
            
            let respectDistance = 5.0
            
            // Based on icon placement and size, compute offsets for the info window
            if let icon = model.data[.icon] as? UIImage {
                if let iconPlacement = model.marker?.properties[.markerIconPlacement] as? String {
                    
                    yOffset = (icon.size.height / 2) + respectDistance
                    
                    switch iconPlacement {
                    case "bottom":
                        yOffset = icon.size.height + respectDistance
                    case "top":
                        yOffset = respectDistance
                    case "left":
                        xOffset = icon.size.width / 2
                    case "right":
                        xOffset = -(icon.size.width / 2)
                    case "center":
                        fallthrough
                    default:
                        break
                    }
                }
            }
            
            let options = ViewAnnotationOptions(
                geometry: Point(point.coordinate),
                allowOverlap: false,
                anchor: .bottom,
                offsetX: xOffset,
                offsetY: yOffset
            )
            
            let infoWindowView = infoWindows.getValue(key: model.id)
            
            if infoWindowView == nil {
                if let infoWindowView = customInfoWindow?.infoWindowFor(location: location) {
                    infoWindows.setValue(value: infoWindowView, key: model.id)
                }
            }
            
            if let view = infoWindowView {
                let viewId = MBRenderer.infoWindowPrefix + model.id
                if let existingView = mapView?.viewAnnotations.view(forId: viewId) {
                    try? mapView?.viewAnnotations.update(existingView, options: options)
                } else {
                    try? mapView?.viewAnnotations.add(view, id: viewId, options: options)
                }
                self.setupInfoWindowTapRecognizer(infoWindowView: view, modelId: model.id)
            }
        }
    }
    
    private func updateImage(for model: any MPViewModel) {
        if let icon = model.data[.icon] as? UIImage, let id = model.marker?.id {
            map?.style.safeAddImage(image: icon, id: id)
        } else {
            map?.style.safeRemoveImage(id: model.id)
        }
    }
    
    private func update2DModel(for model: any MPViewModel) {
        if let model2D = model.data[.model2D] as? UIImage, let id = model.model2D?.id, is2dModelsEnabled {
            map?.style.safeAddImage(image: model2D, id: id)
        } else {
            map?.style.safeRemoveImage(id: model.id + "/2D")
        }
    }
    
    // TODO: remove addedModels - just a heuristic to avoid flickering by repeatedly adding the same model, while we're missing some interface from Mapbox
    private var addedModels = [String: String]()
    private func update3DModel(for model: any MPViewModel) {
        if let model3DUri = model.model3D?.properties[.model3dUri] as? String, let model3DId = model.model3D?.id /*, is3dModelsEnabled*/ {
            DispatchQueue.main.async {
                if self.addedModels[model3DId] == nil || self.addedModels[model3DId] != model3DUri {
                    do {
                        try self.map?.style.addStyleModel(modelId: model3DId, modelUri: model3DUri)
                        self.addedModels[model3DId] = model3DUri
                    } catch { }
                }
            }
        }
    }

    private func updateGeoJSONSource(features: [Feature], nonCollisionFeatures: [Feature], featuresExtrusions: [Feature], features3DModels: [Feature]) {
        guard let map else { return }
        
        DispatchQueue.main.async {
            do {
                try map.style.updateGeoJSONSource(withId: Constants.SourceIDs.geoJsonSource, geoJSON: .featureCollection(FeatureCollection(features: features)).geoJSONObject)
                try map.style.updateGeoJSONSource(withId: Constants.SourceIDs.geoJsonNoCollisionSource, geoJSON: .featureCollection(FeatureCollection(features: nonCollisionFeatures)).geoJSONObject)
                try map.style.updateGeoJSONSource(withId: Constants.SourceIDs.geoJsonSourceExtrusions, geoJSON: .featureCollection(FeatureCollection(features: featuresExtrusions)).geoJSONObject)
                try map.style.updateGeoJSONSource(withId: Constants.SourceIDs.geoJsonSource3dModels, geoJSON: .featureCollection(FeatureCollection(features: features3DModels)).geoJSONObject)
            } catch {
                MPLog.mapbox.error("Error updating geojson source: \(error.localizedDescription)")
            }
        }
    }
}
    
// MARK: Extensions

/**
 We are extending the view model protocol with implementations for producing Mapbox 'Feature' objects.
 */
fileprivate extension MPViewModel {
    
    var markerFeature: Feature? {
        guard let marker = self.marker else { return nil }
        let string = marker.toGeoJson()
        return parse(geojson: string)
    }
    
    var polygonFeature: Feature? {
        guard let polygon = self.polygon else { return nil }
        let string = polygon.toGeoJson()
        return parse(geojson: string)
    }
    
    var floorPlanFeature: Feature? {
        guard let floorPlan = self.floorPlanExtrusion else { return nil }
        let string = floorPlan.toGeoJson()
        return parse(geojson: string)
    }
    
    var model2DFeature: Feature? {
        guard let model2D = self.model2D else { return nil }
        let string = model2D.toGeoJson()
        return parse(geojson: string)
    }
    
    var model3DFeature: Feature? {
        guard let model3D = self.model3D else { return nil }
        let string = model3D.toGeoJson()
        return parse(geojson: string)
    }
    
    var wallExtrusionFeature: Feature? {
        guard let wallExtrusion = self.wallExtrusion else { return nil }
        let string = wallExtrusion.toGeoJson()
        return parse(geojson: string)
    }
    
    var featureExtrusionFeature: Feature? {
        guard let featureExtrusion = self.featureExtrusion else { return nil }
        let string = featureExtrusion.toGeoJson()
        return parse(geojson: string)
    }
    
    private func parse(geojson: String) -> Feature? {
        do {
            return try JSONDecoder().decode(Feature.self, from: geojson.data(using: .utf8)!)
        } catch {
            MPLog.mapbox.error("Error parsing data: \(error)")
        }
        return nil
    }
    
}

fileprivate extension UIImage {
    func scaled(size: CGSize) -> UIImage? {
        guard size != .zero else { return nil }
        
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.opaque = false
        rendererFormat.scale = scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width, height: size.height), format: rendererFormat)
        
        return renderer.image { _ in
            draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}

fileprivate extension Style {
    
    /// Call this to add/update image
    /// - Parameters:
    ///   - image: image/icon to be passed
    ///   - withId: Id with which to check/add to map style
    func safeAddImage(image: UIImage, id: String) {
        DispatchQueue.main.async {
            do {
                try self.addImage(image, id: id)
            } catch {
                MPLog.mapbox.error("Error adding/updating image: \(error.localizedDescription)")
            }
        }
    }
    
    func safeRemoveImage(id: String) {
        DispatchQueue.main.async {
            if self.imageExists(withId: id) {
                do {
                    try self.removeImage(withId: id)
                } catch { }
            }
        }
    }
}


fileprivate class UnfairLock {
    // https://swiftrocks.com/thread-safety-in-swift
    
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    init() {
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deallocate()
    }

    func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try f()
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
