//
//  Filter.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import Foundation
import GPUImage

enum Filter: String, Identifiable, Hashable, CaseIterable {
    case amatorka
    case bulge
    case falseColor
    case gaussianBlur
    case glassSphere
    case halftone
    case haze
    case iosBlur
    case kuwahara
    case luminance
    case luminanceThreshold
    case missEtitake
    case monochrome
    case motionBlur
    case opacity
    case pinch
    case pixellate
    case polarPixellate
    case polkaDot
    case posterize
    case prewittEdgeDetection
    case rgbAdjustment
    case saturation
    case sepia
    case sharpness
    case sketch
    case sobelEdgeDetection
    case solarize
    case sphereRefraction
    case stretch
    case swirl
    case thresholdSketch
    case thresholdSobelEdgeDetection
    case tiltShift
    case toon
    case vibrance
    case vignette
    case whiteBalance
    case zoomBlur
    
    var stylizedName: String {
        switch self {
        case .iosBlur: "iOS Blur"
        case .rgbAdjustment: "RGB Adjustment"
        default: rawValue.camelCaseToReadableFormatted()
        }
    }
    
    var parameters: [FilterParameter] {
        switch self {
        case .amatorka:
            [.slider(title: "intensity", range: 0...1, stepCount: 10)]
        case .bulge:
            [.position(title: "center"),
             .slider(title: "radius", range: 0...1, stepCount: 20),
             .slider(title: "scale", range: 0...1, stepCount: 20)]
        case .falseColor:
            [.color(title: "firstColor"), .color(title: "secondColor")]
        case .gaussianBlur:
            [.slider(title: "blurRadiusInPixels", range: 0.1...50, customGetter: { operation in
                (operation as! GaussianBlur).blurRadiusInPixels
            }, customSetter: { operation, value in
                (operation as! GaussianBlur).blurRadiusInPixels = value
            })]
        case .glassSphere:
            [.slider(title: "radius", range: 0...1),
             .slider(title: "refractiveIndex", range: 0...1)]
        case .halftone:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1)]
        case .haze:
            [.slider(title: "hazeDistance", range: 0...1),
             .slider(title: "slope", range: 0...1)]
        case .iosBlur:
            [.slider(title: "blurRadiusInPixels", range: 0.01...60, customGetter: { operation in
                (operation as! iOSBlur)
                    .blurRadiusInPixels
            }, customSetter: { operation, value in
                (operation as! iOSBlur)
                    .blurRadiusInPixels = value
            }),
             .slider(title: "saturation", range: 0...1, customGetter: { operation in
                 (operation as! iOSBlur).saturation
             }, customSetter: { operation, value in
                 (operation as! iOSBlur).saturation = value
             }),
             .slider(title: "rangeReductionFactor", range: 0...1, customGetter: { operation in
                 (operation as! iOSBlur).rangeReductionFactor
             }, customSetter: { operation, value in
                 (operation as! iOSBlur).rangeReductionFactor  = value
             })]
        case .kuwahara:
            [.slider(title: "radius", range: 1...10)]
        case .luminance:
            []
        case .luminanceThreshold:
            [.slider(title: "threshold", range: 0...1)]
        case .missEtitake:
            [.slider(title: "intensity", range: 0...1)]
        case .monochrome:
            [.color(title: "filterColor"),
             .slider(title: "intensity", range: 0...1)]
        case .motionBlur:
            [.slider(title: "blurSize", range: 0.01...50, customGetter: { operation in
                (operation as! MotionBlur).blurSize
            }, customSetter: { operation, value in
                (operation as! MotionBlur).blurSize = value
            }),
             .slider(title: "blurAngle", range: 0...180, customGetter: { operation in
                 (operation as! MotionBlur).blurAngle
             }, customSetter: { operation, value in
                 (operation as! MotionBlur).blurAngle = value
             })]
        case .opacity:
            [.slider(title: "opacity", range: 0...1)]
        case .pinch:
            [.position(title: "center"),
             .slider(title: "radius", range: 0...1),
             .slider(title: "scale", range: 0...1)]
        case .pixellate:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1)]
        case .polarPixellate:
            [.size(title: "pixelSize"),
             .position(title: "center")]
        case .polkaDot:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1),
             .slider(title: "dotScaling", range: 0...1)]
        case .posterize:
            [.slider(title: "colorLevels", range: 0...10)]
        case .prewittEdgeDetection:
            [.slider(title: "edgeStrength", range: 0.1...4)]
        case .rgbAdjustment:
            [.slider(title: "redAdjustment", range: 0...1),
             .slider(title: "blueAdjustment", range: 0...1),
             .slider(title: "greenAdjustment", range: 0...1)]
        case .saturation:
            [.slider(title: "saturation", range: 0...1)]
        case .sepia:
            [.slider(title: "intensity", range: 0...1)]
        case .sharpness:
            [.slider(title: "sharpness", range: 0...1)]
        case .sketch:
            [.slider(title: "edgeStrength", range: 0.1...4)]
        case .sobelEdgeDetection:
            [.slider(title: "edgeStrength", range: 0.1...4)]
        case .solarize:
            [.slider(title: "threshold", range: 0...1)]
        case .sphereRefraction:
            [.position(title: "center"),
             .slider(title: "radius", range: 0...1),
             .slider(title: "refractiveIndex", range: 0...1)]
        case .stretch:
            [.position(title: "center")]
        case .swirl:
            [.slider(title: "radius", range: 0...1),
             .slider(title: "angle", range: 0...(.pi)),
             .position(title: "center")]
        case .thresholdSketch:
            [.slider(title: "edgeStrength", range: 0.1...4),
             .slider(title: "threshold", range: 0...1)]
        case .thresholdSobelEdgeDetection:
            [.slider(title: "edgeStrength", range: 0.1...4),
             .slider(title: "threshold", range: 0...1)]
        case .tiltShift:
            []
        case .toon:
            [.slider(title: "threshold", range: 0...1),
             .slider(title: "quantizationLevels", range: 0...20)]
        case .vibrance:
            [.slider(title: "vibrance", range: 0...1)]
        case .vignette:
            [.position(title: "vignetteCenter"),
             .color(title: "vignetteColor"),
             .slider(title: "vignetteStart", range: 0...1),
             .slider(title: "vignetteEnd", range: 0...1)]
        case .whiteBalance:
            [.slider(title: "temperature", range: 4000...6000, customGetter: { operation in
                (operation as! WhiteBalance).temperature
            }, customSetter: { operation, value in
                (operation as! WhiteBalance).temperature = value
            }),
             .slider(title: "tint", range: 0...1)]
        case .zoomBlur:
            [.slider(title: "size", range: 0...40),
             .position(title: "center")]
        }
    }
    
    func makeOperation() -> ImageProcessingOperation {
        switch self {
        case .amatorka:
            AmatorkaFilter()
        case .bulge:
            BulgeDistortion()
        case .falseColor:
            FalseColor()
        case .gaussianBlur:
            GaussianBlur()
        case .glassSphere:
            GlassSphereRefraction()
        case .halftone:
            Halftone()
        case .haze:
            Haze()
        case .iosBlur:
            iOSBlur()
        case .kuwahara:
            KuwaharaFilter()
        case .luminance:
            Luminance()
        case .luminanceThreshold:
            LuminanceThreshold()
        case .missEtitake:
            MissEtikateFilter()
        case .monochrome:
            MonochromeFilter()
        case .motionBlur:
            MotionBlur()
        case .opacity:
            OpacityAdjustment()
        case .pinch:
            PinchDistortion()
        case .pixellate:
            Pixellate()
        case .polarPixellate:
            PolarPixellate()
        case .polkaDot:
            PolkaDot()
        case .posterize:
            Posterize()
        case .prewittEdgeDetection:
            PrewittEdgeDetection()
        case .rgbAdjustment:
            RGBAdjustment()
        case .saturation:
            SaturationAdjustment()
        case .sepia:
            SepiaToneFilter()
        case .sharpness:
            Sharpen()
        case .sketch:
            SketchFilter()
        case .sobelEdgeDetection:
            SobelEdgeDetection()
        case .solarize:
            Solarize()
        case .sphereRefraction:
            SphereRefraction()
        case .stretch:
            StretchDistortion()
        case .swirl:
            SwirlDistortion()
        case .thresholdSketch:
            ThresholdSketchFilter()
        case .thresholdSobelEdgeDetection:
            ThresholdSobelEdgeDetection()
        case .tiltShift:
            TiltShift()
        case .toon:
            ToonFilter()
        case .vibrance:
            Vibrance()
        case .vignette:
            Vignette()
        case .whiteBalance:
            WhiteBalance()
        case .zoomBlur:
            ZoomBlur()
        }
    }
}

extension Identifiable where Self: RawRepresentable {
    var id: RawValue { rawValue }
}

extension Array where Element: Equatable {
    mutating func removeAll(of element: Element) {
        removeAll(where: { $0 == element })
    }
}
