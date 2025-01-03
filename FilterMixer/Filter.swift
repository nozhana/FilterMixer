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
    case kuwahara
    case pixellate
    case polkaDot
    case posterize
    case sepia
    
    var parameters: [FilterParameter] {
        switch self {
        case .amatorka:
            [.slider(title: "intensity", range: 0...1)]
        case .bulge:
            [.slider(title: "radius", range: 0...1),
             .slider(title: "scale", range: 0...1)]
        case .falseColor:
            [.color(title: "firstColor"), .color(title: "secondColor")]
        case .kuwahara:
            [.slider(title: "radius", range: 1...10)]
        case .pixellate:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1)]
        case .polkaDot:
            [.slider(title: "fractionalWidthOfPixel", range: 0.01...0.1),
             .slider(title: "dotScaling", range: 0...1)]
        case .posterize:
            [.slider(title: "colorLevels", range: 0...10)]
        case .sepia:
            [.slider(title: "intensity", range: 0...1)]
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
        case .kuwahara:
            KuwaharaFilter()
        case .pixellate:
            Pixellate()
        case .polkaDot:
            PolkaDot()
        case .posterize:
            Posterize()
        case .sepia:
            SepiaToneFilter()
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
