//
//  UDKVDomainItem.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/21.
//

#if !LARK_NO_DEBUG
import Foundation

enum UDKVType: String {
    case bool, number, string, data, unknown
}

struct UDKVDomainItem: SearchTableItem {
    let key: String
    let actualKey: String
    let value: Any

    var title: String { key }

    func bool() -> Bool? {
        guard String(describing: Swift.type(of: value)) == "__NSCFBoolean" else {
            return nil
        }
        return value as? Bool
    }

    func number() -> NSNumber? {
        guard let number = value as? NSNumber else {
            return nil
        }
        guard String(describing: Swift.type(of: value)) != "__NSCFBoolean" else {
            return nil
        }
        return number
    }

    func string() -> String? {
        return value as? String
    }

    func data() -> Data? {
        return value as? Data
    }
}

extension UDKVDomainItem: Equatable {
    static func == (lhs: UDKVDomainItem, rhs: UDKVDomainItem) -> Bool {
        if lhs.key == rhs.key {
            if let lhs = lhs.bool(), let rhs = rhs.bool() {
                return lhs == rhs
            } else if let lhs = lhs.number(), let rhs = rhs.number() {
                return lhs == rhs
            } else if let lhs = lhs.string(), let rhs = rhs.string() {
                return lhs == rhs
            } else if let lhs = lhs.data(), let rhs = rhs.data() {
                return lhs == rhs
            }
        }
        return false
    }
}

extension UDKVDomainItem: CustomStringConvertible {
    var description: String {
        if let bool = self.bool() {
            return bool.description
        } else if let data = self.data(), let text = String(data: data, encoding: .utf8) {
            return text
        }
        return String(describing: self.value)
    }
}
#endif
