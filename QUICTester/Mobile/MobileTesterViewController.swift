//
//  MobileTesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/8/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class MobileTesterViewController: UIViewController, ChartViewDelegate {
    @IBOutlet weak var distanceChartView: LineChartView!
    @IBOutlet weak var snrDelayChartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(UIDevice.current.wifiAddresses)
        print(UIDevice.current.cellularAddresses)
        
        // Do any additional setup after loading the view.
        LineChartHelper.initialize(chartView: distanceChartView, delegate: self, xValueFormatter: DateValueFormatter())
        MultiLineChartHelper.initialize(chartView: snrDelayChartView, delegate: self)
        
        self.updateChartData()
        distanceChartView.animate(xAxisDuration: 0.01 * Double(distanceChartView.data!.entryCount))
        snrDelayChartView.animate(xAxisDuration: 0.01 * Double(snrDelayChartView.data!.entryCount / 2))
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
        MultiLineChartHelper.setData(to: snrDelayChartView, with1: values1, label1: "WiFi SNR (dB)", with2: values2, label2: "Delay (ms)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
