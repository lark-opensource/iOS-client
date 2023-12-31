//
//  Encodable.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import UniversalCardInterface
extension Encodable {
    public func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError(domain: "error", code: 0, userInfo: ["reason": "Encodable :\(self) use JSONSerialization serialize to dictionary fail"])
        }
        return dictionary
    }
}
