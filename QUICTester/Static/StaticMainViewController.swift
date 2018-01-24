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

    var locationTracker = LocationTracker.sharedTracker()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(StaticMainViewController.testsLaunched(note:)), name: Utils.TestsLaunchedNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton!.isEnabled = Utils.startNewTestsEnabled
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticMainViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
        _ = locationTracker.startIfAuthorized()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc
    func locationChanged(note: Notification) {
        let info = note.userInfo
        guard let locations = info!["locations"] as? [CLLocation] else {
            return
        }
        for location in locations {
            print(location.description)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
