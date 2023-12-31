//
//  Utils.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/7/31.
//

import Foundation

extension String {
    func appendingPathComponent(_ path: String) -> String {
        URL(fileURLWithPath: self).appendingPathComponent(path).path
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }
        } catch {
            return []
        }
    }
    func versionArray() -> [String] {
        return self.components(separatedBy: ".")
    }
}

@propertyWrapper
struct ThreadSafe<Value> {
    private let semaphore = DispatchSemaphore(value: 1)
    private var value: Value

    init(wrappedValue: Value) {
        value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            semaphore.wait()
            defer {
                semaphore.signal()
            }
            return value
        }

        set {
            semaphore.wait()
            defer {
                semaphore.signal()
            }
            value = newValue
        }
    }
}
