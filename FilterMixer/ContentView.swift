//
//  ContentView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import GPUImage
import SwiftUI
import WheelSlider
import PhotosUI

struct ContentView: View {
    @StateObject private var model = FilterMixer()
    @Namespace private var animation
    @State private var imageToPresent: ImageID?
    @State private var position: UnitPoint = .center
    @State private var size: CGSize = .init(width: 0.5, height: 0.5)
    @State private var isPipEnabled = false
    @State private var isShowingPhotosPicker = false
    
    private func section(forActiveFilter filter: Filter) -> some View {
        Section {
            Button(filter.stylizedName, systemImage: "minus.circle.fill") {
                model.filters.removeAll(of: filter)
            }
            if let filterIndex = model.filters.firstIndex(of: filter) {
                if let operation = model.operations[filterIndex] as? BasicOperation {
                    ForEach(filter.parameters) { parameter in
                        switch parameter {
                        case .slider(let title, let range, let stepCount, let customGetter, let customSetter):
                            HStack {
                                Text(title.camelCaseToReadableFormatted())
                                WheelSlider(value: Binding(get: {
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
                                }), in: range, stepCount: stepCount ?? 50)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .offset(y: 6)
                                .overlay(alignment: .bottom) {
                                    Group {
                                        if let customGetter {
                                            Text(Double(customGetter(operation)).formatted())
                                        } else {
                                            Text(Double(operation.uniformSettings[title]).formatted())
                                        }
                                    }
                                    .font(.caption2.bold())
                                    .foregroundStyle(.yellow.mix(with: .black, by: 0.25))
                                    .offset(y: 6)
                                }
                            } // HStack
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
                                Spacer()
                                SizePicker(size: $size)
                                    .onChange(of: size) { _, newValue in
                                        operation.uniformSettings[title] = newValue.toGpuImageSize
                                        model.processImage()
                                    }
                            } // HStack
                        } // switch
                    } // ForEach
                } // if
            } // if
        } // Section
    }
    
    private func loadSelection(_ pickerItem: PhotosPickerItem?) {
        guard let pickerItem else { return }
        pickerItem.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let data,
                      let uiImage = UIImage(data: data) else { return }
                model.originalImage = uiImage
            case .failure(let error):
                print("Failed to load photos picker item: \(error.localizedDescription)")
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
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
                    .contextMenu {
                        Button("Save to photos", systemImage: "square.and.arrow.down.fill") {
                            UIImageWriteToSavedPhotosAlbum(model.filteredImage, nil, nil, nil)
                        }
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
                    .contextMenu {
                        Button("Change photo", systemImage: "photo.fill") {
                            isShowingPhotosPicker = true
                        }
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
                    .contextMenu {
                        Button("Change photo", systemImage: "photo.fill") {
                            isShowingPhotosPicker = true
                        }
                    }
                
                Image(uiImage: model.filteredImage)
                    .resizable()
                    .scaledToFit()
                    .matchedTransitionSource(id: ImageID.filteredImage, in: animation)
                    .matchedGeometryEffect(id: ImageID.filteredImage, in: animation)
                    .onTapGesture {
                        imageToPresent = .filteredImage
                    }
                    .contextMenu {
                        Button("Save to photos", systemImage: "square.and.arrow.down.fill") {
                            UIImageWriteToSavedPhotosAlbum(model.filteredImage, nil, nil, nil)
                        }
                    }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
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
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView
                
                if model.filters.isEmpty {
                    ContentUnavailableView("Add a filter to see the result.", systemImage: "plus.circle.dashed")
                        .foregroundStyle(.gray)
                } else {
                    List(model.filters) { filter in
                        section(forActiveFilter: filter)
                            .listRowBackground(Color.primary.opacity(0.04))
                            .listRowSeparator(.hidden)
                            .listSectionSeparator(.hidden)
                    }
                    .scrollContentBackground(.hidden)
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
            .photosPicker(isPresented: $isShowingPhotosPicker, selection: Binding(get: { nil }, set: { loadSelection($0) }), matching: .images)
            .toolbar {
                toolbarItems
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
