//
//  DelayData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/23/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class DelayData: Codable {
    // MARK: Properties
    var time: Double
    var delayUs: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("delayDatas")
    
    // MARK: Initializers
    init(time: Double, delayUs: UInt64) {
        self.time = time
        self.delayUs = delayUs
    }
}
