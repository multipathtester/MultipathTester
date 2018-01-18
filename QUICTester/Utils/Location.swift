//
//  Location.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/17/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class Location: Codable {
    // MARK: Properties
    var lon: Double
    var lat: Double
    var timestamp: Date
    var accuracy: Double
    var altitude: Double
    var speed: Double  // Negative speed = WiFi location
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("locations")
    
    // MARK: Initializers
    init(lon: Double, lat: Double, timestamp: Date, accuracy: Double, altitude: Double, speed: Double) {
        self.lon = lon
        self.lat = lat
        self.timestamp = timestamp
        self.accuracy = accuracy
        self.altitude = altitude
        self.speed = speed
    }
    
    func getDescription() -> String {
        let latSecondsRaw = Int(round(abs(lat * 3600)))
        let latDegrees = latSecondsRaw / 3600;
        let latSeconds = latSecondsRaw % 3600;
        let latMinutes = Double(latSeconds) / 60.0;
        
        let lonSecondsRaw = Int(round(abs(lon * 3600)))
        let lonDegrees = lonSecondsRaw / 3600;
        let lonSeconds = lonSecondsRaw % 3600;
        let lonMinutes = Double(lonSeconds) / 60.0;
        
        let latDirection = (lat >= 0) ? "N" : "S"
        let lonDirection = (lon >= 0) ? "E" : "W"
        
        return String.init(format: latDirection + " %d° %.3f' " + lonDirection + " %d° %.3f' (+/- %.0fm)", latDegrees, latMinutes, lonDegrees, lonMinutes, accuracy)
    }
    
    // MARK: JSON serialization to collect server
    func toJSONDict() -> [String: Any] {
        return [
            "lon": lon,
            "lat": lat,
            "timestamp": Utils.getDateFormatter().string(from: timestamp),
            "acc": String.init(format: "%.1f", accuracy),
            "alt": String.init(format: "%.1f", altitude),
            "speed": String.init(format: "%.3f", speed),
        ]
    }
}
