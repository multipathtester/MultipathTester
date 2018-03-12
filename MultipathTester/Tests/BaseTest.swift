//
//  BaseTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
class BaseTest {
    // MARK: Properties
    var ipVer: IPVersion
    var logFileURL: URL = URL(fileURLWithPath: "")
    var notifyID: String
    var outFileURL: URL = URL(fileURLWithPath: "")
    var port: UInt16
    var result: [String:Any] = [String:Any]()
    var runCfg: RunConfig
    var startTime: Date = Date()
    var testServer: TestServer = .fr
    var urlPath: String = "" // If not empty, it MUST start with a '/' character
    var waitTime: Double  // In seconds
    
    var stopped: Bool = false
    
    var wifiInfoStart = InterfaceInfo()
    var wifiInfoEnd = InterfaceInfo()
    var cellInfoStart = InterfaceInfo()
    var cellInfoEnd = InterfaceInfo()
    
    init(traffic: String, ipVer: IPVersion, port: UInt16, urlPath: String?, filePrefix: String, waitTime: Double) {
        self.ipVer = ipVer
        self.port = port
        if let argURLPath = urlPath {
            self.urlPath = argURLPath
        }
        self.waitTime = waitTime
        
        // Notify ID
        let now = Date().timeIntervalSince1970
        notifyID = String(now)
        
        // Log file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logFileURL = dir.appendingPathComponent(filePrefix + ".log")
        }
        do {
            try FileManager.default.removeItem(at: logFileURL)
        } catch {print(logFileURL, "does not exist")}
        do {
            try "".write(to: logFileURL, atomically: false, encoding: .utf8)
        }
        catch {print(logFileURL, "oups log")}
        
        // Out file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            outFileURL = dir.appendingPathComponent(filePrefix + ".out")
        }
        do {
            try FileManager.default.removeItem(at: outFileURL)
        } catch {print(outFileURL, "does not exist")}
        do {
            try "".write(to: outFileURL, atomically: false, encoding: .utf8)
        }
        catch {print(outFileURL, "oups out")}
        
        // Prepare the run configuration
        runCfg = RunConfig(traffic: traffic)
        runCfg.notifyIDVar = notifyID
        runCfg.logFileVar = logFileURL.absoluteString
        runCfg.outputVar = outFileURL.absoluteString
        runCfg.urlVar = getURL()
    }
    
    func getNotifyID() -> String {
        return notifyID
    }
    
    func getStartTime() -> Date {
        return startTime
    }
    
    func getProtocol() -> NetProtocol {
        fatalError("Must Override")
    }
    
    func getProtoInfo() -> [[String: Any]] {
        switch getProtocol() {
        case .TCP, .MPTCP:
            return result["tcp_infos"] as? [[String: Any]] ?? []
        case .QUIC, .MPQUIC:
            return Utils.collectQUICInfo(logFileURL: logFileURL)
        }
        
    }
    
    func getTestServer() -> TestServer {
        return testServer
    }
    
    func getTestServerHostname() -> String {
        var ipVerPrefix = ""
        switch ipVer {
        case .any:
            break
        default:
            ipVerPrefix = ipVer.rawValue + "."
        }
        return ipVerPrefix + testServer.rawValue + ".traffic.multipath-quic.org"
    }
    
    func getURL() -> String {
        return getTestServerHostname() + ":" + String(port) + urlPath
    }
    
    func setTestServer(testServer: TestServer) {
        self.testServer = testServer
        updateURL()
    }
    
    func updateURL() {
        runCfg.urlVar = getURL()
    }
    
    func getRunTime() -> Double {
        return Double(runCfg.runTime())
    }
    
    func getWaitTime() -> Double {
        return waitTime
    }
    
    func setMultipathService(service: RunConfig.MultipathServiceType) {
        runCfg.multipathServiceVar = service
    }
    
    func wait() {
        // This is why this MUST be run in background
        usleep(UInt32(waitTime * 1000000))
    }
    
    func succeeded() -> Bool {
        return result["success"] as? Bool ?? false
    }
    
    func getStopped() -> Bool {
        return stopped
    }
    
    func stop() {
        stopped = true
    }
    
    func run() -> [String:Any] {
        startTime = Date()
        wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        // This MUST be overriden
        return [:]
    }
}
