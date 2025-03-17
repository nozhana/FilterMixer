//
//  Filter.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import Foundation
import GPUImage

enum Filter: String, Identifiable, Hashable, CaseIterable, Codable {
    case adaptiveThreshold
    case brightness
    case bulge
    case contrast
    case exposure
    case falseColor
    case gaussianBlur
    case glassSphere
    case halftone
    case haze
    case highlightAndShadowTint
    case hueRotation
    case iosBlur
    case kuwahara
    case levelsAdjustment
    case luminance
    case luminanceThreshold
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
    
    // Basic lookup filters
    case amatorka
    case missEtitake
    case softElegance
    case twoStrip
    case threeStrip
    case bleachBypass
    case candlelight
    case crispWarm
    case crispWinter
    case dropBlues
    case edgyAmber
    case fallColors
    case filmstock50
    case foggyNight
    case fujiEternaFuji3510
    case fujiEternaKodak2395
    case fujiF125Kodak2393
    case fujiF125Kodak2395
    case fujiReala500DKodak2393
    case futuristicBleak
    case horrorBlue
    case kodak5205Fuji3510
    case kodak5218Kodak2383
    case kodak5218Kodak2395
    case lateSunset
    case moonlight
    case nightFromDay
    case softWarming
    case tealOrangePlusContrast
    case tensionGreen
    
    // Custom lookups
    case oldPhoto1
    case oldPhoto15
    case cyberpunk3
    case f4
    
    // CIFilters
    case ciGaussianBlur
    case ciUnsharpMask
    case ciHueAdjust
    case ciGloom
    case ciComicEffect
    case ciBokehEffect
    case ciPixellate
    case ciHexagonalPixellate
    
    var stylizedName: String {
        switch self {
        case .iosBlur: "iOS Blur"
        case .rgbAdjustment: "RGB Adjustment"
        // Basic Lookup filters
        case .filmstock50: "Filmstock 50"
        case .fujiEternaFuji3510: "Fuji Eterna Fuji 3510"
        case .fujiEternaKodak2395: "Fuji Eterna Kodak 2395"
        case .fujiF125Kodak2393: "Fuji F125 Kodak 2393"
        case .fujiF125Kodak2395: "Fuji F125 Kodak 2395"
        case .fujiReala500DKodak2393: "Fuji Reala 500D Kodak 2393"
        case .kodak5205Fuji3510: "Kodak 5205 Fuji 3510"
        case .kodak5218Kodak2383: "Kodak 5218 Kodak 2383"
        case .kodak5218Kodak2395: "Kodak 5218 Kodak 2395"
        case .oldPhoto1: "Old Photo 1"
        case .oldPhoto15: "Old Photo 15"
        case .cyberpunk3: "Cyberpunk 3"
        default: rawValue.filterStylizedNameFormatted
        }
    }
    
    var isLookupFilter: Bool {
        [.amatorka,
         .missEtitake,
         .softElegance,
         .twoStrip,
         .threeStrip,
         .bleachBypass,
         .candlelight,
         .crispWarm,
         .crispWinter,
         .dropBlues,
         .edgyAmber,
         .fallColors,
         .filmstock50,
         .foggyNight,
         .fujiEternaFuji3510,
         .fujiEternaKodak2395,
         .fujiF125Kodak2393,
         .fujiF125Kodak2395,
         .fujiReala500DKodak2393,
         .futuristicBleak,
         .horrorBlue,
         .kodak5205Fuji3510,
         .kodak5218Kodak2383,
         .kodak5218Kodak2395,
         .lateSunset,
         .moonlight,
         .nightFromDay,
         .softWarming,
         .tealOrangePlusContrast,
         .tensionGreen,
         .oldPhoto1,
         .oldPhoto15,
         .cyberpunk3,
         .f4]
            .contains(self)
    }
    
    var isCiFilterOperation: Bool {
        stylizedName.starts(with: "CI")
    }
    
    static var genericFilters: [Filter] {
        allCases.filter { !$0.isLookupFilter && !$0.isCiFilterOperation }
    }
    
    static var lookupFilters: [Filter] {
        allCases.filter(\.isLookupFilter)
    }
    
    static var ciFilters: [Filter] {
        allCases.filter(\.isCiFilterOperation)
    }
    
    var parameters: [FilterParameter] {
        switch self {
        case .adaptiveThreshold:
            [.slider(title: "blurRadiusInPixels", range: 1...30, stepCount: 60,
                     customGetter: { ($0 as? AdaptiveThreshold)?.blurRadiusInPixels ?? 2 },
                     customSetter: { ($0 as? AdaptiveThreshold)?.blurRadiusInPixels = $1 })]
        case .brightness:
            [.slider(title: "brightness", range: 0...1)]
        case .bulge:
            [.position(title: "center") { ($0 as! BulgeDistortion).center } setter: { ($0 as! BulgeDistortion).center = $1 },
             .slider(title: "radius", range: 0...1, stepCount: 20),
             .slider(title: "scale", range: 0...1, stepCount: 20)]
        case .contrast:
            [.slider(title: "contrast", range: 0...2)]
        case .exposure:
            [.slider(title: "exposure", range: -1...1)]
        case .falseColor:
            [.color(title: "firstColor") { ($0 as! FalseColor).firstColor } setter: { ($0 as! FalseColor).firstColor = $1 },
             .color(title: "secondColor") { ($0 as! FalseColor).secondColor } setter: { ($0 as! FalseColor).secondColor = $1 }]
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
        case .highlightAndShadowTint:
            [.slider(title: "highlightTintIntensity", range: 0...1),
             .color(title: "highlightTintColor") { ($0 as! HighlightAndShadowTint).highlightTintColor } setter: { ($0 as! HighlightAndShadowTint).highlightTintColor = $1 },
             .slider(title: "shadowTintIntensity", range: 0...1),
             .color(title: "shadowTintColor") { ($0 as! HighlightAndShadowTint).shadowTintColor } setter: { ($0 as! HighlightAndShadowTint).shadowTintColor = $1 }]
        case .hueRotation:
            [.slider(title: "hue", range: 0...180, stepCount: 90, customGetter: { ($0 as! HueAdjustment).hue.normalized(from: (90 - .pi/2)...(90 + .pi/2), to: 0...180).rounded() }, customSetter: { ($0 as! HueAdjustment).hue = $1.rounded().normalized(from: 0...180, to: (90 - .pi/2)...(90 + .pi/2)) })]
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
        case .levelsAdjustment:
            [.color(title: "minimum") { ($0 as! LevelsAdjustment).minimum } setter: { ($0 as! LevelsAdjustment).minimum = $1 },
             .color(title: "middle") { ($0 as! LevelsAdjustment).middle } setter: { ($0 as! LevelsAdjustment).middle = $1 },
             .color(title: "maximum") { ($0 as! LevelsAdjustment).maximum } setter: { ($0 as! LevelsAdjustment).maximum = $1 }]
        case .luminance:
            []
        case .luminanceThreshold:
            [.slider(title: "threshold", range: 0...1)]
        case .monochrome:
            [.color(title: "filterColor") { ($0 as! MonochromeFilter).color } setter: { ($0 as! MonochromeFilter).color = $1 },
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
            [.position(title: "center") { ($0 as! PinchDistortion).center } setter: { ($0 as! PinchDistortion).center = $1 },
             .slider(title: "radius", range: 0...1),
             .slider(title: "scale", range: 0...1)]
        case .pixellate:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1)]
        case .polarPixellate:
            [.size(title: "pixelSize") { ($0 as! PolarPixellate).pixelSize } setter: { ($0 as! PolarPixellate).pixelSize = $1 },
             .position(title: "center") { ($0 as! PolarPixellate).center } setter: { ($0 as! PolarPixellate).center = $1 }]
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
            [.position(title: "center") { ($0 as! SphereRefraction).center } setter: { ($0 as! SphereRefraction).center = $1 },
             .slider(title: "radius", range: 0...1),
             .slider(title: "refractiveIndex", range: 0...1)]
        case .stretch:
            [.position(title: "center") { ($0 as! StretchDistortion).center } setter: { ($0 as! StretchDistortion).center = $1 }]
        case .swirl:
            [.slider(title: "radius", range: 0...1),
             .slider(title: "angle", range: 0...(.pi)),
             .position(title: "center") { ($0 as! SwirlDistortion).center } setter: { ($0 as! SwirlDistortion).center = $1 }]
        case .thresholdSketch:
            [.slider(title: "edgeStrength", range: 0.1...4),
             .slider(title: "threshold", range: 0...1)]
        case .thresholdSobelEdgeDetection:
            [.slider(title: "edgeStrength", range: 0.1...4),
             .slider(title: "threshold", range: 0...1)]
        case .tiltShift:
            [.slider(title: "blurRadiusInPixels", range: 1...50, stepCount: 49, customGetter: { ($0 as! TiltShift).blurRadiusInPixels }, customSetter: { ($0 as! TiltShift).blurRadiusInPixels = $1 }),
             .slider(title: "topFocusLevel", range: 0...1, stepCount: 20, customGetter: { ($0 as! TiltShift).topFocusLevel }, customSetter: { ($0 as! TiltShift).topFocusLevel = $1 }),
             .slider(title: "bottomFocusLevel", range: 0...1, stepCount: 20, customGetter: { ($0 as! TiltShift).bottomFocusLevel }, customSetter: { ($0 as! TiltShift).bottomFocusLevel = $1 }),
             .slider(title: "focusFallOffRate", range: 0...1, stepCount: 20, customGetter: { ($0 as! TiltShift).focusFallOffRate }, customSetter: { ($0 as! TiltShift).focusFallOffRate = $1 })]
        case .toon:
            [.slider(title: "threshold", range: 0...1),
             .slider(title: "quantizationLevels", range: 0...20)]
        case .vibrance:
            [.slider(title: "vibrance", range: 0...1)]
        case .vignette:
            [.position(title: "vignetteCenter") { ($0 as! Vignette).center } setter: { ($0 as! Vignette).center = $1 },
             .color(title: "vignetteColor") { ($0 as! Vignette).color } setter: { ($0 as! Vignette).color = $1 },
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
             .position(title: "blurCenter") { ($0 as! ZoomBlur).blurCenter } setter: { ($0 as! ZoomBlur).blurCenter = $1 }]
        case .ciGaussianBlur:
            [.slider(title: "radius", range: 1...60, customGetter: { ($0 as! CIGaussianBlurOperation).radius }, customSetter: { ($0 as! CIGaussianBlurOperation).radius = $1 })]
        case .ciUnsharpMask:
            [.slider(title: "radius", range: 0...20, customGetter: { ($0 as! CIUnsharpMaskOperation).radius }, customSetter: { ($0 as! CIUnsharpMaskOperation).radius = $1 }),
             .slider(title: "intensity", range: 0...20, customGetter: { ($0 as! CIUnsharpMaskOperation).intensity }, customSetter: { ($0 as! CIUnsharpMaskOperation).intensity = $1 })]
        case .ciHueAdjust:
            [.slider(title: "angle", range: 0...180, customGetter: { Float(($0 as! CIHueAdjustOperation).angle.degrees) }, customSetter: { ($0 as! CIHueAdjustOperation).angle = .degrees(Double($1)) })]
        case .ciGloom:
            []
        case .ciComicEffect:
            []
        case .ciBokehEffect:
            [.slider(title: "ringSize", range: 0.1...5),
             .slider(title: "ringAmount", range: 0...10),
             .slider(title: "softness", range: 0...10),
             .slider(title: "radius", range: 1...60)]
        case .ciPixellate:
            [.slider(title: "scale", range: 0.1...60)]
        case .ciHexagonalPixellate:
            [.slider(title: "scale", range: 0.1...60)]
        default: isLookupFilter ? [.slider(title: "intensity", range: 0...1, stepCount: 50)] : []
        }
    }
    
    func makeOperation() -> ImageProcessingOperation {
        switch self {
        case .adaptiveThreshold: AdaptiveThreshold()
        case .brightness: BrightnessAdjustment()
        case .bulge: BulgeDistortion()
        case .contrast: ContrastAdjustment()
        case .exposure: ExposureAdjustment()
        case .falseColor: FalseColor()
        case .gaussianBlur: GaussianBlur()
        case .glassSphere: GlassSphereRefraction()
        case .halftone: Halftone()
        case .haze: Haze()
        case .highlightAndShadowTint: HighlightAndShadowTint()
        case .hueRotation: HueAdjustment()
        case .iosBlur: iOSBlur()
        case .kuwahara: KuwaharaFilter()
        case .levelsAdjustment: LevelsAdjustment()
        case .luminance: Luminance()
        case .luminanceThreshold: LuminanceThreshold()
        case .monochrome: MonochromeFilter()
        case .motionBlur: MotionBlur()
        case .opacity: OpacityAdjustment()
        case .pinch: PinchDistortion()
        case .pixellate: Pixellate()
        case .polarPixellate: PolarPixellate()
        case .polkaDot: PolkaDot()
        case .posterize: Posterize()
        case .prewittEdgeDetection: PrewittEdgeDetection()
        case .rgbAdjustment: RGBAdjustment()
        case .saturation: SaturationAdjustment()
        case .sepia: SepiaToneFilter()
        case .sharpness: Sharpen()
        case .sketch: SketchFilter()
        case .sobelEdgeDetection: SobelEdgeDetection()
        case .solarize: Solarize()
        case .sphereRefraction: SphereRefraction()
        case .stretch: StretchDistortion()
        case .swirl: SwirlDistortion()
        case .thresholdSketch: ThresholdSketchFilter()
        case .thresholdSobelEdgeDetection: ThresholdSobelEdgeDetection()
        case .tiltShift: TiltShift()
        case .toon: ToonFilter()
        case .vibrance: Vibrance()
        case .vignette: Vignette()
        case .whiteBalance: WhiteBalance()
        case .zoomBlur: ZoomBlur()
        // Basic lookup filters
        case .amatorka: AmatorkaFilter()
        case .missEtitake: MissEtikateFilter()
        case .softElegance: SoftElegance()
        case .twoStrip: LookupFilter("lookup_2strip")
        case .threeStrip: LookupFilter("lookup_3strip")
        case .bleachBypass: LookupFilter("lookup_bleach_bypass")
        case .candlelight: LookupFilter("lookup_candlelight")
        case .crispWarm: LookupFilter("lookup_crisp_warm")
        case .crispWinter: LookupFilter("lookup_crisp_winter")
        case .dropBlues: LookupFilter("lookup_drop_blues")
        case .edgyAmber: LookupFilter("lookup_edgy_amber")
        case .fallColors: LookupFilter("lookup_fall_colors")
        case .filmstock50: LookupFilter("lookup_filmstock_50")
        case .foggyNight: LookupFilter("lookup_foggy_night")
        case .fujiEternaFuji3510: LookupFilter("lookup_fuji_eterna_fuji_3510")
        case .fujiEternaKodak2395: LookupFilter("lookup_fuji_eterna_kodak_2395")
        case .fujiF125Kodak2393: LookupFilter("lookup_fuji_f125_kodak_2393")
        case .fujiF125Kodak2395: LookupFilter("lookup_fuji_f125_kodak_2395")
        case .fujiReala500DKodak2393: LookupFilter("lookup_fuji_reala_500d_kodak_2393")
        case .futuristicBleak: LookupFilter("lookup_futuristic_bleak")
        case .horrorBlue: LookupFilter("lookup_horror_blue")
        case .kodak5205Fuji3510: LookupFilter("lookup_kodak_5205_fuji_3510")
        case .kodak5218Kodak2383: LookupFilter("lookup_kodak_5218_kodak_2383")
        case .kodak5218Kodak2395: LookupFilter("lookup_kodak_5218_kodak_2395")
        case .lateSunset: LookupFilter("lookup_late_sunset")
        case .moonlight: LookupFilter("lookup_moonlight")
        case .nightFromDay: LookupFilter("lookup_night_from_day")
        case .softWarming: LookupFilter("lookup_soft_warming")
        case .tealOrangePlusContrast: LookupFilter("lookup_teal_orange_plus_contrast")
        case .tensionGreen: LookupFilter("lookup_tension_green")
        case .oldPhoto1: LookupFilter("lookup_old_photo_1")
        case .oldPhoto15: LookupFilter("lookup_old_photo_15")
        case .cyberpunk3: LookupFilter("lookup_cyberpunk_3")
        case .f4: LookupFilter("lookup_f4")
        // CIFilterOperations
        case .ciGaussianBlur: CIGaussianBlurOperation()
        case .ciUnsharpMask: CIUnsharpMaskOperation()
        case .ciHueAdjust: CIHueAdjustOperation()
        case .ciGloom: CIFilterOperation(.gloom())
        case .ciComicEffect: CIFilterOperation(.comicEffect())
        case .ciBokehEffect: CIFilterOperation(.bokehBlur())
        case .ciPixellate: CIFilterOperation(.pixellate())
        case .ciHexagonalPixellate: CIFilterOperation(.hexagonalPixellate())
        }
    }
}
