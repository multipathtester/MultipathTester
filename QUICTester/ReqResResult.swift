//
//  ReqResResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/14/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import os.log

class ReqResResult: NSObject, NSCoding {
    // MARK: Properties
    var startTime: Double
    var networkProtocol: String
    var multipath: Bool
    var durationNs: Int64
    var missed: Int
    var delays: [Int]
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("reqresResults")
    
    // MARK: Types
    struct PropertyKey {
        static let startTime = "startTime"
        static let networkProtocol = "networkProtocol"
        static let multipath = "multipath"
        static let durationNs = "durationNs"
        static let missed = "missed"
        static let delays = "delays"
    }
    
    // MARK: Initializer
    init(startTime: Double, networkProtocol: String, multipath: Bool, durationNs: Int64, missed: Int, delays: [Int]) {
        self.startTime = startTime
        self.networkProtocol = networkProtocol
        self.multipath = multipath
        self.durationNs = durationNs
        self.missed = missed
        self.delays = delays
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(startTime, forKey: PropertyKey.startTime)
        aCoder.encode(networkProtocol, forKey: PropertyKey.networkProtocol)
        aCoder.encode(multipath, forKey: PropertyKey.multipath)
        aCoder.encode(durationNs, forKey: PropertyKey.durationNs)
        aCoder.encode(missed, forKey: PropertyKey.missed)
        aCoder.encode(delays, forKey: PropertyKey.delays)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let startTime = aDecoder.decodeDouble(forKey: PropertyKey.startTime)
        let networkProtocol = aDecoder.decodeObject(forKey: PropertyKey.networkProtocol) as! String
        let multipath = aDecoder.decodeBool(forKey: PropertyKey.multipath)
        let durationNs = aDecoder.decodeInt64(forKey: PropertyKey.durationNs)
        let missed = aDecoder.decodeInteger(forKey: PropertyKey.missed)
        let delays = aDecoder.decodeObject(forKey: PropertyKey.delays) as? [Int]
        
        self.init(startTime: startTime, networkProtocol: networkProtocol, multipath: multipath, durationNs: durationNs, missed: missed, delays: delays!)
    }
}
