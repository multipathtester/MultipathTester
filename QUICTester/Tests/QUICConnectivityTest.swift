//
//  QUICConnectivityTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICConnectivityTest: BaseTest, Test {
    // MARK: Properties
    var port: Int16
    var url: String
    
    init(port: Int16) {
        self.port = port
        url = "https://traffic.multipath-quic.org:" + String(self.port) + "/connectivityTest"
        super.init(traffic: "bulk", url: url)
        
        // Out file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            outFileURL = dir.appendingPathComponent("quictraffic_connectivity_" + String(self.port) + ".out")
        }
        do {
            try "".write(to: outFileURL, atomically: false, encoding: .utf8)
        }
        catch {}
        
        // Prepare the run configuration
        runCfg.outputVar = outFileURL.absoluteString
        runCfg.printBodyVar = true
    }
    
    func getDescription() -> String {
        return "QUIC Connectivity on port " + String(self.port)
    }
    
    func getBenchDict() -> [String : Any] {
        return [
            "name": "quic_connectivity",
            "config": [
                "port": self.port,
                "url": self.url,
            ],
        ]
    }
    
    func getTestResult() -> TestResult {
        // FIXME should check if result is ready
        return QUICConnectivityResult(target: "QUIC Connectivity port " + String(port), runTime: Double(result["run_time"] as! String)!, success: result["success"] as! Bool)!
    }
    
    func run() -> [String:Any] {
        startTime = Date().timeIntervalSince1970
        var success = false
        let durationString = QuictrafficRun(runCfg)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("It works!") {
                    success = true
                }
            }
        } catch { print("Nope...") }
        result = [
            "run_time": String(format: "%.9f", Utils.parse(durationString: durationString!)),
            "success": success,
        ]
        return result
    }
}
