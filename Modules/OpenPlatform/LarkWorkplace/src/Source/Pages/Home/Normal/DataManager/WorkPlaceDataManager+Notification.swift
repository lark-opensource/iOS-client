//
//  WorkPlaceDataManager+Notification.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/22.
//

import Foundation
import Swinject
import OPSDK
import LarkContainer

/// 工作台数据更新对外发送通知
extension AppCenterDataManager {
    func onWorkplaceDataUpdate(dataModel: WorkPlaceDataModel, fromCache: Bool) {
        // 对外通知: 触发刷新红点数据
        dataModel.extractBadgeInfo { [weak self](badgeInfo) in
            guard let `self` = self else { return }
            let source: WorkplaceBadgeSource = fromCache ? .workplaceHomeCache : .workplaceHomeRemote
            self.appCenterBadgeService?.updateBadgeInfo(badgeMap: badgeInfo, source: source)
        }
    }
}
