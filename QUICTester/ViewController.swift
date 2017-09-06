//
//  ViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Client

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Starting")
        let res = ClientRun(true, true, "", "https://ns387496.ip-176-31-249.eu:6121/random")
        print(res)
        print("Alibababababa End")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

