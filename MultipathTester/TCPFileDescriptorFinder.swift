//
//  TCPFileDescriptorFinder.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 10/18/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

var lastFD: Int32 = -1

func ipsOf(hostname: String) -> [String] {
    var ips = [String]()
    let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
    CFHostStartInfoResolution(host, .addresses, nil)
    var success: DarwinBoolean = false
    if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? {
        for case let theAddress as NSData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                ips.append(numAddress)
            }
        }
    }
    return ips
}

func findTCPFileDescriptor(expectedIPs: [String], expectedPort: Int16) -> Int32 {
    // This is quite ugly, but Apple does not provide an easy way to collect this information...
    var saddr = sockaddr()
    var slen: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
    let startFd = Int32(0)
    let stopFd = startFd + 1000
    // FIXME consider changing this later to adapt to changing fd
    for fd in startFd...stopFd {
        if (fd == lastFD) {
            continue
        }
        let err = getpeername(fd, &saddr, &slen)
        if err == 0 {
            print(fd)
            let port = Int16(UInt16(UInt8(bitPattern: saddr.sa_data.0)) * 256 + UInt16(UInt8(bitPattern: saddr.sa_data.1)))
            if port != expectedPort {
                print(port, expectedPort)
                continue
            }
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if (getnameinfo(&saddr, socklen_t(saddr.sa_len), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) == 0) {
                let host = String(cString: hostBuffer)
                print("FD \(fd) ip \(host) port \(port)")
                for expIP in expectedIPs {
                    if host == expIP {
                        lastFD = fd
                        return fd
                    }
                }
            }
        }
    }
    lastFD = -1
    return -1
}
