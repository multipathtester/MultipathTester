//
//  StaticTesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import CoreLocation

class StaticMainViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton?
    
    @IBOutlet weak var wifiImageView: UIImageView!
    @IBOutlet weak var wifiNameLabel: UILabel!
    @IBOutlet weak var wifiIPv4ImageView: UIImageView!
    @IBOutlet weak var wifiIPv6ImageView: UIImageView!

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellNameLabel: UILabel!
    @IBOutlet weak var cellTechLabel: UILabel!
    @IBOutlet weak var cellIPv4ImageView: UIImageView!
    @IBOutlet weak var cellIPv6ImageView: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var aggregationSwitch: UISwitch!
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var timer: Timer?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(StaticMainViewController.testsLaunched(note:)), name: Utils.TestsLaunchedNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        aggregationSwitch.isOn = false
        startButton!.isEnabled = Utils.startNewTestsEnabled
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticMainViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()

        _ = LocationTracker.sharedTracker().startIfAuthorized()
        
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        updateUI(conn: conn)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer = Timer(timeInterval: 0.5, target: self, selector: #selector(StaticMainViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI(conn: Connectivity) {
        let bundle = Bundle(for: type(of: self))
        let ok = UIImage(named: "ok", in: bundle, compatibleWith: self.traitCollection)
        let error = UIImage(named: "error", in: bundle, compatibleWith: self.traitCollection)
        var (wifiAddr, cellAddr) = (false, false)
        
        if conn.networkType == .WiFi || conn.networkType == .WiFiCellular {
            let wifi = UIImage(named: "wifi", in: bundle, compatibleWith: self.traitCollection)
            wifiImageView.image = wifi
            wifiNameLabel.text = conn.wifiNetworkName
            var (v4, v6) = (false, false)
            for ip in conn.wifiAddresses! {
                wifiAddr = true
                if ip.contains(":") {
                    v6 = true
                } else {
                    v4 = true
                }
            }
            if v4 {
                wifiIPv4ImageView.image = ok
            } else {
                wifiIPv4ImageView.image = error
            }
            if v6 {
                wifiIPv6ImageView.image = ok
            } else {
                wifiIPv6ImageView.image = error
            }
        } else {
            let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
            wifiImageView.image = no_wifi
            wifiNameLabel.text = "No WiFi"
            wifiIPv4ImageView.image = error
            wifiIPv6ImageView.image = error
        }
        
        if conn.networkType == .Cellular || conn.networkType == .WiFiCellular {
            let cellular = UIImage(named: "cellular", in: bundle, compatibleWith: self.traitCollection)
            cellImageView.image = cellular
            cellNameLabel.text = conn.cellularNetworkName
            cellTechLabel.text = conn.cellularCodeDescription
            var (v4, v6) = (false, false)
            for ip in conn.cellularAddresses! {
                cellAddr = true
                if ip.contains(":") {
                    v6 = true
                } else {
                    v4 = true
                }
            }
            if v4 {
                cellIPv4ImageView.image = ok
            } else {
                cellIPv4ImageView.image = error
            }
            if v6 {
                cellIPv6ImageView.image = ok
            } else {
                cellIPv6ImageView.image = error
            }
        } else {
            let no_cellular = UIImage(named: "no_cellular", in: bundle, compatibleWith: self.traitCollection)
            cellImageView.image = no_cellular
            cellNameLabel.text = "No cellular"
            cellTechLabel.text = "None"
            cellIPv4ImageView.image = error
            cellIPv6ImageView.image = error
        }
        
        if wifiAddr || cellAddr {
            startButton!.isEnabled = Utils.startNewTestsEnabled
            if wifiAddr && cellAddr {
                summaryLabel.text = "Both network interfaces are ready."
            } else {
                summaryLabel.text = "Only one network interface is available. You can start tests, but you won't benefit from multipath protocols."
            }
        } else {
            startButton!.isEnabled = false
            summaryLabel.text = "No network connectivity."
        }
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        DispatchQueue.main.async {
            self.updateUI(conn: conn)
        }
    }
    
    @objc
    func testsLaunched(note: Notification) {
        let info = note.userInfo
        guard let enabled = info!["startNewTestsEnabled"] as? Bool else {
            return
        }
        Utils.startNewTestsEnabled = enabled
        if let button = startButton {
            DispatchQueue.main.async {
                button.isEnabled = enabled
            }
        }
    }
    
    @objc
    func probeCellular() {
        let cellStatus = UIDevice.current.hasCellularConnectivity
        if cellStatus != wasCellularOn {
            wasCellularOn = cellStatus
        }
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        DispatchQueue.main.async {
            self.updateUI(conn: conn)
        }
    }

    // MARK: Actions
    @IBAction func aboutTests(_ sender: Any) {
        let alert = UIAlertController(title: "About multipath tests", message: """
        This mode allows you to test how your device deals with multiple paths when conditions are stable. It prefers WiFi only by default, but you can enable the aggregation mode to benefit from the cellular.
        
        Some tests are bandwidth-intensive. Please do alter network connectivity during the tests.
        """, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "RunStaticTests":
            guard let staticRunnerViewController = segue.destination as? StaticRunnerViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            staticRunnerViewController.aggregate = aggregationSwitch.isOn
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }

}
