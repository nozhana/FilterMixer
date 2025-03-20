//
//  MTKViewRepresentable.swift
//  FilterMixer
//
//  Created by Nozhan on 12/28/1403 AP.
//

import MetalKit
import SwiftUI

struct MTKViewRepresentable: UIViewRepresentable {
    var mtkView: MTKView
    
    func makeUIView(context: Context) -> MTKView {
        mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
}
