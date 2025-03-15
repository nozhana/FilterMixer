//
//  Pluralization.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/14/25.
//

import Foundation

func pluralize(_ word: String, count: Int) -> String {
    let localized = String.LocalizationValue("^[\(count) \(word)](inflect: true)")
    return String(AttributedString(localized: localized).characters)
}

infix operator ~~ : MultiplicationPrecedence
func ~~ (lhs: Int, rhs: String) -> String {
    pluralize(rhs, count: lhs)
}
