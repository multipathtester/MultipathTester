//
//  ConnectivityResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICConnectivityResult: NSObject, NSCoding, TestResult {
    // MARK: Properties
    var target: String
    var runTime: Double
    var success: Bool
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicConnectivityResults")
    
    // MARK: Types
    struct PropertyKey {
        static let target = "target"
        static let runTime = "runTime"
        static let success = "success"
    }
    
    // MARK: Initializers
    init?(target: String, runTime: Double, success: Bool) {
        self.target = target
        self.runTime = runTime
        self.success = success
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(target, forKey: PropertyKey.target)
        aCoder.encode(runTime, forKey: PropertyKey.runTime)
        aCoder.encode(success, forKey: PropertyKey.success)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let target = aDecoder.decodeObject(forKey: PropertyKey.target) as! String
        let runTime = aDecoder.decodeDouble(forKey: PropertyKey.runTime)
        let success = aDecoder.decodeBool(forKey: PropertyKey.success)
        
        self.init(target: target, runTime: runTime, success: success)
    }
    
    func getDescription() -> String {
        return target
    }
    
    func getResult() -> String {
        if success {
            return "Succeeded in " + String(runTime) + " s"
        }
        return "Failed"
    }
}
