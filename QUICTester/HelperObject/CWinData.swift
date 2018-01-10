//
//  CWinData.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class CWinData: Codable {
    // MARK: Properties
    var time: Double
    var cwin: UInt64
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("cwinDatas")
    
    // MARK: Initializers
    init(time: Double, cwin: UInt64) {
        self.time = time
        self.cwin = cwin
    }
    
}
