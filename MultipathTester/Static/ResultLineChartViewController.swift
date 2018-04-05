//
//  ResultLineChartViewController.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 4/5/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class ResultLineChartViewController: UIViewController, ChartViewDelegate {
    @IBOutlet weak var yAxisLabel: UILabel!
    @IBOutlet weak var chart: LineChartView!
    @IBOutlet weak var xAxisLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateChart(chartEntries: ChartEntries) {
        LineChartHelper.clearData(to: chart)
        switch chartEntries.type {
        case .lineChartEntries:
            let lineChartEntries = chartEntries as! LineChartEntries
            LineChartHelper.initialize(chartView: chart, delegate: self, xValueFormatter: lineChartEntries.xValueFormatter)
            LineChartHelper.setData(to: chart, with: lineChartEntries.data, label: lineChartEntries.dataLabel, color: UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1), mode: .linear)
            xAxisLabel.text = lineChartEntries.xLabel
            // Rotate Y axis
            yAxisLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            yAxisLabel.text = lineChartEntries.yLabel
        case .multiLineChartEntries:
            // FIXME BIG BUG
            let colors = [
                UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1),
                UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
                UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
                UIColor(red: 229/255, green: 51/255, blue: 181/255, alpha: 1),
                UIColor(red: 0.5, green: 0.9, blue: 0.3, alpha: 1),
                UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
                UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1),
                UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
                UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
                UIColor(red: 229/255, green: 51/255, blue: 181/255, alpha: 1),
                UIColor(red: 0.5, green: 0.9, blue: 0.3, alpha: 1),
                UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
                UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1),
                UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
                UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1),
                UIColor(red: 229/255, green: 51/255, blue: 181/255, alpha: 1),
                UIColor(red: 0.5, green: 0.9, blue: 0.3, alpha: 1),
                UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1),
                ]
            let multiLineChartEntries = chartEntries as! MultiLineChartEntries
            LineChartHelper.initialize(chartView: chart, delegate: self, xValueFormatter: DateValueFormatter())
            for (index, k) in multiLineChartEntries.dataLines.keys.enumerated() {
                LineChartHelper.setData(to: chart, with: multiLineChartEntries.dataLines[k]!, label: k, color: colors[index], mode: .linear)
            }
            xAxisLabel.text = multiLineChartEntries.xLabel
            // Rotate Y axis
            yAxisLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            yAxisLabel.text = multiLineChartEntries.yLabel
        }
        chart.notifyDataSetChanged()
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
