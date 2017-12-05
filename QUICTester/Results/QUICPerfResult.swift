//
//  QUICPerfResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICPerfResult: NSObject, NSCoding, TestResult {
    // MARK: Properties
    var name: String
    var runTime: Double
    var totalRetrans: UInt64
    var totalSent: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicPerfResults")
    
    // MARK: Types
    struct PropertyKey {
        static let name = "name"
        static let runTime = "runTime"
        static let totalRetrans = "totalRetrans"
        static let totalSent = "totalSent"
    }
    
    // MARK: Initializers
    init?(name: String, runTime: Double, totalRetrans: UInt64, totalSent: UInt64) {
        self.name = name
        self.runTime = runTime
        self.totalRetrans = totalRetrans
        self.totalSent = totalSent
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(runTime, forKey: PropertyKey.runTime)
        aCoder.encode(totalRetrans, forKey: PropertyKey.totalRetrans)
        aCoder.encode(totalSent, forKey: PropertyKey.totalSent)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let runTime = aDecoder.decodeDouble(forKey: PropertyKey.runTime)
        let totalRetrans = aDecoder.decodeObject(forKey: PropertyKey.totalRetrans) as! UInt64
        let totalSent = aDecoder.decodeObject(forKey: PropertyKey.totalSent) as! UInt64
        
        self.init(name: name, runTime: runTime, totalRetrans: totalRetrans, totalSent: totalSent)
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        return "Tranfered " + String(totalSent) + " in " + String(runTime) + "s"
    }
}
