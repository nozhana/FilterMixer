//
//  Array+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/22/1403 AP.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        get { self.indices.contains(index) ? self[index] : nil }
        mutating set {
            if let newValue {
                self[index] = newValue
            } else {
                self.remove(at: index)
            }
        }
    }
}

extension Array where Element: Equatable {
    mutating func removeAll(of element: Element) {
        removeAll(where: { $0 == element })
    }
}
