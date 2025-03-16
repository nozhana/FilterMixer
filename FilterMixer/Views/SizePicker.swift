//
//  SizePicker.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import SwiftUI

struct SizePicker: View {
    @Binding var size: CGSize
    @State private var lastSize: CGSize
    
    init(size: Binding<CGSize>) {
        self._size = size
        self._lastSize = State(initialValue: size.wrappedValue)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                CustomSlider(value: $size.height, in: 0...0.75, orientation: .vertical)
                    .frame(height: geometry.size.height * 0.8)

                VStack {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 112, height: 112)
                        
                        GridShape()
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.primary.opacity(0.25))
                            .frame(width: 112, height: 112)
                        
                        Ellipse()
                            .fill(.blue)
                            .frame(width: geometry.size.width * size.width, height: geometry.size.height * size.height)
                            .shadow(color: .blue.mix(with: .black, by: 0.5).opacity(0.12), radius: 4, y: 1)
                    } // ZStack
                    .clipShape(.rect(cornerRadius: 8))
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let width = (lastSize.width * value.magnification).clamped(to: 0...1)
                                let height = (lastSize.height * value.magnification).clamped(to: 0...1)
                                let halfWidth = (lastSize.width + width) / 2
                                let halfHeight = (lastSize.height + height) / 2
                                size = CGSize(width: halfWidth, height: halfHeight)
                            }
                            .onEnded { _ in
                                lastSize = size
                            }
                            .simultaneously(
                                with: TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation(.smooth) {
                                            size = CGSize(width: 0.5, height: 0.5)
                                        }
                                    }
                            )
                    )
                    CustomSlider(value: $size.width, in: 0...0.75)
                        .frame(width: geometry.size.width * 0.8)
                } // VStack
            } // HStack
            .font(.caption)
        } // GeometryReader
        .frame(width: 136, height: 136)
    }
}
