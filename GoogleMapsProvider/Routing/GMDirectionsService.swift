import Foundation
import MapsIndoorsCore

enum GoogleTravelModes {
    case driving
    case walking
    case bicycling
    case transit
}

enum GoogleTransitModes {
    case bus
    case subway
    case train
    case tram
    case rail
}

enum GoogleAvoids {
    case tolls
    case highways
    case ferries
    case indoor
}

enum GoogleTrafficModels {
    case bestGuess
    case pessimistic
    case optimistic
}

enum GoogleRoutingPreference {
    case lessWalking
    case fewerTransfers
}

enum GoogleRoutingUnits {
    case metric
    case imperial
}

class GMDirectionsService: MPExternalDirectionsService {
    
    private let apiKey: String
    
    let baseUrl = "https://maps.googleapis.com/maps/api/directions/json?"
    
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
    
    func query(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, config: MPDirectionsConfig) async throws -> MPRoute? {
        let url = buildUrl(origin: origin, destination: destination, config: config)
        let (data, _) = try await URLSession.shared.data(from: url)
        let deserializedResponse = try JSONDecoder().decode(GoogleRouteResponse.self, from: data)

        guard let mpRoute = deserializedResponse.routes.first?.asMPRoute else {
            return nil
        }

        return mpRoute
    }
    
    private func buildUrl(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, config: MPDirectionsConfig) -> URL {
        applyConfig(config: config)
        
        var components = URLComponents(string: baseUrl)!
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "origin", value: String(origin.latitude)+","+String(origin.longitude)))
        queryItems.append(URLQueryItem(name: "destination", value: String(destination.latitude)+","+String(destination.longitude)))
        
        queryItems.append(URLQueryItem(name: "language", value: config.language ?? language))
        
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
    
}
