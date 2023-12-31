//
//  Dictionary+Ext.swift
//  SpaceKit
//
//  Created by weidong fu on 15/3/2018.
//

import Foundation

extension Dictionary {
    func toString() -> String? {
        do {
            assert(JSONSerialization.isValidJSONObject(self))
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            assertionFailure("mail dict to string error")
        }
        return nil
    }

    /// Merges the given dictionary into this dictionary while using newer value for any duplicate keys.
    public mutating func merge(other: [Key: Value]?, coverKey: String? = nil) {
        guard let mergedDic = other else { return }
        for (k, v) in mergedDic {
            if let key = k as? String, key == coverKey {
                updateValue(v, forKey: k)
                continue
            }
            if let value = v as? [String: Any], var dic = self[k] as? [String: Any] {
                dic.merge(other: value)
                self[k] = dic as? Value
                continue
            }
            updateValue(v, forKey: k)
        }
    }
}
