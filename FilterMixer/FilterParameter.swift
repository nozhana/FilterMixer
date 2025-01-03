//
//  FilterParameter.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/3/25.
//

import Foundation
import SwiftUICore

enum FilterParameter: Identifiable {
    case slider(title: String, range: ClosedRange<Double>)
    case color(title: String)
    case position(title: String)
    
    var id: String {
        switch self {
        case .slider(let title, _), .color(let title), .position(let title):
            title
        }
    }
}
