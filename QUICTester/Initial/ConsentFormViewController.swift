//
//  ConsentFormViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 2/13/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class ConsentFormViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var acceptButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // FIXME change the name of the app
        textView.text = """
        Thank you for downloading MultipathTester. This gives you the opportunity to take part in a research study. Our research aims to evaluate the benefits of using multiple network paths. Most of the mobile devices have access to several networks, typically WiFi and cellular ones. Despite this, most of the smartphone application traffics remain stuck on a given network and cannot seamlessly switch from a network to another one. This is the consequence of design decisions made in the 70s about the Transmission Control Protocol (TCP), the most deployed reliable transport protocol on the Internet. Therefore, this is a software limitation.
        
        This application aims to compare the performance of two network protocols solving the TCP's limitations: Multipath TCP (MPTCP) and Quick UDP Internet Connection (QUIC). MPTCP is an extension of TCP allowing the usage of multiple network paths. It has been recently introduced in iOS11 and any application could now benefit from this protocol. QUIC is a new protocol, initially developed in 2012 by Google, that is currently in standardization process. However, it already represents more than 7% of the whole Internet traffic. Because of the lack of reference implementation, this application embeds its own QUIC implementation.
        
        The comparaison between both protocols is performed by generating different kinds of network traffic. The application does not record the traffic itself, but metadata associated to it (e.g., the bandwidth achieved, the amount of bytes sent or received by network interfaces,...). Some tests are bandwidth intensive. If you are concerned by the potential cellular usage, you can configure the test to avoid sending data on cellular if the WiFi is good (this option is enabled by default). Once you completed tests, you will get a summary describing what was performed and the associated results.
        
        The application does not collect any personal information and never will. All collected metadata are for research purpose. For the tests, the application will ask you access to your location. For the mobile test, this is used to estimate the distance you crossed before losing WiFi connectivity. For other tests, it is used to get a coarsed-grained location. If you are worried about this, you can simply deny the location permission.
        
        Your participation to this research is voluntary and lasts as long as you want. You can run as many tests as you want. Those can provide you an overview of the performance of your networks when using multiple paths and in mobility cases. Your contribution to the study will be anonymous to the researchers. However, due to the nature of the Internet traffic, it might still be possible to identify participants by their IP addresses. When processing the data, those addresses will be anonymized. The results we might get out of them will come from group of data, and not from a particular user.
        
        If you have any question about this study, feel free to contact Quentin De Coninck at quentin.deconinck@uclouvain.be, which is the main person in charge of this study. This study is performed at Universite Catholique de Louvain (Belgium) and is funded by the Fonds de la Recherche Scientifique -- FNRS.
        
        By clicking the "Accept" button, you agree to participate in this study.
        """
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "AcceptConsent":
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            self.navigationController!.viewControllers.removeAll()
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
        
    }
    @IBAction func declineConsent(_ sender: Any) {
        let alert = UIAlertController(title: "Thank you", message: "Thanks for the interest you have in our application.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Exit", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in exit(0)}))
        self.present(alert, animated: true, completion: nil)
    }
    
}
