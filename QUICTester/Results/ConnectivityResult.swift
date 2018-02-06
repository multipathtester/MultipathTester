//
//  ConnectivityResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class ConnectivityResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.connectivity
    
    // MARK: Collect URL
    static func getCollectURL() -> URL {
        return URL(string: "https://ns387496.ip-176-31-249.eu/connectivity/test/")!
    }
    
    // MARK: Properties
    var durations: [Double]
    
    enum CodingKeys: String, CodingKey {
        case durations
    }

    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("connectivityResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, duration: Double, startTime: Date, waitTime: Double, durations: [Double]) {
        self.durations = durations
        super.init(name: name, proto: proto, success: success, result: result, duration: duration, startTime: startTime, waitTime: waitTime)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superdecoder = try container.superDecoder()
        
        durations = try container.decode([Double].self, forKey: .durations)
        
        try super.init(from: superdecoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(durations, forKey: .durations)
        
        let superencoder = container.superEncoder()
        try super.encode(to: superencoder)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Connectivity"
    }
    
    static func getTestDescription() -> String {
        return "This test checks if a connection can be established and estimate the latency."
    }
    
    func getChartData() -> [ChartEntries] {
        return []
    }
    
    override func resultsToJSONDict() -> [String: Any] {
        var res = super.resultsToJSONDict()
        res["delays"] = durations.map { (d) -> String in
            return String(format: "%.6f", d)
        }
        if !success {
            res["error_msg"] = result
        }
        return res
    }
}
