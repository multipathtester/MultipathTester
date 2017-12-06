//
//  QUICReqResResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICReqResResult: NSObject, NSCoding, TestResult {
    // MARK: Properties
    var name: String
    var runTime: Double
    var missed: Int64
    var maxDelay: Int64
    var delays: [Int64]

    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicReqResResults")
    
    // MARK: Types
    struct PropertyKey {
        static let name = "name"
        static let runTime = "runTime"
        static let missed = "missed"
        static let maxDelay = "maxDelay"
        static let delays = "delays"
    }
    
    // MARK: Initializers
    init?(name: String, runTime: Double, missed: Int64, maxDelay: Int64, delays: [Int64]) {
        self.name = name
        self.runTime = runTime
        self.missed = missed
        self.maxDelay = maxDelay
        self.delays = delays
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(runTime, forKey: PropertyKey.runTime)
        aCoder.encode(missed, forKey: PropertyKey.missed)
        aCoder.encode(maxDelay, forKey: PropertyKey.maxDelay)
        aCoder.encode(delays, forKey: PropertyKey.delays)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let runTime = aDecoder.decodeDouble(forKey: PropertyKey.runTime)
        let missed = aDecoder.decodeInt64(forKey: PropertyKey.missed)
        let maxDelay = aDecoder.decodeInt64(forKey: PropertyKey.maxDelay)
        let delays = aDecoder.decodeObject(forKey: PropertyKey.delays) as! [Int64]
        
        self.init(name: name, runTime: runTime, missed: missed, maxDelay: maxDelay, delays: delays)
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
