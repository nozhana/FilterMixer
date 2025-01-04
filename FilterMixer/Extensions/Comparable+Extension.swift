//
//  Comparable+Extension.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import Foundation

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
