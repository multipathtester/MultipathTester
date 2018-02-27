//
//  Binary.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/27/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class Binary {
    static func getUInt32(bytes: [UInt8], startIndex: Int) -> UInt32 {
        let subBytes = bytes[startIndex..<startIndex+4]
        let data = Data(bytes: subBytes)
        return UInt32(bigEndian: data.withUnsafeBytes { $0.pointee })
    }
    
    static func getUInt64(bytes: [UInt8], startIndex: Int) -> UInt64 {
        let subBytes = bytes[startIndex..<startIndex+8]
        let data = Data(bytes: subBytes)
        return UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
    }
    
    static func putUInt8(_ val: UInt8, to data: NSMutableData) {
        var value = val
        data.append(&value, length: 1)
    }
    
    static func putUInt32(_ val: UInt32, to data: NSMutableData) {
        var valBE = val.bigEndian
        data.append(&valBE, length: 4)
    }
    
    static func putUInt64(_ val: UInt64, to data: NSMutableData) {
        var valBE = val.bigEndian
        data.append(&valBE, length: 8)
    }
}
