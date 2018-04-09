//
//  AppDelegate.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    var delegate = DownloadSessionDelegate.sharedInstance

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            print("Not first launch.")
        }
        else {
            print("First launch, setting NSUserDefault.")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "NavigationConsentFormViewController")
            self.window?.rootViewController = vc
            //UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
        
        // Notifications
        let okAction = UNNotificationAction(identifier: "OK", title: "OK", options: UNNotificationActionOptions(rawValue: 0))
        let readMoreAction = UNNotificationAction(identifier: "READ MORE", title: "Read more", options: .foreground)
        let resultCategory = UNNotificationCategory(identifier: "RESULT", actions: [okAction, readMoreAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([resultCategory])
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorizations
        }
        center.delegate = self
        
        // Fetch data when we can
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("HandleEventsForBackgroundURLSession")
        let config = URLSessionConfiguration.background(withIdentifier: "MultipathTesterFeed")
        let session = URLSession(configuration: config, delegate: self.delegate, delegateQueue: nil)
        print("Rejoining session \(session)")
        
        self.delegate.addCompletionHandler(handler: completionHandler, identifier: identifier)
        
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("We start background task!")
        
        DispatchQueue.main.async {
            // Create GET request
            let config = URLSessionConfiguration.background(withIdentifier: "MultipathTesterFeed")
            let session = URLSession(configuration: config, delegate: self.delegate, delegateQueue: nil)
            
            let url = URL(string: "https://multipath-quic.org/feed.multipathtester.json")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.downloadTask(with: request)
            task.resume()
            
            completionHandler(.newData)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.categoryIdentifier == "RESULT" {
            // Handle the actions
            if response.actionIdentifier == "READ MORE" {
                let urlString = response.notification.request.content.userInfo["url"] as? String ?? ""
                if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:])
                }
            } else if response.actionIdentifier == "OK" {
                // Do nothing
            }
        }
        
        completionHandler()
    }
}

