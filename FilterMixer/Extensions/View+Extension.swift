//
//  View+Extension.swift
//  FilterMixer
//
//  Created by Nozhan on 12/20/1403 AP.
//

import SwiftUI

extension View {
    @ViewBuilder
    func evaluating(_ condition: Bool, configure: @escaping (Self) -> some View) -> some View {
        if condition {
            configure(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func unwrapping<T>(_ optional: T?, configure: @escaping (Self, T) -> some View) -> some View {
        if let unwrapped = optional {
            configure(self, unwrapped)
        } else {
            self
        }
    }
}

extension View {
    func unveilingScrollEffect(axis: Axis = .horizontal) -> some View {
        TightGeometryReader(coordinateSpace: .scrollView(axis: axis)) { frame, bounds in
            switch axis {
            case .horizontal:
                let xOffset = ((bounds?.minX ?? .zero) - frame.minX) / 2
                let xOffsetFraction = xOffset / (bounds?.width ?? UIScreen.main.bounds.width)
                let leadingAnchor = xOffsetFraction.clamped(to: -1...0)
                let trailingAnchor: CGFloat = 1
                
                self
                    .offset(x: xOffset)
                    .mask {
                        Rectangle()
                            .fill(.linearGradient(stops: [
                                .init(color: .clear, location: leadingAnchor),
                                .init(color: .black, location: leadingAnchor),
                                .init(color: .black, location: trailingAnchor),
                                .init(color: .clear, location: trailingAnchor)
                            ], startPoint: .leading, endPoint: .trailing))
                    }
            case .vertical:
                let yOffset = ((bounds?.minY ?? .zero) - frame.minY) / 2
                let yOffsetFraction = yOffset / (bounds?.height ?? UIScreen.main.bounds.height)
                let topAnchor = yOffsetFraction.clamped(to: -1...0)
                let bottomAnchor: CGFloat = 1
                
                self
                    .offset(y: yOffset)
                    .mask {
                        Rectangle()
                            .fill(.linearGradient(stops: [
                                .init(color: .clear, location: topAnchor),
                                .init(color: .black, location: topAnchor),
                                .init(color: .black, location: bottomAnchor),
                                .init(color: .clear, location: bottomAnchor)
                            ], startPoint: .top, endPoint: .bottom))
                    }
            }
        }
    }
}
