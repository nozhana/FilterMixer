//
//  CustomSlider.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import SwiftUI

struct CustomSlider: View {
    enum Orientation {
        case horizontal, vertical
    }
    
    @Binding var value: CGFloat
    var range: ClosedRange<Double>
    var orientation: Orientation
    
    private var normalizedValue: Double {
        value / (range.upperBound - range.lowerBound)
    }
    
    init(value: Binding<CGFloat>, in range: ClosedRange<Double>, orientation: Orientation = .horizontal) {
        self._value = value
        self.range = range
        self.orientation = orientation
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: orientation == .horizontal ? .leading : .bottom) {
                if orientation == .horizontal {
                    Capsule()
                        .fill(.thinMaterial)
                        .frame(height: 6)
                        .background {
                            HStack {
                                Text(range.lowerBound.formatted())
                                Spacer()
                                Text(range.upperBound.formatted())
                            }
                            .font(.caption)
                            .offset(y: 10)
                        }
                    
                    Capsule()
                        .fill(.blue)
                        .frame(width: geometry.size.width * normalizedValue, height: 6)
                    
                    ZStack {
//                        Text(value.formatted())
//                            .font(.caption)
//                            .offset(y: 14)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                            .position(x: geometry.size.width * normalizedValue, y: 9)
                            .gesture(
                                DragGesture(coordinateSpace: .named("slider"))
                                    .onChanged { value in
                                        let normalizedX = value.location.x / geometry.size.width
                                        self.value = (normalizedX * (range.upperBound - range.lowerBound))
                                            .clamped(to: range)
                                    }
                            )
                    }
                } else {
                    Capsule()
                        .fill(.thinMaterial)
                        .frame(width: 6)
                        .background {
                            VStack {
                                Text(range.upperBound.formatted())
                                    .rotationEffect(.degrees(90), anchor: .topLeading)
                                    .fixedSize()
                                    .frame(width: 4, height: 100)
                                Text(range.lowerBound.formatted())
                                    .rotationEffect(.degrees(90), anchor: .topLeading)
                                    .fixedSize()
                                    .frame(width: 4, height: 100)
                            }
                            .font(.caption)
                            .offset(y: 4)
                        }
                    
                    Capsule()
                        .fill(.blue)
                        .frame(width: 6, height: geometry.size.height * normalizedValue)
                    
                    ZStack {
//                        Text(value.formatted())
//                            .font(.caption)
//                            .offset(x: -14)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                            .position(x: 9, y: geometry.size.height * (1 - normalizedValue))
                            .gesture(
                                DragGesture(coordinateSpace: .named("slider"))
                                    .onChanged { value in
                                        let normalizedY = 1 - value.location.y / geometry.size.height
                                        self.value = (normalizedY * (range.upperBound - range.lowerBound))
                                            .clamped(to: range)
                                    }
                            )
                    }
                }
            } // ZStack
            .frame(maxWidth: orientation == .horizontal ? .infinity : 16, maxHeight: orientation == .horizontal ? 16 : .infinity)
            .coordinateSpace(.named("slider"))
        } // GeometryReader
        .sensoryFeedback(.selection, trigger: value)
    }
}
