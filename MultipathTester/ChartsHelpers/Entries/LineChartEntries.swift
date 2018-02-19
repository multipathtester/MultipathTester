//
//  LineChartEntry.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class LineChartEntries: ChartEntries {
    var type = ChartEntriesType.lineChartEntries
    
    var xLabel: String
    var yLabel: String
    var xValueFormatter: IAxisValueFormatter?
    var data: [ChartDataEntry]
    var dataLabel: String
    
    init(xLabel: String, yLabel: String, data: [ChartDataEntry], dataLabel: String, xValueFormatter: IAxisValueFormatter?) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.data = data
        self.dataLabel = dataLabel
        self.xValueFormatter = xValueFormatter
    }
}
