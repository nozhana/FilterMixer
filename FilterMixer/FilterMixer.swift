//
//  FilterMixer.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import Foundation
import GPUImage
import class UIKit.UIImage

final class FilterMixer: ObservableObject {
    @Published var originalImage: UIImage = .placeholder {
        didSet {
            configurePipeline()
        }
    }
    
    @Published private(set) var filteredImage: UIImage = .placeholder
    
    @Published var filters: [Filter] = [] {
        didSet {
            configurePipeline()
        }
    }
    
    private var inputImage: PictureInput?
    private lazy var outputImage = {
        let output = PictureOutput()
        output.onlyCaptureNextFrame = false
        output.imageAvailableCallback = { image in
            Task { @MainActor in
                self.filteredImage = image
            }
        }
        return output
    }()
    
    private(set) var operations: [ImageProcessingOperation] = []
    private var operationGroup: OperationGroup?
    
    init() {
        configurePipeline()
    }
    
    func processImage() {
        inputImage?.processImage()
    }
    
    private func configurePipeline() {
        operationGroup?.removeAllTargets()
        operationGroup = OperationGroup()
        operations.forEach { $0.removeAllTargets() }
        operations = filters.map { $0.makeOperation() }
        operationGroup!.configureGroup(withOperations: operations)
        
        inputImage?.removeAllTargets()
        inputImage = PictureInput(image: originalImage)
        
        inputImage! -->> operationGroup! -->> outputImage
        inputImage!.processImage()
    }
}

extension OperationGroup {
    func configureGroup(withOperations operations: [ImageProcessingOperation]) {
        if operations.isEmpty {
            configureGroup { $0 --> $1 }
            return
        }
        
        configureGroup { input, output in
            let last = operations.reduce(input) { partialResult, operation in
                partialResult --> operation
            }
            
            last --> output
        }
    }
}

infix operator -->> : AdditionPrecedence
@discardableResult
func -->> <T: ImageConsumer>(lhs: ImageSource, rhs: T) -> T {
    lhs.removeAllTargets()
    lhs.addTarget(rhs, atTargetIndex: 0)
    return rhs
}
