//
//  CaseIterable+Extension.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/19/25.
//

import Foundation

extension CaseIterable where Self: Equatable {
    var next: Self {
        let allCases = Self.allCases
        let indexOfSelf = allCases.firstIndex(of: self)!
        var nextIndex = allCases.index(after: indexOfSelf)
        if !allCases.indices.contains(nextIndex) {
            nextIndex = allCases.startIndex
        }
        return allCases[nextIndex]
    }
    
    var previous: Self {
        let allCases = Self.allCases
        let indexOfSelf = allCases.firstIndex(of: self)!
        var previousIndex = allCases.index(indexOfSelf, offsetBy: -1)
        if !allCases.indices.contains(previousIndex) {
            let lastIndex = allCases.index(allCases.endIndex, offsetBy: -1)
            previousIndex = lastIndex
        }
        return allCases[previousIndex]
    }
    
    mutating func cycle(reverse: Bool = false) {
        self = reverse ? previous : next
    }
}
