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
    @IBOutlet weak var snrDelayChartView: LineChartView!
    @IBOutlet weak var delaysChartView: LineChartView!
    
    var tests: [Test] = [Test]()
    var startTime: Date = Date()
    var timer: Timer?
    
    var upDelays: [DelayData] = [DelayData]()
    var downDelays: [DelayData] = [DelayData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        LineChartHelper.initialize(chartView: distanceChartView, delegate: self, xValueFormatter: DateValueFormatter())
        //MultiLineChartHelper.initialize(chartView: snrDelayChartView, delegate: self)
        LineChartHelper.initialize(chartView: delaysChartView, delegate: self, xValueFormatter: DateValueFormatter())
        
        self.updateChartData()
        distanceChartView.animate(xAxisDuration: 0.01 * Double(distanceChartView.data!.entryCount))
        //snrDelayChartView.animate(xAxisDuration: 0.01 * Double(snrDelayChartView.data!.entryCount / 2))
        
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
        
        let values1 = stride(from: from, to: to, by: 1).map { (x) -> ChartDataEntry in
            let val = ((from - x) * 30.0 / (to - from)) - 60
            return ChartDataEntry(x: x, y: val)
        }
        
        let values2 = stride(from: from, to: to, by: 1).map { (x) -> ChartDataEntry in
            let y = arc4random_uniform(range) + 50
            return ChartDataEntry(x: x, y: Double(y))
        }
        
        LineChartHelper.setData(to: distanceChartView, with: values2, label: "Distance", color: UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        //MultiLineChartHelper.setData(to: snrDelayChartView, with1: values1, label1: "WiFi SNR (dB)", with2: values2, label2: "Delay (ms)")
    }
    
    func updateDelays() {
        let upValues = stride(from: 0, to: upDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: upDelays[x].time, y: Double(upDelays[x].delayUs) / 1000.0)
        }
        let downValues = stride(from: 0, to: downDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: downDelays[x].time, y: Double(downDelays[x].delayUs) / 1000.0)
        }
        LineChartHelper.clearData(to: delaysChartView)
        if upValues.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: upValues, label: "Delays upload (ms)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        }
        if downValues.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: downValues, label: "Delays download (ms)", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        }
        
        delaysChartView.notifyDataSetChanged()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startTests() {
        startTime = Date()
        self.navigationItem.hidesBackButton = true
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(MobileRunnerViewController.getDelays), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        print("We start mobility!")
        upDelays = []
        downDelays = []
        
        DispatchQueue.global(qos: .background).async {
            for t in self.tests {
                t.run()
            }
            self.timer?.invalidate()
            self.timer = nil
            print("Finished!")

            DispatchQueue.main.async {
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
    // MARK: Timer function
    @objc func getDelays() {
        // TODO
        let delaysStr = QuictrafficGetStreamProgressResult()
        let lines = delaysStr!.components(separatedBy: .newlines)
        if lines.count < 2 {
            return
        }
        let splitted_up_line = lines[0].components(separatedBy: " ")
        let up_count = Int(splitted_up_line[1])!
        if up_count > 0 {
            for i in 1...up_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                upDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        let splitted_down_line = lines[up_count+1].components(separatedBy: " ")
        let down_count = Int(splitted_down_line[1])!
        if down_count > 0 {
            for i in up_count+2...up_count+1+down_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                downDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        
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
