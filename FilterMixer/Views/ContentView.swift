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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = FilterMixer()
    @State private var isPipEnabled = false
    @State private var isShowingNewRepresentationAlert = false
    @State private var newRepresentationName = ""
    @State private var query = ""
    
    @Defaults(\.representations) var representations
    
    var searchResults: [Filter] {
        Filter.allCases.filter { !model.filters.contains($0) && $0.stylizedName.lowercased().contains(query.lowercased()) }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if horizontalSizeClass != .compact {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Picture-in-picture", systemImage: isPipEnabled ? "pip.fill" : "pip") {
                    withAnimation(.snappy) {
                        isPipEnabled.toggle()
                    }
                }
            } // ToolbarItem
        } // if
        
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
                    } // Menu
                } // ForEach
                
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
            } // Menu
            .alert("New filter stack", isPresented: $isShowingNewRepresentationAlert) {
                TextField("My filter stack", text: $newRepresentationName)
                Button("Cancel", role: .cancel) {
                    newRepresentationName = ""
                }
                
                if let representation = model.operationRepresentation {
                    Button("Save") {
                        guard !newRepresentationName.isEmpty else { return }
                        representations[newRepresentationName] = representation
                        newRepresentationName = ""
                    }
                }
            } message: {
                Text("Choose a name for your new filter stack.")
            } // alert/message
        } // ToolbarItem
        
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Add Filters", systemImage: "plus.circle.fill") {
                Menu("Lookup filters", systemImage: "paintpalette") {
                    ForEach(Filter.lookupFilters.filter { !model.filters.contains($0) }) { filter in
                        Button(filter.stylizedName, systemImage: "plus.circle") {
                            model.filters.append(filter)
                        }
                    }
                }
                
                Menu("CIFilters", systemImage: "camera.filters") {
                    ForEach(Filter.ciFilters.filter { !model.filters.contains($0) }) { filter in
                        Button(filter.stylizedName, systemImage: "plus.circle") {
                            model.filters.append(filter)
                        }
                    }
                }
                
                Divider()
                
                ForEach(Filter.genericFilters.filter { !model.filters.contains($0) }) { filter in
                    Button(filter.stylizedName, systemImage: "plus.circle") {
                        model.filters.append(filter)
                    }
                }
            } // Menu
        } // ToolbarItem
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HeaderView(isPipEnabled: isPipEnabled)
                    .environmentObject(model)
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
                    .shadow(color: .black.opacity(0.06), radius: 16, y: 10)
                    .safeAreaPadding(.vertical, 10)
                    .safeAreaPadding(.horizontal, 16)
                    .background(.ultraThinMaterial, ignoresSafeAreaEdges: .all)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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

private struct LookupView: View {
    @Binding var lookupImage: UIImage?
    
    @Namespace private var lookupTransition
    @State private var isPresentingLookupImage = false
    
    var body: some View {
        PhaseAnimator(AnimationPhase.allCases, trigger: lookupImage, content: { phase in
            if let lookupImage {
                VStack(spacing: 12) {
                    Image(uiImage: lookupImage)
                        .resizable().scaledToFit()
                        .frame(width: phase.imageSize, height: phase.imageSize)
                        .clipShape(.rect(cornerRadius: phase.cornerRadius))
                        .matchedTransitionSource(id: "lookupImage", in: lookupTransition)
                        .onTapGesture {
                            isPresentingLookupImage = true
                        }
                        .contextMenu {
                            Label("Filtered CLUT", systemImage: "swatchpalette")
                            
                            Button("Save to photos", systemImage: "square.and.arrow.down") {
                                ImageSaver.saveToPhotos(lookupImage)
                            } // Button
                            
                            Button("Save to files", systemImage: "square.and.arrow.down") {
                                ImageSaver.saveToFileSystem(lookupImage)
                            } // Button
                            
                            Button("Clear", systemImage: "xmark.circle.fill", role: .destructive) {
                                withAnimation(.snappy) {
                                    self.lookupImage = nil
                                }
                            } // Button
                        } preview: {
                            Image(uiImage: lookupImage)
                                .resizable().scaledToFit()
                        }
                        
                    
                    if phase.shouldShowButtons {
                        VStack(alignment: .leading, spacing: 6) {
                            Button("Save to photos", systemImage: "square.and.arrow.down") {
                                ImageSaver.saveToPhotos(lookupImage)
                            } // Button
                            
                            Button("Save to files", systemImage: "square.and.arrow.down") {
                                ImageSaver.saveToFileSystem(lookupImage)
                            } // Button
                            
                            Button("Clear", systemImage: "xmark.circle.fill", role: .destructive) {
                                withAnimation(.snappy) {
                                    self.lookupImage = nil
                                }
                            } // Button
                        } // VStack
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .font(.system(size: 14, weight: .medium))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } // if
                } // VStack
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } // if
        }, animation: \.animation)
        .sheet(isPresented: $isPresentingLookupImage) {
            LookupFullscreenView(lookupImage: $lookupImage, lookupTransition: lookupTransition)
        }
    }
}

extension LookupView {
    enum AnimationPhase: CaseIterable {
        case idle, flashing, shrinking
        
        var shouldShowButtons: Bool {
            switch self {
            case .idle: true
            default: false
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .flashing: 12
            default: 8
            }
        }
        
        var imageSize: CGFloat {
            switch self {
            case .idle, .shrinking: 52
            case .flashing: 86
            }
        }
        
        var animation: Animation? {
            switch self {
            case .idle: .smooth.delay(0.25)
            case .flashing: .snappy
            case .shrinking: .smooth(duration: 0.5).delay(0.5)
            }
        }
    }
}

private struct LookupFullscreenView: View {
    @Binding var lookupImage: UIImage?
    var lookupTransition: Namespace.ID
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            if let lookupImage {
                Image(uiImage: lookupImage)
                    .resizable().scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .frame(maxWidth: 400, maxHeight: 400)
                    .navigationTransition(.zoom(sourceID: "lookupImage", in: lookupTransition))
                
                Label("Filtered Color Lookup Table", systemImage: "swatchpalette")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                
                Group {
                    HStack {
                        Button("Save to photos", systemImage: "square.and.arrow.down") {
                            ImageSaver.saveToPhotos(lookupImage)
                        } // Button
                        
                        Button("Save to files", systemImage: "square.and.arrow.down") {
                            ImageSaver.saveToFileSystem(lookupImage)
                        } // Button
                    } // HStack
                    
                    Button("Clear", systemImage: "xmark.circle.fill", role: .destructive) {
                        withAnimation(.snappy) {
                            self.lookupImage = nil
                            dismiss()
                        }
                    } // Button
                } // Group
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.system(size: 16, weight: .bold))
            } else {
                ContentUnavailableView("Failed to load Color Lookup Table.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
        .safeAreaPadding(.horizontal, 16)
    }
}

private struct HeaderView: View {
    var isPipEnabled: Bool
    
    @EnvironmentObject private var model: FilterMixer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var imageTransition
    @State private var imageToPresent: ImageID?
    @State private var isPresentingPhotosPicker = false
    
    private func loadSelection(pickerItem: PhotosPickerItem?) {
        pickerItem?.loadImage { image in
            model.originalImage = image
        }
    }
    
    private var spacing: CGFloat {
        isPipEnabled ? -16 - (originalImageSize ?? 0) : 16
    }
    
    private var originalImageSize: CGFloat? {
        isPipEnabled ? 86 : nil
    }
    
    private var cornerRadius: CGFloat {
        isPipEnabled ? 8 : 16
    }
    
    private var regularSizedContent: some View {
        HStack(alignment: .top, spacing: spacing) {
            if isPipEnabled {
                Spacer()
            }
            
            Image(uiImage: model.originalImage)
                .resizable().scaledToFit()
                .frame(maxWidth: originalImageSize, maxHeight: originalImageSize)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .padding(.top, isPipEnabled ? 16 : 0)
                .matchedTransitionSource(id: ImageID.originalImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .originalImage
                }
                .contextMenu {
                    Label("Original image", systemImage: "photo")
                    
                    Button("Choose new photo", systemImage: "photo") {
                        isPresentingPhotosPicker = true
                    }
                }
                .zIndex(1)
            
            Image(uiImage: model.filteredImage)
                .resizable().scaledToFit()
                .clipShape(.rect(cornerRadius: 16))
                .matchedTransitionSource(id: ImageID.filteredImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .filteredImage
                }
                .contextMenu {
                    Label("Filtered image", systemImage: "photo.on.rectangle")
                    
                    Button("Save to photos", systemImage: "square.and.arrow.down") {
                        ImageSaver.saveToPhotos(model.filteredImage)
                    }
                    
                    Button("Save to files", systemImage: "archivebox") {
                        ImageSaver.saveToFileSystem(model.filteredImage)
                    }
                }
                .zIndex(0)
            
            Spacer()
        } // HStack
    }
    
    private var compactSizedContent: some View {
        VStack(spacing: 12) {
            Image(uiImage: model.originalImage)
                .resizable().scaledToFit()
                .clipShape(.rect(cornerRadius: 12))
                .matchedTransitionSource(id: ImageID.originalImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .originalImage
                }
                .contextMenu {
                    Label("Original image", systemImage: "photo")
                    
                    Button("Choose new photo", systemImage: "photo") {
                        isPresentingPhotosPicker = true
                    }
                }
            
            Image(uiImage: model.filteredImage)
                .resizable().scaledToFit()
                .clipShape(.rect(cornerRadius: 12))
                .matchedTransitionSource(id: ImageID.filteredImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .filteredImage
                }
                .contextMenu {
                    Label("Filtered image", systemImage: "photo.on.rectangle")
                    
                    Button("Save to photos", systemImage: "square.and.arrow.down") {
                        ImageSaver.saveToPhotos(model.filteredImage)
                    }
                    
                    Button("Save to files", systemImage: "archivebox") {
                        ImageSaver.saveToFileSystem(model.filteredImage)
                    }
                }
        } // VStack
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View {
        Group {
            switch horizontalSizeClass {
            case .compact: compactSizedContent
            default: regularSizedContent
            }
        }
        .safeAreaInset(edge: .trailing, spacing: 12) {
            VStack(spacing: 12) {
                Button("Generate CLUT", systemImage: "swatchpalette") {
                    Task { await model.processLookupImage() }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                LookupView(lookupImage: $model.filteredLookupImage)
                
                Spacer()
            }
        }
        .safeAreaPadding(12)
        .sheet(item: $imageToPresent) { imageId in
            let image = imageId == .originalImage ? model.originalImage : model.filteredImage
            
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 8))
                    .navigationTransition(.zoom(sourceID: imageId, in: imageTransition))
                
                switch imageId {
                case .originalImage:
                    Label("Original image", systemImage: "photo")
                case .filteredImage:
                    Label("Filtered image", systemImage: "photo.on.rectangle")
                }
            }
            .safeAreaPadding(.horizontal, 16)
            .font(.title2.bold())
            .foregroundStyle(.secondary)
        }
        .photosPicker(isPresented: $isPresentingPhotosPicker, selection: Binding(get: { nil }, set: loadSelection), matching: .images)
    }
}

private enum ImageID: String, Identifiable {
    case originalImage, filteredImage
}

private extension PhotosPickerItem {
    func loadImage(completion: @escaping (UIImage) -> Void) {
        loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data?):
                guard let uiImage = UIImage(data: data) else {
                    print("Failed to construct UIImage from data: \(data)")
                    return
                }
                completion(uiImage)
            case .success(nil):
                break
            case .failure(let error):
                print("Failed to load data from picker item: \(error)")
            }
        }
    }
}
