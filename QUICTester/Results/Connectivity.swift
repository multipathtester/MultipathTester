//
//  Connectivity.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/10/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class Connectivity: Codable {
    enum NetworkType: String, Codable {
        case Unknown
        case None // Used internally to denote no connection
        case WiFi
        case Cellular
    }
    
    // MARK: Properties
    var networkType: NetworkType
    // WLAN SSID for WiFi, operator name for cellular
    var networkName: String
    // Timestamp at which connectivity was detected
    var timestamp: Double
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("connectivities")
    
    // MARK: Initializers
    init(networkType: NetworkType, networkName: String, timestamp: Double) {
        // Initilialize stored properties
        self.networkType = networkType
        self.networkName = networkName
        self.timestamp = timestamp
    }
}
