//
//  QUICPerfResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class PerfResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.perf
    
    // MARK: Properties
    var totalRetrans: UInt64
    var totalSent: UInt64
    var intervals: [IntervalData]
    var cwins: [String: [CWinData]]
    
    enum CodingKeys: String, CodingKey {
        case totalRetrans
        case totalSent
        case intervals
        case cwins
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("perfResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, runTime: Double, totalRetrans: UInt64, totalSent: UInt64, intervals: [IntervalData], cwins:[String: [CWinData]]) {
        self.totalRetrans = totalRetrans
        self.totalSent = totalSent
        self.intervals = intervals
        self.cwins = cwins
        
        super.init(name: name, proto: proto, success: success, result: result, runTime: runTime)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superdecoder = try container.superDecoder()
        
        totalRetrans = try container.decode(UInt64.self, forKey: .totalRetrans)
        totalSent = try container.decode(UInt64.self, forKey: .totalSent)
        intervals = try container.decode([IntervalData].self, forKey: .intervals)
        cwins = try container.decode([String: [CWinData]].self, forKey: .cwins)
        
        try super.init(from: superdecoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalRetrans, forKey: .totalRetrans)
        try container.encode(totalSent, forKey: .totalSent)
        try container.encode(intervals, forKey: .intervals)
        try container.encode(cwins, forKey: .cwins)
        
        let superencoder = container.superEncoder()
        try super.encode(to: superencoder)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Perf"
    }
    
    static func getTestDescription() -> String {
        return "This test evaluates the bandwidth the protocol can leverage"
    }
}
