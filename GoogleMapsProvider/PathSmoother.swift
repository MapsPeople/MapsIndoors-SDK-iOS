//
//  PathSmoother.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Jens Brobak Eibye on 14/12/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GoogleMaps
import MapsIndoorsCore

class PathSmoother {
        
    open class func smoothenPath(withCoordinates path: GMSPath!) -> GMSMutablePath! {
                
        let smoothPath = GMSMutablePath()
        
        smoothPath.accessibilityLabel = path.accessibilityLabel
        
        smoothPath.add(path.coordinate(at: 0))
        
        guard path.count() > 2 else {
            return GMSMutablePath(path: path)
        }
        
        for i in 1 ..< path.count() - 1 {
            
            let p0 = smoothPath.coordinate(at: smoothPath.count()-1)
            let p1 = path.coordinate(at: i)
            let p2 = path.coordinate(at: i+1)
            
            let kMinSegmentLengthForPathSmoothing = 0.1
            let kMaxPathSmoothingRadius = 1.0
            
            let smoothDist = kMaxPathSmoothingRadius
            
            let p0p1dist = GMSGeometryDistance(p0, p1)
            let p1p2dist = GMSGeometryDistance(p1, p2)
            
            if p0p1dist > kMinSegmentLengthForPathSmoothing && p1p2dist > kMinSegmentLengthForPathSmoothing {
                let p0t = min( smoothDist / p0p1dist, 0.5)
                let p2t = min( smoothDist / p1p2dist, 0.5)
                
                let p0delta = GMSGeometryInterpolate(p1, p0, p0t)
                let p2delta = GMSGeometryInterpolate(p1, p2, p2t)
                
                smoothPath.add(p0delta)
                
                let tDelta: Float = 0.25
                var t = tDelta
                while t < 1 {
                    let interpolated = MPGeometryUtils.coordinateInQuadCurve(p0: p0delta, p1: p1, p2: p2delta, t: Double(t))
                    smoothPath.add(interpolated)
                    t += tDelta
                }
                smoothPath.add(p2delta)
            } else {
                smoothPath.add(path.coordinate(at: i))
            }
        }
        
        smoothPath.add(path.coordinate(at: path.count() - 1))
        return smoothPath
    }
}
