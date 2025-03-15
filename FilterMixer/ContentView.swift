//
//  ContentView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import GPUImage
import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var model = FilterMixer()
    @Namespace private var animation
    @State private var imageToPresent: ImageID?
    @State private var isPipEnabled = false
    @State private var isShowingPhotosPicker = false
    @State private var isShowingNewRepresentationAlert = false
    @State private var newRepresentationName = ""
    @State private var query = ""
    
    @Defaults(\.representations) var representations
    
    var searchResults: [Filter] {
        Filter.allCases.filter { !model.filters.contains($0) && $0.stylizedName.lowercased().contains(query.lowercased()) }
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
                    .zIndex(1)
                
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
                    .zIndex(0)
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
            Menu("Representations", systemImage: "archivebox") {
                ForEach(representations.map(\.self), id: \.key) { (key, representation) in
                    Menu(key) {
                        Menu(representation.items.count ~~ "filter", systemImage: "camera.filters") {
                            ForEach(representation.items.map(\.filter)) { filter in
                                Text(filter.stylizedName)
                            }
                        }
                        Divider()
                        Button("Restore", systemImage: "arrow.circlepath") {
                            model.restoreRepresentation(withName: key)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            representations.removeValue(forKey: key)
                        }
                    }
                }
                
                if !representations.isEmpty {
                    Button("Clear all", systemImage: "trash.fill", role: .destructive) {
                        representations.removeAll()
                    }
                }
                
                if !model.filters.isEmpty {
                    Button("Save current stack", systemImage: "square.and.arrow.down") {
                        isShowingNewRepresentationAlert = true
                    }
                }
                
                if model.filters.isEmpty, representations.isEmpty {
                    Label("Choose a filter to get started.", systemImage: "camera.filters")
                        .foregroundStyle(.secondary)
                }
            }
            .alert("New filter stack", isPresented: $isShowingNewRepresentationAlert) {
                TextField("My filter stack", text: $newRepresentationName)
                Button("Cancel", role: .cancel) {}
                if let representation = model.operationRepresentation {
                    Button("Save") {
                        guard !newRepresentationName.isEmpty else { return }
                        representations[newRepresentationName] = representation
                    }
                }
            } message: {
                Text("Choose a name for your new filter stack.")
            }
        }
        
        if !model.filters.isEmpty,
           let representation = model.operationRepresentation {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: representation.lookupImage, subject: Text("Operation Representation"), message: Text(representation.description), preview: SharePreview("Lookup", image: representation.lookupImage))
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Add Filters", systemImage: "plus.circle.fill") {
                Menu("Lookup filters", systemImage: "paintpalette") {
                    ForEach(Filter.lookupFilters.filter { !model.filters.contains($0) }) { filter in
                        Button(filter.stylizedName, systemImage: "plus.circle") {
                            model.filters.append(filter)
                        }
                    }
                }
                
                ForEach(Filter.genericFilters.filter { !model.filters.contains($0) }) { filter in
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
                    .safeAreaPadding(.horizontal, 16)
                    .onDrop(of: [.image], isTargeted: nil) { providers in
                        for provider in providers {
                            _ = provider.loadTransferable(type: Data.self) { result in
                                switch result {
                                case .success(let data):
                                    guard let uiImage = UIImage(data: data) else { return }
                                    Task { @MainActor in
                                        model.originalImage = uiImage
                                    }
                                case .failure(let error):
                                    print("Failed to load photos picker item: \(error.localizedDescription)")
                                }
                            }
                        }
                        return true
                    }
                
                if query.isEmpty {
                    if model.filters.isEmpty {
                        ContentUnavailableView("Add a filter to see the result.", systemImage: "plus.circle.dashed")
                            .foregroundStyle(.gray)
                    } else {
                        List {
                            ForEach(model.filters) { filter in
                                FilterSectionView(filter: filter)
                                    .environmentObject(model)
                            }
                            .onMove { fromOffsets, toOffset in
                                model.filters.move(fromOffsets: fromOffsets, toOffset: toOffset)
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.04))
                        .listRowSeparator(.hidden)
                        .listSectionSeparator(.hidden)
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    List(searchResults) { filter in
                        Button(filter.stylizedName, systemImage: "plus.circle") {
                            model.filters.append(filter)
                            withAnimation(.interactiveSpring) {
                                query = ""
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !model.filters.isEmpty {
                    Button("Remove all", systemImage: "trash", role: .destructive) {
                        withAnimation(.interactiveSpring) {
                            model.filters.removeAll()
                        }
                    }
                    .font(.system(size: 19, weight: .medium))
                    .buttonStyle(.fullWidthCapsule)
                    .background(.ultraThinMaterial, ignoresSafeAreaEdges: .all)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
        } // NavigationStack
        .searchable(text: $query, prompt: "Look for a filter") {
            ForEach(searchResults) { result in
                Text(result.stylizedName).font(.caption)
                    .searchCompletion(result.stylizedName)
            }
        }
        .submitLabel(.done)
        .onSubmit(of: .search) {
            if let firstResult = searchResults.first {
                model.filters.append(firstResult)
                withAnimation(.interactiveSpring) {
                    query = ""
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

enum ImageID: String, Identifiable {
    case originalImage, filteredImage
}
