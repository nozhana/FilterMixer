//
//  CameraView.swift
//  FilterMixer
//
//  Created by Nozhan on 12/28/1403 AP.
//

import AVFoundation
import SwiftUI

struct CameraView: UIViewRepresentable {
    var session: AVCaptureSession
    
    init(_ session: AVCaptureSession) {
        self.session = session
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ view: PreviewView, context: Context) {}
    
    static func dismantleUIView(_ view: PreviewView, coordinator: ()) {
        view.session = nil
    }
}

extension CameraView {
    final class PreviewView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            DispatchQueue.main.async { [weak self] in
                self?.previewLayer.videoGravity = .resizeAspectFill
            }
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            DispatchQueue.main.async { [weak self] in
                self?.previewLayer.videoGravity = .resizeAspectFill
            }
        }
        
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        
        private var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
        
        var session: AVCaptureSession? {
            get { previewLayer.session }
            set {
                DispatchQueue.main.async { [weak self] in
                    newValue?.beginConfiguration()
                    defer { newValue?.commitConfiguration() }
                    self?.previewLayer.session = newValue
                }
            }
        }
    }
}
