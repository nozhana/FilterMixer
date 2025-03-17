//
//  PositionPicker.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import SwiftUI

struct PositionPicker: View {
    @Binding var position: UnitPoint
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                GridShape()
                    .stroke(lineWidth: 1)
                    .foregroundStyle(.primary.opacity(0.25))
                
                Image(systemName: "plus")
                    .imageScale(.small)
                    .foregroundStyle(.primary.opacity(0.25))
                
                Circle()
                    .fill(.blue)
                    .frame(width: 24, height: 24)
                    .shadow(color: .blue.mix(with: .black, by: 0.5).opacity(0.12), radius: 4, y: 1)
                    .position(CGPoint(x: position.x * geometry.size.width, y: position.y * geometry.size.height))
            } // ZStack
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = UnitPoint(x: value.location.x / geometry.size.width, y: value.location.y / geometry.size.height)
                    }
                    .simultaneously(
                        with:
                            TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    position = .center
                                }
                            }
                    ),
                including: .gesture
            )
            .clipShape(.rect(cornerRadius: 8))
        } // GeometryReader
        .frame(width: 112, height: 112)
    }
}
