//
//  QUICReqResResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICReqResResult: NSObject, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.quicReqRes
    
    // MARK: Properties
    var name: String
    var runTime: Double
    var missed: Int64
    var maxDelay: Int64
    var delays: [Int64]

    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicReqResResults")
    
    // MARK: Initializers
    init(name: String, runTime: Double, missed: Int64, maxDelay: Int64, delays: [Int64]) {
        self.name = name
        self.runTime = runTime
        self.missed = missed
        self.maxDelay = maxDelay
        self.delays = delays
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        if runTime < 0.0 {
            return "Failed"
        }
        return "Maximum delay of " + String(maxDelay) + " ms, " + String(missed) + " missed"
    }
}
