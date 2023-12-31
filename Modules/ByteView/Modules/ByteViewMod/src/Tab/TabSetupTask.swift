//
//  TabSetupTask.swift
//  Lark
//
//  Created by kiri on 2021/8/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import BootManager
import ByteViewTab
import ByteViewCommon
import LarkTab

final class TabSetupTask: UserFlowBootTask, Identifiable {
    private static let tabBadgeLogger = Logger.getLogger("Badge", prefix: "ByteViewTab.")

    static var identify = "ByteViewTabSetupTask"

    override var scope: Set<BizScope> { return [.vc] }

    override func execute() throws {
        setupTabBadge()
    }

    func setupTabBadge() {
        let badgeService = try? userResolver.resolve(assert: TabBadgeService.self)
        badgeService?.notifyTabContextEnabled()
        badgeService?.registerUnreadCountDidChangedCallback { (unreadCount: Int64) in
            guard let byteviewTab = TabRegistry.resolve(.byteview) as? VideoConferenceTab else {
                Self.tabBadgeLogger.debug("cannot find valid byteview tab")
                return
            }
            var type: LarkTab.BadgeType = .none
            if unreadCount > 0 {
                type = .number(Int(unreadCount))
                Self.tabBadgeLogger.debug("will set unread count to: \(unreadCount)")
            } else if unreadCount < 0 {
                Self.tabBadgeLogger.warn("unread count < 0, will set unread count to .none")
            }
            byteviewTab.updateBadge(type)
        }
    }
}
