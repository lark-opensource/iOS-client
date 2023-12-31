//
//  Extensions.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/23.
//

import UIKit
import SSZipArchive

extension Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var LSCBundle: Bundle? = {
        let bundleName = "LarkSensitivityControl"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: TokenConfigManager.self).resourceURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return nil
    }()
}

/*
/// 线程安全的字典
///
/// 只保证了使用的方法线程安全，后续再根据需要继续拓展
class SafeDictionary<Key: Hashable, Value>: CustomDebugStringConvertible {

    private var elements = [Key: Value]()
    private let queue = DispatchQueue(label: "LarkSensitivityControl.current.queue", attributes: .concurrent)

    subscript(key: Key) -> Value? {
        get {
            queue.sync {
                elements[key]
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.elements[key] = newValue
            }
        }
    }

    var keys: Dictionary<Key, Value>.Keys {
        queue.sync {
            elements.keys
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.elements.removeAll()
        }
    }

    var debugDescription: String {
        return elements.debugDescription
    }
}
 */
