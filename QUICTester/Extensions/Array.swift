//
//  Array.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 2/5/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

extension Array where Element: FloatingPoint {
    /// Returns the sum of all elements in the array
    func summed() -> Element {
        return self.reduce(0, +)
    }
    
    /// Returns the average of all elements in the array
    func averaged() -> Element {
        return self.isEmpty ? 0 : self.summed() / Element(count)
    }
    
    /// Returns an array of the squared deviations from the mean
    func squaredDeviations() -> [Element] {
        let average = self.averaged()
        return isEmpty ? [] : map{ ($0 - average) * ($0 - average) }
    }
    
    /// Returns the variance of the Array
    func variance() -> Element {
        return self.squaredDeviations().averaged()
    }
    
    /// Returns the standard deviation of the Array
    func standardDeviation() -> Element {
        return sqrt(self.variance())
    }
    
    /// Returns the median of the Array
    func median() -> Element {
        let sortedArray = sorted()
        if count % 2 != 0 {
            return sortedArray[count / 2]
        } else {
            return (sortedArray[count / 2] + sortedArray[count / 2 - 1]) / Element(2)
        }
    }
}
