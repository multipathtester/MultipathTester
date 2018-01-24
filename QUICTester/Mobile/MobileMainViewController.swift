//
//  MobileMainViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/22/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import NetworkExtension

class MobileMainViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton?
    
    @IBOutlet weak var wifiImageView: UIImageView!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var locImageView: UIImageView!
    @IBOutlet weak var locLabel: UILabel!
    
    @IBOutlet weak var summaryLabel: UILabel!
    
    var locationAuthorized: Bool = false
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var timer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(MobileMainViewController.testsLaunched(note:)), name: Utils.TestsLaunchedNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton!.isEnabled = Utils.startNewTestsEnabled
        print(NEHotspotHelper.supportedNetworkInterfaces())
        
        NotificationCenter.default.addObserver(self, selector: #selector(MobileMainViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        locationAuthorized = LocationTracker.sharedTracker().startIfAuthorized()
        
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        updateUI(conn: conn)
        
        timer = Timer(timeInterval: 0.5, target: self, selector: #selector(MobileMainViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI(conn: Connectivity) {
        let bundle = Bundle(for: type(of: self))
        var (wifi, cell) = (false, false)
        
        if conn.networkType == .WiFi || conn.networkType == .WiFiCellular {
            if conn.wifiAddresses!.count > 0 {
                let wifiIm = UIImage(named: "wifi", in: bundle, compatibleWith: self.traitCollection)
                wifiImageView.image = wifiIm
                wifiLabel.text = "Wifi is ready."
                wifi = true
            } else {
                let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
                wifiImageView.image = no_wifi
                wifiLabel.text = "Wifi has no addresses."
            }
        } else {
            let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
            wifiImageView.image = no_wifi
            wifiLabel.text = "Wifi is not ready."
        }
        
        if conn.networkType == .Cellular || conn.networkType == .WiFiCellular {
            if conn.cellularAddresses!.count > 0 {
                let cellular = UIImage(named: "cellular", in: bundle, compatibleWith: self.traitCollection)
                cellImageView.image = cellular
                cellLabel.text = "Cellular is ready."
                cell = true
            } else {
                let no_cellular = UIImage(named: "no_cellular", in: bundle, compatibleWith: self.traitCollection)
                cellImageView.image = no_cellular
                cellLabel.text = "Cellular has no addresses."
            }
        } else {
            let no_cellular = UIImage(named: "no_cellular", in: bundle, compatibleWith: self.traitCollection)
            cellImageView.image = no_cellular
            cellLabel.text = "Cellular is not ready."
        }
        
        if locationAuthorized {
            let location = UIImage(named: "location", in: bundle, compatibleWith: self.traitCollection)
            locImageView.image = location
            locLabel.text = "You can estimate how far your WiFi is reachable."
        } else {
            let no_location = UIImage(named: "no_location", in: bundle, compatibleWith: self.traitCollection)
            locImageView.image = no_location
            locLabel.text = "Location is disabled, the application cannot estimate how far your WiFi is reachable."
        }
        
        if wifi && cell {
            summaryLabel.text = "You are ready to perform this test."
            startButton!.isEnabled = Utils.startNewTestsEnabled
        } else {
            summaryLabel.text = "You need both WiFi and cellular networks to perform this test."
            startButton!.isEnabled = false
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
            let reachabilityStatus = internetReachability.currentReachabilityStatus()
            let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
            DispatchQueue.main.async {
                self.updateUI(conn: conn)
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