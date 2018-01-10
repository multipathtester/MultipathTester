//
//  RcvBytesData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class RcvBytesData: Codable {
    // MARK: Properties
    var time: Double
    var rcvBytes: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("rcvBytesDatas")
    
    // MARK: Initializers
    init(time: Double, rcvBytes: UInt64) {
        self.time = time
        self.rcvBytes = rcvBytes
    }
}
