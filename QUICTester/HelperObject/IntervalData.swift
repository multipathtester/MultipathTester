//
//  IntervalData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class IntervalData: NSObject, NSCoding {
    // MARK: Properties
    var interval: String
    var transferredLastSecond: UInt64
    var globalBandwidth: UInt64
    var retransmittedLastSecond: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("intervalDatas")
    
    // MARK: Types
    struct PropertyKey {
        static let interval = "interval"
        static let transferredLastSecond = "transferredLastSecond"
        static let globalBandwidth = "globalBandwidth"
        static let retransmittedLastSecond = "retransmittedLastSecond"
    }
    
    // MARK: Initializers
    init?(interval: String, transferredLastSecond: UInt64, globalBandwidth: UInt64, retransmittedLastSecond: UInt64) {
        self.interval = interval
        self.transferredLastSecond = transferredLastSecond
        self.globalBandwidth = globalBandwidth
        self.retransmittedLastSecond = retransmittedLastSecond
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(interval, forKey: PropertyKey.interval)
        aCoder.encode(transferredLastSecond, forKey: PropertyKey.transferredLastSecond)
        aCoder.encode(globalBandwidth, forKey: PropertyKey.globalBandwidth)
        aCoder.encode(retransmittedLastSecond, forKey: PropertyKey.retransmittedLastSecond)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let interval = aDecoder.decodeObject(forKey: PropertyKey.interval) as! String
        let transferredLastSecond = aDecoder.decodeObject(forKey: PropertyKey.transferredLastSecond) as! UInt64
        let globalBandwidth = aDecoder.decodeObject(forKey: PropertyKey.globalBandwidth) as! UInt64
        let retransmittedLastSecond = aDecoder.decodeObject(forKey: PropertyKey.retransmittedLastSecond) as! UInt64
        
        self.init(interval: interval, transferredLastSecond: transferredLastSecond, globalBandwidth: globalBandwidth, retransmittedLastSecond: retransmittedLastSecond)
    }
}
