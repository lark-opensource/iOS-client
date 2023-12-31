//
//  EmotionLauncherDelegate.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import Foundation
import LarkAccountInterface

/// 切租户/冷启动/重新登陆会重新加载一次兜底数据
final class EmotionLauncherDelegate: PassportDelegate {
    var name: String = "EmotionLauncherDelegate"

    /// 切租户，需要在很早的时机加载数据（Feed会用），故在此时机进行加载
    func userDidOnline(state: PassportState) {
        if case .switch = state.action {
            EmotionUtils.logger.info("beforeSwitchSetAccount start")
            EmotionResouce.shared.reloadResouces()
        }
    }
}
