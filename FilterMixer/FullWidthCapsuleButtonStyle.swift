//
//  FullWidthCapsuleButtonStyle.swift
//  FilterMixer
//
//  Created by Nozhan on 12/25/1403 AP.
//

import SwiftUI

struct FullWidthCapsuleButtonStyle: ButtonStyle {
    func background(for configuration: Configuration) -> some ShapeStyle {
        switch configuration.role {
        case .cancel: AnyShapeStyle(.ultraThinMaterial.opacity(configuration.isPressed ? 0.75 : 1))
        case .destructive: AnyShapeStyle(.red.opacity(configuration.isPressed ? 0.75 : 1))
        default: AnyShapeStyle(Color.accentColor.opacity(configuration.isPressed ? 0.75 : 1))
        }
    }
    
    func foreground(for configuration: Configuration) -> some ShapeStyle {
        switch configuration.role {
        case .cancel: Color.primary
        default: Color.white
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground(for: configuration))
            .safeAreaPadding(.vertical, 12)
            .safeAreaPadding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(background(for: configuration), in: .capsule)
    }
}

extension ButtonStyle where Self == FullWidthCapsuleButtonStyle {
    static var fullWidthCapsule: Self { .init() }
}
