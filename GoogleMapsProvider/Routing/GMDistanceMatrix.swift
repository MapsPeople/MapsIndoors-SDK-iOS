import Foundation
import MapsIndoors
import MapsIndoorsCore

class GoogleDistanceMatrix: Codable {
    let destinationAddresses, originAddresses: [String]?
    let rows: [GoogleMatrixRow]?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case destinationAddresses = "destination_addresses"
        case originAddresses = "origin_addresses"
        case rows, status
    }

    init(destinationAddresses: [String]?, originAddresses: [String]?, rows: [GoogleMatrixRow]?, status: String?) {
        self.destinationAddresses = destinationAddresses
        self.originAddresses = originAddresses
        self.rows = rows
        self.status = status
    }
    
    var asMPMatrix: MPDistanceMatrixResult {
        var mpMatrix = MPDistanceMatrixResult()
        guard self.rows != nil else { return mpMatrix }
        
        mpMatrix.origin_addresses = self.originAddresses
        mpMatrix.destination_addresses = self.destinationAddresses
        mpMatrix.status = self.status
        mpMatrix.rows = [MPDistanceMatrixRows]()
        
        for row in self.rows! {
            var mpRow = MPDistanceMatrixRows()
            mpRow.elements = [MPDistanceMatrixElements]()
            for elem in row.elements! {
                var mpElem = MPDistanceMatrixElements()
                mpElem.duration = MPRoutePropertyInternal(withValue: NSNumber(value: elem.duration?.value ?? 0), withText: elem.duration?.text)
                mpElem.distance = MPRoutePropertyInternal(withValue: NSNumber(value: elem.distance?.value ?? 0), withText: elem.distance?.text)
                mpElem.status = elem.status
                mpRow.elements?.append(mpElem)
            }
            mpMatrix.rows?.append(mpRow)
        }
        
        return mpMatrix
    }
    
}

class GoogleMatrixRow: Codable {
    let elements: [GoogleMatrixElement]?

    init(elements: [GoogleMatrixElement]?) {
        self.elements = elements
    }
}

class GoogleMatrixElement: Codable {
    let distance, duration: GoogleMatrixDistance?
    let status: String?

    init(distance: GoogleMatrixDistance?, duration: GoogleMatrixDistance?, status: String?) {
        self.distance = distance
        self.duration = duration
        self.status = status
    }
}

class GoogleMatrixDistance: Codable {
    let text: String?
    let value: Double?

    init(text: String?, value: Double?) {
        self.text = text
        self.value = value
    }
}
