//
//  BinaryFloatingPoint+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/26/1403 AP.
//

import Foundation

extension BinaryFloatingPoint {
    func interpolated(towards other: Self, amount: some BinaryFloatingPoint) -> Self {
        self + (other - self) * Self(amount)
    }
    
    func normalized(from source: ClosedRange<Self>, to destination: ClosedRange<Self>) -> Self {
        let interpolationAmount = (self - source.lowerBound) / (source.upperBound - source.lowerBound)
        return destination.lowerBound.interpolated(towards: destination.upperBound, amount: interpolationAmount)
    }
}
