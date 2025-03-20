//
//  Tips.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/20/25.
//

import Foundation
import TipKit

struct AddFilterTip: Tip {
    var title: Text {
        Text("Add a filter").foregroundStyle(Color.accentColor)
    }
    
    var message: Text {
        Text("Add a filter by pressing the plus button.")
    }
    
    var image: Image {
        Image(systemName: "camera.filters")
    }
}

struct EnablePipTip: Tip {
    var title: Text {
        Text("Enable Picture-in-Picture (PiP)").foregroundStyle(.cyan)
    }
    
    var message: Text {
        Text("Enable Picture-in-picture by pressing the PiP button.")
    }
    
    var image: Image {
        Image(systemName: "pip.enter")
    }
}

struct ChangeSourceImageTip: Tip {
    var title: Text {
        Text("Update source image").foregroundStyle(.teal)
    }
    
    var message: Text {
        Text("Update source image by long-pressing or dropping an image on the left side.")
    }
    
    var image: Image {
        Image(systemName: "photo")
    }
}

struct AddLookupImageTip: Tip {
    var title: Text {
        Text("Add a custom CLUT").foregroundStyle(.orange)
    }
    
    var message: Text {
        Text("Add a custom CLUT by dropping an image on the right side.")
    }
    
    var image: Image {
        Image(systemName: "swatchpalette")
    }
}

struct ReorderFiltersTip: Tip {
    static let addFilterEvent = Event(id: "addFilter")
    
    var title: Text {
        Text("Reorder filters").foregroundStyle(Color.accentColor)
    }
    
    var message: Text {
        Text("Reorder filters by dragging them across the vertical axis. Press the edit button in the toolbar to show the handle.")
    }
    
    var image: Image {
        Image(systemName: "line.3.horizontal")
    }
    
    var rules: [Rule] {
        #Rule(Self.addFilterEvent) { event in
            event.donations.count > 1
        }
    }
}

struct ReorderCustomClutsTip: Tip {
    static let addClutEvent = Event(id: "addClut")
    
    var title: Text {
        Text("Reorder CLUTs").foregroundStyle(Color.accentColor)
    }
    
    var message: Text {
        Text("Reorder custom CLUTs by dragging them across the vertical axis. Press the edit button in the toolbar to show the handle.")
    }
    
    var image: Image {
        Image(systemName: "line.3.horizontal")
    }
    
    var rules: [Rule] {
        #Rule(Self.addClutEvent) { event in
            event.donations.count > 1
        }
    }
}

struct ReorderCustomCIFiltersTip: Tip {
    static let addCIFilterEvent = Event(id: "addCIFilter")
    
    var title: Text {
        Text("Reorder CIFilters").foregroundStyle(Color.accentColor)
    }
    
    var message: Text {
        Text("Reorder CIFilters by dragging them across the vertical axis. Press the edit button in the toolbar to show the handle.")
    }
    
    var image: Image {
        Image(systemName: "line.3.horizontal")
    }
    
    var rules: [Rule] {
        #Rule(Self.addCIFilterEvent) { event in
            event.donations.count > 1
        }
    }
}
