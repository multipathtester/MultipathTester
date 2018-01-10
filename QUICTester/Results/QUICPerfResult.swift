//
//  QUICPerfResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICPerfResult: NSObject, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.quicPerf
    
    // MARK: Properties
    var name: String
    var runTime: Double
    var totalRetrans: UInt64
    var totalSent: UInt64
    var intervals: [IntervalData]
    var cwins: [String: [CWinData]]
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicPerfResults")
    
    // MARK: Initializers
    init(name: String, runTime: Double, totalRetrans: UInt64, totalSent: UInt64, intervals: [IntervalData], cwins:[String: [CWinData]]) {
        self.name = name
        self.runTime = runTime
        self.totalRetrans = totalRetrans
        self.totalSent = totalSent
        self.intervals = intervals
        self.cwins = cwins
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        if runTime < 0.0 {
            return "Failed"
        }
        return "Transferred " + String(totalSent) + " in " + String(runTime) + "s"
    }
}
