//
//  GoogleMapProvider.swift
//  MapsIndoors
//
//  Created by Christian Wolf Johannsen on 06/04/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

public class GoogleMapProvider: MPMapProvider {

    public let model2DResolutionLimit = 200
    
    // Unused on Google Maps
    public var enableNativeMapBuildings: Bool = false

    public var routingService: MPExternalDirectionsService {
        GMDirectionsService(apiKey: self.googleApiKey! as String)
    }
    
    public var distanceMatrixService: MPExternalDistanceMatrixService {
        GMDistanceMatrixService(apiKey: self.googleApiKey! as String)
    }
    
    public var customInfoWindow: MPCustomInfoWindow?
    
    public func reloadTilesForFloorChange() { }
    
    private var renderer: Renderer?
    private var _routeRenderer: GMRouteRenderer?
    private var tileProvider: GMTileProvider?
    
    public var collisionHandling: MPCollisionHandling = .allowOverLap
    
    public var cameraOperator: MPCameraOperator {
        get {
            GMCameraOperator(gmsView: self.mapView)
        }
    }
    
    public var routeRenderer: MPRouteRenderer {
        if _routeRenderer != nil {
            return _routeRenderer!
        } else {
            _routeRenderer = GMRouteRenderer(map: self.mapView)
            return _routeRenderer!
        }
    }
    
    @MainActor
    public func setTileProvider(tileProvider: MPTileProvider) async {
        self.tileProvider?.map = nil
        self.tileProvider = GMTileProvider(provider: tileProvider)
        self.tileProvider?.map = self.mapView
    }

    public var delegate: MPMapProviderDelegate? {
        set {
            mapViewDelegate?.mapsIndoorsDelegate = newValue
        }
        get {
            return mapViewDelegate?.mapsIndoorsDelegate
        }
    }
        
    private weak var mapView: GMSMapView?
    
    private var googleApiKey: String?
    
    private var mapViewDelegate: GoogleMapViewDelegate?
    
    public var positionPresenter: MPPositionPresenter

    public var cameraPosition: MPCameraPosition
        
    public init(mapView: GMSMapView, googleApiKey: String? = nil) {
        self.mapView = mapView
        self.renderer = Renderer(map: self.mapView)
        
        self.mapView?.isBuildingsEnabled = false
        self.mapView?.isIndoorEnabled = false
        self.mapView?.setMinZoom(1, maxZoom: 21)

        self.googleApiKey = googleApiKey

        positionPresenter = GMPositionPresenter(map: mapView)

        cameraPosition = GMCameraPosition(cameraPosition: GMSMutableCameraPosition())

        mapViewDelegate = GoogleMapViewDelegate(googleMapProvider: self)
        if let originalDelegate = self.mapView?.delegate {
            mapViewDelegate?.originalMapViewDelegate = originalDelegate
        }
        self.mapView?.delegate = mapViewDelegate
        
        configureMapsIndoorsModuleLicensing()
    }
    
    public func setViewModels(models: [any MPViewModel], forceClear: Bool) async {
        self.configureMapsIndoorsModuleLicensing()
        self.renderer?.setViewModels(models: models, collision: self.collisionHandling, forceClear: forceClear)
    }

    public var view: UIView? {
        get {
            self.mapView
        }
    }
    
    public var MPaccessibilityElementsHidden: Bool {
        get {
            self.mapView?.accessibilityElementsHidden ?? true
        }
        set {
            self.mapView?.accessibilityElementsHidden = newValue
        }
    }
    
    public var padding: UIEdgeInsets {
        get {
            self.mapView?.padding ?? UIEdgeInsets.zero
        }
        set {
            self.mapView?.padding = newValue
        }
    }
    
    // Unused
    public var wallExtrusionOpacity: Double = 0
    
    // Unused
    public var featureExtrusionOpacity: Double = 0
    
    private func configureMapsIndoorsModuleLicensing() {
        if let solutionModules = MPMapsIndoors.shared.solution?.modules {
            renderer?.is2dModelsEnabled = solutionModules.contains("2dmodels")
            renderer?.isFloorPlanEnabled = solutionModules.contains("floorplan")
        }
    }
    
}
