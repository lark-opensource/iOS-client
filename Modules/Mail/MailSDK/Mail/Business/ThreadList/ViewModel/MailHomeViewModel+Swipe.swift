//
//  MailHomeViewModel+Swipe.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/17.
//

import Foundation

/// 滑动方向
struct SwipeDirection: OptionSet {
    let rawValue: Int

    static let left = SwipeDirection(rawValue: 1 << 0)
    static let right = SwipeDirection(rawValue: 1 << 1)

    static let both: SwipeDirection = [.left, .right]

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

protocol MailListSwipeTargetDataSourceProtocol {
    /// 是否允许滑动.
    func swipeActionEnable(labelId: String) -> Bool
    /// 支持滑动方向.
    func allowsSwipeDirection(labelId: String, threadAction: [ActionType], filterType: MailThreadFilterType) -> SwipeDirection?
    /// 根据滑动方向获取触发 target 的前景色.
    func swipeTargetForegroundColor(labelId: String, isLeftSwipe: Bool, filterType: MailThreadFilterType) -> UIColor?
    /// 根据滑动方向获取背景色.
    func swipeTargetBackgroundColor(labelId: String, filterType: MailThreadFilterType) -> UIColor
    /// 根据滑动方向获取 target 图标.
    func swipeTargetIcon(labelId: String, isLeftSwipe: Bool, hasTrigeredTarget: Bool, filterType: MailThreadFilterType) -> UIImage?
    /// 根据滑动方向获取 target 名称.
    func swipeTargetTitle(labelId: String, isLeftSwipe: Bool, hasTrigeredTarget: Bool, filterType: MailThreadFilterType) -> String?
}

extension MailListSwipeTargetDataSourceProtocol {
    func swipeActionEnable(labelId: String) -> Bool {
        /// 交由 threadAction 控制
        return true
    }

    func allowsSwipeDirection(labelId: String, threadAction actionFromList: [ActionType], filterType: MailThreadFilterType) -> SwipeDirection? {
        /// 用于判断threadaction里是否包含目标操作
        func checkContainAction(actions: [ActionType]) -> Bool {
            for temp in actionFromList {
                for target in actions where temp == target {
                    return true
                }
            }
            return false
        }
        
        if FeatureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) {
            return .both
        }

        if labelId == Mail_LabelId_Draft {
            return nil
        }

        /// 判断是否能左滑或右滑
        var canSwipeToLeft = false
        var canSwipeToRight = false
        if checkContainAction(actions: [.read, .unRead]) {
            canSwipeToLeft = true
        }
        if checkContainAction(actions: [.archive]) {
            canSwipeToRight = true
        }
        var direction: SwipeDirection?
        if canSwipeToLeft && canSwipeToRight {
            direction = .both
        } else if canSwipeToLeft {
            direction = .left
        } else if canSwipeToRight {
            direction = .right
        }
        return direction
    }

    func swipeTargetForegroundColor(labelId: String, isLeftSwipe: Bool, filterType: MailThreadFilterType) -> UIColor? {
        /// 左滑 蓝色
        if isLeftSwipe {
            return UIColor.ud.colorfulWathet
        } else {
            /// 右滑 绿色
            return UIColor.ud.colorfulTurquoise
        }
    }

    func swipeTargetBackgroundColor(labelId: String, filterType: MailThreadFilterType) -> UIColor {
        return UIColor.ud.N400
    }

    func swipeTargetIcon(labelId: String, isLeftSwipe: Bool, hasTrigeredTarget: Bool, filterType: MailThreadFilterType) -> UIImage? {
        /// 左滑
        if isLeftSwipe {
            return hasTrigeredTarget ? Resources.mail_set_unread : Resources.mail_set_read
        } else {
            /// 右滑
            return Resources.feed_archived_icon
        }
    }

    func swipeTargetTitle(labelId: String, isLeftSwipe: Bool, hasTrigeredTarget: Bool, filterType: MailThreadFilterType) -> String? {
        /// 左滑
        if isLeftSwipe {
            return hasTrigeredTarget ? BundleI18n.MailSDK.Mail_ThreadList_SetUnread : BundleI18n.MailSDK.Mail_ThreadList_SetRead
        } else {
            /// 右滑
            return BundleI18n.MailSDK.Mail_ThreadList_ActionArchived
        }
    }
}

extension MailHomeViewModel: MailListSwipeTargetDataSourceProtocol {
    
}
