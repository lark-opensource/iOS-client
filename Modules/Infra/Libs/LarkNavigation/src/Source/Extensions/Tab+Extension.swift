//
//  Tab+Extension.swift
//  LarkNavigation
//
//  Created by KT on 2020/2/2.
//

import Foundation
import AnimatedTabBar
import LarkTab

public extension Tab {
    var tabName: String {
        var name: String = ""
        // 本地配置
        if let locoal = TabConfig.defaultConfig(for: self.key, of: self.appType).name {
            name = locoal
        }
        // 小程序/h5 读取下发
        if self.appType != .native, let remote = self.remoteName {
            name = remote
        }
        // 自定义类型
        if self.isCustomType() {
            name = self.name ?? name
        }
        return name
    }

    var remoteName: String? {
        let name = self.extra[NavigationKeys.name] as? [String: String]
        return TabMeta.getName(in: name ?? [:])
    }
}
