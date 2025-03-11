//
//  GPUImage+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/21/1403 AP.
//

import Foundation
import GPUImage

extension LookupFilter {
    convenience init(_ imageName: String) {
        self.init()
        ({ lookupImage = PictureInput(imageName: "\(imageName).png") })()
        ({ intensity = 1 })()
    }
}
