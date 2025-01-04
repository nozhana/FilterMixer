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
    
    private var operationRepresentation: OperationRepresentation?
    
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
        saveRepresentation()
    }
    
    private func configurePipeline() {
        operationGroup?.removeAllTargets()
        operationGroup = OperationGroup()
        operations.forEach { $0.removeAllTargets() }
        operations = filters.map { $0.makeOperation() }
        restoreOperations()
        operationGroup!.configureGroup(withOperations: operations)
        
        inputImage?.removeAllTargets()
        inputImage = PictureInput(image: originalImage)
        
        inputImage! -->> operationGroup! -->> outputImage
        inputImage!.processImage()
        saveRepresentation()
    }
    
    private func restoreOperations() {
        guard let operationRepresentation else { return }
        operationRepresentation.items.forEach { item in
            if let filterIndex = filters.firstIndex(of: item.filter),
               operations.count > filterIndex,
               let operation = operations[filterIndex] as? BasicOperation {
                item.parameterValues.forEach { key, value in
                    if let floatValue = value as? Float {
                        operation.uniformSettings[key] = floatValue
                    } else if let colorValue = value as? Color {
                        operation.uniformSettings[key] = colorValue
                    } else if let positionValue = value as? Position {
                        operation.uniformSettings[key] = positionValue
                    } else if let sizeValue = value as? Size {
                        operation.uniformSettings[key] = sizeValue
                    }
                }
            }
        }
    }
    
    private func saveRepresentation() {
        var items: [OperationRepresentation.Item] = []
        
        filters.indices.forEach { index in
            guard operations.count > index else { return }
            let filter = filters[index]
            guard let operation = operations[index] as? BasicOperation else { return }
            var parameterValues = [String: Any]()
            filter.parameters.forEach { parameter in
                switch parameter {
                case .slider(let title, _, let customGetter, _):
                    let value: Float = customGetter?(operation) ?? operation.uniformSettings[title]
                    parameterValues[title] = value
                case .color(let title):
                    let value: Color = operation.uniformSettings[title]
                    parameterValues[title] = value
                case .position(let title):
                    let value: Position = operation.uniformSettings[title]
                    parameterValues[title] = value
                case .size(let title):
                    let value: Size = operation.uniformSettings[title]
                    parameterValues[title] = value
                }
            }
            let item = OperationRepresentation.Item(filter: filter, parameterValues: parameterValues)
            items.append(item)
        }
        
        operationRepresentation = OperationRepresentation(items: items)
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

struct OperationRepresentation {
    struct Item {
        var filter: Filter
        var parameterValues: [String: Any]
    }
    
    let items: [Item]
}
