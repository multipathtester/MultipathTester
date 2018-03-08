//
//  AboutViewController.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/19/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let softVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
        let softwareVersion = softVersion + " (" + buildVersion + ")"

        // Do any additional setup after loading the view.
        textView.text = """
        This application is part of a research project aiming to evaluate the benefits of simultaneously using several network paths such as WiFi and cellular on your iPhone. The tests will evaluate two transport protocols: Multipath TCP and Multipath QUIC. The outcome of the tests is available in the "Results" section of the application. This enables you to figure out if your networks behave well with those protocols.
        
        This application collects network metadata. Those metadata will only be used for research purposes. MultipathTester does not collect any personal information and never will.

        Client UUID: \(UIDevice.current.identifierForVendor!.uuidString)
        Software version: \(softwareVersion)
        
        Some of the icons are under CC 3.0 BY license. Maxim Basinski is the author of them.
        
        Developed by Quentin De Coninck, working at Universite Catholique de Louvain. Contact:  <quentin.deconinck@uclouvain.be>
        """
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
