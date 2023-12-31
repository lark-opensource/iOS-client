//
//  SettingAccountDelegate.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/11/8.
//

import Foundation
import LarkContainer
import LarkAccountInterface


final class SettingAccountDelegate: PassportDelegate {

    public var name: String = "SettingAccountDelegate"

    func backgroundUserDidOnline(state: PassportState) {
        guard let account = state.user else { return }
        let userID = account.userID
        let queue = DispatchQueue(label: "com.setting.backgroundUserSetting")
        queue.async{
            if let userResolver = try? Container.shared.getUserResolver(userID: userID, type: .background) {
                SettingStorage.settingDatasource?.fetchSetting(resolver: userResolver)
                FeatureGatingStorage.featureGatingDatasource?.fetchImmutableFeatureGating(with: userResolver.userID)
            }
        }
    }
}
