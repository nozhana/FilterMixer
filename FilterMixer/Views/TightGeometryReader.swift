//
//  TightGeometryReader.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/19/25.
//

import SwiftUI

struct TightGeometryReader<Content, C>: View where Content: View, C: CoordinateSpaceProtocol {
    var coordinateSpace: C 
    @ViewBuilder var content: (CGRect, CGRect?) -> Content
    @State private var frame: CGRect = .zero
    @State private var bounds: CGRect?
    
    var body: some View {
        content(frame, bounds)
            .background(
                GeometryReader { geometry in
                    let frame = geometry.frame(in: coordinateSpace)
                    let bounds = coordinateSpace is NamedCoordinateSpace ? geometry.bounds(of: coordinateSpace as! NamedCoordinateSpace) : nil
                    Color.clear
                        .preference(key: FramePreferenceKey.self, value: frame)
                        .preference(key: BoundsPreferenceKey.self, value: bounds)
                }
            )
            .onPreferenceChange(FramePreferenceKey.self) { newFrame in
                frame = newFrame
            }
            .onPreferenceChange(BoundsPreferenceKey.self) { newBounds in
                bounds = newBounds
            }
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct BoundsPreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue()
    }
}
