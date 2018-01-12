//
//  BenchmarkResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

public extension UIDevice {
    
    var internalModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "AppleTV6,2":                              return "Apple TV 4K"
        case "AudioAccessory1,1":                       return "HomePod"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

class BenchmarkResult: NSObject, Codable {
    // MARK: Properties
    var connectivities: [Connectivity]
    var startTime: Double
    var testResults: [TestResult]
    
    var model: String
    var modelCode: String
    var platform: String
    var platformVersion: String
    var softwareName: String
    var softwareVersion: String
    var timezone: TimeZone
    
    enum CodingKeys: String, CodingKey {
        case connectivities
        case startTime
        case testResults

        case model
        case modelCode
        case platform
        case platformVersion
        case softwareName
        case softwareVersion
        case timezone
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("benchmarkTests")
    
    // MARK: Initializers
    init(connectivities: [Connectivity], startTime: Double, testResults: [TestResult]) {
        // Initilialize stored properties
        self.connectivities = connectivities
        self.startTime = startTime
        self.testResults = testResults
        
        self.model = UIDevice.current.modelName
        self.modelCode = UIDevice.current.internalModelName
        self.platform = "iOS"
        self.platformVersion = UIDevice.current.systemVersion
        self.softwareName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
        self.softwareVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
        self.timezone = TimeZone.current
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectivities, forKey: .connectivities)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(testResults.map(AnyTestResult.init), forKey: .testResults)
        
        try container.encode(model, forKey: .model)
        try container.encode(modelCode, forKey: .modelCode)
        try container.encode(platform, forKey: .platform)
        try container.encode(platformVersion, forKey: .platformVersion)
        try container.encode(softwareName, forKey: .softwareName)
        try container.encode(softwareVersion, forKey: .softwareVersion)
        try container.encode(timezone, forKey: .timezone)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectivities = try container.decode([Connectivity].self, forKey: .connectivities)
        startTime = try container.decode(Double.self, forKey: .startTime)
        testResults = try container.decode([AnyTestResult].self, forKey: .testResults).map { $0.base }
        
        model = try container.decode(String.self, forKey: .model)
        modelCode = try container.decode(String.self, forKey: .modelCode)
        platform = try container.decode(String.self, forKey: .platform)
        platformVersion = try container.decode(String.self, forKey: .platformVersion)
        softwareName = try container.decode(String.self, forKey: .softwareName)
        softwareVersion = try container.decode(String.self, forKey: .softwareVersion)
        timezone = try container.decode(TimeZone.self, forKey: .timezone)
    }
    
    // MARK: Utils
    static func loadBenchmarkResults() -> [BenchmarkResult]? {
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: BenchmarkResult.ArchiveURL.path)
        if let data = unarchivedData as? Data {
            do {
                let decoder = PropertyListDecoder()
                let benchmarkResults = try decoder.decode([BenchmarkResult].self, from: data)
                return benchmarkResults
            } catch {
                print("Retrieve Failed")
                return nil
            }
        }
            // Work with NSCoding
        else if let benchmarkResults = unarchivedData as? [BenchmarkResult] {
            return benchmarkResults
        } else {
            return nil
        }
    }
}
