//
//  UpdateUrgentNumTask.swift
//  LarkUrgent
//
//  Created by ByteDance on 2023/5/15.
//

import Foundation
import BootManager
import LarkStorage
import Contacts
import UniverseDesignToast
import LarkAssembler
import LarkSetting
import LarkSDKInterface
import LarkContainer
import EENavigator

// 更新用户通讯录加急电话
final class UpdateUrgentNumTask: UserFlowBootTask, Identifiable {

    override class var compatibleMode: Bool { Urgent.userScopeCompatibleMode }

    static var identify = "UpdateUrgentNumTask"

    @ScopedProvider private var appConfigService: UserAppConfig?

    override func execute() throws {
        guard let appConfig = self.appConfigService?.appConfig, !appConfig.urgentNum.nums.isEmpty else {
            return
        }
        let updateTime = appConfig.urgentNum.updateTime
        let localUpdateTime = KVPublic.Setting.urgentNumUpdateTime.value()
        let hasContactAuth = CNContactStore.authorizationStatus(for: CNEntityType.contacts) == CNAuthorizationStatus.authorized
        /// 触发更新条件：
        ///     1. 功能FG打开
        ///     2. 添加联系人到通讯录设置打开
        ///     3. 本地更新时间落后于远端
        ///     4. 已有通讯录权限
        if KVPublic.Setting.enableAddUrgentNum.value(),
           userResolver.fg.staticFeatureGatingValue(with: "messenger.buzzcall.numsetting"),
           hasContactAuth,
           localUpdateTime < updateTime {
            // 更新通讯录加急电话
            NotificationSettingAddUrgentNumModule.updateUrgentNumWith(appConfig.urgentNum.nums, updateTime: updateTime)
            // 展示Toast
            if let mainSceneWindow = userResolver.navigator.mainSceneWindow {
                UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_Settings_UpdatingBuzzCallNumber_Toast(), on: mainSceneWindow, delay: 4)
            }
        }
    }
}
