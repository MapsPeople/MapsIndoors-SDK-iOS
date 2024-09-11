//
//  GMTileProvider.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Malte Myhlendorph on 06/09/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

class GMTileProvider: GMSTileLayer {
    
    required init(provider: MPTileProvider) {
        _tileProvider = provider
        super.init()
        self.tileSize = Int(provider.tileSize())
    }
    
    var _tileProvider: MPTileProvider

    override func requestTileFor(x: UInt, y: UInt, zoom: UInt, receiver: GMSTileReceiver) {
        DispatchQueue.global(qos: .userInteractive).async {
            let tile = self._tileProvider.getTile(x: x, y: y, zoom: zoom)
            DispatchQueue.main.async {
                receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: tile)
            }
        }
    }
    
}
