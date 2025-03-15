//
//  UnitPoint+Position.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import Foundation
import struct GPUImage.Position
import struct SwiftUI.UnitPoint

extension UnitPoint {
    var toGpuImagePosition: Position {
        Position(Float(x), Float(y))
    }
}

extension Position {
    var toUnitPoint: UnitPoint {
        UnitPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
