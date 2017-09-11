//
//  ViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Bulkclient

class ViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Actions
    @IBAction func startTestButtonPressed(_ sender: UIButton) {
        // Avoid launching multiples tests in parralel
        sender.isEnabled = false
        
        print("Starting")
        let res = BulkclientRun(true, true, "", "https://ns387496.ip-176-31-249.eu:6121/random")
        print("End with time \(String(describing: res))")
        
        // Show the result to the user
        resultLabel.text = res
        
        // Then reactivate the button
        sender.isEnabled = true
    }
    
}

