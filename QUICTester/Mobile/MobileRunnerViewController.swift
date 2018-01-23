//
//  MobileTesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/8/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts
import Quictraffic // TODO remove

class MobileRunnerViewController: UIViewController, ChartViewDelegate {
    @IBOutlet weak var distanceChartView: LineChartView!
    @IBOutlet weak var delaysChartView: LineChartView!
    @IBOutlet weak var userLabel: UILabel!
    
    var tests: [QUICStreamTest] = [QUICStreamTest]()
    var runningTest: QUICStreamTest?
    var startTime: Date = Date()
    var timer: Timer?
    
    var upDelays: [ChartDataEntry] = [ChartDataEntry]()
    var downDelays: [ChartDataEntry] = [ChartDataEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        LineChartHelper.initialize(chartView: distanceChartView, delegate: self, xValueFormatter: DateValueFormatter())
        LineChartHelper.initialize(chartView: delaysChartView, delegate: self, xValueFormatter: DateValueFormatter())
        
        self.updateChartData()
        distanceChartView.animate(xAxisDuration: 0.01 * Double(distanceChartView.data!.entryCount))
        
        tests = [
            QUICStreamTest(maxPathID: 255, ipVer: .any)
        ]
        
        startTests()
    }
    
    func updateChartData() {
        self.setDataCount(Int(3), range: 30)
    }
    
    func setDataCount(_ count: Int, range: UInt32) {
        let now = Date().timeIntervalSince1970
        let minuteSeconds: TimeInterval = 60
        
        let from = now - (Double(count) / 2) * minuteSeconds
        let to = now + (Double(count) / 2) * minuteSeconds
        
        let values2 = stride(from: from, to: to, by: 1).map { (x) -> ChartDataEntry in
            let y = arc4random_uniform(range) + 50
            return ChartDataEntry(x: x, y: Double(y))
        }
        
        LineChartHelper.setData(to: distanceChartView, with: values2, label: "Distance", color: UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
    }
    
    func updateDelays() {
        LineChartHelper.clearData(to: delaysChartView)
        if upDelays.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: upDelays, label: "Delays upload (ms)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        }
        if downDelays.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: downDelays, label: "Delays download (ms)", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        }
        
        delaysChartView.notifyDataSetChanged()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startTests() {
        startTime = Date()
        self.userLabel.text = "Please move away from your WiFi Access Point."
        self.navigationItem.hidesBackButton = true
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(MobileRunnerViewController.getDelays), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        print("We start mobility!")
        upDelays = []
        downDelays = []
        
        DispatchQueue.global(qos: .background).async {
            for t in self.tests {
                self.runningTest = t
                _ = t.run()
            }
            self.runningTest = nil
            self.timer?.invalidate()
            self.timer = nil
            print("Finished!")

            DispatchQueue.main.async {
                self.userLabel.text = "Test completed."
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
    // MARK: Timer function
    @objc func getDelays() {
        // TODO
        guard let streamTest = runningTest else {
            return
        }
        let (newUpDelays, newDownDelays) = streamTest.getProgressDelays()
        let newUpValues = stride(from: 0, to: newUpDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: newUpDelays[x].time, y: Double(newUpDelays[x].delayUs) / 1000.0)
        }
        let newDownValues = stride(from: 0, to: newDownDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: newDownDelays[x].time, y: Double(newDownDelays[x].delayUs) / 1000.0)
        }
        upDelays += newUpValues
        downDelays += newDownValues
        
        self.updateDelays()
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
