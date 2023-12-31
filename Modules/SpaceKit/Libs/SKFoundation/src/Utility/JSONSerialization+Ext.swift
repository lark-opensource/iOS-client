//
//  JSONSerialization+Ext.swift
//  SKFoundation
//
//  Created by chenhuaguan on 2021/12/30.
//

import Foundation

extension JSONSerialization {
    public static func modelToJson<T>(_ value: T) -> Any? where T: Encodable {
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(value)
        guard let jsonData = jsonData else {
            return nil
        }
        let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        return json
    }
}
