//
//  SliderColorPicker.swift
//  FilterMixer
//
//  Created by Nozhan on 12/21/1403 AP.
//

import GPUImage
import SwiftUI

struct SliderColorPicker: View {
    var title: String
    @Binding var gpuImageColor: GPUImage.Color
    
    @State private var internalColor: GPUImage.Color
    
    init(_ title: String, color: Binding<GPUImage.Color>) {
        self.title = title
        _gpuImageColor = color
        _internalColor = .init(initialValue: color.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            
            ForEach(ColorComponent.allCases) { component in
                HStack {
                    Text(component.rawValue.capitalized).font(.subheadline)
                    Spacer()
                    Text(internalColor[component].formatted()).font(.caption).foregroundStyle(.yellow)
                    WheelSlider(value: Binding(get: { internalColor[component] }, set: { internalColor[component] = $0 }), in: 0...1, step: 0.02)
                        .onChange(of: internalColor) { _, newValue in
                            gpuImageColor = newValue
                        }
                }
            }
        }
        .safeAreaPadding(.horizontal, 12)
        .safeAreaPadding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(.tertiary, style: .init(lineWidth: 1, dash: [8, 12])))
    }
}

#Preview {
    @Previewable @State var color = GPUImage.Color(red: 0.25, green: 0.5, blue: 0.75)
    
    VStack {
        SliderColorPicker("My Color", color: $color)
        RoundedRectangle(cornerRadius: 12)
            .fill(color.swiftUiColor)
            .frame(width: 200, height: 200)
    }
    .safeAreaPadding(.horizontal)
}

private enum ColorComponent: String, CaseIterable, Identifiable {
    case red, green, blue
    
    var keyPath: KeyPath<GPUImage.Color, Float> {
        switch self {
        case .red: \.redComponent
        case .green: \.greenComponent
        case .blue: \.blueComponent
        }
    }
}

private extension GPUImage.Color {
    subscript(_ component: ColorComponent) -> Float {
        get { self[keyPath: component.keyPath] }
        set {
            self = .init(red: component == .red ? newValue : redComponent,
                         green: component == .green ? newValue : greenComponent,
                         blue: component == .blue ? newValue : blueComponent,
                         alpha: alphaComponent)
        }
    }
}

extension GPUImage.Color: @retroactive Equatable {
    public static func == (lhs: GPUImage.Color, rhs: GPUImage.Color) -> Bool {
        lhs.redComponent == rhs.redComponent &&
        lhs.greenComponent == rhs.greenComponent &&
        lhs.blueComponent == rhs.blueComponent &&
        lhs.alphaComponent == rhs.alphaComponent
    }
}
