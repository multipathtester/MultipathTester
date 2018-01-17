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
    var locationTracker = LocationTracker.sharedTracker()

    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
