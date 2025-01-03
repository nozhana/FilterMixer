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
    
    private func section(forActiveFilter filter: Filter) -> some View {
        Section {
            Button(filter.rawValue.capitalized, systemImage: "minus.circle.fill") {
                model.filters.removeAll(of: filter)
            }
            if let filterIndex = model.filters.firstIndex(of: filter),
               let operation = model.operations[filterIndex] as? BasicOperation {
                ForEach(filter.parameters) { parameter in
                    switch parameter {
                    case .slider(let title, let range):
                        VStack(alignment: .leading) {
                            Text(title.camelCaseToReadableFormatted())
                                .font(.caption)
                            Slider(value: Binding(get: {
                                Double(operation.uniformSettings[title])
                            }, set: {
                                operation.uniformSettings[title] = Float($0)
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
                    } // switch
                } // ForEach
            } // if
        } // Section
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(uiImage: model.originalImage)
                        .resizable()
                        .scaledToFit()
                        .matchedTransitionSource(id: ImageID.originalImage, in: animation)
                        .onTapGesture {
                            imageToPresent = .originalImage
                        }
                    
                    Image(uiImage: model.filteredImage)
                        .resizable()
                        .scaledToFit()
                        .matchedTransitionSource(id: ImageID.filteredImage, in: animation)
                        .onTapGesture {
                            imageToPresent = .filteredImage
                        }
                }
                .frame(height: 250)
                
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
                ToolbarItem(placement: .primaryAction) {
                    Menu("Add Filters", systemImage: "plus.circle.fill") {
                        ForEach(Filter.allCases.filter { !model.filters.contains($0) }) { filter in
                            Button(filter.rawValue.capitalized, systemImage: "plus.circle") {
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
