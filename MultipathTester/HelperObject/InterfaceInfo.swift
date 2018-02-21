//
//  InterfaceBytes.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 2/7/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class InterfaceInfo: Codable {
    var bytesSent: UInt32
    var bytesReceived: UInt32
    
    init(bytesSent: UInt32, bytesReceived: UInt32) {
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
    }
    
    convenience init() {
        self.init(bytesSent: 0, bytesReceived: 0)
    }
    
    // Get info about an interface
    static func getInterfaceInfo(netInterface: Connectivity.NetworkType) -> InterfaceInfo {
        let res = InterfaceInfo()
        // Get list of all interfaces of the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return res }
        guard let firstAddr = ifaddr else { return res }
        
        // For each interface...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_LINK) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if (name.hasPrefix("en") && netInterface == .WiFi) || (name.hasPrefix("pdp_ip") && netInterface == .Cellular) {
                    let stats = UnsafeMutablePointer<if_data>(OpaquePointer(interface.ifa_data))
                    guard let statsOk = stats else {
                        continue
                    }
                    res.bytesReceived += statsOk.pointee.ifi_ibytes
                    res.bytesSent += statsOk.pointee.ifi_obytes
                }
            }
        }
        return res
    }
}
