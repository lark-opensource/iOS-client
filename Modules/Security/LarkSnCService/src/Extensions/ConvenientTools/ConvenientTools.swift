//
//  Foundation.swift
//  LarkSnCService
//
//  Created by Hao Wang on 2023/3/2.
//

import Foundation

extension Optional {
    /// 返回可选值或默认值
    /// - 参数: 如果可选值为空，将会默认值
    public func or(_ default: Wrapped) -> Wrapped {
        return self ?? `default`
    }
}

extension Dictionary {
    public func toJsonString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }
}

extension String {
    public func toDictionary() -> [String: Any]? {
        if self.isEmpty {
            return nil
        }

        guard let data = self.data(using: .utf8) else {
            return nil
        }

        if let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
            return dict
        }
        return nil
    }
}

public protocol Emptable {
    var isEmpty: Bool { get }
}

extension Swift.Optional where Wrapped: Emptable {
    public var isEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

extension String: Emptable { }
extension Dictionary: Emptable { }
