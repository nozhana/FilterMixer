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

final class CIBumpDistortionOperation: CIFilterOperation {
    private let extent: CGSize
    
    var scale: Float = 2 {
        didSet {
            setValue(scale, forKey: kCIInputScaleKey)
        }
    }
    
    var radius: Float = 0.5 {
        didSet {
            setValue(radius * Float(min(extent.width, extent.height)), forKey: kCIInputRadiusKey)
        }
    }
    
    var center = Position(0.5, 0.5) {
        didSet {
            let centerVector = CIVector(x: (CGFloat(center.x) * extent.width).clamped(to: 0...extent.width), y: extent.height - (CGFloat(center.y) * extent.height).clamped(to: 0...extent.height))
            setValue(centerVector, forKey: kCIInputCenterKey)
        }
    }
    
    init(extent: CGSize) {
        self.extent = extent
        let filter = CIFilter.bumpDistortion()
        filter.scale = 2
        filter.radius = Float(min(extent.width, extent.height)) / 2
        filter.center = CGPoint(x: extent.width / 2, y: extent.height / 2)
        super.init(filter)
    }
}

final class CIDrosteOperation: CIFilterOperation {
    private let extent: CGSize
    
    var rotation: Angle = .zero {
        didSet {
            setValue(rotation.radians, forKey: "rotation")
        }
    }
    
    var insetPoint1 = Position(0.2, 0.2) {
        didSet {
            let insetVector = CIVector(x: extent.width * CGFloat(insetPoint1.x),
                                       y: extent.height - extent.height * CGFloat(insetPoint1.y))
            setValue(insetVector, forKey: "inputInsetPoint1")
        }
    }
    
    var insetPoint0 = Position(0.8, 0.8) {
        didSet {
            let insetVector = CIVector(x: extent.width * CGFloat(insetPoint0.x),
                                       y: extent.height - extent.height * CGFloat(insetPoint0.y))
            setValue(insetVector, forKey: "inputInsetPoint0")
        }
    }
    
    init(extent: CGSize) {
        self.extent = extent
        let filter = CIFilter.droste()
        filter.insetPoint1 = CGPoint(
            x: extent.width * 0.2,
            y: extent.height * 0.2
        )
        filter.insetPoint0 = CGPoint(
            x: extent.width * 0.8,
            y: extent.height * 0.8
        )
        filter.periodicity = 1
        filter.rotation = 0
        filter.strands = 1
        filter.zoom = 1
        super.init(filter)
    }
}

final class CIGlassLozengeOperation: CIFilterOperation {
    private let extent: CGSize
    
    var point0 = Position(0.2, 0.8) {
        didSet {
            let pointVector = CIVector(x: extent.width * CGFloat(point0.x),
                                       y: extent.height - extent.height * CGFloat(point0.y))
            setValue(pointVector, forKey: "inputPoint1")
        }
    }
    
    var point1 = Position(0.8, 0.2) {
        didSet {
            let pointVector = CIVector(x: extent.width * CGFloat(point1.x),
                                       y: extent.height - extent.height * CGFloat(point1.y))
            setValue(pointVector, forKey: "inputPoint0")
        }
    }
    
    init(extent: CGSize) {
        self.extent = extent
        let filter = CIFilter.glassLozenge()
        filter.point1 = CGPoint(x: 0.2 * extent.width, y: 0.2 * extent.height)
        filter.point0 = CGPoint(x: 0.8 * extent.width, y: 0.8 * extent.height)
        filter.refraction = 1.7
        filter.radius = 50
        super.init(filter)
    }
}
