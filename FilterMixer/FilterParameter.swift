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
    case color(title: String)
    case position(title: String)
    case size(title: String)
    
    var id: String {
        switch self {
        case .slider(let title, _, _, _, _), .color(let title), .position(let title), .size(let title):
            title
        }
    }
}
