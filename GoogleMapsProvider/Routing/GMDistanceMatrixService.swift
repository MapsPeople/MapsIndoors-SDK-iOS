import Foundation
import MapsIndoors
import MapsIndoorsCore


class GMDistanceMatrixService: MPExternalDistanceMatrixService {
    
    private let maxOrigins = 25
    
    private let maxDestinations = 25
    
    private let maxTotalElements = 100
    
    private let apiKey: String
    
    let baseUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?"
    
    var language = "en"
    
    var units: GoogleRoutingUnits = .metric
    
    var travelMode: GoogleTravelModes = .driving
    var transitMode: GoogleTransitModes = .bus
    var avoids = [GoogleAvoids]()
    var trafficModel: GoogleTrafficModels = .bestGuess
    var routingPreference: GoogleRoutingPreference = .lessWalking
    
    required init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func query(origins: [CLLocationCoordinate2D],
               destinations: [CLLocationCoordinate2D],
               config: MPDirectionsConfig) async throws -> MPDistanceMatrixResult? {
        
        let url = buildUrl(origins: origins, destinations: destinations, config: MPDirectionsConfig(origin: MPPoint(), destination: MPPoint()))
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let deserializedResponse = try JSONDecoder().decode(GoogleDistanceMatrix.self, from: data)

        return deserializedResponse.asMPMatrix
    }
    
    private func buildUrl(origins: [CLLocationCoordinate2D], destinations: [CLLocationCoordinate2D], config: MPDirectionsConfig) -> URL {
        applyConfig(config: config)
        
        var components = URLComponents(string: baseUrl)!
        var queryItems = [URLQueryItem]()
        
        var originsString = ""
        for origin in origins {
            originsString.append(String(origin.latitude) + "," + String(origin.longitude) + "|")
        }
        originsString.removeLast()
        queryItems.append(URLQueryItem(name: "origins", value: originsString))
        
        var destinationsString = ""
        for destination in destinations {
            destinationsString.append(String(destination.latitude) + "," + String(destination.longitude) + "|")
        }
        destinationsString.removeLast()
        queryItems.append(URLQueryItem(name: "destinations", value: destinationsString))

        queryItems.append(URLQueryItem(name: "language", value: language))
        
        switch units {
        case .metric:
            queryItems.append(URLQueryItem(name: "units", value: "metric"))
        case .imperial:
            queryItems.append(URLQueryItem(name: "units", value: "imperial"))
        }

        if let arrivalTime = config.arrival {
            queryItems.append(URLQueryItem(name: "arrival_time", value: String(Int(arrivalTime.timeIntervalSince1970)+10)))
        } else if let departureTime = config.departure {
            queryItems.append(URLQueryItem(name: "departure_time", value: String(Int(departureTime.timeIntervalSince1970.rounded())+10)))
        } else {
            queryItems.append(URLQueryItem(name: "departure_time", value: "now"))
        }
        
        switch travelMode {
        case .driving:
            queryItems.append(URLQueryItem(name: "mode", value: "driving"))
        case .walking:
            queryItems.append(URLQueryItem(name: "mode", value: "walking"))
        case .bicycling:
            queryItems.append(URLQueryItem(name: "mode", value: "bicycling"))
        case .transit:
            queryItems.append(URLQueryItem(name: "mode", value: "transit"))
            switch transitMode {
            case .bus:
                queryItems.append(URLQueryItem(name: "transit_mode", value: "bus"))
            case .subway:
                queryItems.append(URLQueryItem(name: "transit_mode", value: "subway"))
            case .train:
                queryItems.append(URLQueryItem(name: "transit_mode", value: "train"))
            case .tram:
                queryItems.append(URLQueryItem(name: "transit_mode", value: "tram"))
            case .rail:
                queryItems.append(URLQueryItem(name: "transit_mode", value: "rail"))
            }
        }
        
        if avoids.isEmpty == false {
            var avoidsString = ""
            for avoid in avoids {
                switch avoid {
                case .ferries:
                    avoidsString.append("ferries|")
                case .highways:
                    avoidsString.append("highways|")
                case .tolls:
                    avoidsString.append("tolls|")
                case .indoor:
                    avoidsString.append("indoor|")
                }
                avoidsString.removeLast()
                queryItems.append(URLQueryItem(name: "avoid", value: avoidsString))
            }
        }
            
        switch trafficModel {
        case .bestGuess:
            queryItems.append(URLQueryItem(name: "traffic_model", value: "best_guess"))
        case .pessimistic:
            queryItems.append(URLQueryItem(name: "traffic_model", value: "pessimistic"))
        case .optimistic:
            queryItems.append(URLQueryItem(name: "traffic_model", value: "optimistic"))
        }
        
        switch routingPreference {
        case .lessWalking:
            queryItems.append(URLQueryItem(name: "transit_routing_preference", value: "less_walking"))
        case .fewerTransfers:
            queryItems.append(URLQueryItem(name: "transit_routing_preference", value: "fewer_transfers"))
        }
        
        queryItems.append(URLQueryItem(name: "key", value: self.apiKey))
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    private func applyConfig(config: MPDirectionsConfig) {
        switch config.travelMode {
        case .driving:
            self.travelMode = .driving
        case .walking:
            self.travelMode = .walking
        case .bicycling:
            self.travelMode = .bicycling
        case .transit:
            self.travelMode = .transit
        default:
            self.travelMode = .driving
        }
        
        self.avoids.removeAll()
        for configAvoid in config.avoidTypes ?? [] {
            switch configAvoid.typeString {
            case "ferries":
                self.avoids.append(.ferries)
            case "highways":
                self.avoids.append(.highways)
            case "tolls":
                self.avoids.append(.tolls)
            case "indoor":
                self.avoids.append(.indoor)
            default:
                continue
            }
        }
    }
    
    func pruneDistanceMatrixDimensions(origins: [MPPoint],
                                       destinations: [MPPoint]) -> ([MPPoint], [MPPoint]) {
        var resultingOrigins = origins
        var resultingDestinations = destinations
        
        // Prune origins
        if origins.count > maxOrigins {
            let destinationsAvg = MPPoint(coordinate:
                                            CLLocationCoordinate2D(latitude: (destinations.map({$0.latitude}).reduce(0.0, +)) / Double(destinations.count),
                                                                   longitude: (destinations.map({$0.longitude}).reduce(0.0, +)) / Double(destinations.count)))
            
            var originsDistanceTuple = [(MPPoint, Double)]()
            for origin in origins {
                let distance = destinationsAvg.distanceTo(origin)
                originsDistanceTuple.append((origin, distance))
            }
            
            let sortedByDistance = originsDistanceTuple.sorted { a, b in a.1 < b.1 }.map({$0.0})
            resultingOrigins = sortedByDistance.dropLast(abs(maxOrigins - sortedByDistance.count))
        }
        
        // Prune destinations
        if destinations.count > maxDestinations {
            let originsAvg = MPPoint(coordinate:
                                        CLLocationCoordinate2D(latitude: (origins.map({$0.latitude}).reduce(0.0, +)) / Double(origins.count),
                                                                        longitude: (origins.map({$0.longitude}).reduce(0.0, +)) / Double(origins.count)))
            
            var distinationsDistanceTuple = [(MPPoint, Double)]()
            for destination in destinations {
                let distance = originsAvg.distanceTo(destination)
                distinationsDistanceTuple.append((destination, distance))
            }
            
            let sortedByDistance = distinationsDistanceTuple.sorted { a, b in a.1 < b.1 }.map({$0.0})
            resultingDestinations = sortedByDistance.dropLast(abs(maxDestinations - sortedByDistance.count))
        }
        
        // While the total size exceeds the max, we drop the last entry for the largest dimension
        while resultingOrigins.count * resultingDestinations.count >= maxTotalElements {
            if resultingOrigins.count > resultingDestinations.count {
                resultingOrigins = resultingOrigins.dropLast()
            } else {
                resultingDestinations = resultingDestinations.dropLast()
            }
        }
        
        return (resultingOrigins, resultingDestinations)
    }
    
}
