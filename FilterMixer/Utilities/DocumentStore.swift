//
//  DocumentStore.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/18/25.
//

import SwiftUI

final class DocumentStore {
    private init() {}
    static let shared = DocumentStore()
    
    private let fileManager = FileManager.default
    private(set) lazy var customLookupsDirectory: URL = {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: "CustomLookups", directoryHint: .isDirectory) else {
            fatalError("Failed to create custom lookups directory URL")
        }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    
    func saveLookupImage(_ image: UIImage, name: String? = nil) {
        guard let pngData = image.pngData() else {
            return
        }
        let url: URL
        if let name {
            url = customLookupsDirectory.appending(path: "\(name).png")
        } else {
            let allUrls = getAllLookupImageURLs()
            var count = allUrls.count
            while allUrls.map(\.lastPathComponent).contains("image\(count).png") {
                count += 1
            }
            
            url = customLookupsDirectory.appending(path: "image\(count).png")
        }
        try? pngData.write(to: url)
    }
    
    func deleteLookupImage(name: String) {
        let strippedName = name.hasSuffix(".png") ? String(name.prefix(upTo: name.index(name.endIndex, offsetBy: -4))) : name
        try? fileManager.removeItem(at: customLookupsDirectory.appending(path: "\(strippedName).png"))
    }
    
    func getAllLookupImageURLs() -> [URL] {
        (try? fileManager.contentsOfDirectory(at: customLookupsDirectory, includingPropertiesForKeys: [.isRegularFileKey])) ?? []
    }
    
    func getAllLookupImages() -> [UIImage] {
        getAllLookupImageURLs().compactMap { url in
            guard let data = fileManager.contents(atPath: url.absoluteString),
                  let image = UIImage(data: data) else { return nil }
            return image
        }
    }
    
    func getLookupImageURL(name: String) -> URL? {
        getAllLookupImageURLs().first(where: { $0.lastPathComponent == "\(name).png" })
    }
    
    func getLookupImage(name: String) -> UIImage? {
        guard let url = getLookupImageURL(name: name),
              let data = fileManager.contents(atPath: url.absoluteString),
              let image = UIImage(data: data) else { return nil }
        return image
    }
}
