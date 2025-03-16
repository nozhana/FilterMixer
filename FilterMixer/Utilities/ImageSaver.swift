//
//  SaveImage.swift
//  FilterMixer
//
//  Created by Nozhan on 12/26/1403 AP.
//

import UIKit

struct ImageSaver {
    static func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    static func saveToFileSystem(_ image: UIImage) {
        guard let pngData = image.pngData() else { return }
        let tempUrl = FileManager.default.temporaryDirectory.appending(path: "clut.png")
        do {
            try pngData.write(to: tempUrl)
            let controller = UIDocumentPickerViewController(forExporting: [tempUrl])
            UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
        } catch {}
    }
}
