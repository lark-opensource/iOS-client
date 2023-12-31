//
//  AppBadgeSettingViewModel.swift
//  LarkWorkplace
//
//  Created by houjihu on 2020/12/22.
//

import Foundation
import Swinject

/// 「应用角标设置」cell view model
final class AppBadgeSettingViewModel {
    private let dataManager: AppCenterDataManager

    init(dataManager: AppCenterDataManager) {
        self.dataManager = dataManager
    }

    /// 更新角标状态
    func updateStatus(
        shouldShow: Bool,
        appBadgeSettingItem: AppBadgeSettingItem,
        callback: @escaping((Bool) -> Void)
    ) {
        guard !appBadgeSettingItem.clientID.isEmpty else {
            callback(false)
            return
        }
        dataManager.updateAppBadgeStatus(
            appID: appBadgeSettingItem.clientID,
            shouldShow: shouldShow,
            success: {
                callback(true)
            },
            failure: { _ in
                callback(false)
            }
        )
    }
}
