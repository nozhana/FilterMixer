//
//  ImageSharable.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/15/25.
//

import CoreTransferable
import SwiftUI

struct ImageSharable: Transferable {
    let fetchImage: () async -> UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { sharable in
            let image = await sharable.fetchImage()
            return Image(uiImage: image)
        }
    }
}

enum ShareError: Error {
    case failedToSerializeImage
}
