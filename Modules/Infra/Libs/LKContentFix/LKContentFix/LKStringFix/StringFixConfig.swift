//
//  StringFixConfig.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/7.
//

import Foundation
import UIKit
import EEAtomic

struct StringFixConfig {
    static let key = "string_fix_config"

    let config: [String: [String: Any]]

    init?(fieldGroups: [String: String]) {
        guard let configData = fieldGroups[StringFixConfig.key],
            let data = configData.data(using: .utf8),
            let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
        }

        // 找到匹配当前版本的config信息
        var currVersionConfig: Any?
        jsonDict.forEach { (version, config) in
            let splits = version.split(separator: "-")
            // 只获取有效的版本区间信息
            guard splits.count == 2 else { return }
            // 版本采用字符串对比方式比较大小
            if UIDevice.current.systemVersion >= splits[0] && UIDevice.current.systemVersion <= splits[1] {
                currVersionConfig = config
                return
            }
        }

        // 过滤无效配置
        guard let config = currVersionConfig as? [String: [String: Any]] else { return nil }
        self.config = config
    }
}
