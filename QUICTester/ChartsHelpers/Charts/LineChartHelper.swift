//
//  LineChartInitializer.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class LineChartHelper {
    static func initialize(chartView: LineChartView, delegate: ChartViewDelegate?, xValueFormatter: IAxisValueFormatter?) {
        //chartView.noDataText = "Run tests to see SNR evolution"
        
        chartView.delegate = delegate
        
        chartView.chartDescription?.enabled = false
        
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        chartView.highlightPerDragEnabled = true
        
        chartView.backgroundColor = .white
        
        //chartView.legend.enabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .topInside
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        xAxis.labelTextColor = UIColor(red: 255/255, green: 192/255, blue: 56/255, alpha: 1)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 1
        xAxis.valueFormatter = xValueFormatter
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .insideChart
        leftAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        leftAxis.axisMinimum = 0
        //leftAxis.axisMaximum = 170
        leftAxis.yOffset = -9
        leftAxis.labelTextColor = UIColor(red: 255/255, green: 192/255, blue: 56/255, alpha: 1)
        
        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        
        chartView.rightAxis.enabled = false
        
        chartView.legend.form = .line
    }
    
    static func clearData(to chartView: LineChartView) {
        let data = LineChartData()
        data.setValueTextColor(.white)
        data.setValueFont(.systemFont(ofSize: 9, weight: .light))
        
        chartView.data = data
    }
    
    static func setData(to chartView: LineChartView, with values: [ChartDataEntry], label: String, color: UIColor) {
        let set1 = LineChartDataSet(values: values, label: label)
        set1.axisDependency = .left
        set1.setColor(color)
        set1.lineWidth = 1.5
        set1.drawCirclesEnabled = true
        set1.setCircleColor(.black)
        set1.circleRadius = 1
        set1.drawValuesEnabled = false
        set1.fillAlpha = 0.26
        set1.fillColor = color
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        
        
        if chartView.data == nil {
            let data = LineChartData()
            data.setValueTextColor(.white)
            data.setValueFont(.systemFont(ofSize: 9, weight: .light))
            
            chartView.data = data
        }
        chartView.data?.addDataSet(set1)
    }
}
