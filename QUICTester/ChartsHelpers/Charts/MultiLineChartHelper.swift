//
//  MultiLineChartHelper.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class MultiLineChartHelper {
    static func initialize(chartView: LineChartView, delegate: ChartViewDelegate?) {
        chartView.delegate = delegate
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        let l = chartView.legend
        l.form = .line
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.textColor = .black
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 11)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        //leftAxis.axisMaximum = 200
        //leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        
        let rightAxis = chartView.rightAxis
        rightAxis.labelTextColor = .red
        // rightAxis.axisMaximum = 900
        // rightAxis.axisMinimum = -200
        rightAxis.granularityEnabled = true
    }
    
    static func setData(to chartView: LineChartView, with1 values1: [ChartDataEntry], label1: String, with2 values2: [ChartDataEntry], label2: String) {
        let set1 = LineChartDataSet(values: values1, label: label1)
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        set1.drawCirclesEnabled = false
        //set1.setCircleColor(.black)
        set1.lineWidth = 2
        //set1.circleRadius = 3
        set1.fillAlpha = 65/255
        set1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        
        let set2 = LineChartDataSet(values: values2, label: label2)
        set2.axisDependency = .right
        set2.setColor(.red)
        set2.drawCirclesEnabled = false
        //set2.setCircleColor(.black)
        set2.lineWidth = 2
        //set2.circleRadius = 3
        set2.fillAlpha = 65/255
        set2.fillColor = .red
        set2.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set2.drawCircleHoleEnabled = false
        
        let data = LineChartData(dataSets: [set1, set2])
        data.setValueTextColor(.white)
        data.setValueFont(.systemFont(ofSize: 9))
        
        chartView.data = data
    }
}
