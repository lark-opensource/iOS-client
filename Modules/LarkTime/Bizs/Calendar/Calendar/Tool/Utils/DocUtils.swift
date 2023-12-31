//
//  DocUtils.swift
//  Calendar
//
//  Created by pluto on 2022-10-12.
//

import UIKit
import Foundation
import EENavigator
import LarkNavigator

struct DocUtils {

    /// 此函数需要在主线程调用
    static func docUrlDetector(_ str: String, userNavigator: UserNavigator) -> Bool {
        var detectedStr = str.removingPercentEncoding ?? str
        if detectedStr.isEmpty { return false }
        var hasDoc: Bool = false
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let detector = detector {
            let matches = detector.matches(in: detectedStr, range: NSRange(location: 0, length: detectedStr.count - 1))
                .map { item in
                    if let url = item.url {
                        /// check url 是否为docURL ，底层最终会调用到SKCommon的URLValidator.isDocsURL方法，跨环境链接不可识别
                        let param = userNavigator.response(for: url, context: [:], test: true).parameters
                        if param["_canOpenInDocs"] as? Bool == true {
                            hasDoc = true
                        }
                    }
                }
        }
        return hasDoc
    }
    
    static func encryptDocInfo(_ source: String) -> String {
        let md5Value = (source + "42b91e").md5()
        let sha1Value = ("08a441" + md5Value).sha1()
        return sha1Value
    }
}
