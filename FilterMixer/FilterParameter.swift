//
//  FilterParameter.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/3/25.
//

import Foundation

enum FilterParameter: Identifiable {
    case slider(title: String, range: ClosedRange<Double>)
    case color(title: String)
    
    var id: String {
        switch self {
        case .slider(let title, _):
            title
        case .color(let title):
            title
        }
    }
}
