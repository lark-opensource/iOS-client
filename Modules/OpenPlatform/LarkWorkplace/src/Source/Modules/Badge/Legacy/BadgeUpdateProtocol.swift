//
//  BadgeUpdateProtocol.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/12/22.
//

import Foundation
import RxSwift
import LarkContainer
import LarkWorkplaceModel

protocol BadgeUpdateProtocol: NSObjectProtocol {
    var disposeBag: DisposeBag { get }
    /// badgekey
    var badgeKey: WorkPlaceBadgeKey? { get set }
    /// 获取badge数量
    func getBadge() -> Int?
    /// observe badge update
    func observeBadgeUpdate()
    /// unObserve
    func unObserveBadgeUpdate()
    /// on Badge Update
    func onBadgeUpdate()
}

extension BadgeUpdateProtocol {
    func getBadge() -> Int? {
        return BadgeTool.getBadge(badgeKey: badgeKey)
    }
    func observeBadgeUpdate() {
        let notiName = WorkPlaceBadge.Noti.badgeUpdate.name
        // swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(
            forName: notiName,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.onBadgeUpdate()
        }
        // swiftlint:enable discarded_notification_center_observer
    }
    func unObserveBadgeUpdate() {
        let notiName = WorkPlaceBadge.Noti.badgeUpdate.name
        NotificationCenter.default.removeObserver(self, name: notiName, object: nil)
    }
}

// TODO: 后续单独处理，原生工作台与模版工作台 Badge 逻辑需要合并
enum BadgeTool {
    static func getBadge(badgeKey: WorkPlaceBadgeKey?) -> Int? {
        guard let key = badgeKey  else { return nil }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let badgeService = try? userResolver.resolve(assert: AppCenterBadgeService.self)
        return badgeService?.getBadge(badgeKey: key)
    }

    static func getBadgeInfo(badgeKey: WorkPlaceBadgeKey?) -> (Bool, WPBadge?)? {
        guard let key = badgeKey else { return nil }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let badgeService = try? userResolver.resolve(assert: AppCenterBadgeService.self)
        return badgeService?.getBadgeNode(badgeKey: key)
    }
}
