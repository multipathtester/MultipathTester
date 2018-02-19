//
//  ChartEntries.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

enum ChartEntriesType: String {
    case lineChartEntries
    case multiLineChartEntries
    
    var metatype: ChartEntries.Type {
        switch self {
        case .lineChartEntries:
            return LineChartEntries.self
        case .multiLineChartEntries:
            return MultiLineChartEntries.self
        }
    }
}

protocol ChartEntries {
    var type: ChartEntriesType { get }
}
