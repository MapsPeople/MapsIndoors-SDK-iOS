//
//  MapBoxProvider.swift
//  MapsIndoorsMapbox
//
//  Created by Malte Myhlendorph on 20/07/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import MapsIndoorsCore
import MapboxMaps

public class MapBoxProvider: MPMapProvider {
    
    public let model2DResolutionLimit = 500
    
    // Not respected on Mapbox v10
    public var enableNativeMapBuildings: Bool = true
    
    private var mapboxTransitionHandler: MapboxWorldTransitionHandler?
    
    public var wallExtrusionOpacity: Double = 0
    
    public var featureExtrusionOpacity: Double = 0
    
    public var routingService: MPExternalDirectionsService {
        return MBDirectionsService(accessToken: self.accessToken)
    }
    
    public var distanceMatrixService: MPExternalDistanceMatrixService {
        return MBDistanceMatrixService(accessToken: self.accessToken)
    }
    
    public var customInfoWindow: MPCustomInfoWindow?
    
    private var tileProvider: MBTileProvider?
    
    private var hasSetup = false
    
    private var onStyleLoadedCancelable: Cancelable?
    
    @MainActor
    public func setTileProvider(tileProvider: MPTileProvider) async {
        if hasSetup {
            self.tileProvider = MBTileProvider(mapView: mapView, provider: tileProvider)
        } else {
            if mapView?.mapboxMap.style.isLoaded == true {
                self.tileProvider = MBTileProvider(mapView: mapView, provider: tileProvider)
                setupWhenStyleIsLoaded()
            } else {
                self.onStyleLoadedCancelable = mapView?.mapboxMap.onNext(event: .styleLoaded) { _ in
                    self.onStyleLoadedCancelable?.cancel()
                    self.tileProvider = MBTileProvider(mapView: self.mapView, provider: tileProvider)
                    self.setupWhenStyleIsLoaded()
                }
            }
        }
    }
    
    public func reloadTilesForFloorChange() {
        self.tileProvider?.update()
    }
    
    private var renderer: MBRenderer?
    
    private var layerSetup: MBLayerPrecendence?
    
    private var _routeRenderer: MBRouteRenderer?
    
    public weak var view: UIView?
    
    public var padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet { adjustOrnaments()}
    }
    
    public var MPaccessibilityElementsHidden: Bool = false
    
    public weak var delegate: MPMapProviderDelegate? {
        didSet { mapboxTransitionHandler?.mapProviderDelegate = delegate }
    }
    
    public var positionPresenter: MPPositionPresenter

    public var collisionHandling: MPCollisionHandling = .allowOverLap
    
    public var routeRenderer: MPRouteRenderer {
        return _routeRenderer ?? MBRouteRenderer(mapView: self.mapView)
    }
    
    public func setViewModels(models: [any MPViewModel], forceClear: Bool) async {
        // Ignore `forceClear` - not applicable to mapbox rendering
        renderer?.customInfoWindow = customInfoWindow
        renderer?.collisionHandling = self.collisionHandling
        renderer?.featureExtrusionOpacity = featureExtrusionOpacity
        renderer?.wallExtrusionOpacity = wallExtrusionOpacity
        self.renderer?.render(models: models)
    }
    
    public var cameraOperator: MPCameraOperator {
        MBCameraOperator(mapView: self.mapView, provider: self)
    }
    
    private weak var mapView: MapView?
    
    private var accessToken: String
    
    public required init(mapView: MapView, accessToken: String) {
        self.mapView = mapView
        self.view = mapView
        self.accessToken = accessToken
        self.positionPresenter = MBPositionPresenter(map: self.mapView?.mapboxMap)
        
        mapboxTransitionHandler = MapboxWorldTransitionHandler()
        if let originalDelegate = mapView.gestures.delegate {
            mapboxTransitionHandler?.originalMapViewDelegate = originalDelegate
        }
        mapView.gestures.delegate = mapboxTransitionHandler
    }

    public func setupWhenStyleIsLoaded() {
        guard self.hasSetup == false else { return }
        
        self.hasSetup = true

        adjustOrnaments()
        renderer = MBRenderer(mapView: mapView, provider: self)
        _routeRenderer = MBRouteRenderer(mapView: self.mapView)
        mapView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onMapClick)))
        mapView?.mapboxMap.onEvery(event: .cameraChanged) { _ in
            self.delegate?.cameraChangedPosition()
        }
        
        // Set flags for certain MapsIndoors features (which require specific MapsIndoors licenses to utilize)
        if let r = renderer {
            configureMapsIndoorsModuleLicensing(renderer: r)
        }
        
        self.positionPresenter = MBPositionPresenter(map: mapView?.mapboxMap)
    }
    
    @objc func onMapClick(_ sender: UITapGestureRecognizer) {
        let screenPoint = sender.location(in: mapView)

         let queryOptions = RenderedQueryOptions(layerIds: [
            Constants.LayerIDs.routeMarkerLayer,
            Constants.LayerIDs.markerLayer,
            Constants.LayerIDs.markerNoCollisionLayer,
            Constants.LayerIDs.flatLabelsLayer,
            Constants.LayerIDs.model3DLayer,
            Constants.LayerIDs.model2DLayer,
            Constants.LayerIDs.polygonFillLayer,
            Constants.LayerIDs.wallExtrusionLayer,
            Constants.LayerIDs.featureExtrusionLayer
         ], filter: nil)

        mapView?.mapboxMap.queryRenderedFeatures(with: screenPoint, options: queryOptions) { result in
            if case let .success(queriedFeatures) = result {
                
                for queriedFeature in queriedFeatures {
                    if queriedFeature.feature.properties?["clickable"] == JSONValue(booleanLiteral: false) {
                        continue
                    }
                    
                    guard let id = queriedFeature.feature.identifier, case let .string(idString) = id else { continue }

                    if idString == "end_marker" || idString == "start_marker" {
                        self.routeRenderer.routeMarkerDelegate?.onRouteMarkerClicked(tag: idString)
                        return
                    } else {
                        _ = self.delegate?.didTap(locationId: String(idString), type: queriedFeature.mpRenderedFeatureType)
                        return
                    }
                }
            }

            if let coordinate = self.mapView?.mapboxMap.coordinate(for: screenPoint) {
                self.delegate?.didTap(coordinate: coordinate)
            }
        }
    }

    func onInfoWindowTapped(locationId: String) {
        _ = self.delegate?.didTapInfoWindowOf(locationId: locationId)
    }
    
    private func adjustOrnaments() {
        guard let mapView else { return }
        
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.logo.margins = .init(x: 20, y: padding.bottom)
        mapView.ornaments.options.attributionButton.position = .bottomLeading
        
        let pos = mapView.ornaments.logoView.frame.width
    
        mapView.ornaments.options.attributionButton.margins = .init(x: pos + 20, y: padding.bottom)
    }
    
    private func configureMapsIndoorsModuleLicensing(renderer: MBRenderer) {
        DispatchQueue.main.async {
            do {
                if let solutionModules = MPMapsIndoors.shared.solution?.modules {
                    if solutionModules.contains("z22") {
                        try self.mapView?.mapboxMap.setCameraBounds(with: CameraBoundsOptions(maxZoom: 25))
                    } else {
                        try self.mapView?.mapboxMap.setCameraBounds(with: CameraBoundsOptions(maxZoom: 21))
                    }
                    renderer.isWallExtrusionsEnabled = solutionModules.contains("3dwalls")
                    renderer.isFeatureExtrusionsEnabled = solutionModules.contains("3dextrusions")
                    renderer.is2dModelsEnabled = solutionModules.contains("2dmodels")
                    renderer.isFloorPlanEnabled = solutionModules.contains("floorplan")
                }
                try self.mapView?.mapboxMap.setCameraBounds(with: CameraBoundsOptions())
            } catch { }
        }
    }

}

fileprivate extension QueriedFeature {
    
    var mpRenderedFeatureType: MPRenderedFeatureType {
        if let typeString = (self.feature.properties?["type"] as? JSONValue)?.rawValue as? String,
           let type = MPRenderedFeatureType(rawValue: typeString) {
            return type
        }
        return .undefined
    }
    
}
