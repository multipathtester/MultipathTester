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
        textView.text = """
        Thank you for downloading MultipathTester. This gives you the opportunity to take part in a research study. Our research aims to evaluate the benefits of simultaneously using several network paths such as WiFi and cellular on your iPhone. Today, most applications use either WiFi or cellular and switching from one to the other remains difficult. Our objective is to compare the performance of two different approaches to combine different networks : Multipath TCP and Multipath QUIC. Multipath TCP is included in iOS11. Multipath QUIC is an extension to the QUIC protocol that is being standardized. MultipathTester uses the Multipath TCP stack provided by iOS and its own implementation of Multipath QUIC.
        
        We compare the two protocols by performing active measurements. MultipathTester collects various measurements (e.g. bandwidth, traffic sent over each network interface, delays, ...) and uploads them to a control server. You can also see the results of your measurements. Some tests are bandwidth intensive. If you are concerned by the potential utilisation of your cellular interface, you can configure the application to avoid sending data on the cellular interface when the WiFi works well (this option is enabled by default). MultipathTester does not collect any personal information and never will. All the collected metadata will only be used for research purposes. For the mobility tests, the application will ask the permission to obtain your location. This is used to estimate the distance you walk before losing WiFi connectivity. For the other tests, the location is only used to get a coarsed-grained information. If you are worried about this, you can simply deny the location permission.
        
        Your participation to this research is voluntary and lasts as long as you want. You can run as many tests as you want. Those can give you an overview of the performance of your networks when using multiple paths and in mobility cases. Your contribution to the study will be anonymous to the researchers. However, due to the nature of the Internet traffic, it might still be possible to identify participants by their IP addresses. When processing the data, those addresses will be anonymized. We will only report on aggregated data, never individual users.
        
        If you have any question about this study, feel free to contact Quentin De Coninck at quentin.deconinck@uclouvain.be, which is the main person in charge of this study. This study is performed at Universite Catholique de Louvain (Belgium) and is funded by the Fonds de la Recherche Scientifique -- FNRS. By clicking the "Accept" button, you agree to participate in this study.
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
