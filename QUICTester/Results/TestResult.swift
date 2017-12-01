//
//  TestResults.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
protocol TestResult {
    func getDescription() -> String
    func getResult() -> String
}
