//
//  OverlapEngine.swift
//  MapsIndoorsGoogleMaps
//
//  Created by Frederik Hansen on 28/10/2022.
//  Copyright © 2022 MapsPeople A/S. All rights reserved.
//

import Foundation
import GameplayKit
@_spi(Private) import MapsIndoorsCore
import GoogleMaps

class OverlapEngine {
    
    private var views: [ViewState]
    private weak var projection: GMSProjection!
    private let policy: MPCollisionHandling
    
    @MainActor private var tree: GKRTree<Entry>?
    private var entries = [String: Entry]()
    
    private var visited = MPThreadSafeDictionary<String, Bool>()
    
    @MainActor
    required init(views: [ViewState], projection: GMSProjection, overlapPolicy: MPCollisionHandling) async {
        self.views = views
        self.projection = projection
        self.policy = overlapPolicy
        tree = await buildTree(viewStates: views)
    }
    
    private func buildTree(viewStates: [ViewState]) async -> GKRTree<Entry> {
        let rtree = GKRTree<Entry>(maxNumberOfChildren: 4)
        rtree.queryReserve = 100
        for view in viewStates {
            let viewEntry = Entry(viewState: view, projection: projection)
            entries[view.id] = viewEntry
            await rtree.addEntry(entry: viewEntry)
        }
        return rtree
    }
    
    /**
     Run collision checks for each view state, against all other view states - and handle potential collisions by computing delta operations
     */
    func computeDeltas() async {
        guard policy != .allowOverLap else { return }
        // Sort by poi area size, (smallest first), so we process in order of area size from smallest to largest
        views = views.sorted(by: {a, b in a.poiArea < b.poiArea })
        
        let _ = await withTaskGroup(of: Bool.self) { group -> Bool in
            for view in views {
                _ = group.addTaskUnlessCancelled(priority: .high) {
                    if let current = self.entries[view.id], self.visited[view.id] == nil, let bounds = await current.bounds, let tree = await self.tree {
                        let collisions = tree.elements(inBoundingRectMin: bounds.0, rectMax: bounds.1)
                        for hit in collisions {
                            guard hit != current && self.visited[hit.id] == nil && current.viewState.markerState.isVisible && hit.viewState.markerState.isVisible else { continue }
                            let (winner, loser) = self.decideCollision(a: current, b: hit)
                            await self.resolveCollision(winnerEntry: winner, loserEntry: loser, overlapPolicy: self.policy)
                        }
                        self.visited[view.id] = true
                    }
                    return true
                }
            }
            for await x in group { }
            return true
        }
    }
    
    /**
     Returns a (winner, loser)-tuple.
     The winner is determined by the smallest geometry size (poiArea). In case they are equal - we use the lat/lng to determine a winner.
     The most northern or the most eastern point wins.
     If a viewstate is "selected", it should always be the winner!
     */
    private func decideCollision(a: Entry, b: Entry) -> (Entry, Entry) {
    
        if a.viewState.forceRender { return (a, b) }
        if b.viewState.forceRender { return (b, a) }

        // 1. Compare based on poiArea size
        if a.viewState.poiArea != b.viewState.poiArea {
            return a.viewState.poiArea < b.viewState.poiArea ? (a, b) : (b, a)
        }
        
        // 2. Compare based on name - alphabetically
        if a.viewState.poiArea == b.viewState.poiArea {
            let aName = a.viewState.infoWindowText ?? ""
            let bName = b.viewState.infoWindowText ?? ""
            if aName != bName {
                return aName < bName ? (a, b) : (b, a)
            }
        }
        
        // 3. Compare based on longtitude
        let aLongitude = a.viewState.markerPosition?.longitude ?? -Double.infinity
        let bLongitude = b.viewState.markerPosition?.longitude ?? -Double.infinity

        return aLongitude > bLongitude ? (a, b) : (b, a)
    }
    
    /**
     Decide what delta operations should be commited to view states in order to resolve the collision according to the set MPCollisionHandling.
     Here we know that a collision has happened between two entries (and their underlying view states), so we remove them from the rtree -
     make the necessary state mutations to resolve the conflict - and re-add them to the rtree (in order to update their hitbox representation).
     */
    @MainActor 
    private func resolveCollision(winnerEntry: Entry, loserEntry: Entry, overlapPolicy: MPCollisionHandling) async {
        await tree?.removeEntry(entry: winnerEntry)
        await tree?.removeEntry(entry: loserEntry)
        
        switch overlapPolicy {
        case .removeIconFirst:
            await removeIconFirst(winnerState: winnerEntry.viewState, loserState: loserEntry.viewState)
        case .removeLabelFirst:
            await removeLabelFirst(winnerState: winnerEntry.viewState, loserState: loserEntry.viewState)
        case .removeIconAndLabel:
            removeIconAndLabel(winnerState: winnerEntry.viewState, loserState: loserEntry.viewState)
        default:
            break
        }
        
        await tree?.addEntry(entry: winnerEntry)
        await tree?.addEntry(entry: loserEntry)
    }
    
    private func removeIconAndLabel(winnerState: ViewState, loserState: ViewState) {
        if !loserState.forceRender {
            loserState.markerState = .INVISIBLE
        }
    }
    
    /**
     Remove the icon(s) first, to attempt to resolve the collision - if that isn't enough, remove label(s)
     */
    private func removeIconFirst(winnerState: ViewState, loserState: ViewState) async {
        var winner = await winnerState.bounds ?? CGRect(x: -1000, y: -1000, width: 1, height: 1)
        var loser = await loserState.bounds ?? CGRect(x: -2000, y: -2000, width: 1, height: 1)
        let winnerHasLabel = winnerState.markerState.isLabelVisible
        let winnerHasIcon = winnerState.markerState.isIconVisible
        let loserHasLabel = loserState.markerState.isLabelVisible
        var loserHasIcon = loserState.markerState.isIconVisible
        
        if loserHasIcon && !loserState.forceRender {
            if loserHasLabel && winnerHasLabel {
                loserState.markerState = .VISIBLE_LABEL
            } else {
                loserState.markerState = .INVISIBLE
                return
            }
        }
        
        loser = await loserState.bounds ?? CGRect(x: -2000, y: -2000, width: 1, height: 1)
        
        if winner.intersects(loser) {
            loserHasIcon = loserState.markerState.isIconVisible
            
            if winnerHasIcon && !winnerState.forceRender {
                winnerState.markerState = .VISIBLE_LABEL
            }
            
            winner = await winnerState.bounds ?? CGRect(x: -1000, y: -1000, width: 1, height: 1)
            if winner.intersects(loser) && !loserState.forceRender {
                loserState.markerState = .INVISIBLE
            }
        }
    }
    
    /**
     Remove the label(s) first, to attempt to resolve the collision - if that isn't enough, remove icons(s)
     */
    private func removeLabelFirst(winnerState: ViewState, loserState: ViewState) async {
        var winner = await winnerState.bounds ?? CGRect(x: -1000, y: -1000, width: 1, height: 1)
        var loser = await loserState.bounds ?? CGRect(x: -2000, y: -2000, width: 1, height: 1)
        let winnerHasLabel = winnerState.markerState.isLabelVisible
        let winnerHasIcon = winnerState.markerState.isIconVisible
        var loserHasLabel = loserState.markerState.isLabelVisible
        let loserHasIcon = loserState.markerState.isIconVisible
        
        if loserHasLabel && !loserState.forceRender {
            if loserHasIcon && winnerHasIcon {
                loserState.markerState = .VISIBLE_ICON
            } else {
                loserState.markerState = .INVISIBLE
                return
            }
        }
        
        loser = await loserState.bounds ?? CGRect(x: -2000, y: -2000, width: 1, height: 1)
        
        if winner.intersects(loser) {
            loserHasLabel = loserState.markerState.isLabelVisible
            
            if winnerHasLabel && !winnerState.forceRender {
                winnerState.markerState = .VISIBLE_ICON
            }
                        
            winner = await winnerState.bounds ?? CGRect(x: -1000, y: -1000, width: 1, height: 1)
            if winner.intersects(loser) && !loserState.forceRender {
                loserState.markerState = .INVISIBLE
            }
        }
    }
    
}

extension GKRTree<Entry> {
    
    @MainActor
    func addEntry(entry: Entry) async {
        if let bounds = await entry.bounds {
            // GKRTree does not recognize partial overlap of rectangles, when searching - so we need to add each corner to the tree as individual nodes, to get the desired collision detection
            let split = GKRTreeSplitStrategy.reduceOverlap
            let bottomLeft = bounds.0
            let topRight = bounds.1
            let topLeft = vector_float2(bounds.0.x, bounds.1.y)
            let bottomRight = vector_float2(bounds.1.x, bounds.0.y)
            addElement(entry, boundingRectMin: bottomLeft, boundingRectMax: bottomLeft, splitStrategy: split)
            addElement(entry, boundingRectMin: topRight, boundingRectMax: topRight, splitStrategy: split)
            addElement(entry, boundingRectMin: topLeft, boundingRectMax: topLeft, splitStrategy: split)
            addElement(entry, boundingRectMin: bottomRight, boundingRectMax: bottomRight, splitStrategy: split)
        }
    }
    
    @MainActor
    func removeEntry(entry: Entry) async {
        if let bounds = await entry.bounds {
            removeElement(entry, boundingRectMin: bounds.0+10, boundingRectMax: bounds.1+10)
        }
    }
    
}

class Entry: NSObject {
    
    weak var viewState: ViewState!
    let id: String
    weak var projection: GMSProjection!

    required init(viewState: ViewState, projection: GMSProjection) {
        self.viewState = viewState
        self.projection = projection
        self.id = viewState.id
    }
    
    var bounds: (vector_float2, vector_float2)? {
        get async {
            var bounds: (vector_float2, vector_float2)?
            if let b = await viewState.bounds {
                let min = vector_float2(Float(b.minX).rounded(.down), Float(b.minY).rounded(.down))
                let max = vector_float2(Float(b.maxX).rounded(.down), Float(b.maxY).rounded(.down))
                bounds = (min, max)
            }
            return bounds
        }
    }
    
}
