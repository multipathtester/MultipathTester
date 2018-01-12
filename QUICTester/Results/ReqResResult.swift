//
//  QUICReqResResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class ReqResResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.reqRes
    
    // MARK: Properties
    var missed: Int64
    var maxDelay: Int64
    var delays: [Int64]
    
    enum CodingKeys: String, CodingKey {
        case missed
        case maxDelay
        case delays
    }

    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("reqResResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, runTime: Double, missed: Int64, maxDelay: Int64, delays: [Int64]) {
        self.missed = missed
        self.maxDelay = maxDelay
        self.delays = delays
        
        super.init(name: name, proto: proto, success: success, result: result, runTime: runTime)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superdecoder = try container.superDecoder()
        
        missed = try container.decode(Int64.self, forKey: .missed)
        maxDelay = try container.decode(Int64.self, forKey: .maxDelay)
        delays = try container.decode([Int64].self, forKey: .delays)
        
        try super.init(from: superdecoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(missed, forKey: .missed)
        try container.encode(maxDelay, forKey: .maxDelay)
        try container.encode(delays, forKey: .delays)
        
        let superencoder = container.superEncoder()
        try super.encode(to: superencoder)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Request/Response"
    }
    
    static func getTestDescription() -> String {
        return "This test generates small requests and computes the time to receive small responses from the server"
    }
    
    func getChartData() -> [ChartEntries] {
        let values = delays.sorted().enumerated().map { (arg) -> ChartDataEntry in
            let (index, d) = arg
            return ChartDataEntry(x: 100.0 * Double(index) / Double(delays.count), y: Double(d))
        }
        return [LineChartEntries(xLabel: "CDF", yLabel: "Time (ms)", data: values, dataLabel: "Delays", xValueFormatter: nil)]
    }
}
