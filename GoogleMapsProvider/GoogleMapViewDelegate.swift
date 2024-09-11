//
//  GoogleMapProviderDelegate.swift
//  MapsIndoors
//
//  Created by Christian Wolf Johannsen on 13/04/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

class GoogleMapViewDelegate: NSObject, GMSMapViewDelegate {
    weak var originalMapViewDelegate: GMSMapViewDelegate?
    weak var mapsIndoorsDelegate: MPMapProviderDelegate?
    var userGestureInProgress: Bool?
    var didRunFirstMapIdle: Bool?
    weak var map: GoogleMapProvider!
    
    
    required init(googleMapProvider: GoogleMapProvider) {
        map = googleMapProvider
    }
    
    /**
     Google didTapMarker delegate
     Called after a marker has been tapped.
     */
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard marker.isTappable else { return false }
        var result = false
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didTap:))) {
                result = originalMapViewDelegate?.mapView?(mapView, didTap: marker) ?? false
            }
        }
        
        // Retrieve the corresponding marker identifier
        let markerIdentifier = marker.locationId
        
        if let tag = marker.userData as? String, tag == "end_marker" || tag == "start_marker" || tag.starts(with: "stop")  {
            map.routeRenderer.routeMarkerDelegate?.onRouteMarkerClicked(tag: tag)
        }

        return mapsIndoorsDelegate?.didTap(locationId: markerIdentifier, type: .marker) ?? result
    }

    /**
     Google didTapAtCoordinate delegate
     Called after a tap gesture at a particular coordinate, but only if a marker was not tapped.
     This is called before deselecting any currently selected marker (the implicit action for tapping on the map).
     */
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didTapAt:))) {
                originalMapViewDelegate?.mapView?(mapView, didTapAt: coordinate)
            }
        }

        mapsIndoorsDelegate?.didTap(coordinate: coordinate)
    }
    
    /**
     Google willMove delegate
     Called before the camera on the map changes, either due to a gesture, animation (e.g., by a user tapping on the "My Location" button) or by being updated explicitly via the camera or a zero-length animation on layer.
     */
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.userGestureInProgress = gesture
        
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:willMove:))) {
                originalMapViewDelegate?.mapView?(mapView, willMove: gesture)
            }
        }
        mapsIndoorsDelegate?.cameraWillMove()
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:idleAt:))) {
                originalMapViewDelegate?.mapView?(mapView, idleAt: position)
            }
        }
        mapsIndoorsDelegate?.cameraIdle()
    }
    
    /**
     Google didChangeCameraPosition delegate
     Called repeatedly during any animations or gestures on the map (or once, if the camera is explicitly set).This may not be called for all intermediate camera positions. It is always called for the final position of an animation or gesture.
     */
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didChange:))) {
                originalMapViewDelegate?.mapView?(mapView, didChange: position)
            }
        }
        mapsIndoorsDelegate?.cameraChangedPosition()
    }
    
    /**
     Google didTapInfoWindowOfMarker delegate
     Called after a marker's info window has been tapped.
     */
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:markerInfoWindow:))) {
                originalMapViewDelegate?.mapView?(mapView, didTapInfoWindowOf: marker)
            }
        }
        
        if let viewState = marker.userData as? ViewState {
            let _ = mapsIndoorsDelegate?.didTapInfoWindowOf(locationId: viewState.id)
        }
        
    }
    
    /**
     Google didBeginDraggingMarker delegate
     Called when dragging has been initiated on a marker.
     */
    
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        if let originaldelegate = originalMapViewDelegate {
            if originaldelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didBeginDragging:))) {
                originalMapViewDelegate?.mapView?(mapView, didBeginDragging: marker)
            }
        }
    }
    
    /**
     Google didEndDraggingMarker delegate
     Called after dragging of a marker ended.
     */
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didEndDragging:))) {
                originalMapViewDelegate?.mapView?(mapView, didEndDragging: marker)
            }
        }
    }
    
    /**
     Google didDragMarker delegate
     Called while a marker is dragged.
     */
    
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didDrag:))) {
                originalMapViewDelegate?.mapView?(mapView, didDrag: marker)
            }
        }
    }
    
    /**
     Google mapViewDidStartTileRendering delegate
     Called when tiles have just been requested or labels have just started rendering.
     */
    
    func mapViewDidStartTileRendering(_ mapView: GMSMapView) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapViewDidStartTileRendering(_:))) {
                originalMapViewDelegate?.mapViewDidStartTileRendering?(mapView)
            }
        }
    }
    
    //This has to be updated to the one in mapControl
    /**
     Google mapViewDidFinishTileRendering delegate
     Called when all tiles have been loaded (or failed permanently) and labels have been rendered.
     */
    
    //JSON styling only needs to be loaded once
    private var didLoadStyling = false
    
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapViewDidFinishTileRendering(_:))) {
                originalMapViewDelegate?.mapViewDidFinishTileRendering?(mapView)
            }
        }
        
        if didLoadStyling == false {
            let bundles = Bundle.allBundles
            for bundle in bundles {
                if let styleUrl = bundle.url(forResource: "default_mapspeople_googlemaps_style", withExtension: "json") {
                    if let mapStyle = try? GMSMapStyle(contentsOfFileURL: styleUrl) {
                        mapView.mapStyle = mapStyle
                        didLoadStyling = true
                        break
                    }
                }
            }
        }
    }
    
    /**
     Google didTapOverlay delegate
     Called after an overlay has been tapped.
     This method is not called for taps on markers.
     */
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        guard overlay.isTappable else { return }
        
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didTap:))) {
                originalMapViewDelegate?.mapView?(mapView, didTap: overlay)
            }
        }
        
        let id = overlay.locationId
        _ = mapsIndoorsDelegate?.didTap(locationId: id, type: overlay is GMSPolygon ? .polygon : .model2d)
    }
    
    /**
     Google didLongPressAtCoordinate delegate
     Called after a long-press gesture at a particular coordinate.
     */
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didLongPressAt:))) {
                originalMapViewDelegate?.mapView?(mapView, didLongPressAt: coordinate)
            }
        }
    }
    
    /**
     Google didLongPressInfoWindowOfMarker delegate
     Called after a marker's info window has been long pressed.
     */
    
    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didLongPressInfoWindowOf:))) {
                originalMapViewDelegate?.mapView?(mapView, didLongPressInfoWindowOf: marker)
            }
        }
    }
    
    /**
     Google didTapMyLocationButtonForMapView delegate
     Called when the My Location button is tapped.
     */
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.didTapMyLocationButton(for:))) {
                return ((originalMapViewDelegate?.didTapMyLocationButton?(for: mapView)) != nil)
            }
        }
        return ((originalMapViewDelegate?.didTapMyLocationButton?(for: mapView)) == nil)
    }
    
    /**
     Google didTapMyLocation delegate
     Called when the My Location Dot is tapped.
     */
    
    func mapView(_ mapView: GMSMapView, didTapMyLocation location: CLLocationCoordinate2D) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didTapMyLocation:))) {
                originalMapViewDelegate?.mapView?(mapView, didTapMyLocation: location)
            }
        }
    }
    
    /**
     Google mapViewSnapshotReady delegate
     Called when map is stable (tiles loaded, labels rendered, camera idle) and overlay objects have been rendered.
     */
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapViewSnapshotReady(_:))) {
                originalMapViewDelegate?.mapViewSnapshotReady?(mapView)
            }
        }
    }
    
    /**
     Google didCloseInfoWindowOfMarker delegate
     Called when the marker's info window is closed.
     */
    
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didCloseInfoWindowOf:))) {
                originalMapViewDelegate?.mapView?(mapView, didCloseInfoWindowOf: marker)
            }
        }
    }
    
    /**
     Google didTapPOIWithPlaceID delegate
     Called after a POI has been tapped.
     */
    
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:didTapPOIWithPlaceID:name:location:))) {
                originalMapViewDelegate?.mapView?(mapView, didTapPOIWithPlaceID: placeID, name: name, location: location)
            }
        }
    }
    
    /**
     Google markerInfoContents delegate
     Called when mapView:markerInfoWindow: returns nil.
     If this method returns a view, it will be placed within the default info window frame. If this method returns nil, then the default rendering will be used instead.
     */
    
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:markerInfoContents:))) {
                if let infoWindow = originalMapViewDelegate?.mapView?(mapView, markerInfoContents: marker) {
                    return infoWindow
                }
            }
        }
        return nil
    }
    
    /**
     Google markerInfoWindow delegate
     Called when a marker is about to become selected, and provides an optional custom info window to use for that marker if this method returns a UIView.
     If you change this view after this method is called, those changes will not necessarily be reflected in the rendered version.
     */

    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
 
        if let originalDelegate = originalMapViewDelegate {
            if originalDelegate.responds(to: #selector(GMSMapViewDelegate.mapView(_:markerInfoWindow:))) {
                if let infoWindow = originalMapViewDelegate?.mapView?(mapView, markerInfoWindow: marker) {
                    return infoWindow
                }
            }
        }

        var res: UIView?
        if let viewState = marker.userData as? ViewState {
            if let location = MPMapsIndoors.shared.locationWith(locationId: viewState.id) {
                res = map.customInfoWindow?.infoWindowFor(location: location)
            }
        }
        return res
    }
}

fileprivate extension GMSMarker {
    
    @objc override var locationId: String {
        (self.userData as? ViewState)?.id ?? ""
    }
    
}

fileprivate extension GMSOverlay {
    
    @objc var locationId: String {
        (self.userData as? ViewState)?.id ?? ""
    }
    
}
