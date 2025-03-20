//
//  CIFilterStackOperation.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/19/25.
//

import CoreImage
import Foundation
import GPUImage
import MetalKit
import OSLog

class CIFilterStackOperation: ImageProcessingOperation {
    var maximumInputs: UInt = 1
    var relayOnwards = false
    var synchronous = true
    
    let sources = SourceContainer()
    let targets = TargetContainer()
    
    private let logger = Logger(subsystem: kCFBundleIdentifierKey as String, category: "CIFilterOperation")
    
    private let context = CIContext(mtlDevice: sharedMetalRenderingDevice.device)
    private let filteringQueue = DispatchQueue(label: "CIFilterOperation.filteringQueue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem)
    private let lock = NSRecursiveLock()
    
    let ciFilters: [CIFilter]
    
    private var internalTexture: MTLTexture?
    private(set) var inputExtent: CGRect?
    
    init(_ ciFilters: [CIFilter], relayOnwards: Bool = true, synchronous: Bool = true) {
        self.ciFilters = ciFilters
        self.relayOnwards = relayOnwards
        self.synchronous = synchronous
    }
    
    func processOutputImage() {
        filteringQueue.async { [weak self] in
            self?._processOutputImage()
        }
    }
    
    private func _processOutputImage() {
        guard var outputImage = ciFilters.reduce(into: CIImage?.none, {
            if let input = $0 {
                $1.setValue(input, forKey: kCIInputImageKey)
            }
            $0 = $1.outputImage
        }) else {
            logger.error("\(#function) - Failed to get output image from CIFilter")
            return
        }
        
        if let inputExtent {
            outputImage = outputImage.cropped(to: inputExtent)
        }
        
        guard let cgImage = outputImage.cgImage ?? context.createCGImage(outputImage,
                                                                         from: outputImage.extent,
                                                                         format: .BGRA8,
                                                                         colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            logger.error("\(#function) - Failed to create CGImage from output image")
            return
        }
        let textureLoader = MTKTextureLoader(device: sharedMetalRenderingDevice.device)
        
        if let metalTexture = outputImage.metalTexture {
            processOutputTexture(metalTexture)
            return
        }
        
        if synchronous {
            do {
                let metalTexture = try textureLoader.newTexture(cgImage: cgImage, options: [.SRGB: false])
                processOutputTexture(metalTexture)
            } catch {
                logger.error("\(#function) - Failed to create texture from CGImage: \(error)")
            }
        } else {
            textureLoader.newTexture(cgImage: cgImage, options: [.SRGB: false]) { [weak self] metalTexture, error in
                if let error {
                    self?.logger.error("\(#function) - Failed to create texture from CGImage: \(error)")
                }
                
                if let metalTexture {
                    self?.processOutputTexture(metalTexture)
                }
            }
        }
    }
    
    private func processOutputTexture(_ metalTexture: MTLTexture) {
        if relayOnwards {
            let texture = Texture(orientation: .portrait, texture: metalTexture)
            updateTargetsWithTexture(texture)
        } else {
            lock.withLock {
                self.internalTexture = metalTexture
            }
        }
    }
    
    func processTexture(_ inputTexture: Texture) {
        filteringQueue.async { [weak self] in
            guard let self else { return }
            
            guard !ciFilters.isEmpty else {
                processOutputTexture(inputTexture.texture)
                return
            }
            
            guard let image = CIImage(mtlTexture: inputTexture.texture, options: [.colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                                                  .applyOrientationProperty: true])?.oriented(.downMirrored) else {
                logger.error("\(#function) - Couldn't create CIImage from MTLTexture")
                return
            }
            
            ciFilters.first?.setValue(image, forKey: kCIInputImageKey)
            inputExtent = image.extent
            _processOutputImage()
        }
    }
    
    func newTextureAvailable(_ texture: Texture, fromSourceIndex sourceIndex: UInt) {
        processTexture(texture)
    }
    
    func transmitPreviousImage(to target: any ImageConsumer, atIndex targetIndex: UInt) {
        guard !relayOnwards else { return }
        var metalTexture: MTLTexture?
        lock.withLock {
            metalTexture = internalTexture
        }
        guard let metalTexture else {
            logger.warning("\(#function) - No internal texture available")
            return
        }
        let texture = Texture(orientation: .portrait, texture: metalTexture)
        target.newTextureAvailable(texture, fromSourceIndex: targetIndex)
    }
}
