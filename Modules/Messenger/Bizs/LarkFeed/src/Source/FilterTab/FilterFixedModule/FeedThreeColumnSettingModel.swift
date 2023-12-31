//
//  FeedThreeColumnSettingModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/24.
//

import Foundation
import RustPB

final class FeedThreeColumnSettingModel {

    static let maxNumber = 999

    let mobileShowEnable: Bool // 移动端是否展示固定分组栏
    let pcShowEnable: Bool // PC端是否展示固定分组栏
    let isNewUser: Bool  // 是否新注册用户
    let updateTime: Int
    let triggerScene: Feed_V1_ThreeColumnsSetting.TriggerScene

    static func transform(_ getSettingPB: Feed_V1_GetThreeColumnsSettingResponse) -> FeedThreeColumnSettingModel {
        let mobileShowEnable = getSettingPB.setting.showMobileThreeColumns
        let pcShowEnable = getSettingPB.setting.showPcThreeColumns
        let isNewUser = getSettingPB.setting.mobileThreeColumnsNewUser
        let triggerScence = getSettingPB.setting.mobileTriggerScene
        let updateTime = getSettingPB.setting.updateTime

        return FeedThreeColumnSettingModel(mobileShowEnable: mobileShowEnable,
                                           pcShowEnable: pcShowEnable,
                                           isNewUser: isNewUser,
                                           triggerScene: triggerScence,
                                           updateTime: Int(updateTime))
    }

    static func transform(_ setSettingPB: Feed_V1_SetThreeColumnsSettingResponse) -> FeedThreeColumnSettingModel {
        let mobileShowEnable = setSettingPB.setting.showMobileThreeColumns
        let pcShowEnable = setSettingPB.setting.showPcThreeColumns
        let isNewUser = setSettingPB.setting.mobileThreeColumnsNewUser
        let triggerScence = setSettingPB.setting.mobileTriggerScene
        let updateTime = setSettingPB.setting.updateTime

        return FeedThreeColumnSettingModel(mobileShowEnable: mobileShowEnable,
                                           pcShowEnable: pcShowEnable,
                                           isNewUser: isNewUser,
                                           triggerScene: triggerScence,
                                           updateTime: Int(updateTime))
    }

    static func transform(_ pushSettingPB: Feed_V1_PushThreeColumnsSetting) -> FeedThreeColumnSettingModel {
        let mobileShowEnable = pushSettingPB.setting.showMobileThreeColumns
        let pcShowEnable = pushSettingPB.setting.showPcThreeColumns
        let isNewUser = pushSettingPB.setting.mobileThreeColumnsNewUser
        let triggerScence = pushSettingPB.setting.mobileTriggerScene
        let updateTime = pushSettingPB.setting.updateTime

        return FeedThreeColumnSettingModel(mobileShowEnable: mobileShowEnable,
                                           pcShowEnable: pcShowEnable,
                                           isNewUser: isNewUser,
                                           triggerScene: triggerScence,
                                           updateTime: Int(updateTime))
    }

    init(mobileShowEnable: Bool,
         pcShowEnable: Bool,
         isNewUser: Bool,
         triggerScene: Feed_V1_ThreeColumnsSetting.TriggerScene,
         updateTime: Int) {
        self.mobileShowEnable = mobileShowEnable
        self.pcShowEnable = pcShowEnable
        self.isNewUser = isNewUser
        self.triggerScene = triggerScene
        self.updateTime = updateTime
    }
}
