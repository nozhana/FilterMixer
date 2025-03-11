//
//  View+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/20/1403 AP.
//

import SwiftUI

extension View {
    @ViewBuilder
    func evaluating(_ condition: Bool, configure: @escaping (Self) -> some View) -> some View {
        if condition {
            configure(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func unwrapping<T>(_ optional: T?, configure: @escaping (Self, T) -> some View) -> some View {
        if let unwrapped = optional {
            configure(self, unwrapped)
        } else {
            self
        }
    }
}
