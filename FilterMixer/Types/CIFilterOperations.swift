//
//  CIFilterOperations.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/18/25.
//

import CoreImage.CIFilterBuiltins
import GPUImage
import SwiftUI

final class CIGaussianBlurOperation: CIFilterOperation {
    var radius: Float = 20 {
        didSet {
            setValue(radius, forKey: kCIInputRadiusKey)
        }
    }
    
    init() {
        let filter = CIFilter.gaussianBlur()
        filter.radius = radius
        super.init(filter)
    }
}

final class CIUnsharpMaskOperation: CIFilterOperation {
    var radius: Float = 5 {
        didSet {
            setValue(radius, forKey: kCIInputRadiusKey)
        }
    }
    
    var intensity: Float = 2.5 {
        didSet {
            setValue(intensity, forKey: kCIInputIntensityKey)
        }
    }
    
    init() {
        let filter = CIFilter.unsharpMask()
        filter.radius = radius
        filter.intensity = intensity
        super.init(filter)
    }
}

final class CIHueAdjustOperation: CIFilterOperation {
    var angle: Angle = .zero {
        didSet {
            setValue(Float(angle.radians), forKey: kCIInputAngleKey)
        }
    }
    
    init() {
        let filter = CIFilter.hueAdjust()
        filter.angle = Float(angle.radians)
        super.init(filter)
    }
}
