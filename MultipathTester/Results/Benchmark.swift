//
//  BenchmarkResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import os.log

class Benchmark: NSObject, Codable {
    // MARK: Properties
    var connectivities: [Connectivity]
    var duration: Double
    var locations: [Location]
    var mobile: Bool
    var pingMed: Double  // Stored in milliseconds
    var pingStd: Double  // Stored in milliseconds
    var wifiBytesReceived: UInt32
    var wifiBytesSent: UInt32
    var cellBytesReceived: UInt32
    var cellBytesSent: UInt32
    var multipathService: RunConfig.MultipathServiceType
    var serverName: TestServer
    var startTime: Date
    var testResults: [TestResult]
    
    // This is specific to mobile tests
    var wifiBytesDistance: Double?
    var wifiBytesLostTime: Date?
    var wifiSystemDistance: Double?
    var wifiSystemLostTime: Date?
    var wifiBSSIDSwitches: Int?
    var wifiMultipleSSID: Bool?
    
    // This is specific to mobile tests so far, but can be extended to other tests
    var userInterrupted: Bool
    
    var model: String
    var modelCode: String
    var platform: String
    var platformVersion: String
    var platformVersionCode: String
    var softwareName: String
    var softwareVersion: String
    var timezone: TimeZone
    var uuid: UUID
    
    enum CodingKeys: String, CodingKey {
        case connectivities
        case duration
        case locations
        case mobile
        case pingMed
        case pingStd
        case wifiBytesReceived
        case wifiBytesSent
        case cellBytesReceived
        case cellBytesSent
        case multipathService
        case serverName
        case startTime
        case testResults
        
        case wifiBytesDistance
        case wifiBytesLostTime
        case wifiSystemDistance
        case wifiSystemLostTime
        case wifiBSSIDSwitches
        case wifiMultipleSSID
        
        case userInterrupted

        case model
        case modelCode
        case platform
        case platformVersion
        case platformVersionCode
        case softwareName
        case softwareVersion
        case timezone
        case uuid
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("benchmarks")
    
    // MARK: Initializers
    init(connectivities: [Connectivity], duration: Double, locations: [Location], mobile: Bool, pingMed: Double, pingStd: Double, wifiBytesReceived: UInt32, wifiBytesSent: UInt32, cellBytesReceived: UInt32, cellBytesSent: UInt32, multipathService: RunConfig.MultipathServiceType, serverName: TestServer, startTime: Date, testResults: [TestResult]) {
        // Initilialize stored properties
        self.connectivities = connectivities
        self.duration = duration
        self.locations = locations
        self.mobile = mobile
        self.pingMed = pingMed
        self.pingStd = pingStd
        self.wifiBytesReceived = wifiBytesReceived
        self.wifiBytesSent = wifiBytesSent
        self.cellBytesReceived = cellBytesReceived
        self.cellBytesSent = cellBytesSent
        self.multipathService = multipathService
        self.serverName = serverName
        self.startTime = startTime
        self.testResults = testResults
        
        self.userInterrupted = false
        
        self.model = UIDevice.current.modelName
        self.modelCode = UIDevice.current.internalModelName
        self.platform = "iOS"
        self.platformVersion = UIDevice.current.systemVersion
        self.platformVersionCode = ProcessInfo().operatingSystemVersionString
        self.softwareName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
        let softVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
        self.softwareVersion = softVersion + " (" + buildVersion + ")"
        self.timezone = TimeZone.current
        self.uuid = UUID() // Has to be overriden
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectivities, forKey: .connectivities)
        try container.encode(duration, forKey: .duration)
        try container.encode(locations, forKey: .locations)
        try container.encode(mobile, forKey: .mobile)
        try container.encode(pingMed, forKey: .pingMed)
        try container.encode(pingStd, forKey: .pingStd)
        try container.encode(wifiBytesReceived, forKey: .wifiBytesReceived)
        try container.encode(wifiBytesSent, forKey: .wifiBytesSent)
        try container.encode(cellBytesReceived, forKey: .cellBytesReceived)
        try container.encode(cellBytesSent, forKey: .cellBytesSent)
        try container.encode(multipathService, forKey: .multipathService)
        try container.encode(serverName, forKey: .serverName)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(testResults.map(AnyTestResult.init), forKey: .testResults)
        
        try container.encode(wifiBytesDistance, forKey: .wifiBytesDistance)
        try container.encode(wifiBytesLostTime, forKey: .wifiBytesLostTime)
        try container.encode(wifiSystemDistance, forKey: .wifiSystemDistance)
        try container.encode(wifiSystemLostTime, forKey: .wifiSystemLostTime)
        try container.encode(wifiBSSIDSwitches, forKey: .wifiBSSIDSwitches)
        try container.encode(wifiMultipleSSID, forKey: .wifiMultipleSSID)
        
        try container.encode(userInterrupted, forKey: .userInterrupted)
        
        try container.encode(model, forKey: .model)
        try container.encode(modelCode, forKey: .modelCode)
        try container.encode(platform, forKey: .platform)
        try container.encode(platformVersion, forKey: .platformVersion)
        try container.encode(platformVersionCode, forKey: .platformVersionCode)
        try container.encode(softwareName, forKey: .softwareName)
        try container.encode(softwareVersion, forKey: .softwareVersion)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(uuid, forKey: .uuid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectivities = try container.decode([Connectivity].self, forKey: .connectivities)
        duration = try container.decode(Double.self, forKey: .duration)
        locations = try container.decode([Location].self, forKey: .locations)
        mobile = try container.decode(Bool.self, forKey: .mobile)
        pingMed = try container.decode(Double.self, forKey: .pingMed)
        pingStd = try container.decode(Double.self, forKey: .pingStd)
        wifiBytesReceived = try container.decode(UInt32.self, forKey: .wifiBytesReceived)
        wifiBytesSent = try container.decode(UInt32.self, forKey: .wifiBytesSent)
        cellBytesReceived = try container.decode(UInt32.self, forKey: .cellBytesReceived)
        cellBytesSent = try container.decode(UInt32.self, forKey: .cellBytesSent)
        multipathService = try container.decode(RunConfig.MultipathServiceType.self, forKey: .multipathService)
        serverName = try container.decode(TestServer.self, forKey: .serverName)
        startTime = try container.decode(Date.self, forKey: .startTime)
        testResults = try container.decode([AnyTestResult].self, forKey: .testResults).map { $0.base }
        
        wifiBytesDistance = try container.decode(Double?.self, forKey: .wifiBytesDistance)
        wifiBytesLostTime = try container.decode(Date?.self, forKey: .wifiBytesLostTime)
        wifiSystemDistance = try container.decode(Double?.self, forKey: .wifiSystemDistance)
        wifiSystemLostTime = try container.decode(Date?.self, forKey: .wifiSystemLostTime)
        wifiBSSIDSwitches = try container.decode(Int?.self, forKey: .wifiBSSIDSwitches)
        wifiMultipleSSID = try container.decode(Bool?.self, forKey: .wifiMultipleSSID)
        
        do {
            userInterrupted = try container.decode(Bool.self, forKey: .userInterrupted)
        } catch {
            userInterrupted = false
        }
        
        model = try container.decode(String.self, forKey: .model)
        modelCode = try container.decode(String.self, forKey: .modelCode)
        platform = try container.decode(String.self, forKey: .platform)
        platformVersion = try container.decode(String.self, forKey: .platformVersion)
        platformVersionCode = try container.decode(String.self, forKey: .platformVersionCode)
        softwareName = try container.decode(String.self, forKey: .softwareName)
        softwareVersion = try container.decode(String.self, forKey: .softwareVersion)
        timezone = try container.decode(TimeZone.self, forKey: .timezone)
        uuid = try container.decode(UUID.self, forKey: .uuid)
    }
    
    // MARK: JSON serialization to collect server
    func toJSONDict() -> [String: Any] {
        var locationsList = [[String: Any]]()
        for location in locations {
            locationsList.append(location.toJSONDict())
        }

        var json: [String: Any] = [
            "locations": locationsList,
            "start_time": Utils.getDateFormatter().string(from: startTime),
            "duration": String.init(format: "%.6f", duration),
            "tz": timezone.identifier,
            "ping_med": String.init(format: "%.3f", pingMed),
            "ping_std": String.init(format: "%.3f", pingStd),
            "wifi_bytes_received": wifiBytesReceived,
            "wifi_bytes_sent": wifiBytesSent,
            "cell_bytes_received": cellBytesReceived,
            "cell_bytes_sent": cellBytesSent,
            "multipath_service": multipathService.rawValue,
            "server_name": serverName.rawValue,
            "platform": platform,
            "platform_version_name": platformVersion,
            "platform_version_code": platformVersionCode,
            "device_uuid": UIDevice.current.identifierForVendor!.uuidString,
            "device_model": model,
            "device_model_code": modelCode,
            "software_name": softwareName,
            "software_version": softwareVersion,
        ]
        
        // If absent, per default it is NOT user interrupted
        if userInterrupted {
            json["user_interrupted"] = true
        }
        
        if mobile {
            json["mobile"] = [
                "wifi_bytes_distance": wifiBytesDistance!,
                "wifi_bytes_lost_time": Utils.getDateFormatter().string(from: wifiBytesLostTime!),
                "wifi_system_distance": wifiSystemDistance!,
                "wifi_system_lost_time": Utils.getDateFormatter().string(from: wifiSystemLostTime!),
                "wifi_bssid_switches": wifiBSSIDSwitches!,
                "wifi_multiple_ssid": wifiMultipleSSID!,
            ]
        }
        
        return json
    }
    
    // MARK: Save
    func save() {
        var benchmarks: [Benchmark] = [Benchmark]()
        if let benchmarksOk = Benchmark.loadBenchmarks() {
            benchmarks = benchmarksOk
        }
        // Add the new result at the top of the list
        benchmarks = [self] + benchmarks
        // And save the results
        do {
            let data = try PropertyListEncoder().encode(benchmarks)
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(data, toFile: Benchmark.ArchiveURL.path)
            if isSuccessfulSave {
                os_log("Benchmarks successfully saved.", log: OSLog.default, type: .debug)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateResult"), object: nil)
            } else {
                os_log("Failed to save benchmarks...", log: OSLog.default, type: .error)
            }
        } catch {
            os_log("Failed to save benchmarks...", log: OSLog.default, type: .error)
        }
    }
    
    // MARK: Utils
    static func loadBenchmarks() -> [Benchmark]? {
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: Benchmark.ArchiveURL.path)
        if let data = unarchivedData as? Data {
            do {
                let decoder = PropertyListDecoder()
                let benchmarks = try decoder.decode([Benchmark].self, from: data)
                return benchmarks
            } catch {
                print("Retrieve Failed: \(error)")
                return nil
            }
        }
            // Work with NSCoding
        else if let benchmarks = unarchivedData as? [Benchmark] {
            return benchmarks
        } else {
            return nil
        }
    }
}
