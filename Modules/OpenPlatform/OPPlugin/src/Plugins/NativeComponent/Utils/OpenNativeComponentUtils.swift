//
//  OpenNativeComponentUtils.swift
//  OPPlugin
//
//  Created by zhujingcheng on 3/6/23.
//

import Foundation

final class OpenNativeComponentUtils {
    class func checkAndConvertVideoHeader(header: [String: Any]) -> [String: String] {
        var result: [String: String] = [:]
        header.forEach { (key: String, value: Any) in
            if value is String {
                result[key] = value as? String
            } else if value is NSNumber {
                let number = value as? NSNumber
                if CFNumberGetType(number) == .charType {
                    if number == 0 {
                        result[key] = "false"
                    } else if number == 1 {
                        result[key] = "true"
                    }
                } else {
                    result[key] = "\(value)"
                }
            }
        }
        return result
    }
}
