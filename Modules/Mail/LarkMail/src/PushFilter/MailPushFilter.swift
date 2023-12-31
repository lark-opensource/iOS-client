//
//  MailPushFilter.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/8/4.
//

import Foundation
import LKCommonsLogging
import MailSDK
import RxSwift
import LarkFeatureGating

// MARK: manager
class MailPushFilter {
    struct RecoverWayType: OptionSet {
        let rawValue: Int

        static let refreshThreadList = RecoverWayType(rawValue: 1 << 0) // 刷新列表
        static let refreshMigration = RecoverWayType(rawValue: 1 << 1) // migration状态变更，需要刷新顶部标识
        static let refreshOutBox = RecoverWayType(rawValue: 1 << 2) // oubox状态刷新

        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    static let shared = MailPushFilter()

    static let logger = Logger.log(MailPushFilter.self, category: "Module.LarkMail")

    private let disposeBag = DisposeBag()

    private var recoverActions: RecoverWayType = RecoverWayType([])

    init() {
        MailStateManager.shared.addObserver(self)
    }
}

// MARK: interface
extension MailPushFilter {
    var isInMailPage: Bool {
        return MailStateManager.shared.isInMailPage
    }

    func enterMailPage() {
        MailStateManager.shared.enterMailPage()
    }

    func exitMailPage() {
        MailStateManager.shared.exitMailPage()
    }

    func enterMailTab() {
        MailStateManager.shared.enterMailTab()
    }

    func exitMailTab() {
        MailStateManager.shared.exitMailTab()
    }

    func markRecoverWay(type: RecoverWayType) {
        recoverActions.insert(type)
    }
}

// MARK: internal
extension MailPushFilter {
    func handleRecoverActions() {
        var types = Set<MailRecoverAction.ActionType>()

        if recoverActions.contains(.refreshThreadList) {
            types.insert(.reloadThreadData)
        }
        if recoverActions.contains(.refreshMigration) {
            types.insert(.refreshMigration)
        }
        if recoverActions.contains(.refreshOutBox) {
            types.insert(.refreshOutBox)
        }

        if !types.isEmpty {
            // 抛出通知告诉MailHome去重新拉取相关数据
            let action = MailRecoverAction(actionType: types)
            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SERVICE_RECOVER_ACTION,
                                            object: nil, userInfo: [MailRecoverAction.NotificationKey: action])
        }

        // 清空池子
        recoverActions = RecoverWayType([])
    }

    func activeMailPage() {
        MailSDKManager.markActiveMailPage().subscribe().disposed(by: disposeBag)
    }

    func inActiveMailPage() {
        MailSDKManager.markInActiveMailPage().subscribe().disposed(by: disposeBag)
    }
}

extension MailPushFilter: MailStateObserver {
    func didMailServiceFirstEntry() {
        print("--------- did first enter mail service")
        MailPushFilter.logger.info("did first enter mail service")
        activeMailPage()
    }

    func didLeaveMailService() {
        // dosomething if need
        print("--------- did leave mail service")
        MailPushFilter.logger.info("did leave mail service")
        inActiveMailPage()
    }

    func didEnterMailService() {
        print("--------- did enter mail service")
        MailPushFilter.logger.info("did enter mail service")
        activeMailPage()
        handleRecoverActions()
    }
}
