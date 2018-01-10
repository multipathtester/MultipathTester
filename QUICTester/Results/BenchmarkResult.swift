//
//  BenchmarkResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
class BenchmarkResult: NSObject, Codable {
    // MARK: Properties
    var connectivities: [Connectivity]
    var startTime: Double
    var testResults: [TestResult]
    enum CodingKeys: String, CodingKey {
        case connectivities
        case startTime
        case testResults
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
    }
    
    // MARK: Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(connectivities, forKey: .connectivities)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(testResults.map(AnyTestResult.init), forKey: .testResults)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectivities = try container.decode([Connectivity].self, forKey: .connectivities)
        startTime = try container.decode(Double.self, forKey: .startTime)
        testResults = try container.decode([AnyTestResult].self, forKey: .testResults).map { $0.base }
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
