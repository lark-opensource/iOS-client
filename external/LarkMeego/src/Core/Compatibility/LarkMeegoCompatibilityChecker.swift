//
//  LarkMeegoCompatibilityChecker.swift
//  LarkMeego
//
//  Created by qsc on 2023/8/7.
//

import Foundation
import LarkSetting
import EENavigator

/// Meego Flutter 业务兼容性，forceUpgrade 时客户端需要升级后才能进入 Flutter, 可进入网页版作为兜底
/// https://bytedance.feishu.cn/wiki/PABqwVkoHiPhfakwuLbct3tknbd
enum MeegoCompatibility {
    /// Flutter 不兼容，需要强制升级，可进入网页版作为兜底
    case forceUpgrade
    /// 提醒用户可以升级新版本
    case remindUpgrade
}

extension MeegoCompatibility {
    func routeEndResource(with request: EENavigator.Request) -> Resource {
        switch self {
        case .forceUpgrade:
            return LarkMeegoCompatiblityViewController(req: request)
        case .remindUpgrade:
            return EmptyResource()
        }
    }

    func buildFlutterViewEventHandler(config: MeegoAbilityConfig, route: String, from: String) -> FlutterViewEventHandler {
        return FlutterViewEventHandler(abilityConfig: config, route: route, from: from)
    }
}
