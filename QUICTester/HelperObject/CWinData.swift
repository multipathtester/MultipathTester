//
//  CWinData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class CWinData: NSObject, NSCoding {
    // MARK: Properties
    var time: Double
    var cwin: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("cwinDatas")
    
    // MARK: Types
    struct PropertyKey {
        static let time = "time"
        static let cwin = "cwin"
    }
    
    // MARK: Initializers
    init?(time: Double, cwin: UInt64) {
        self.time = time
        self.cwin = cwin
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(time, forKey: PropertyKey.time)
        aCoder.encode(cwin, forKey: PropertyKey.cwin)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let time = aDecoder.decodeDouble(forKey: PropertyKey.time)
        let cwin = aDecoder.decodeObject(forKey: PropertyKey.cwin) as! UInt64
        
        self.init(time: time, cwin: cwin)
    }
    
    
}
