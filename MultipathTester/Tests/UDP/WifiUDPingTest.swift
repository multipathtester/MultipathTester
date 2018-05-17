//
//  WifiUDPingTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 5/17/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class WifiUDPingTest: BaseUDPingTest {
    init(port: UInt16, testServer: TestServer) {
        let filePrefix = "quictraffic_wifiudping_" + testServer.rawValue
        super.init(port: port, testServer: testServer, wifiProbe: true, filePrefix: filePrefix)
        // Just to be sure
        runCfg.notifyIDVar += "-wifi"
    }
    
    convenience init(testServer: TestServer) {
        // By default, use OpenVPN 2.0 port
        self.init(port: 1194, testServer: testServer)
    }
}
