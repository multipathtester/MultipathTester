//
//  UIDevice.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/16/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

public extension UIDevice {
    
    var internalModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "AppleTV6,2":                              return "Apple TV 4K"
        case "AudioAccessory1,1":                       return "HomePod"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
    /// A Boolean value indicating whether the device has cellular data connectivity (true) or not (false).
    var hasCellularConnectivity: Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #endif
        var addrs: UnsafeMutablePointer<ifaddrs>?
        var cursor: UnsafeMutablePointer<ifaddrs>?
        
        defer { freeifaddrs(addrs) }
        
        guard getifaddrs(&addrs) == 0 else { return false }
        cursor = addrs
        
        while cursor != nil {
            guard
                let utf8String = cursor?.pointee.ifa_name,
                let name = NSString(utf8String: utf8String),
                // Is the interface UP and resources allocated?
                let flags = cursor?.pointee.ifa_flags,
                name == "pdp_ip0" && Int32(flags) & IFF_UP > 0 && Int32(flags) & IFF_RUNNING > 0
                else {
                    cursor = cursor?.pointee.ifa_next
                    continue
            }
            return cellularAddresses.count > 0
        }
        return false
    }
    
    /// A Boolean value indicating whether the device has wifi connectivity (true) or not (false).
    var hasWiFiConnectivity: Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        var cursor: UnsafeMutablePointer<ifaddrs>?
        
        defer { freeifaddrs(addrs) }
        
        guard getifaddrs(&addrs) == 0 else { return false }
        cursor = addrs
        
        while cursor != nil {
            guard
                let utf8String = cursor?.pointee.ifa_name,
                let name = NSString(utf8String: utf8String),
                // Is the interface UP and resources allocated?
                let flags = cursor?.pointee.ifa_flags,
                name == "en0" && Int32(flags) & IFF_UP > 0 && Int32(flags) & IFF_RUNNING > 0
                else {
                    cursor = cursor?.pointee.ifa_next
                    continue
            }
            return wifiAddresses.count > 0
        }
        return false
    }
    
    func getAddresses(interface_name: String) -> [String] {
        // Inspired from https://stackoverflow.com/a/30754194
        var addresses = [String]()
        
        // Get list of all interfaces of the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 addresses
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name.starts(with: interface_name) {
                    // Convert interface name to a human readable string
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    addresses.append(String(cString: hostname))
                    print(name, String(cString: hostname), interface.ifa_flags)
                }
            }
        }
        
        return addresses
    }
    
    func getFilteredAddresses(interface_name: String) -> [String] {
        var addrs = getAddresses(interface_name: interface_name)
        var indexToRemove = [Int]()
        // Remove link-local IPv6 addresses
        for i in 0..<addrs.count {
            // Also remove site-local private IPv6 addresses
            let addr = addrs[i]
            if addr.starts(with: "fe80:") || addr.starts(with: "fc") || addr.starts(with: "fd") {
                indexToRemove.append(i)
            }
        }
        // Remove indexes in reverse order, to avoid removing a wrong element if several items have to be removed
        for r in (indexToRemove).reversed() {
            addrs.remove(at: r)
        }
        
        return addrs
    }
    
    var wifiAddresses: [String] {
        return getFilteredAddresses(interface_name: "en0")
    }
    
    var cellularAddresses: [String] {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return ["10.0.1.2"]
        #endif
        return getFilteredAddresses(interface_name: "pdp_ip0")
    }
}
