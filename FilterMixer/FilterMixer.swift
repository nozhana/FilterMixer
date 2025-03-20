//
//  FilterMixer.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import Foundation
import CoreImage.CIFilter
import GPUImage
import class UIKit.UIImage

final class FilterMixer: ObservableObject {
    @Published var originalImage: UIImage = .placeholder {
        didSet {
            configurePipeline()
        }
    }
    
    @MainActor @Published private(set) var filteredImage: UIImage = .placeholder
    @MainActor @Published var filteredLookupImage: UIImage?
    
    @Published var filters: [Filter] = [] {
        didSet {
            configurePipeline()
        }
    }
    
    @Published var customLookupImages: [UIImage] = [] {
        didSet {
            configurePipeline()
        }
    }
    
    @Published var isLiveMode = false {
        didSet {
            configurePipeline()
        }
    }
    
    @Published var customCIFilters: [CIFilter] = [] {
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
    private(set) var customLookupOperations: [ImageProcessingOperation] = []
    
    private var operationGroup: OperationGroup?
    private var customLookupsOperationGroup: OperationGroup?
    private var customCIFilterStackOperation: CIFilterStackOperation?
    
    let camera = try? Camera(sessionPreset: .hd1920x1080)
    let renderView = RenderView(frame: .init(origin: .zero, size: .init(width: 1080, height: 1920)), device: nil)
    let presentationRenderView = RenderView(frame: .init(origin: .zero, size: .init(width: 1080, height: 1920)), device: nil)
    
    init() {
        // camera?.runBenchmark = true
        // camera?.logFPS = true
        configurePipeline()
    }
    
    func processImage() {
        inputImage?.processImage()
        cacheRepresentation()
    }
    
    func processLookupImage() async {
        let lookupOps = customLookupImages.map { LookupFilter($0) }
        let originalLookup = UIImage(named: "lookup")!
        let intermediate = await withCheckedContinuation { continuation in
            originalLookup.filterWithOperationsAsynchronously(lookupOps) { result in
                continuation.resume(returning: result)
            }
        }
        let filtered = await operationRepresentation?.apply(to: intermediate)
        await MainActor.run {
            filteredLookupImage = filtered
        }
    }
    
    func configurePipeline() {
        operationGroup?.removeAllTargets()
        customLookupsOperationGroup?.removeAllTargets()
        
        operationGroup = OperationGroup()
        customLookupsOperationGroup = OperationGroup()
        
        operations.forEach { $0.removeAllTargets() }
        customLookupOperations.forEach { $0.removeAllTargets() }
        
        operations = filters.map { $0.makeOperation(parameters: ["extent": originalImage.size.applying(.init(scaleX: originalImage.scale, y: originalImage.scale))]) }
        customLookupOperations = customLookupImages.map { LookupFilter($0) }
        
        restoreCachedRepresentation()
        
        operationGroup!.configureGroup(withOperations: operations)
        customLookupsOperationGroup!.configureGroup(withOperations: customLookupOperations)
        
        customCIFilterStackOperation?.removeAllTargets()
        customCIFilterStackOperation = CIFilterStackOperation(customCIFilters)
        
        if isLiveMode {
            if let camera {
                camera.removeAllTargets()
                camera -->> customCIFilterStackOperation! -->> customLookupsOperationGroup! -->> operationGroup! -->> renderView
                operationGroup! --> presentationRenderView
            }
            
            camera?.startCapture()
        } else {
            camera?.stopCapture()
            inputImage?.removeAllTargets()
            
            inputImage = PictureInput(image: originalImage)
            
            // if let ciImage = originalImage.inferredCIImage {
            //     let filtered = customCIFilters.reduce(into: ciImage) { partialResult, filter in
            //         filter.setValue(partialResult, forKey: kCIInputImageKey)
            //         if let outputImage = filter.outputImage?.cropped(to: partialResult.extent) {
            //             partialResult = outputImage
            //         }
            //     }
            //     let context = CIContext(mtlDevice: sharedMetalRenderingDevice.device)
            //     if let cgImage = context.createCGImage(filtered, from: filtered.extent) {
            //         inputImage = PictureInput(image: cgImage)
            //     } else {
            //         inputImage = PictureInput(image: originalImage)
            //     }
            // } else {
            //     inputImage = PictureInput(image: originalImage)
            // }
            
            inputImage! -->> customCIFilterStackOperation! -->> customLookupsOperationGroup! -->> operationGroup! -->> outputImage
            inputImage!.processImage()
        }
        
        cacheRepresentation()
    }
    
    func restoreRepresentation(withName name: String) {
        let representations = Defaults[\.representations]
        guard let representation = representations[name] else { return }
        operationRepresentation = representation
        filters = representation.items.map(\.filter)
    }
    
    private func restoreCachedRepresentation() {
        guard let operationRepresentation else { return }
        operationRepresentation.items.forEach { item in
            if let filterIndex = filters.firstIndex(of: item.filter),
               let operation = operations[safe: filterIndex] {
                item.filter.parameters.forEach { parameter in
                    switch parameter {
                    case .slider(let title, _, _, _, let customSetter):
                        if let value = item.parameterValues[title],
                           case .float(let float) = value {
                            if let customSetter {
                                customSetter(operation, float)
                            } else if let operation = operation as? BasicOperation {
                                operation.uniformSettings[title] = float
                            } else if let operation = operation as? CIFilterOperation {
                                operation.setValue(float, forKey: title)
                            }
                        }
                    case .position(let title, _, let setter):
                        if let value = item.parameterValues[title],
                           case .position(let position) = value {
                            setter(operation, position)
                        }
                    case .size(let title, _, let setter):
                        if let value = item.parameterValues[title],
                           case .size(let size) = value {
                            setter(operation, size)
                        }
                    case .color(let title, _, let setter):
                        if let value = item.parameterValues[title],
                           case .color(let color) = value {
                            setter(operation, color)
                        }
                    }
                }
            }
        }
    }
    
    private func cacheRepresentation() {
        var items: [OperationRepresentation.Item] = []
        
        filters.indices.forEach { index in
            guard let filter = filters[safe: index],
                  let operation = operations[safe: index] else { return }
            
            let parameterValues = filter.parameters.reduce(into: [String: OperationRepresentation.Item.Parameter]()) { partialResult, parameter in
                switch parameter {
                case .slider(let title, _, _, let customGetter, _):
                    var floatValue: Float?
                    if let float = customGetter?(operation) {
                        floatValue = float
                    } else if let operation = operation as? BasicOperation {
                        floatValue = operation.uniformSettings[title]
                    } else if let operation = operation as? CIFilterOperation {
                        floatValue = operation.value(forKey: title) as? Float
                    }
                    
                    if let floatValue {
                        partialResult[title] = .float(floatValue)
                    }
                case .color(let title, let getter, _):
                    let color = getter(operation)
                    partialResult[title] = .color(color)
                case .position(let title, let getter, _):
                    let position = getter(operation)
                    partialResult[title] = .position(position)
                case .size(let title, let getter, _):
                    let size = getter(operation)
                    partialResult[title] = .size(size)
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

struct OperationRepresentation: CustomStringConvertible, Codable {
    struct Item: CustomStringConvertible, Codable {
        var filter: Filter
        var parameterValues: [String: Parameter]
        
        enum Parameter: Codable, CustomStringConvertible {
            case float(Float)
            case size(Size)
            case position(Position)
            case color(Color)
            
            var description: String {
                switch self {
                case .float(let float):
                    "[FLOAT] \(float)"
                case .size(let size):
                    "[SIZE] \(size)"
                case .position(let position):
                    "[POSITION] \(position)"
                case .color(let color):
                    "[COLOR] \(color)"
                }
            }
        }
        
        var description: String {
            "- \(filter.stylizedName)\n"
            + parameterValues
                .map { "\($0.key.camelCaseToReadableFormatted()): \($0.value)"}
                .joined(separator: "\n")
        }
    }
    
    let items: [Item]
    
    var description: String {
        items.enumerated().map { String($0.offset + 1) + $0.element.description }.joined(separator: "\n\n")
    }
    
    func apply(to image: UIImage) async -> UIImage {
        let ops = items.map(\.filter).map { $0.makeOperation(parameters: ["extent": image.size.applying(.init(scaleX: image.scale, y: image.scale))]) }
        for (item, operation) in zip(items, ops) {
            for parameter in item.filter.parameters {
                switch parameter {
                case .slider(let title, _, _, _, let customSetter):
                    if let parameterValue = item.parameterValues[title],
                       case .float(let float) = parameterValue {
                        if let customSetter {
                            customSetter(operation, float)
                        } else if let operation = operation as? BasicOperation {
                            operation.uniformSettings[title] = float
                        } else if let operation = operation as? CIFilterOperation {
                            operation.setValue(float, forKey: title)
                        }
                    }
                case .color(let title, _, let setter):
                    if let parameterValue = item.parameterValues[title],
                       case .color(let color) = parameterValue {
                        setter(operation, color)
                    }
                case .position(let title, _, let setter):
                    if let parameterValue = item.parameterValues[title],
                       case .position(let position) = parameterValue {
                        setter(operation, position)
                    }
                case .size(let title, _, let setter):
                    if let parameterValue = item.parameterValues[title],
                       case .size(let size) = parameterValue {
                        setter(operation, size)
                    }
                }
            }
        }
        
        return await withCheckedContinuation { continuation in
            image.filterWithOperationsAsynchronously(ops) { image in
                continuation.resume(returning: image)
            }
        }
    }
}

extension Size: @retroactive CustomStringConvertible {
    public var description: String {
        "(w: \(width), h: \(height))"
    }
}

extension Size: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Float.self, forKey: .width)
        let height = try container.decode(Float.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

extension Position: @retroactive CustomStringConvertible {
    public var description: String {
        "(x: \(x), y: \(y)" + (z == nil ? ")" : ", z: \(z!))")
    }
}

extension Position: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, z
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Float.self, forKey: .x)
        let y = try container.decode(Float.self, forKey: .y)
        let z = try container.decodeIfPresent(Float.self, forKey: .z)
        self.init(x, y, z)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(z, forKey: .z)
    }
}

extension GPUImage.Color: @retroactive CustomStringConvertible {
    public var description: String {
        "(r: \(redComponent), g: \(greenComponent), b: \(blueComponent), a: \(alphaComponent))"
    }
}

extension GPUImage.Color: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Float.self, forKey: .red)
        let green = try container.decode(Float.self, forKey: .green)
        let blue = try container.decode(Float.self, forKey: .blue)
        let alpha = try container.decodeIfPresent(Float.self, forKey: .alpha) ?? 1
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(redComponent, forKey: .red)
        try container.encode(greenComponent, forKey: .green)
        try container.encode(blueComponent, forKey: .blue)
        try container.encode(alphaComponent, forKey: .alpha)
    }
}

extension DefaultsContainer {
    var representations: [String: OperationRepresentation] {
        [:]
    }
}
