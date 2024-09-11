//
//  MBTileProvider.swift
//  MapsIndoorsMapbox
//
//  Created by Malte Myhlendorph on 22/09/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import MapboxMaps
import MapsIndoorsCore

class MBTileProvider {
    private weak var mapView: MapView?
    public var _tileProvider: MPTileProvider
    private var rasterSource = RasterSource()
    private var templateUrl: String!
    
    init(mapView: MapView?, provider: MPTileProvider) {
        self.mapView = mapView
        _tileProvider = provider
        setupLayer()
        update()
    }
    
    private func setupLayer() {
        guard let mapView else { return }
        
        if !mapView.mapboxMap.style.layerExists(withId: Constants.LayerIDs.tileLayer) {
            var tileLayer = RasterLayer(id: Constants.LayerIDs.tileLayer)
            tileLayer.source = Constants.SourceIDs.tileSource
            do {
                try mapView.mapboxMap.style.addLayer(tileLayer)
            } catch {
                MPLog.mapbox.error(error.localizedDescription)
            }
        }
    }
    
    func update() {
        DispatchQueue.main.async {
            do {
                try self.updateSource()
                try self.updateLayer()
            } catch {
                MPLog.mapbox.error("Error updating tile layer/source: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSource() throws {
        guard let mapView else { return }
        
        if templateUrl != _tileProvider.templateUrl() {
            templateUrl = _tileProvider.templateUrl()
            rasterSource.tiles = [templateUrl]
            rasterSource.tileSize = _tileProvider.tileSize()
            rasterSource.volatile = false
        }
        
        if mapView.mapboxMap.style.sourceExists(withId: Constants.SourceIDs.tileSource) == false {
            return try mapView.mapboxMap.style.addSource(rasterSource, id: Constants.SourceIDs.tileSource)
        }

        try mapView.mapboxMap.style.updateLayer(withId: Constants.LayerIDs.tileLayer, type: RasterLayer.self) { updateLayer in
            
            if mapView.mapboxMap.style.layerExists(withId: Constants.LayerIDs.polygonFillLayer) {
                do {
                    try mapView.mapboxMap.style.moveLayer(withId: Constants.LayerIDs.tileLayer, to: .below(Constants.LayerIDs.polygonFillLayer))
                } catch {
                    MPLog.mapbox.error(error.localizedDescription)
                }
            }
            updateLayer.source = .none
        }
        
        try mapView.mapboxMap.style.removeSource(withId: Constants.SourceIDs.tileSource)
        try mapView.mapboxMap.style.addSource(rasterSource, id: Constants.SourceIDs.tileSource)

    }
    
    private func updateLayer() throws {
        try mapView?.mapboxMap.style.updateLayer(withId: Constants.LayerIDs.tileLayer, type: RasterLayer.self) { updateLayer in
            updateLayer.source = Constants.SourceIDs.tileSource
            updateLayer.rasterFadeDuration = .constant(0.5)
        }
    }
    
}
