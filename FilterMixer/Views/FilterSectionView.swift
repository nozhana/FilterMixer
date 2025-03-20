//
//  FilterSectionView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/15/25.
//

import GPUImage
import SwiftUI

struct FilterSectionView: View {
    var filter: Filter
    var isRegularSlider = false
    
    @EnvironmentObject private var model: FilterMixer
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Button(filter.stylizedName, systemImage: "minus.circle.fill") {
                    model.filters.removeAll(of: filter)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                let filterIndex = model.filters.firstIndex(of: filter) ?? 0
                Label("Layer \(filterIndex + 1)", systemImage: "square.3.layers.3d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .safeAreaPadding(.vertical, 8)
                    .safeAreaPadding(.horizontal, 10)
                    .background(.thinMaterial, in: .rect(cornerRadius: 10))
            } // HStack
            
            if let filterIndex = model.filters.firstIndex(of: filter) {
                if let operation = model.operations[safe: filterIndex] {
                    ForEach(filter.parameters) { parameter in
                        FilterParameterView(operation: operation, parameter: parameter, isRegularSlider: isRegularSlider)
                    } // ForEach
                } // if
            } // if
        } // VStack
    }
}

struct FilterParameterView: View {
    var operation: ImageProcessingOperation
    var parameter: FilterParameter
    var isRegularSlider = false
    
    @EnvironmentObject private var model: FilterMixer
    
    var body: some View {
        switch parameter {
        case .slider(let title, let range, let stepCount, let customGetter, let customSetter):
            HStack {
                Text(title.camelCaseToReadableFormatted())
                let binding = Binding<Double>(get: {
                    if let customGetter {
                        Double(customGetter(operation))
                    } else if let operation = operation as? BasicOperation {
                        Double(operation.uniformSettings[title])
                    } else if let operation = operation as? CIFilterOperation,
                              let floatValue = operation.value(forKey: title) as? Float {
                        Double(floatValue)
                    } else {
                        0
                    }
                }, set: {
                    if let customSetter {
                        customSetter(operation, Float($0))
                    } else if let operation = operation as? BasicOperation {
                        operation.uniformSettings[title] = Float($0)
                    } else if let operation = operation as? CIFilterOperation {
                        operation.setValue(Float($0), forKey: title)
                    }
                    model.processImage()
                })
                
                if isRegularSlider {
                    Slider(value: binding, in: range) {
                        Text(binding.wrappedValue.formatted())
                    } minimumValueLabel: {
                        Text(range.lowerBound.formatted())
                    } maximumValueLabel: {
                        Text(range.upperBound.formatted())
                    }
                } else {
                    WheelSlider(value: binding, in: range, stepCount: stepCount ?? 50, curved: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .offset(y: 6)
                        .overlay(alignment: .bottom) {
                            Group {
                                if let customGetter {
                                    Text(Double(customGetter(operation)).formatted())
                                } else if let operation = operation as? BasicOperation {
                                    Text(Double(operation.uniformSettings[title]).formatted())
                                } else if let operation = operation as? CIFilterOperation,
                                          let floatValue = operation.value(forKey: title) as? Float {
                                    Text(Double(floatValue).formatted())
                                }
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(.yellow.mix(with: .black, by: 0.25))
                            .offset(y: 6)
                        }
                }
            } // HStack
        case .color(let title, let getter, let setter):
            SliderColorPicker(title.camelCaseToReadableFormatted(), color: Binding(get: {
                getter(operation)
            }, set: {
                setter(operation, $0)
                model.processImage()
            }), isRegularSlider: isRegularSlider)
        case .position(let title, let getter, let setter):
            HStack {
                Text(title.camelCaseToReadableFormatted())
                Spacer()
                PositionPicker(position: Binding(get: {
                    getter(operation).toUnitPoint
                }, set: {
                    setter(operation, $0.toGpuImagePosition)
                    model.processImage()
                }))
            } // HStack
        case .size(let title, let getter, let setter):
            HStack {
                Text(title.camelCaseToReadableFormatted())
                Spacer()
                SizePicker(size: Binding(get: {
                    getter(operation).toCgSize
                }, set: {
                    setter(operation, $0.toGpuImageSize)
                    model.processImage()
                }))
            } // HStack
        } // switch
    }
}
