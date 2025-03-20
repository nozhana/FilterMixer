//
//  CustomLookupSectionView.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/18/25.
//

import GPUImage
import SwiftUI

struct CustomLookupSectionView: View {
    var index: Int
    var isRegularSlider = false
    
    @EnvironmentObject private var model: FilterMixer
    
    var body: some View {
        if let lookupImage = model.customLookupImages[safe: index] {
            VStack {
                HStack(alignment: .top, spacing: 12) {
                    Button("Custom Lookup", systemImage: "minus.circle.fill") {
                        model.customLookupImages.remove(at: index)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Label("Layer \(index + 1)", systemImage: "square.3.layers.3d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .safeAreaPadding(.vertical, 8)
                        .safeAreaPadding(.horizontal, 10)
                        .background(.thinMaterial, in: .rect(cornerRadius: 10))
                }
                
                HStack {
                    FilterParameterView(operation: model.customLookupOperations[index], parameter: .slider(title: "intensity", range: 0...1, stepCount: 50), isRegularSlider: isRegularSlider)
                    
                    Spacer()
                    
                    Image(uiImage: lookupImage)
                        .resizable().scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
        } else {
            ContentUnavailableView("Failed to load lookup image", systemImage: "exclamationmark.triangle")
        }
    }
}
