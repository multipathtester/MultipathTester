//
//  RcvBytesData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class RcvBytesData: NSObject, NSCoding {
    // MARK: Properties
    var time: Double
    var rcvBytes: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("rcvBytesDatas")
    
    // MARK: Types
    struct PropertyKey {
        static let time = "time"
        static let rcvBytes = "rcvBytes"
    }
    
    // MARK: Initializers
    init?(time: Double, rcvBytes: UInt64) {
        self.time = time
        self.rcvBytes = rcvBytes
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(rcvBytes, forKey: PropertyKey.rcvBytes)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let time = aDecoder.decodeDouble(forKey: PropertyKey.time)
        let rcvBytes = aDecoder.decodeObject(forKey: PropertyKey.rcvBytes) as! UInt64
        
        self.init(time: time, rcvBytes: rcvBytes)
    }
    
    
}
