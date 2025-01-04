//
//  CGSize+Size.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import Foundation
import GPUImage

extension CGSize {
    var toGpuImageSize: Size {
        Size(width: Float(width), height: Float(height))
    }
}
