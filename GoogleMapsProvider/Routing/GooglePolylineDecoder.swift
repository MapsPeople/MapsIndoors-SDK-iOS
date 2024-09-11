// Credit to: https://github.com/mwoollard/SwiftGooglePolyline/blob/05af7b10b2e821c69778f21a9cbfca58bd4bf4ab/SwiftGooglePolyline/String%2BGooglePolyline.swift

import CoreLocation

extension String {
    func decodePolylineString() -> [CLLocationCoordinate2D] {
        return [CLLocationCoordinate2D](try! PolylineSequence(self))
    }
}

fileprivate struct PolylineIterator: IteratorProtocol {
    typealias Element = CLLocationCoordinate2D
    
    struct Coordinate {
        private var value = 0.0
        mutating func nextValue(
            polyline: String.UnicodeScalarView,
            index: inout String.UnicodeScalarView.Index) -> Double? {

            if index >= polyline.endIndex {
                return nil
            }

            var byte: Int
            var res = 0
            var shift = 0

            repeat {
                byte = Int(polyline[index].value) - 63
                if !(0..<64 ~= byte) {
                    return nil
                }
                res |= (byte & 0x1F) << shift
                shift += 5
                index = polyline.index(index, offsetBy: 1)
            } while (byte >= 0x20 && index < polyline.endIndex)

            self.value += Double(((res % 2) == 1) ? ~(res >> 1) : res >> 1)

            return self.value * 1E-5
        }
    }
  
    private var polylineUnicodeChars: String.UnicodeScalarView
    private var current: String.UnicodeScalarView.Index
    private var latitude = Coordinate()
    private var longitude = Coordinate()
  
    init(_ polyline: String) {
        self.polylineUnicodeChars = polyline.unicodeScalars
        self.current = self.polylineUnicodeChars.startIndex
    }
  
    mutating func next() -> Element? {
        guard
            let lat = self.latitude.nextValue(polyline: self.polylineUnicodeChars, index: &self.current),
            let lng = self.longitude.nextValue(polyline: self.polylineUnicodeChars, index: &self.current)
        else {
            return nil
        }
        return Element(latitude: lat, longitude: lng)
    }
}

fileprivate struct PolylineSequence: Sequence {
    private let encodedPolyline: String

    init(_ encodedPolyline: String) throws {
        var index = encodedPolyline.startIndex
        encodedPolyline.unicodeScalars.forEach {_ in
            index = encodedPolyline.index(index, offsetBy: 1)
        }
        self.encodedPolyline = encodedPolyline
    }

    func makeIterator() -> PolylineIterator {
        PolylineIterator(self.encodedPolyline)
    }
}
