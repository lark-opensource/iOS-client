//
//  MineGuideHelper.swift
//  LarkMine
//
//  Created by liuxianyu on 2021/8/10.
//

import Foundation
import LarkGuide

enum MineGuideKey: String {
    case userAgreementUpdateTip = "user_agreement_update_tip" // 用户协议更新红点提示
    case userPrivacyUpdateTip = "user_privacy_update_tip" // 隐私声明更新红点提示
}

/// 红点提示优先级：版本更新 > 用户协议 > 隐私声明
enum MineTipType: Int {
    case noneTip //无提示
    case upgradeTip //版本更新
    case userAgreementUpdateTip //用户协议
    case userPrivacyUpdateTip // 隐私声明
}

final class MineGuideHelper {

    class func checkTipType(_ shouldUpdate: Bool, _ newGuideManager: NewGuideService) -> MineTipType {

        guard !shouldUpdate else {
            return .upgradeTip
        }

        guard !newGuideManager.checkShouldShowGuide(key: MineGuideKey.userAgreementUpdateTip.rawValue) else {
            return .userAgreementUpdateTip
        }

        guard !newGuideManager.checkShouldShowGuide(key: MineGuideKey.userPrivacyUpdateTip.rawValue) else {
            return .userPrivacyUpdateTip
        }

        return .noneTip
    }
}
