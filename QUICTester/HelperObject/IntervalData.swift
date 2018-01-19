//
//  IntervalData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class IntervalData: Codable {
    // MARK: Properties
    var interval: String
    var transferredLastSecond: UInt64
    var globalBandwidth: UInt64
    var retransmittedLastSecond: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("intervalDatas")
    
    // MARK: Initializers
    init(interval: String, transferredLastSecond: UInt64, globalBandwidth: UInt64, retransmittedLastSecond: UInt64) {
        self.interval = interval
        self.transferredLastSecond = transferredLastSecond
        self.globalBandwidth = globalBandwidth
        self.retransmittedLastSecond = retransmittedLastSecond
    }
    
    // MARK: JSON serialization for sending to collect server
    func toJSONDict() -> [String: Any] {
        return [
            "intervalInSec": interval,
            "transferredLastSecond": transferredLastSecond,
            "globalBandwidth": globalBandwidth,
            "retransmittedLastSecond": retransmittedLastSecond,
        ]
    }
}
