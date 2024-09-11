//
//  GMRouteRenderer.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Frederik Hansen on 06/10/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import MapsIndoorsCore
import GoogleMaps
import ValueAnimator

extension BinaryFloatingPoint {
    var degrees: Self {
        return self * 180.0 / .pi
    }
    var radians: Self {
        return self * .pi / 180.0
    }
}

class GMRouteRenderer: MPRouteRenderer {

    private weak var map: GMSMapView?
    
    private var polylineColor = UIColor.black
    private var polyline: GMSPolyline?

    private var animatedColor = UIColor.black
    private var animatedWidth: Float = 3.0
    private var animationPath: GMSMutablePath?
    private var animationPolyline: GMSPolyline?
    private var valueAnimator: ValueAnimator?
    
    var routeMarkerDelegate: MPRouteMarkerDelegate?
    
    required init(map: GMSMapView?) {
        self.map = map
    }
    
    private var queue = DispatchQueue(label: "MapsIndoors.GoogleMapsRouteRenderer")
    
    func apply(model: RouteViewModelProducer, animate: Bool, duration: TimeInterval,
               repeating: Bool, primaryColor: UIColor, secondaryColor: UIColor,
               primaryWidth: Float, secondaryWidth: Float, pathSmoothing: Bool) {
        
        for viewState in self.views {
            Task {
                await viewState.destroy()
            }
        }
        self.views.removeAll()
        
        queue.async {
            let gmsPath = GMSMutablePath()
            
            for c in model.polyline {
                gmsPath.add(c)
            }
            
            var path = gmsPath
            
            if pathSmoothing {
                path = PathSmoother.smoothenPath(withCoordinates: gmsPath)
            }

            DispatchQueue.main.async { [weak self] in
                self?.polyline?.map = nil
                self?.polyline = GMSPolyline(path: path)
                self?.polyline?.geodesic = true
                self?.polyline?.strokeColor = primaryColor
                self?.polyline?.strokeWidth = CGFloat(primaryWidth)
                self?.polyline?.map = self?.map
                self?.polyline?.zIndex = Int32(MapOverlayZIndex.directionsOverlays.rawValue)
            }
            
            self.valueAnimator?.pause()

            if animate {
                var route = [CLLocationCoordinate2D]()
                if path.count() > 0 {
                    for i in 0...(path.count() - 1) {
                        route.append(path.coordinate(at: i))
                    }
                }
                
                var totalDistance = 0.0
                var prevPoint: CLLocationCoordinate2D? = nil
                for point in route {
                    if prevPoint != nil {
                        totalDistance += MPGeometryUtils.distance(from: MPGeoPoint(coordinate: prevPoint!), to: MPGeoPoint(coordinate: point))
                    }
                    prevPoint = point
                }
                
                //https://github.com/brownsoo/ValueAnimator/tree/0.6.7
                self.valueAnimator = ValueAnimator.animate("val", from: 0.0, to: 1.0, duration: duration,
                                                      easing: EaseLinear.easeInOut(),
                                                           onChanged: { p, v in
                    self.queue.sync { [self] in
                        var points = [CLLocationCoordinate2D]()
                        let routePoints = route
                        
                        let stopDistance = v.value * totalDistance
                        var distance = 0.0
                        
                        for i in stride(from: 0, through: routePoints.count - 1, by: 1) {
                            let nextPoint = routePoints[i]
                            if i == 0 || v.value == 1.0 {
                                points.append(nextPoint)
                            } else {
                                let lastPoint = routePoints[i-1]
                                var nextDistance = MPGeometryUtils.distance(from: MPGeoPoint(coordinate: lastPoint), to: MPGeoPoint(coordinate: nextPoint))
                                if distance + nextDistance > stopDistance {
                                    nextDistance = stopDistance - distance
                                    let bearing = MPGeometryUtils.bearingBetweenPoints(from: lastPoint, to: nextPoint)
                                    let computedPoint = self.computeOffset(from: lastPoint, dist: nextDistance, head: bearing)
                                    points.append(computedPoint)
                                    break
                                } else {
                                    points.append(nextPoint)
                                }
                                distance += nextDistance
                            }
                        }
                        
                        let animatedPath = GMSMutablePath()
                        for coord in points {
                            animatedPath.add(coord)
                        }

                        DispatchQueue.main.async { [weak self] in
                            if self?.valueAnimator?.isAnimating ?? false {
                                if self?.animationPolyline != nil {
                                    self?.animationPolyline!.path = animatedPath
                                } else {
                                    self?.animationPolyline = GMSPolyline(path: animatedPath)
                                    self?.animationPolyline?.strokeColor = secondaryColor
                                    self?.animationPolyline?.strokeWidth = CGFloat(secondaryWidth)
                                    self?.animationPolyline?.zIndex = Int32(MapOverlayZIndex.directionsOverlays.rawValue)
                                    self?.animationPolyline?.map = self?.map
                                }
                            } else {
                                self?.clear()
                            }
                        }
                    }
                }, option: ValueAnimator.OptionBuilder().setDelay(0.1).setRepeatInfinitely(repeating).build())
                self.valueAnimator?.callbackOnMainThread = false
                self.valueAnimator?.resume()
            }
            DispatchQueue.main.async { [weak self] in
                // start model render
                self?.renderMarker(model: model.start, type: .start)
                // end model render
                self?.renderMarker(model: model.end, type: .end)
                
                for stop in model.stops ?? [] {
                    self?.renderMarker(model: stop, type: .stop)
                }
            }
        }
        
        
    }
    
    func moveCamera(points path: [CLLocationCoordinate2D], animate: Bool, durationMs: Int, tilt: Float, fitMode: MPCameraViewFitMode, padding: UIEdgeInsets) {
        guard let map = self.map, path.count >= 2 else { return }

        let bounds = MPGeoBounds(points: path)

        switch fitMode {
        case .northAligned:
            let pos = createCameraPosition(for: bounds.center.coordinate, zoom: adjustedZoom(path: path, heading: 0, insets: padding), bearing: 0, tilt: 0)
            DispatchQueue.main.async { map.animate(to: pos) }
        case .firstStepAligned, .startToEndAligned:
            guard path.count >= 2 else { break }
            let bearing = fitMode == .firstStepAligned ? MPGeometryUtils.bearingBetweenPoints(from: path[0], to: path[1]) : MPGeometryUtils.bearingBetweenPoints(from: path[0], to: path.last!)
            let pos = createCameraPosition(for: bounds.center.coordinate, zoom: adjustedZoom(path: path, heading: bearing, insets: padding), bearing: bearing, tilt: tilt)
            DispatchQueue.main.async { map.animate(to: pos) }
        case .none:
            return
        default:
            break
        }
    }

    private func adjustedZoom(path: [CLLocationCoordinate2D], heading: CLLocationDirection, insets: UIEdgeInsets) -> Float {
        guard let map = self.map else { return 0 }

        // Get center in WGS84, height and width in meters of the path
        let centerAndWidth = centerAndWidthOfPath(path, seenFromHeading: heading)
        let centerAndHeight = centerAndWidthOfPath(path, seenFromHeading: heading + 90)

        // Calculate a size factor for width and height
        let widthFactor = widthFactor(centerAndWidth: centerAndWidth)
        let heightFactor = heightFactor(centerAndHeight: centerAndHeight)

        // Derive zoom factor and zoom as the smallest factor:
        // below 1 we will zoom out,
        // above 1 we will zoom in
        var zoomFactor = min(widthFactor, heightFactor)
        let zoom = map.camera.zoom + log2(Float(zoomFactor))

        // Calculate ground resolution for the calculated zoom
        let groundResolution = groundResForLatitude(map.camera.target.latitude, zoom: Double(zoom))

        // Calculate adjusted height and width based on insets
        let adjustedHeightDist = centerAndHeight.distance + groundResolution * insets.bottom + groundResolution * insets.top
        let adjustedWidthDist = centerAndWidth.distance * 1.2 + groundResolution * insets.left + groundResolution * insets.right

        // Calculate a size factor for width and height
        let adjustedHeightFactor = centerAndHeight.distance / adjustedHeightDist
        let adjustedWidthFactor = centerAndWidth.distance / adjustedWidthDist

        // Derive zoom factor and zoom as the smallest factor:
        zoomFactor = min(adjustedWidthFactor, adjustedHeightFactor)
        return zoom + log2(Float(zoomFactor))
    }

    struct PointDistanceResult {
        var position: CLLocationCoordinate2D
        var distance: CLLocationDistance
    }

    private func widthFactor(centerAndWidth: PointDistanceResult) -> Double {
        guard let map = self.map else { return 1 }

        let visibleRegion = map.projection.visibleRegion()
        let left = GMSGeometryInterpolate(visibleRegion.farLeft, visibleRegion.nearLeft, 0.5)
        let right = GMSGeometryInterpolate(visibleRegion.farRight, visibleRegion.nearRight, 0.5)
        let mapWidthDist = GMSGeometryDistance(left, right)
        return mapWidthDist / centerAndWidth.distance
    }

    private func heightFactor(centerAndHeight: PointDistanceResult) -> Double {
        guard let map = self.map else { return 1 }

        let visibleRegion = map.projection.visibleRegion()
        let top = GMSGeometryInterpolate(visibleRegion.farLeft, visibleRegion.farRight, 0.5)
        let bottom = GMSGeometryInterpolate(visibleRegion.nearLeft, visibleRegion.nearRight, 0.5)
        let mapHeightDist = GMSGeometryDistance(top, bottom)
        return mapHeightDist / centerAndHeight.distance
    }

    private func centerAndWidthOfPath(_ path: [CLLocationCoordinate2D], seenFromHeading heading: CLLocationDirection) -> PointDistanceResult {
        let center = centerOfPath(path)

        var bestLeftDist: CLLocationDistance = 0
        var bestRightDist: CLLocationDistance = 0
        for coordinate in path {
            let hypotenuseDist = GMSGeometryDistance(center, coordinate)
            let hypotenuseHeading = GMSGeometryHeading(center, coordinate)
            let relativeHeading = hypotenuseHeading - heading

            // Start with:   sin(relativeHeading)                = perpendicularDist/hypotenuseDist
            // Swap Sides:   perpendicularDist/hypotenuseDist    = sin(relativeHeading)
            // Thus:
            let perpendicularDist = sin(relativeHeading.radians) * hypotenuseDist
            if perpendicularDist > 0 && perpendicularDist > bestRightDist {
                bestRightDist = perpendicularDist
            } else if -perpendicularDist > bestLeftDist {
                bestLeftDist = -perpendicularDist
            }
        }

        let distance = bestLeftDist + bestRightDist + 0.2
        let recenterHeading = heading + (bestRightDist > bestLeftDist ? 90 : -90)
        let position = GMSGeometryOffset(center, max(bestLeftDist, bestRightDist) - distance * 0.5, recenterHeading)

        return PointDistanceResult(position: position, distance: distance)
    }

    private func centerOfPath(_ path: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let gmsPath = GMSMutablePath()
        for coordinate in path {
            gmsPath.add(coordinate)
        }
        let bounds = GMSCoordinateBounds(path: gmsPath)
        return GMSGeometryInterpolate(bounds.northEast, bounds.southWest, 0.5)
    }

    private func groundResForLatitude(_ lat: Double, zoom: Double) -> Double {
        let screenScale = UIScreen.main.scale
        return (156543.03392 * cos(lat.radians) / pow(2, zoom)) / screenScale
    }
    
    func clear() {
        self.valueAnimator?.pause()
        self.valueAnimator = nil
        DispatchQueue.main.async { [weak self] in
            self?.polyline?.map = nil
            self?.animationPolyline?.map = nil
            
            self?.polyline = nil
            self?.animationPolyline = nil
            
            for viewState in self?.views ?? [] {
                Task {
                    await viewState.destroy()
                }
            }
            self?.views.removeAll()
        }
    }
    
    private var views = [ViewState]()
    
    // Helper methods
    private func renderMarker(model: (any MPViewModel)?, type: MarkerType) {
        guard let model else { return }
        Task { @MainActor in
            let s = await ViewState(viewModel: model, map: self.map!, is2dModelEnabled: false, isFloorPlanEnabled: false)
            s.computeDelta(newModel: model)
            await s.applyDelta()
            s.marker.userData = model.id
            s.marker.zIndex = type == .start ? Int32(MapOverlayZIndex.startMarkerOverlay.rawValue) : Int32(MapOverlayZIndex.endMarkerOverlay.rawValue)
            self.views.append(s)
        }
    }
    
    private func createCameraUpdate(for bounds: GMSCoordinateBounds, with insets: UIEdgeInsets) -> GMSCameraUpdate {
        GMSCameraUpdate.fit(bounds, with: insets)
    }
    
    private func createCameraPosition(for target: CLLocationCoordinate2D, zoom: Float, bearing: Double, tilt: Float) -> GMSCameraPosition {
        return GMSCameraPosition(target: target, zoom: zoom, bearing: CLLocationDirection(floatLiteral: bearing), viewingAngle: Double(tilt))
    }
    
    // Calculation from Google's Spherical utils, earth radius from MapboxSDK v9
    private func computeOffset(from: CLLocationCoordinate2D, dist: Double, head: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6378137.0
        let distance = dist / earthRadius
        let heading = head.radians
        let fromLat = from.latitude.radians
        let fromLng = from.longitude.radians
        let cosDistance = cos(distance)
        let sinDistance = sin(distance)
        let sinFromLat = sin(fromLat)
        let cosFromLat = cos(fromLat)
        let sinLat = cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading)
        let dLng = atan2(sinDistance * cosFromLat * sin(heading), cosDistance - sinFromLat * sinLat)
        return CLLocationCoordinate2D(latitude: asin(sinLat).degrees, longitude: (fromLng + dLng).degrees)
    }
    
}
fileprivate enum MarkerType: String {
    case start = "start_marker"
    case end = "end_marker"
    case stop = "stop"
}
