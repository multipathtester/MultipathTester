//
//  BulkResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/14/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import os.log

class BulkResult: NSObject, NSCoding {
    // MARK: Properties
    var startTime: Double
    var networkProtocol: String
    var multipath: Bool
    var durationNs: Int64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("bulkResults")
    
    // MARK: Types
    struct PropertyKey {
        static let startTime = "startTime"
        static let networkProtocol = "networkProtocol"
        static let multipath = "multipath"
        static let durationNs = "durationNs"
    }
    
    // MARK: Initializer
    init(startTime: Double, networkProtocol: String, multipath: Bool, durationNs: Int64) {
        self.startTime = startTime
        self.networkProtocol = networkProtocol
        self.multipath = multipath
        self.durationNs = durationNs
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(startTime, forKey: PropertyKey.startTime)
        aCoder.encode(networkProtocol, forKey: PropertyKey.networkProtocol)
        aCoder.encode(multipath, forKey: PropertyKey.multipath)
        aCoder.encode(durationNs, forKey: PropertyKey.durationNs)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // The startTime is required. If we cannot decode it, the initializer should fail.
        let startTime = aDecoder.decodeDouble(forKey: PropertyKey.startTime)
        // Assume the remaining will work
        let networkProtocol = aDecoder.decodeObject(forKey: PropertyKey.networkProtocol) as! String
        let multipath = aDecoder.decodeBool(forKey: PropertyKey.multipath)
        let durationNs = aDecoder.decodeInt64(forKey: PropertyKey.durationNs)
        
        // Must call designated initializer.
        self.init(startTime: startTime, networkProtocol: networkProtocol, multipath: multipath, durationNs: durationNs)
    }
}
