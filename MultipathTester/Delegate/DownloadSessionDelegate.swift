//
//  DownloadSessionDelegate.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 4/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import UserNotifications

typealias CompleteHandlerBlock = () -> ()

class DownloadSessionDelegate : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    var handlerQueue: [String : CompleteHandlerBlock]!
    
    class var sharedInstance: DownloadSessionDelegate {
        struct Static {
            static var instance : DownloadSessionDelegate?
            static var token = 0
        }
        
        Static.instance = DownloadSessionDelegate()
        Static.instance!.handlerQueue = [String : CompleteHandlerBlock]()
        
        return Static.instance!
    }
    
    //MARK: session delegate
    func URLSession(session: URLSession, didBecomeInvalidWithError error: NSError?) {
        print("session error: \(error?.localizedDescription).")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("session \(session) has finished the download task \(downloadTask) of URL \(location).")
        
        var title = ""
        var body = ""
        var url = ""
        var newData = false
        do {
            let data = try Data(contentsOf: location)
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let items = responseJSON["items"] as? [[String: String]] {
                    if let lastItem = items.first {
                        if let lastTitle = lastItem["title"] {
                            let previousTitle = UserDefaults.standard.string(forKey: "resultTitle")
                            if previousTitle == nil || lastTitle != previousTitle {
                                title = lastTitle
                                if let lastBody = lastItem["content_html"] {
                                    let cleanBody = lastBody.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                                    body = cleanBody
                                    url = lastItem["url"] ?? ""
                                    UserDefaults.standard.setValue(title, forKey: "resultTitle")
                                    newData = true
                                    print(title, body)
                                }
                            } else {
                                print("not new")
                                // uncomment for debug
                                // UserDefaults.standard.setValue(nil, forKey: "resultTitle")
                            }
                        }
                    }
                }
            }
        } catch { print("Got error") }
        
        if newData {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.categoryIdentifier = "RESULT"
            content.sound = UNNotificationSound.default()
            content.userInfo["url"] = url
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create the request object
            let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)
            
            // Schedule the request
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error: Error?) in
                if let theError = error {
                    print(theError.localizedDescription)
                }
            }
        }
    }
    
    func URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("session \(session) download task \(downloadTask) wrote an additional \(bytesWritten) bytes (total \(totalBytesWritten) bytes) out of an expected \(totalBytesExpectedToWrite) bytes.")
    }
    
    func URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("session \(session) download task \(downloadTask) resumed at offset \(fileOffset) bytes out of an expected \(expectedTotalBytes) bytes.")
    }
    
    func URLSession(session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        if error == nil {
            print("session \(session) download completed")
        } else {
            print("session \(session) download failed with error \(error?.localizedDescription)")
        }
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: URLSession) {
        print("background session \(session) finished events.")
        
        if !(session.configuration.identifier?.isEmpty)! {
            callCompletionHandlerForSession(identifier: session.configuration.identifier)
        }
    }
    
    //MARK: completion handler
    func addCompletionHandler(handler: @escaping CompleteHandlerBlock, identifier: String) {
        handlerQueue[identifier] = handler
    }
    
    func callCompletionHandlerForSession(identifier: String!) {
        let handler : CompleteHandlerBlock = handlerQueue[identifier]!
        handlerQueue.removeValue(forKey: identifier)
        handler()
    }
}
