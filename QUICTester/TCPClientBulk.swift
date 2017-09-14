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
    
    func Run() -> String {
        var ret: String?
        
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
                    ret = "\(String(describing: error))"
                    group.leave()
                    return
                }
                guard resp != nil else {
                    ret = "received no response"
                    group.leave()
                    return
                }
                let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
                let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(elapsed) / 1_000_000_000
                
                ret = "\(timeInterval)s for \(length) MB"
                group.leave()
            }
            task.resume()
        }
        
        group.wait()
        session.finishTasksAndInvalidate()
        
        return ret!
    }
}
