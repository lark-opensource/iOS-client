//
//  LoadEnterpriseNoticeTask.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import BootManager
import LarkContainer
import LarkSetting

final class LoadEnterpriseNoticeTask: UserFlowBootTask, Identifiable {
    static var identify = "LoadEnterpriseNoticeTask"

    @ScopedProvider private var enterpriseNoticeService: EnterpriseNoticeService?

    override func execute(_ context: BootContext) {
        // 启动时全量拉取通知卡片数据
        guard FeatureGatingManager.shared.featureGatingValue(with: "lark.subscriptions.dialog") else {
            return
        }
        enterpriseNoticeService?.loadAllEnterpriseNoticeCards()
    }
}
