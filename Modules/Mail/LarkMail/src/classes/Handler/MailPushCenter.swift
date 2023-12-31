//
//  MailPushCenter.swift
//  LarkMail
//
//  Created by majx on 2019/8/11.
//

/// 注意： 请不要再给这个类加东西了。

import Foundation
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import MailSDK
import LarkSDKInterface
import RustPB
import LarkFeatureGating
import LarkUIKit
import AnimatedTabBar
import LarkNavigation
import LarkTab

enum BadgeColorType {
    case none
    case warning
    case gray
    case red
    case redDot // 就一个红点 没有数字
}

class MailPushCenter {
    static private let logger = Logger.log(LarkMailService.self, category: "Module.MailPushCenter")
    private var pushCenter: PushNotificationCenter
    private var mainDisposeBag = DisposeBag()
    private var lastUnreadCount: Int = 0
    private var tabBadgeColor: BadgeColorType = .none
    private var dispatcher: PushDispatcher {
        return PushDispatcher.shared
    }
    weak var mailTabBarController: MailTabBarController? {
        didSet {
            mailTabBarController?.unreadData = (lastUnreadCount, unreadStyle(tabBadgeColor))
        }
    }

    required init(_ pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
        self.mainConfig()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func update(_ pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
        mainConfig()
    }

    private func mainConfig() {
        mainDisposeBag = DisposeBag() // release previous observer
        // ATTENTION!! must use mainDispose instead of dispose.
        setUnreadThreadChange()
    }
}

// MARK: bind push
extension MailPushCenter {
    private func setUnreadThreadChange() {
        pushCenter.observable(for: MailUnreadThreadCountChangePush.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](change) in
                guard let `self` = self else { return }
                MailPushCenter.logger.debug("MailUnreadThreadCount \(change.count)")
                MailSettingManagerInterface.updateAccountUnread(by: change.countMap)
                self.updateMailTabBadge(count: change.count, tabUnreadColor: change.tabUnreadColor)

                let unreadChange = MailUnreadThreadCountChange(count: change.count,
                                                               tabUnreadColor: change.tabUnreadColor,
                                                               countMap: change.countMap,
                                                               colorMap: change.colorMap)
                self.dispatcher.acceptMailUnreadCountPush(push: .unreadThreadCount(unreadChange))
            }, onError: { (error) in
                MailPushCenter.logger.error("MailUnreadThreadCount: \(error)")
            }).disposed(by: mainDisposeBag)

        EventBus.larkmailEvent.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                if case let .unreadCountRecover(count: count, color: color) = event {
                    MailPushCenter.logger.info("unread detect recover \(count) color: \(color)")
                    self?.updateMailTabBadge(count: count, tabUnreadColor: color)
                }
        }).disposed(by: mainDisposeBag)
    }
}

// MARK: helper
extension MailPushCenter {
    func updateMailTabBadge(count: Int64, tabUnreadColor: Email_Client_V1_UnreadCountColor?) {
        if let unreadColor = tabUnreadColor {
            switch unreadColor {
            case .gray:
                self.tabBadgeColor = .gray
            case .red:
                self.tabBadgeColor = .red
            case .warning:
                self.tabBadgeColor = .warning
            case .reddot:
                self.tabBadgeColor = .redDot
            @unknown default:
                self.tabBadgeColor = .none
            }
        }

        self.lastUnreadCount = Int(count)
        self.updateTabCount(self.lastUnreadCount, colorType: self.tabBadgeColor)
        self.mailTabBarController?.unreadData = (lastUnreadCount, unreadStyle(tabBadgeColor))
    }

    private func unreadStyle(_ type: BadgeColorType) -> Int {
        var unreadStyle = -1
        switch type {
        case .gray:
            unreadStyle = 0
        case .red:
            unreadStyle = 1
        case .warning:
            unreadStyle = 2
        case .redDot:
            unreadStyle = 3
        default:
            unreadStyle = -1
        }
        return unreadStyle
    }

    private func updateTabCount(_ unreadCount: Int, colorType: BadgeColorType) {
        MailPushCenter.logger.debug("updateTabCount count = \(unreadCount), colorType = \(colorType)")
        var type: LarkTab.BadgeType = .none

        if colorType == .warning {
            type = .image(MailSDKManager.sdkImage(named: "mailClient_notice"))
        } else if unreadCount > 0 {
            if colorType == .red {
                type = .number(unreadCount)
            } else if colorType == .redDot {
                type = .dot(0)
            } else {
                type = .dot(unreadCount)
            }
        }
        (TabRegistry.resolve(.mail) as? MailTab)?.updateBadge(type)
        BadgeProvider.default.progressSubject.onNext(BadgeProvider.transForm(type))
    }
}
