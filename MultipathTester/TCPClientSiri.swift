//
//  TCPClientSiri.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/13/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPClientSiri {
    let intervalTimeMs = 400
    let maxID = 100
    let querySize = 750
    let resSize = 750
    let runTimeMs = 30000
    
    var addr: String
    var delays: [Int]
    var messageID: Int
    var missed: Int
    var multipath: Bool
    var sentTime: [Int: DispatchTime]
    var startTime: DispatchTime
    
    init(multipath: Bool, addr: String) {
        self.addr = addr
        self.delays = []
        self.messageID = 0
        self.missed = 0
        self.multipath = multipath
        self.sentTime = [:]
        self.startTime = DispatchTime.now()
    }
    
    func Run() -> String {
        return "TODO"
    }
}
