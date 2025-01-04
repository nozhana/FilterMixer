//
//  ContentView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import GPUImage
import SwiftUI

struct ContentView: View {
    @StateObject private var model = FilterMixer()
    @Namespace private var animation
    @State private var imageToPresent: ImageID?
    @State private var position: UnitPoint = .center
    @State private var size: CGSize = .init(width: 0.5, height: 0.5)
    @State private var isPipEnabled = false
    
    private func section(forActiveFilter filter: Filter) -> some View {
        Section {
            Button(filter.stylizedName, systemImage: "minus.circle.fill") {
                model.filters.removeAll(of: filter)
            }
            if let filterIndex = model.filters.firstIndex(of: filter) {
                if let operation = model.operations[filterIndex] as? BasicOperation {
                    ForEach(filter.parameters) { parameter in
                        switch parameter {
                        case .slider(let title, let range, let customGetter, let customSetter):
                            VStack(alignment: .leading) {
                                Text(title.camelCaseToReadableFormatted())
                                    .font(.caption)
                                Slider(value: Binding(get: {
                                    if let customGetter {
                                        Double(customGetter(operation))
                                    } else {
                                        Double(operation.uniformSettings[title])
                                    }
                                }, set: {
                                    if let customSetter {
                                        customSetter(operation, Float($0))
                                    } else {
                                        operation.uniformSettings[title] = Float($0)
                                    }
                                    model.processImage()
                                }), in: range) {
                                    Text(title.camelCaseToReadableFormatted())
                                } minimumValueLabel: {
                                    Text(range.lowerBound.formatted())
                                } maximumValueLabel: {
                                    Text(range.upperBound.formatted())
                                }
                            }
                        case .color(let title):
                            ColorPicker(title.camelCaseToReadableFormatted(), selection: Binding(get: {
                                operation.uniformSettings[title].swiftUiColor
                            }, set: {
                                operation.uniformSettings[title] = $0.gpuImageColor
                                model.processImage()
                            }), supportsOpacity: true)
                        case .position(let title):
                            HStack {
                                Text(title.camelCaseToReadableFormatted())
                                    .font(.caption)
                                Spacer()
                                PositionPicker(position: $position)
                                    .onChange(of: position) { _, newValue in
                                        operation.uniformSettings[title] = newValue.toGpuImagePosition
                                        model.processImage()
                                    }
                            } // HStack
                        case .size(let title):
                            HStack {
                                Text(title.camelCaseToReadableFormatted())
                                    .font(.caption)
                                Spacer()
                                SizePicker(size: $size)
                                    .onChange(of: size) { _, newValue in
                                        operation.uniformSettings[title] = newValue.toGpuImageSize
                                        model.processImage()
                                    }
                            } // HStack
                        } // switch
                    } // ForEach
                } else if let operation = model.operations[filterIndex] as? OperationGroup {
                    ForEach(filter.parameters) { parameter in
                        switch parameter {
                        case .slider(let title, let range, let customGetter, let customSetter):
                            if let customGetter, let customSetter {
                                VStack(alignment: .leading) {
                                    Text(title.camelCaseToReadableFormatted())
                                        .font(.caption)
                                    Slider(value: Binding(get: {
                                        Double(customGetter(operation))
                                    }, set: {
                                        customSetter(operation, Float($0))
                                    })) {
                                        Text(title.camelCaseToReadableFormatted())
                                    } minimumValueLabel: {
                                        Text(range.lowerBound.formatted())
                                    } maximumValueLabel: {
                                        Text(range.upperBound.formatted())
                                    }
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                } // if
            } // if
        } // Section
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isPipEnabled {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: model.filteredImage)
                            .resizable()
                            .scaledToFit()
                            .matchedTransitionSource(id: ImageID.filteredImage, in: animation)
                            .matchedGeometryEffect(id: ImageID.filteredImage, in: animation)
                            .onTapGesture {
                                imageToPresent = .filteredImage
                            }
                        
                        Image(uiImage: model.originalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 80)
                            .padding(6)
                            .matchedTransitionSource(id: ImageID.originalImage, in: animation)
                            .matchedGeometryEffect(id: ImageID.originalImage, in: animation)
                            .onTapGesture {
                                imageToPresent = .originalImage
                            }
                    }
                } else {
                    HStack {
                        Image(uiImage: model.originalImage)
                            .resizable()
                            .scaledToFit()
                            .matchedTransitionSource(id: ImageID.originalImage, in: animation)
                            .matchedGeometryEffect(id: ImageID.originalImage, in: animation)
                            .onTapGesture {
                                imageToPresent = .originalImage
                            }
                        
                        Image(uiImage: model.filteredImage)
                            .resizable()
                            .scaledToFit()
                            .matchedTransitionSource(id: ImageID.filteredImage, in: animation)
                            .matchedGeometryEffect(id: ImageID.filteredImage, in: animation)
                            .onTapGesture {
                                imageToPresent = .filteredImage
                            }
                    }
                    .frame(height: 250)
                }
                
                List(model.filters) { filter in
                    section(forActiveFilter: filter)
                }
            }
            .padding()
            .sheet(item: $imageToPresent) { imageId in
                let image = imageId == .originalImage ? model.originalImage : model.filteredImage
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .navigationTransition(.zoom(sourceID: imageId, in: animation))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Picture-in-picture", systemImage: isPipEnabled ? "pip.fill" : "pip") {
                        withAnimation(.snappy) {
                            isPipEnabled.toggle()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Add Filters", systemImage: "plus.circle.fill") {
                        ForEach(Filter.allCases.filter { !model.filters.contains($0) }) { filter in
                            Button(filter.stylizedName, systemImage: "plus.circle") {
                                model.filters.append(filter)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Mixer")
        }
    }
}

#Preview {
    ContentView()
}

enum ImageID: String, Identifiable {
    case originalImage, filteredImage
}
