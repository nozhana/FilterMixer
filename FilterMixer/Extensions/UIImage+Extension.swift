//
//  UIImage+Extension.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/19/25.
//

import UIKit

extension UIImage {
    var inferredCIImage: CIImage? {
        if let ciImage { return ciImage }
        if let cgImage { return CIImage(cgImage: cgImage) }
        return nil
    }
}
