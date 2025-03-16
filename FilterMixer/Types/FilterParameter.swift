//
//  FilterParameter.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/3/25.
//

import Foundation
import SwiftUICore
import GPUImage

enum FilterParameter: Identifiable {
    case slider(title: String, range: ClosedRange<Double>, stepCount: Int? = nil, customGetter: ((ImageProcessingOperation) -> Float)? = nil, customSetter: ((ImageProcessingOperation, Float) -> Void)? = nil)
    case color(title: String, getter: (ImageProcessingOperation) -> GPUImage.Color, setter: (ImageProcessingOperation, GPUImage.Color) -> Void)
    case position(title: String, getter: (ImageProcessingOperation) -> Position, setter: (ImageProcessingOperation, Position) -> Void)
    case size(title: String, getter: (ImageProcessingOperation) -> Size, setter: (ImageProcessingOperation, Size) -> Void)
    
    var id: String {
        switch self {
        case .slider(let title, _, _, _, _), .color(let title, _, _), .position(let title, _, _), .size(let title, _, _):
            title
        }
    }
}
