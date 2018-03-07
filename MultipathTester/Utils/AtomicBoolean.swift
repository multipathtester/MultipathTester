//
//  AtomicBoolean.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 3/7/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

struct AtomicBoolean {
    private var semaphore = DispatchSemaphore(value: 1)
    private var b: Bool = false
    var val: Bool {
        get {
            semaphore.wait()
            let tmp = b
            semaphore.signal()
            return tmp
        }
        set {
            semaphore.wait()
            b = newValue
            semaphore.signal()
        }
    }
}
