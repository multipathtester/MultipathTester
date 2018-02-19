//
//  MultiLineChartEntries.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class MultiLineChartEntries: ChartEntries {
    var type = ChartEntriesType.multiLineChartEntries
    
    var xLabel: String
    var yLabel: String
    var dataLines: [String: [ChartDataEntry]]
    
    init(xLabel: String, yLabel: String, dataLines: [String: [ChartDataEntry]]) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.dataLines = dataLines
    }
}
