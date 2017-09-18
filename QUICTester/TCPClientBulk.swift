//
//  TCPClientBulk.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/13/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPClientBulk {
    var multipath: Bool
    var url: URL
    
    init(multipath: Bool, url: String) {
        self.multipath = multipath
        self.url = (URL(string: url))!
    }
    
    func Run() -> Double {
        var ret: Double = -1.0
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
        }
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .background).async {
            let start = DispatchTime.now()
            let task = session.dataTask(with: self.url) { (data, resp, error) in
                guard error == nil && data != nil else {
                    print("\(String(describing: error))")
                    ret = -2.0
                    group.leave()
                    return
                }
                guard resp != nil else {
                    print("received no response")
                    ret = -1.0
                    group.leave()
                    return
                }
                let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
                let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(elapsed) / 1_000_000_000
                
                print("\(timeInterval)s for \(length) MB")
                ret = timeInterval
                group.leave()
            }
            task.resume()
        }
        
        group.wait()
        session.finishTasksAndInvalidate()
        
        return ret
    }
}
