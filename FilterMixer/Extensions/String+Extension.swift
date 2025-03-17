//
//  String+Extension.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/3/25.
//

import Foundation

extension String {
    func camelCaseToReadableFormatted() -> String {
        reduce(into: "") { partialResult, element in
            if element.isUppercase {
                partialResult.append(" ")
                partialResult.append(element)
            } else {
                partialResult.append(element)
            }
        }
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .capitalized
    }
    
    var filterStylizedNameFormatted: String {
        if starts(with: "ci") {
            "CI " + String(dropFirst(2)).camelCaseToReadableFormatted()
        } else {
            camelCaseToReadableFormatted()
        }
    }
}
