//
//  Defaults.swift
//  FilterMixer
//
//  Created by Nozhan Amiri on 3/14/25.
//

import SwiftUI

@propertyWrapper
struct Defaults<T>: DynamicProperty where T: Codable {
    private var store: UserDefaults
    private var key: String
    @State private var setNeedsDisplay = false
    @State private var internalValue: T {
        willSet {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            store.set(data, forKey: key)
            setNeedsDisplay = true
        }
    }
    
    var wrappedValue: T {
        get { internalValue }
        nonmutating set { internalValue = newValue }
    }
    
    var projectedValue: Binding<T> { _internalValue.projectedValue }
    
    func update() {
        if setNeedsDisplay,
           let data = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            DispatchQueue.main.async {
                internalValue = decoded
                setNeedsDisplay = false
            }
        }
    }
    
    init(wrappedValue: T, _ key: String, store: UserDefaults = .standard) {
        if let data = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            self._internalValue = .init(initialValue: decoded)
        } else {
            self._internalValue = .init(initialValue: wrappedValue)
            if let data = try? JSONEncoder().encode(wrappedValue) {
                store.set(data, forKey: key)
            }
        }
        self.key = key
        self.store = store
    }
    
    init(_ keyPath: KeyPath<DefaultsContainer, T>, store: UserDefaults = .standard, container: DefaultsContainer = .shared) {
        self.init(wrappedValue: container[keyPath: keyPath], "\(keyPath)", store: store)
    }
    
    init<V>(_ key: String, store: UserDefaults = .standard) where T == Optional<V> {
        if let data = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            self._internalValue = .init(initialValue: decoded)
        } else {
            self._internalValue = .init(initialValue: nil)
        }
        self.key = key
        self.store = store
    }
}

extension Defaults where T == Never {
    static subscript<V>(_ key: String, valueType: V.Type = V.self, store: UserDefaults = .standard) -> V? where V: Codable {
        get {
            guard let data = store.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(V.self, from: data) else { return nil }
            return decoded
        }
        set {
            guard let newValue else {
                store.removeObject(forKey: key)
                return
            }
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            store.set(data, forKey: key)
        }
    }
    
    static subscript<V>(_ keyPath: KeyPath<DefaultsContainer, V>, store: UserDefaults = .standard, container: DefaultsContainer = .shared) -> V where V: Codable {
        get {
            if let value = Defaults["\(keyPath)", V.self] {
                return value
            }
            let value = container[keyPath: keyPath]
            Defaults["\(keyPath)"] = value
            return value
        }
        set {
            Defaults["\(keyPath)"] = newValue
        }
    }
}

struct DefaultsContainer {
    static let shared = DefaultsContainer()
}
