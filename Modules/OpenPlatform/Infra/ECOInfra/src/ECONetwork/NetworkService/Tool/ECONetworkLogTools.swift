//
//  ECONetworkLogTools.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/5/15.
//

import Foundation

class ECONetworkLogTools {
    private static let maxLength = 100
    private static let maxCount = 50

    private static let cookieKey = "cookie"
    private static let setCookieKey = "set-cookie"

    static func monitorValue(data: [String: Any]?) -> (total: String?, cookie: String?)? {
        guard let data = data, data.count > 0 else {
            return nil
        }
        var result = [String: String]()
        var cookieMask: String? = nil

        var currentIndex = 0
        for (key, val) in data {
            guard currentIndex < maxCount else {
                break
            }
            currentIndex += 1
            let value = mask(value: "\(val)", key: key)
            result[key] = value
            if isCookie(key: key) {
                cookieMask = value
            }
        }
        return (result.toJSONString(), cookieMask)
    }

    private static func mask(value: String, key: String?) -> String {
        let nsValue = value as NSString
        if nsValue.length > maxLength {
            let prefix = nsValue.substring(to: 1)
            return "first char is \(prefix), count is \(value.count)"
        }
        if let key = key, isCookie(key: key) {
            return cookieMask(origin: value)
        }
        return value.reuseCacheMask()
    }

    private static func isCookie(key: String) -> Bool {
        return key.lowercased() == cookieKey || key.lowercased() == setCookieKey
    }

    private static func cookieMask(origin: String) -> String {
        var result = ""

        let cookieComponents = origin.components(separatedBy: ";")
        for component in cookieComponents {
            let cookiePair = component.components(separatedBy: "=")

            if !result.isEmpty {
                result += ";"
            }

            if cookiePair.count == 1 {
                if ["secure", "httponly"].contains(cookiePair[0].lowercased()) {
                    result += cookiePair[0]
                } else {
                    result += cookiePair[0].reuseCacheMask()
                }
            } else if cookiePair.count == 2 {
                if ["domain", "expires", "samesite"].contains(cookiePair[0].lowercased()) {
                    result += "\(cookiePair[0])=\(cookiePair[1])"
                } else if cookiePair[0].lowercased() == "path" {
                    result += "\(cookiePair[0])=\(cookiePair[1].reuseCacheMask(except:["/", "."]))"
                } else {
                    result += "\(cookiePair[0].reuseCacheMask())=\(cookiePair[1].reuseCacheMask())"
                }
            } else {
                result += component.reuseCacheMask()
            }
        }

        return result
    }
}
