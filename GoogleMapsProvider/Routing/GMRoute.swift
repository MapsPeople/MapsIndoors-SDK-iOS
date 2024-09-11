import Foundation
import MapsIndoors
import MapsIndoorsCore
import GoogleMaps

@_spi(Testable) public struct GoogleRouteResponse: Codable {
    public let routes: [GoogleRoute]
    public let status: String
    
    enum CodingKeys: String, CodingKey {
        case routes
        case status
    }
}

@_spi(Testable) public struct GoogleRoute: Codable {
    public let bounds: GoogleBounds?
    public let copyrights: String?
    public let legs: [GoogleLeg]?
    public let overviewPolyline: GooglePolyline?
    public let summary: String?
    public let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case bounds, copyrights, legs
        case overviewPolyline = "overview_polyline"
        case summary, warnings
    }
    
    var asMPRoute: MPRoute {
        
        let mpRoute = MPRouteInternal()
        mpRoute.copyrights = self.copyrights
        mpRoute.summary = self.summary
        mpRoute.warnings.append(contentsOf: self.warnings ?? [])
        mpRoute.legs = [MPRouteLegInternal]()
        
        for googleLeg in (self.legs ?? []) {
            
            let mpLeg = MPRouteLegInternal()
            
            
            mpLeg.duration = (googleLeg.duration?.value ?? 0.0) as NSNumber
            mpLeg.distance = (googleLeg.distance?.value ?? 0.0) as NSNumber
            
            let legStart = MPRouteCoordinateInternal()
            legStart.lat = (googleLeg.startLocation?.lat ?? 0.0) as NSNumber
            legStart.lng = (googleLeg.startLocation?.lng ?? 0.0) as NSNumber
            legStart.zLevel = 0.0 as NSNumber
            mpLeg.start_location = legStart
            
            let legEnd = MPRouteCoordinateInternal()
            legEnd.lat = (googleLeg.endLocation?.lat ?? 0.0) as NSNumber
            legEnd.lng = (googleLeg.endLocation?.lng ?? 0.0) as NSNumber
            legEnd.zLevel = 0.0 as NSNumber
            mpLeg.end_location = legEnd
            
            mpLeg.start_address = googleLeg.startAddress ?? ""
            mpLeg.end_address = googleLeg.endAddress ?? ""
            
            googleLeg.steps?.forEach { googleStep in
                mpLeg.addStep(mpStepFrom(googleStep: googleStep))
            }
            
            mpLeg.routeLegType = .External
            mpRoute.addLeg(mpLeg)
        }
        
        return mpRoute
    }
    
    func mpStepFrom(googleStep: GoogleStep) -> MPRouteStep {
        let mpStep = MPRouteStepInternal()
        mpStep.duration = (googleStep.duration?.value ?? 0.0) as NSNumber
        mpStep.distance = (googleStep.distance?.value ?? 0.0) as NSNumber
        
        let stepStart = MPRouteCoordinateInternal()
        stepStart.lat = (googleStep.startLocation?.lat ?? 0.0) as NSNumber
        stepStart.lng = (googleStep.startLocation?.lng ?? 0.0) as NSNumber
        stepStart.zLevel = 0.0 as NSNumber
        mpStep.start_location = stepStart
        
        let stepEnd = MPRouteCoordinateInternal()
        stepEnd.lat = (googleStep.endLocation?.lat ?? 0.0) as NSNumber
        stepEnd.lng = (googleStep.endLocation?.lng ?? 0.0) as NSNumber
        stepEnd.zLevel = 0.0 as NSNumber
        mpStep.end_location = stepEnd
        
        mpStep.html_instructions = googleStep.htmlInstructions ?? ""

        mpStep.duration = NSNumber(value: googleStep.duration?.value ?? 0)
        mpStep.distance = NSNumber(value: googleStep.distance?.value ?? 0)

        let path = GMSPath(fromEncodedPath: googleStep.polyline!.points!)!
        
        var geometry = [MPRouteCoordinateInternal]()
        for i in 0..<path.count() {
            let c = path.coordinate(at: i)
            let x = MPRouteCoordinateInternal()
            x.lat = c.latitude as NSNumber
            x.lng = c.longitude as NSNumber
            x.zLevel = 0.0
            geometry.append(x)
        }
        
        mpStep.geometry = geometry
        if let polylineData = googleStep.polyline?.points?.data(using: .utf8) {
            do {
                mpStep.polyline = try JSONDecoder().decode(MPEncodedPolylineInternal.self, from: polylineData)
            } catch {
                MPLog.google.debug("Invalid polyline data in route from Google.")
            }
        }
        mpStep.travel_mode = googleStep.travelMode?.rawValue ?? "unknown"
        
        mpStep.transit_details = mpTransitDetailsFrom(google: googleStep.transit_details)
        
        return mpStep
    }
    
    func mpTransitDetailsFrom(google: GoogleTransitDetails?) -> MPTransitDetails? {
        guard let gTransitDetails = google else { return nil }
        
        let transitDetails = MPTransitDetailsInternal()
        
        var stopCoordinate = MPRouteCoordinateInternal(latitude: gTransitDetails.arrival_stop.location.lat ?? 0, longitude: gTransitDetails.arrival_stop.location.lng ?? 0.0)
        transitDetails.arrival_stop = MPTransitStopInternal(name: gTransitDetails.arrival_stop.name, location: stopCoordinate)
        
        transitDetails.arrival_time = MPTransitTimeInternal(text: gTransitDetails.arrival_time.text, timeZone: gTransitDetails.arrival_time.time_zone, value: gTransitDetails.arrival_time.value)
        
        stopCoordinate = MPRouteCoordinateInternal(latitude: gTransitDetails.departure_stop.location.lat ?? 0, longitude: gTransitDetails.departure_stop.location.lng ?? 0)
        transitDetails.departure_stop = MPTransitStopInternal(name: gTransitDetails.departure_stop.name, location: stopCoordinate)
        
        transitDetails.departure_time = MPTransitTimeInternal(text: gTransitDetails.departure_time.text, timeZone: gTransitDetails.departure_time.time_zone, value: gTransitDetails.departure_time.value)
        
        transitDetails.headsign = gTransitDetails.headsign

        let agencies = gTransitDetails.line.agencies.map { MPTransitAgencyInternal(name: $0.name, url: $0.url) }
        let vehicle = MPTransitVehicleInternal(icon: gTransitDetails.line.vehicle.icon, name: gTransitDetails.line.vehicle.name, type: gTransitDetails.line.vehicle.type)
        transitDetails.line = MPTransitLineInternal(shortName: gTransitDetails.line.short_name, agencies: agencies, vehicle: vehicle)

        transitDetails.num_stops = NSNumber(integerLiteral: gTransitDetails.num_stops)
        
        return transitDetails
    }
    
}

@_spi(Testable) public struct GoogleBounds: Codable {
    public let northeast, southwest: GoogleCoordinate?
}

@_spi(Testable) public struct GoogleCoordinate: Codable {
    public let lat, lng: Double?
}

@_spi(Testable) public struct GoogleLeg: Codable {
    public let distance, duration: GoogleDistance?
    public let endAddress: String?
    public let endLocation: GoogleCoordinate?
    public let startAddress: String?
    public let startLocation: GoogleCoordinate?
    public let steps: [GoogleStep]?

    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endAddress = "end_address"
        case endLocation = "end_location"
        case startAddress = "start_address"
        case startLocation = "start_location"
        case steps
    }
}

@_spi(Testable) public struct GoogleDistance: Codable {
    public let text: String?
    public let value: Double?
}

@_spi(Testable) public struct GoogleStep: Codable {
    public let distance, duration: GoogleDistance?
    public let endLocation: GoogleCoordinate?
    public let htmlInstructions: String?
    public let polyline: GooglePolyline?
    public let startLocation: GoogleCoordinate?
    public let travelMode: GoogleTravelMode?
    public let maneuver: String?
    public let transit_details: GoogleTransitDetails?

    enum CodingKeys: String, CodingKey {
        case distance, duration
        case endLocation = "end_location"
        case htmlInstructions = "html_instructions"
        case polyline
        case startLocation = "start_location"
        case travelMode = "travel_mode"
        case maneuver
        case transit_details
    }
}

@_spi(Testable) public struct GooglePolyline: Codable {
    public let points: String?
}

@_spi(Testable) public enum GoogleTravelMode: String, Codable {
    case driving = "DRIVING"
    case walking = "WALKING"
    case bicycling = "BICYCLING"
    case transit = "TRANSIT"
}

@_spi(Testable) public struct GoogleTransitDetails: Codable {
    public let arrival_stop: GoogleLocation
    public let arrival_time: GoogleTime
    public let departure_stop: GoogleLocation
    public let departure_time: GoogleTime
    public let headsign: String
    public let line: GoogleTransitLine
    public let num_stops: Int
    public let trip_short_name: String
}

@_spi(Testable) public struct GoogleLocation: Codable {
    public let location: GoogleCoordinate
    public let name: String
}

@_spi(Testable) public struct GoogleTime: Codable {
    public let text: String
    public let time_zone: String
    public let value: Int
}

@_spi(Testable) public struct GoogleTransitLine: Codable {
    public let agencies: [GoogleTransitAgency]
    public let short_name: String
    public let vehicle: GoogleTransitVehicle
}

@_spi(Testable) public struct GoogleTransitAgency: Codable {
    public let name: String
    public let url: String
}

@_spi(Testable) public struct GoogleTransitVehicle: Codable {
    public let icon: String
    public let name: String
    public let type: String
}
