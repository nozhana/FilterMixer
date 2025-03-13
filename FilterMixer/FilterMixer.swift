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
    
    private(set) var operationRepresentation: OperationRepresentation?
    
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
    
    func configurePipeline() {
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
               let operation = operations[safe: filterIndex] as? BasicOperation {
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
            guard let filter = filters[safe: index],
                  let operation = operations[safe: index] as? BasicOperation else { return }
            var parameterValues = [String: Any]()
            filter.parameters.forEach { parameter in
                switch parameter {
                case .slider(let title, _, _, let customGetter, _):
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

struct OperationRepresentation: CustomStringConvertible {
    struct Item: CustomStringConvertible {
        var filter: Filter
        var parameterValues: [String: Any]
        
        var description: String {
            "- \(filter.stylizedName)\n"
            + parameterValues
                .map { "\($0.key.camelCaseToReadableFormatted()): \($0.value)"}
                .joined(separator: "\n")
        }
    }
    
    let items: [Item]
    
    var description: String {
        "Operation Representation\n\n"
        + items.enumerated().map { String($0.offset + 1) + $0.element.description }.joined(separator: "\n\n")
    }
}

extension Size: @retroactive CustomStringConvertible {
    public var description: String {
        "(w: \(width), h: \(height))"
    }
}

extension Position: @retroactive CustomStringConvertible {
    public var description: String {
        "(x: \(x), y: \(y)" + (z == nil ? ")" : ", z: \(z!))")
    }
}

extension GPUImage.Color: @retroactive CustomStringConvertible {
    public var description: String {
        "(r: \(redComponent), g: \(greenComponent), b: \(blueComponent), a: \(alphaComponent))"
    }
}
