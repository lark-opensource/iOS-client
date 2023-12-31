//
//  JSON+LarkUIKit.swift
//  LarkUIKit
//
//  Created by lichen on 2018/4/12.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

func JSONDataWithObject(object: Any) -> Data? {
    do {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return data
    } catch {
        return nil
    }
}

public func JSONStringWithObject(object: Any) -> String {
    guard let data = JSONDataWithObject(object: object) else {
        return ""
    }
    return String(data: data, encoding: .utf8) ?? ""
}
