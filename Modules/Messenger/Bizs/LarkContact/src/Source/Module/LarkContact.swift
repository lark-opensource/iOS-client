//
//  LarkContact.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/27.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkRustClient
import LarkContainer
import Swinject
import RxSwift
import RxCocoa
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigation
import AnimatedTabBar
import LarkFeatureGating
import LarkAccountInterface
import LKCommonsLogging
import LarkTab

final class LarkContactConfiguration {
    /// 单选、多选、可单选多选切换
    let style: NewDepartmentViewControllerStyle
    let toolbarClass: AnyClass?
    /// 选择已有群聊、机器人、服务台、外部联系人
    let dataOptions: DataOptions
    let title: String?
    let chooseChatterOnly: Bool
    var needSearchMail: Bool
    let needSearchOuterTenant: Bool
    let allowSelectNone: Bool
    let hiddenSureItem: Bool
    let filterChatter: ((String) -> Bool)?
    /// 强制选中的人，无法取消，一直处于选中态
    let forceSelectedChatterIds: [String]
    /// 如果传了这个值，那么对应chatId中所有chatter都会被动作forceSelect来处理
    let forceSelectedChattersInChatId: String?
    /// 是否默认选择当前用户，可后面取消选中
    let defaultSelectCurrentChatter: Bool
    /// 默认选择的用户，可后面取消选中
    let defaultSelectedChatterIds: [String]
    /// 默认选中的会话，可后面取消选中
    let defaultSelectedChatIds: [String]
    /// 是否需要检查邀请权限，如果无法邀请某人，则选择时会toast提示且无法处于选中态
    let checkInvitePermission: Bool
    /// 当前是否是处于密聊场景，比如：密聊群加人、创建密聊群和密聊单聊建群，这些场景需要检测是否有使用密聊的权限
    var isCryptoModel: Bool = false
    /// 当前是不是出于跨租户沟通
    var isCrossTenantChat: Bool = false
    /// 最大选择数量，仅小程序使用
    let maxSelectedNum: Int
    /// 超出最大选择数量时的提示信息
    let limitTips: String?
    /// 当type为singleMultiChangeable时，记录当前的单选/多选状态
    var singleMultiChangeableStatus: SingleMultiChangeableStatus = .single
    let eventSearchMeetingGroup: Bool
    // 最大可选中的未授权人数
    var maxUnauthorizedSelectedNum: Int
    // 联系人优化模型
    var contactOptPickerModel: ContactOptPickerModel?

    init(style: NewDepartmentViewControllerStyle,
         toolbarClass: AnyClass? = nil,
         dataOptions: DataOptions = [],
         title: String? = nil,
         chooseChatterOnly: Bool = true,
         needSearchMail: Bool = false,
         needSearchOuterTenant: Bool,
         allowSelectNone: Bool = false,
         hiddenSureItem: Bool = false,
         filterChatter: ((String) -> Bool)? = nil,
         forceSelectedChatterIds: [String] = [],
         forceSelectedChattersInChatId: String? = nil,
         defaultSelectCurrentChatter: Bool = true,
         defaultSelectedChatterIds: [String] = [],
         defaultSelectedChatIds: [String] = [],
         checkInvitePermission: Bool = false,
         isCryptoModel: Bool = false,
         maxSelectedNum: Int = Int.max,
         limitTips: String? = nil,
         eventSearchMeetingGroup: Bool = false,
         maxUnauthorizedSelectedNum: Int = 50,
         contactOptPickerModel: ContactOptPickerModel? = nil) {
        self.style = style
        self.toolbarClass = toolbarClass
        self.dataOptions = dataOptions
        self.title = title
        self.chooseChatterOnly = chooseChatterOnly
        self.needSearchMail = needSearchMail
        self.needSearchOuterTenant = needSearchOuterTenant
        self.allowSelectNone = allowSelectNone
        self.hiddenSureItem = hiddenSureItem
        self.filterChatter = filterChatter
        self.forceSelectedChatterIds = forceSelectedChatterIds
        self.forceSelectedChattersInChatId = forceSelectedChattersInChatId
        self.defaultSelectCurrentChatter = defaultSelectCurrentChatter
        self.defaultSelectedChatterIds = defaultSelectedChatterIds
        self.defaultSelectedChatIds = defaultSelectedChatIds
        self.checkInvitePermission = checkInvitePermission
        self.isCryptoModel = isCryptoModel
        self.maxSelectedNum = maxSelectedNum
        self.limitTips = limitTips
        self.eventSearchMeetingGroup = eventSearchMeetingGroup
        self.maxUnauthorizedSelectedNum = maxUnauthorizedSelectedNum
        self.contactOptPickerModel = contactOptPickerModel
        if case .singleMultiChangeable = style {
            let totalCount = forceSelectedChatterIds.count + defaultSelectedChatterIds.count
            if totalCount > 0 {
                singleMultiChangeableStatus = .multi
            } else {
                singleMultiChangeableStatus = .single
            }
        }
    }
}

protocol LarkContactTabProtocol: TabRootViewController {
    var contactTab: LarkContactTab? { get set }
    func contactTabApplicationBadgeUpdate(_ applicationBadge: Int)
    func contactTabRootController() -> UIViewController
}

extension LarkContactTabProtocol {
    var tab: Tab { return self.contactTab?.tab ?? .contact }
    var controller: UIViewController { return self.contactTab?.controller ?? UIViewController() }
    var badge: BehaviorRelay<BadgeType> { return self.contactTab?.badge ?? BehaviorRelay<BadgeType>(value: .none) }
}

final class LarkContactTab: TabRootViewController, TabRepresentable {
    weak var delegate: LarkContactTabProtocol? {
        didSet {
            delegate?.contactTabApplicationBadgeUpdate(self.applicationBadge.value)
        }
    }
    let applicationBadge = BehaviorRelay<Int>(value: 0)

    fileprivate let disposeBag = DisposeBag()

    fileprivate var _badge: BehaviorRelay<BadgeType> = BehaviorRelay<BadgeType>(value: .none)
    fileprivate var _badgeOutsideVisable = BehaviorRelay<Bool>(value: false)
    private static let logger: Log = Logger.log(LarkContactTab.self, category: "LarkContactTab")

    init(chatApplicationAPI: ChatApplicationAPI?,
         pushChatApplicationBadege: Driver<PushChatApplicationBadege>?) {
        chatApplicationAPI?.getChatApplicationBadge()
            .subscribe(onNext: { [weak self] (badge) in
                guard let `self` = self else { return }
                self.applicationBadge.accept(badge.friendBadge)
                let numberBadge = badge.chatBadge + badge.friendBadge
                self.setBadgeNumber(number: numberBadge)
            }).disposed(by: self.disposeBag)

        pushChatApplicationBadege?
            .asObservable()
            .subscribe(onNext: { [weak self] (badge) in
                guard let `self` = self else { return }
                self.applicationBadge.accept(badge.friendBadge)
                let numberBadge = badge.chatBadge + badge.friendBadge
                self.setBadgeNumber(number: numberBadge)
            }).disposed(by: self.disposeBag)

        self.applicationBadge
            .asDriver()
            .drive(onNext: { [weak self] (applicationBadge) in
                self?.delegate?.contactTabApplicationBadgeUpdate(applicationBadge)
            }).disposed(by: self.disposeBag)
    }

    func setBadgeNumber(number: Int) {
        var badge: BadgeType
        if number == 0 {
            badge = .none
        } else {
            badge = .number(number)
        }
        Self.logger.info("[NavigationTabBadge] LarkContactTab update badge: \(badge.description)")
        self._badge.accept(badge)

        if case .number(let number) = badge, number > 0 {
            _badgeOutsideVisable.accept(true)
        } else {
            _badgeOutsideVisable.accept(false)
        }
    }

    var tab: Tab {
        return .contact
    }

    var controller: UIViewController {
        return self.delegate?.contactTabRootController() ?? UIViewController()
    }

    var springBoardBadgeEnable: BehaviorRelay<Bool>? {
        return BehaviorRelay<Bool>(value: true)
    }

    var badge: BehaviorRelay<BadgeType>? {
        return self._badge
    }

    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return BehaviorRelay<BadgeRemindStyle>(value: .strong)
    }

    var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }
}
