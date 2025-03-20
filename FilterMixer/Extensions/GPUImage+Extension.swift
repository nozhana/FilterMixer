//
//  GPUImage+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/21/1403 AP.
//

import Foundation
import GPUImage
import class UIKit.UIImage

extension LookupFilter {
    convenience init(_ imageName: String) {
        self.init()
        ({ lookupImage = PictureInput(imageName: "\(imageName).png") })()
        ({ intensity = 1 })()
    }
    
    convenience init(_ image: UIImage) {
        self.init()
        ({ lookupImage = PictureInput(image: image) })()
        ({ intensity = 1 })()
    }
}

extension PlatformImageType {
    func filterWithPipelineAsynchronously(_ pipeline: @escaping (PictureInput, PictureOutput) -> Void, completion: @escaping (PlatformImageType) -> Void) {
        let input = PictureInput(image: self)
        let output = PictureOutput()
        output.imageAvailableCallback = completion
        pipeline(input, output)
        input.processImage(synchronously: true)
    }
    
    func filterWithOperationAsynchronously(_ operation: ImageProcessingOperation, completion: @escaping (PlatformImageType) -> Void) {
        filterWithPipelineAsynchronously({ $0 --> operation --> $1 }, completion: completion)
    }
    
    func filterWithOperationsAsynchronously(_ operations: [ImageProcessingOperation], completion: @escaping (PlatformImageType) -> Void) {
        let group = OperationGroup()
        group.configureGroup(withOperations: operations)
        filterWithOperationAsynchronously(group, completion: completion)
    }
    
    func filterWithPipelineSynchronously(_ pipeline: @escaping (PictureInput, PictureOutput) -> Void) -> PlatformImageType {
        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()
        var output: PlatformImageType!
        filterWithPipelineAsynchronously(pipeline) { result in
            output = result
            semaphore.signal()
        }
        return output
    }
    
    func filterWithOperationSynchronously(_ operation: ImageProcessingOperation) -> PlatformImageType {
        filterWithPipelineSynchronously {
            $0 --> operation --> $1
        }
    }
    
    func filterWithOperationsSynchronously(_ operations: [ImageProcessingOperation]) -> PlatformImageType {
        let group = OperationGroup()
        group.configureGroup(withOperations: operations)
        return filterWithOperationSynchronously(group)
    }
}
