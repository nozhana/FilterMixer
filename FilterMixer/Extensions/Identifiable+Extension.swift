//
//  Identifiable+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/26/1403 AP.
//

import Foundation

extension Identifiable where Self: RawRepresentable {
    var id: RawValue { rawValue }
}
