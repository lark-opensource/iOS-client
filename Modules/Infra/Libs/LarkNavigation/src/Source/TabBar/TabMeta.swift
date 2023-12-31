//
//  TabMeta.swift
//  LarkNavigation
//
//  Created by Meng on 2019/12/17.
//

import Foundation
import RustPB
import LarkUIKit
import LarkLocalizations
import LarkTab

struct TabMeta: Codable {
    var key: String
    var appType: String
    var source: Int
    var name: [String: String]

    init(key: String, appType: String, name: [String: String], source: Int) {
        self.key = key
        self.appType = appType
        self.name = name
        self.source = source
    }

    var currentName: String? {
        return TabMeta.getName(in: self.name)
    }

    // 取[name]中对应国际化的名称，目前一方应用名称读取本地
    static func getName(in map: [String: String]) -> String? {
        var name: String? = map[LanguageManager.currentLanguage.identifier]
        if name == nil { name = map[LanguageManager.currentLanguage.identifier.lowercased()] }
        // 如果没有目标语言，降级
        if name == nil { name = map[NavigationKeys.Name.en_US] }
        if name == nil { name = map[NavigationKeys.Name.zh_CN] }
        return name
    }
}

extension TabMeta: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(appType)
        hasher.combine(source)
    }
}
