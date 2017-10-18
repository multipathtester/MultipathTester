//
//  TCPFileDescriptorFinder.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 10/18/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

var lastFD: Int32 = -1

func findTCPFileDescriptor(expectedIP: String, expectedPort: Int16) -> Int32 {
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
            let port = (Int16(saddr.sa_data.0) * 256 + Int16(saddr.sa_data.1))
            if port != expectedPort {
                continue
            }
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if (getnameinfo(&saddr, socklen_t(saddr.sa_len), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) == 0) {
                let host = String(cString: hostBuffer)
                print("FD \(fd) ip \(host) port \(port)")
                if (host != expectedIP) {
                    continue
                }
                lastFD = fd
                return fd
            }
        }
    }
    lastFD = -1
    return -1
}
