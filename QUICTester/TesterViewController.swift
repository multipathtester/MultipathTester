//
//  TesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/28/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TesterViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var tests: [Test] = [Test]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressBar.progress = 0.0

        // Do any additional setup after loading the view.
        tests = [
            QUICConnectivityTest(port: 443),
            QUICConnectivityTest(port: 6121),
        ]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func startTests(_ sender: UIButton) {
        sender.isEnabled = false
        print("We start the tests")
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            for i in 0..<nbTests {
                let test = self.tests[i]
                DispatchQueue.main.async {
                    self.countLabel.text = String(i + 1) + "/" + String(nbTests)
                    self.timeLabel.text = "0:00"
                    self.testLabel.text = test.getDescription()
                    self.progressBar.progress = Float(i) / Float(nbTests)
                }
                test.run()
            }
            print("Tests done")
            DispatchQueue.main.async {
                self.progressBar.progress = 1.0
                self.testLabel.text = "Done"
                sender.isEnabled = true
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
