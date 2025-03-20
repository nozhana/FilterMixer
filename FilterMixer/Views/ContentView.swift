//
//  ContentView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 12/31/24.
//

import CoreImage.CIFilterBuiltins
import GPUImage
import SwiftUI
import PhotosUI
import TipKit

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = FilterMixer()
    @State private var isPipEnabled = false
    @State private var isShowingNewRepresentationAlert = false
    @State private var newRepresentationName = ""
    @State private var query = ""
    @State private var isDroppingImage = false
    @State private var isHoveringOnTheRightHalf = false
    @State private var lookups: [URL] = []
    
    @Defaults(\.isRegularSlider) private var isRegularSlider
    @Defaults(\.representations) private var representations
    
    private let addFilterTip = AddFilterTip()
    private let enablePipTip = EnablePipTip()
    private let changeSourceImageTip = ChangeSourceImageTip()
    private let addLookupImageTip = AddLookupImageTip()
    private let reorderFiltersTip = ReorderFiltersTip()
    private let reorderCustomClutsTip = ReorderCustomClutsTip()
    private let reorderCustomCIFiltersTip = ReorderCustomCIFiltersTip()
    
    var searchResults: [Filter] {
        Filter.allCases.filter { !model.filters.contains($0) && $0.stylizedName.lowercased().contains(query.lowercased()) }
    }
    
    var customCIFilterSearchResults: [String] {
        CIFilter.filterNames(inCategories: nil).filter { !model.customCIFilters.map(\.name).contains($0) && $0.lowercased().contains(query.lowercased()) }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if horizontalSizeClass != .compact {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Picture-in-picture", systemImage: isPipEnabled ? "pip.fill" : "pip") {
                    withAnimation(.snappy) {
                        isPipEnabled.toggle()
                        enablePipTip.invalidate(reason: .actionPerformed)
                    }
                }
                .popoverTip(enablePipTip, arrowEdge: .top)
            } // ToolbarItem
        } // if
        
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Toggle("Regular slider", systemImage: "slider.horizontal.3", isOn: $isRegularSlider)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Toggle("Live mode", systemImage: model.isLiveMode ? "livephoto" : "livephoto.slash", isOn: $model.isLiveMode)
                .contentTransition(.symbolEffect(.replace))
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
                    if !lookups.isEmpty {
                        Section("Custom CLUTs") {
                            ForEach(lookups, id: \.lastPathComponent) { url in
                                Menu(url.lastPathComponent) {
                                    Button("Apply", systemImage: "photo.badge.checkmark") {
                                        guard let data = try? Data(contentsOf: url),
                                              let image = UIImage(data: data) else { return }
                                        model.customLookupImages.append(image)
                                        addFilterTip.invalidate(reason: .actionPerformed)
                                        ReorderCustomClutsTip.addClutEvent.sendDonation()
                                    }
                                    
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        lookups.removeAll(of: url)
                                        DocumentStore.shared.deleteLookupImage(name: url.lastPathComponent)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Preset CLUTs") {
                        ForEach(Filter.lookupFilters.filter { !model.filters.contains($0) }) { filter in
                            Button(filter.stylizedName, systemImage: "plus.circle") {
                                model.filters.append(filter)
                                addFilterTip.invalidate(reason: .actionPerformed)
                                ReorderFiltersTip.addFilterEvent.sendDonation()
                            }
                        }
                    }
                }
                
                Menu("CIFilters", systemImage: "camera.filters") {
                    ForEach(Filter.ciFilters.filter { !model.filters.contains($0) }) { filter in
                        Button(filter.stylizedName, systemImage: "plus.circle") {
                            model.filters.append(filter)
                            addFilterTip.invalidate(reason: .actionPerformed)
                            ReorderCustomCIFiltersTip.addCIFilterEvent.sendDonation()
                        }
                    }
                }
                
                Divider()
                
                ForEach(Filter.genericFilters.filter { !model.filters.contains($0) }) { filter in
                    Button(filter.stylizedName, systemImage: "plus.circle") {
                        model.filters.append(filter)
                        addFilterTip.invalidate(reason: .actionPerformed)
                        ReorderFiltersTip.addFilterEvent.sendDonation()
                    }
                }
            } // Menu
            .popoverTip(addFilterTip, arrowEdge: .top)
        } // ToolbarItem
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader { proxy in
                    HeaderView(isPipEnabled: isPipEnabled)
                        .environmentObject(model)
                        .blur(radius: isDroppingImage ? 12 : 0)
                        .overlay {
                            if isDroppingImage {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.accentColor.opacity(isHoveringOnTheRightHalf ? 0 : 0.25))
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor, style: .init(lineWidth: 2, dash: [8, 12]))
                                        
                                        Text("Source Image").font(.title2.bold())
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.accentColor.opacity(isHoveringOnTheRightHalf ? 0.25 : 0))
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor, style: .init(lineWidth: 2, dash: [8, 12]))
                                        
                                        Text("Lookup Image").font(.title2.bold())
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                        .onDrop(of: [.image], delegate: HeaderViewDropDelegate(geometry: proxy, hasImage: $isDroppingImage, isHoveringOnTheRightHalf: $isHoveringOnTheRightHalf, lookupImageDropped: { image in
                            addLookupImageTip.invalidate(reason: .actionPerformed)
                            DocumentStore.shared.saveLookupImage(image)
                            lookups = DocumentStore.shared.getAllLookupImageURLs()
                        }, sourceImageDropped: { image in
                            changeSourceImageTip.invalidate(reason: .actionPerformed)
                            model.originalImage = image
                        }))
                }
                
                if query.isEmpty {
                    if model.filters.isEmpty,
                       model.customLookupImages.isEmpty,
                       model.customCIFilters.isEmpty {
                        ContentUnavailableView("Add a filter to see the result.", systemImage: "plus.circle.dashed")
                            .foregroundStyle(.secondary)
                    } else {
                        List {
                            Section("Custom CIFilters") {
                                TipView(reorderCustomCIFiltersTip)
                                ForEach(model.customCIFilters.map(\.name), id: \.self) { filterName in
                                    Button(filterName, systemImage: "minus.circle.fill") {
                                        model.customCIFilters.removeAll(where: { $0.name == filterName })
                                    }
                                }
                                .onMove { fromOffsets, toOffset in
                                    model.customCIFilters.move(fromOffsets: fromOffsets, toOffset: toOffset)
                                    reorderCustomCIFiltersTip.invalidate(reason: .actionPerformed)
                                }
                            }
                            
                            Section("Custom CLUTS") {
                                TipView(reorderCustomClutsTip)
                                ForEach(0..<model.customLookupImages.count, id: \.self) { index in
                                    CustomLookupSectionView(index: index, isRegularSlider: isRegularSlider)
                                        .environmentObject(model)
                                }
                                .onMove { fromOffsets, toOffset in
                                    model.customLookupImages.move(fromOffsets: fromOffsets, toOffset: toOffset)
                                    reorderCustomClutsTip.invalidate(reason: .actionPerformed)
                                }
                            }
                            
                            Section("Active Filters") {
                                TipView(reorderFiltersTip)
                                ForEach(model.filters) { filter in
                                    FilterSectionView(filter: filter, isRegularSlider: isRegularSlider)
                                        .environmentObject(model)
                                }
                                .onMove { fromOffsets, toOffset in
                                    model.filters.move(fromOffsets: fromOffsets, toOffset: toOffset)
                                    reorderFiltersTip.invalidate(reason: .actionPerformed)
                                }
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.04))
                        .listRowSeparator(.hidden)
                        .listSectionSeparator(.hidden)
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    List {
                        Section("Preset filters") {
                            ForEach(searchResults) { filter in
                                Button(filter.stylizedName, systemImage: "plus.circle") {
                                    model.filters.append(filter)
                                    withAnimation(.interactiveSpring) {
                                        query = ""
                                    }
                                }
                            }
                        }
                        
                        Section("Custom CIFilters") {
                            ForEach(customCIFilterSearchResults, id: \.self) { filterName in
                                Button(filterName, systemImage: "plus.circle") {
                                    if let filter = CIFilter(name: filterName) {
                                        filter.setDefaults()
                                        model.customCIFilters.append(filter)
                                        withAnimation(.interactiveSpring) {
                                            query = ""
                                        }
                                    }
                                }
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
            .onAppear {
                lookups = DocumentStore.shared.getAllLookupImageURLs()
            }
            .navigationTitle("Filter Mixer")
        } // NavigationStack
        .searchable(text: $query, prompt: "Look for a filter") {
            Section("Preset Filters") {
                ForEach(searchResults) { result in
                    Text(result.stylizedName).font(.caption)
                        .searchCompletion(result.stylizedName)
                }
            }
            Section("Custom CIFilters") {
                ForEach(customCIFilterSearchResults, id: \.self) { result in
                    Text(result).font(.caption)
                        .searchCompletion(result)
                }
            }
        }
        .submitLabel(.done)
        .onSubmit(of: .search) {
            if let firstResult = searchResults.first, !query.isEmpty {
                model.filters.append(firstResult)
                withAnimation(.interactiveSpring) {
                    query = ""
                }
            } else if let firstResult = customCIFilterSearchResults.first, !query.isEmpty,
                      let filter = CIFilter(name: firstResult) {
                filter.setDefaults()
                model.customCIFilters.append(filter)
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
                            
                            Button("Save to files", systemImage: "archivebox") {
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
                            
                            Button("Save to files", systemImage: "archivebox") {
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
                        
                        Button("Save to files", systemImage: "archivebox") {
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
    @State private var isPresentingImage = false
    @State private var imageToPresent: ImagePresentationID?
    @State private var isPresentingPhotosPicker = false
    
    private let changeSourceImageTip = ChangeSourceImageTip()
    private let addLookupImageTip = AddLookupImageTip()
    
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
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: spacing) {
                if isPipEnabled {
                    Spacer()
                }
                
                Group {
                    if model.isLiveMode,
                       let camera = model.camera {
                        CameraView(camera.captureSession)
                    } else {
                        Image(uiImage: model.originalImage)
                            .resizable().scaledToFit()
                    }
                } // Group
                .frame(maxWidth: originalImageSize, maxHeight: originalImageSize)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .padding(.top, isPipEnabled ? 16 : 0)
                .matchedTransitionSource(id: ImagePresentationID.originalImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .originalImage
                    isPresentingImage = true
                }
                .contextMenu {
                    Label("Original image", systemImage: "photo")
                    
                    Button("Choose new photo", systemImage: "photo") {
                        isPresentingPhotosPicker = true
                    }
                }
                .popoverTip(changeSourceImageTip, arrowEdge: .top)
                .zIndex(1)
                
                Group {
                    if model.isLiveMode {
                        MTKViewRepresentable(mtkView: model.renderView)
                            .aspectRatio(1080/1920, contentMode: .fill)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(maxWidth: proxy.size.width / 2 - 8)
                    } else {
                        Image(uiImage: model.filteredImage)
                            .resizable().scaledToFit()
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
                .matchedTransitionSource(id: ImagePresentationID.filteredImage, in: imageTransition)
                .onTapGesture {
                    imageToPresent = .filteredImage
                    isPresentingImage = true
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
                .popoverTip(addLookupImageTip, arrowEdge: .top)
                .zIndex(0)
                
                Spacer()
            } // HStack
        } // GeometryReader
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
    }
    
    private var compactSizedContent: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: model.isLiveMode ? 32 : 0) {
                    Group {
                        if model.isLiveMode,
                           let camera = model.camera {
                            CameraView(camera.captureSession)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipShape(.rect(cornerRadius: 8))
                        } else {
                            Image(uiImage: model.originalImage)
                                .resizable().scaledToFit()
                                .clipShape(.rect(cornerRadius: 12))
                                .frame(width: proxy.size.width)
                                .unveilingScrollEffect()
                        }
                    }
                    .matchedTransitionSource(id: ImagePresentationID.originalImage, in: imageTransition)
                    .onTapGesture {
                        imageToPresent = .originalImage
                        isPresentingImage = true
                    }
                    .contextMenu {
                        Label("Original image", systemImage: "photo")
                        
                        Button("Choose new photo", systemImage: "photo") {
                            isPresentingPhotosPicker = true
                        }
                    }
                    
                    Group {
                        if model.isLiveMode {
                            MTKViewRepresentable(mtkView: model.renderView)
                                .aspectRatio(1080/1920, contentMode: .fill)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipShape(.rect(cornerRadius: 8))
                        } else {
                            Image(uiImage: model.filteredImage)
                                .resizable().scaledToFit()
                                .clipShape(.rect(cornerRadius: 12))
                                .frame(width: proxy.size.width)
                                .unveilingScrollEffect()
                        }
                    }
                    .matchedTransitionSource(id: ImagePresentationID.filteredImage, in: imageTransition)
                    .onTapGesture {
                        imageToPresent = .filteredImage
                        isPresentingImage = true
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
                } // HStack
                .scrollTargetLayout()
            } // ScrollView
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .frame(width: proxy.size.width)
        } // GeometryReader
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Button("Generate CLUT", systemImage: "swatchpalette") {
                    Task { await model.processLookupImage() }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.system(size: 14, weight: .medium))
                
                LookupView(lookupImage: $model.filteredLookupImage)
            }
            .safeAreaPadding(8)
        }
    }
    
    var body: some View {
        Group {
            switch horizontalSizeClass {
            case .compact: compactSizedContent
            default: regularSizedContent
            }
        }
        .safeAreaPadding(12)
        .sheet(isPresented: $isPresentingImage, onDismiss: {
            imageToPresent = nil
        }) {
            ImagePresentationView(imageTransition: imageTransition,
                                  presentationId: $imageToPresent.animation(.snappy))
            .environmentObject(model)
        }
        .photosPicker(isPresented: $isPresentingPhotosPicker, selection: Binding(get: { nil }, set: loadSelection), matching: .images)
    }
}

private enum ImagePresentationID: String, Identifiable, CaseIterable {
    case originalImage, filteredImage, bothImages
    
    var title: String {
        rawValue.camelCaseToReadableFormatted()
    }
    
    var systemImage: String {
        switch self {
        case .originalImage: "photo"
        case .filteredImage: "photo.on.rectangle"
        case .bothImages: "photo.stack"
        }
    }
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

private struct ImagePresentationView: View {
    var imageTransition: Namespace.ID
    @Binding var presentationId: ImagePresentationID?
    
    @EnvironmentObject private var model: FilterMixer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var originalFeed: some View {
        VStack(spacing: 16) {
            Group {
                if model.isLiveMode,
                   let camera = model.camera {
                    CameraView(camera.captureSession)
                } else {
                    Image(uiImage: model.originalImage)
                        .resizable().scaledToFit()
                }
            }
            .clipShape(.rect(cornerRadius: 12))
            .navigationTransition(.zoom(sourceID: ImagePresentationID.originalImage, in: imageTransition))
            
            Label(model.isLiveMode ? "Original camera feed" : "Original image",
                  systemImage: model.isLiveMode ? "camera" : "photo")
            .font(.title2.bold())
            .foregroundStyle(.secondary)
        }
    }
    
    private var filteredFeed: some View {
        VStack(spacing: 16) {
            Group {
                if model.isLiveMode {
                    GeometryReader { proxy in
                        MTKViewRepresentable(mtkView: model.presentationRenderView)
                            .aspectRatio(1080/1920, contentMode: .fill)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxHeight: proxy.size.height)
                    }
                } else {
                    Image(uiImage: model.filteredImage)
                        .resizable().scaledToFit()
                }
            }
            .clipShape(.rect(cornerRadius: 12))
            .navigationTransition(.zoom(sourceID: ImagePresentationID.filteredImage, in: imageTransition))
            
            Label(model.isLiveMode ? "Filtered camera feed" : "Filtered image",
                  systemImage: model.isLiveMode ? "camera.fill" : "photo.on.rectangle")
            .font(.title2.bold())
            .foregroundStyle(.secondary)
        }
    }
    
    private var layout: AnyLayout {
        switch horizontalSizeClass {
        case .compact: AnyLayout(VStackLayout(spacing: 16))
        default: AnyLayout(HStackLayout(spacing: 16))
        }
    }
    
    var body: some View {
        if let presentationId {
            VStack(spacing: 16) {
                layout {
                    if presentationId != .filteredImage {
                        originalFeed
                            .transition(horizontalSizeClass == .compact
                                        ? .move(edge: .top).combined(with: .opacity)
                                        : .move(edge: .leading).combined(with: .offset(x: -16)))
                    }
                    
                    if presentationId != .originalImage {
                        filteredFeed
                            .transition(horizontalSizeClass == .compact
                                        ? .move(edge: .bottom).combined(with: .opacity)
                                        : .move(edge: .trailing).combined(with: .offset(x: 16)))
                    }
                }
                .simultaneousGesture(DragGesture()
                    .onEnded({ value in
                        guard abs(value.translation.height) < 100 else { return }
                        if value.predictedEndTranslation.width > 250 {
                            withAnimation(.snappy) {
                                self.presentationId?.cycle(reverse: true)
                            }
                        } else if value.predictedEndTranslation.width < -250 {
                            withAnimation(.snappy) {
                                self.presentationId?.cycle()
                            }
                        }
                    }))
                
                Picker("Layout", systemImage: "square.grid.2x2", selection: $presentationId) {
                    ForEach(ImagePresentationID.allCases) { tag in
                        Label(tag.title, systemImage: tag.systemImage)
                            .tag(tag)
                    }
                }
                .pickerStyle(.segmented)
            }
            .safeAreaPadding(.horizontal, 16)
            .safeAreaPadding(.vertical)
        } else {
            ContentUnavailableView("Nothing to present", systemImage: "xmark")
                .foregroundStyle(.secondary)
        }
    }
}

private struct HeaderViewDropDelegate: DropDelegate {
    var geometry: GeometryProxy
    @Binding var hasImage: Bool
    @Binding var isHoveringOnTheRightHalf: Bool
    var lookupImageDropped: (UIImage) -> Void
    var sourceImageDropped: (UIImage) -> Void
    
    func dropEntered(info: DropInfo) {
        if info.hasItemsConforming(to: [.image]) {
            withAnimation(.smooth) {
                hasImage = true
            }
        }
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.image]) else {
            withAnimation(.smooth) {
                hasImage = false
            }
            return false
        }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        guard info.hasItemsConforming(to: [.image]) else { return .init(operation: .forbidden) }
        withAnimation(.interactiveSpring) {
            isHoveringOnTheRightHalf = info.location.x > geometry.size.width/2
        }
        return .init(operation: .copy)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.image]).first else { return false }
        _ = itemProvider.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else { return }
                Task { @MainActor in
                    if info.location.x > geometry.size.width/2 {
                        lookupImageDropped(image)
                    } else {
                        sourceImageDropped(image)
                    }
                }
            case .failure(let error):
                print("Failed to perform drop: \(error)")
            }
        }
        withAnimation(.smooth) {
            hasImage = false
            isHoveringOnTheRightHalf = false
        }
        return true
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.smooth) {
            hasImage = false
        }
    }
}

extension DefaultsContainer {
    var isRegularSlider: Bool {
        false
    }
}
