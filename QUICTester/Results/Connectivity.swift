//
//  Connectivity.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/10/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import CoreTelephony
import UIKit
import SystemConfiguration.CaptiveNetwork

class Connectivity: Codable {
    enum NetworkType: String, Codable {
        case Unknown
        case None // Used internally to denote no connection
        case WiFi
        case Cellular
        case WiFiCellular
    }
    
    // MARK: Properties
    var networkType: NetworkType
    // Timestamp at which connectivity was detected
    var timestamp: Date
    
    // Only if WiFi
    // WLAN SSID for WiFi
    var wifiNetworkName: String?
    var wifiBSSID: String?
    var wifiAddresses: [String]?
    
    // Only if cellular
    // operator name for cellular
    var cellularNetworkName: String?
    var cellularCode: String?
    var cellularCodeDescription: String?
    var telephonyNetworkSimOperator: String?
    var telephonyNetworkSimCountry: String?
    var cellularAddresses: [String]?
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("connectivities")
    
    // MARK: Initializers
    init(networkType: NetworkType, timestamp: Date) {
        // Initilialize stored properties
        self.networkType = networkType
        self.timestamp = timestamp
    }
    
    // MARK: Helpers
    func getNetworkTypeDescription() -> String {
        switch networkType {
        case .Unknown:
            return "Unknown connectivity"
        case .None:
            return "No connectivity"
        case .WiFi:
            return "WiFi"
        case .Cellular:
            return cellularCodeDescription ?? "No cellular code"
        case .WiFiCellular:
            return "WiFi + " + (cellularCodeDescription ?? "No cellular code")
        }
    }
    
    func getShortNetworkType() -> String {
        switch networkType {
        case .Unknown:
            return "unknown"
        case .None:
            return "none"
        case .WiFi:
            return "wifi"
        case .Cellular:
            return "cell"
        case .WiFiCellular:
            return "wificell"
        }
    }
    
    // MARK: JSON serialization to collect server
    func toJSONDict(benchmarkUUID: String) -> [String: Any] {
        var connDict: [String: Any] = [
            "benchmark_uuid": benchmarkUUID,
            "network_type": getShortNetworkType(),
            "timestamp": Utils.getDateFormatter().string(from: timestamp),
        ]
        
        if networkType == .WiFi || networkType == .WiFiCellular {
            var wifiIPs = [[String: Any]]()
            for wa in wifiAddresses ?? [] {
                wifiIPs.append(["ip": wa])
            }
            connDict["wifi_ips"] = wifiIPs
            connDict["wifi_network_name"] = wifiNetworkName
            connDict["wifi_bssid"] = wifiBSSID
        }
        
        if networkType == .Cellular || networkType == .WiFiCellular {
            var cellIPs = [[String: Any]]()
            for ca in cellularAddresses ?? [] {
                cellIPs.append(["ip": ca])
            }
            connDict["cell_ips"] = cellIPs
            connDict["cell_network_name"] = cellularNetworkName
            connDict["cell_code"] = cellularCode
            connDict["cell_code_description"] = cellularCodeDescription
            connDict["cell_iso_country_code"] = telephonyNetworkSimCountry
            connDict["cell_operator_code"] = telephonyNetworkSimOperator
        }
        
        return connDict
    }
    
    // MARK: Static
    // From https://stackoverflow.com/a/39555503
    static func getWiFiSSID() -> (String?, String?) {
        let interfaces = CNCopySupportedInterfaces()
        if interfaces == nil {
            return (nil, nil)
        }
        
        let interfacesArray = interfaces as! [String]
        if interfacesArray.count <= 0 {
            return (nil, nil)
        }
        
        let interfaceName = interfacesArray[0] as String
        let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName as CFString)
        if unsafeInterfaceData == nil {
            return (nil, nil)
        }
        
        let interfaceData = unsafeInterfaceData as! Dictionary <String,AnyObject>
        
        return (interfaceData["SSID"] as? String, interfaceData["BSSID"] as? String)
    }
    
    static func getCellularCodeDescriptionFor(_ cellularCode: String?) -> String? {
        if cellularCode == nil {
            return nil
        }
        let dict = [
            CTRadioAccessTechnologyGPRS:            "GPRS (2G)",
            CTRadioAccessTechnologyEdge:            "EDGE (2G)",
            CTRadioAccessTechnologyWCDMA:           "UMTS (3G)",
            CTRadioAccessTechnologyCDMA1x:          "CDMA (2G)",
            CTRadioAccessTechnologyCDMAEVDORev0:    "EVDO0 (2G)",
            CTRadioAccessTechnologyCDMAEVDORevA:    "EVDOA (2G)",
            CTRadioAccessTechnologyHSDPA:           "HSDPA (3G)",
            CTRadioAccessTechnologyHSUPA:           "HSUPA (3G)",
            CTRadioAccessTechnologyCDMAEVDORevB:    "EVDOB (2G)",
            CTRadioAccessTechnologyLTE:             "LTE (4G)",
            CTRadioAccessTechnologyeHRPD:           "HRPD (2G)",
        ]
        return dict[cellularCode!]
    }
    
    static func getCurrentConnectivity(reachabilityStatus: NetworkStatus) -> Connectivity {
        let conn = Connectivity(networkType: .None, timestamp: Date())
        if reachabilityStatus == ReachableViaWiFi {
            conn.networkType = .WiFi
            let (netName, bssid) = Connectivity.getWiFiSSID()
            conn.wifiNetworkName = netName ?? "None"
            conn.wifiBSSID = bssid ?? "None"
            conn.wifiAddresses = UIDevice.current.wifiAddresses
            // Good, but now distinguish the case between WiFi and WiFi + Cellular
            if UIDevice.current.hasCellularConnectivity {
                conn.networkType = .WiFiCellular
                let netInfo = CTTelephonyNetworkInfo.init()
                let carrier = netInfo.subscriberCellularProvider
                conn.cellularNetworkName = carrier?.carrierName ?? "None"
                conn.telephonyNetworkSimCountry = carrier?.isoCountryCode
                conn.telephonyNetworkSimOperator = String.init(format: "%@-%@", carrier?.mobileCountryCode ?? "None", carrier?.mobileNetworkCode ?? "None")
                conn.cellularCode = netInfo.currentRadioAccessTechnology ?? "None"
                conn.cellularCodeDescription = Connectivity.getCellularCodeDescriptionFor(conn.cellularCode) ?? "None"
                conn.cellularAddresses = UIDevice.current.cellularAddresses
            }
            // Only WiFi
            return conn
        } else if reachabilityStatus == ReachableViaWWAN {
            conn.networkType = .Cellular
            let netInfo = CTTelephonyNetworkInfo.init()
            let carrier = netInfo.subscriberCellularProvider
            conn.cellularNetworkName = carrier?.carrierName ?? "None"
            conn.telephonyNetworkSimCountry = carrier?.isoCountryCode
            conn.telephonyNetworkSimOperator = String.init(format: "%@-%@", carrier?.mobileCountryCode ?? "None", carrier?.mobileNetworkCode ?? "None")
            conn.cellularCode = netInfo.currentRadioAccessTechnology ?? "None"
            conn.cellularCodeDescription = Connectivity.getCellularCodeDescriptionFor(conn.cellularCode) ?? "None"
            conn.cellularAddresses = UIDevice.current.cellularAddresses
        }
        return conn
    }
}
