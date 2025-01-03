//
//  GridShape.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 1/4/25.
//

import SwiftUI

struct GridShape: Shape {
    var side: Int = 3
    var drawOutside: Bool = false
    
    nonisolated func path(in rect: CGRect) -> Path {
        let range = drawOutside ? 0...side : 1...side-1
        
        var path = Path()
        
        range.forEach { stop in
            let stopX = rect.width * CGFloat(stop) / CGFloat(side)
            path.move(to: CGPoint(x: stopX, y: rect.minY))
            path.addLine(to: CGPoint(x: stopX, y: rect.maxY))
        }
        
        range.forEach { stop in
            let stopY = rect.height * CGFloat(stop) / CGFloat(side)
            path.move(to: CGPoint(x: rect.minX, y: stopY))
            path.addLine(to: CGPoint(x: rect.maxX, y: stopY))
        }
        
        return path
    }
}
