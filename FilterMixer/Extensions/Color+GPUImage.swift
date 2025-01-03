//
//  Color+GPUImage.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/3/25.
//

import struct GPUImage.Color
import SwiftUI
import class UIKit.UIColor

extension SwiftUI.Color {
    var gpuImageColor: GPUImage.Color {
        let components = UIColor(self).cgColor.components!.map(Float.init)
        
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components[3]
        
        return .init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension GPUImage.Color {
    var swiftUiColor: SwiftUI.Color {
        let red = Double(redComponent)
        let green = Double(greenComponent)
        let blue = Double(blueComponent)
        let opacity = Double(alphaComponent)
        
        return .init(red: red, green: green, blue: blue, opacity: opacity)
    }
}
