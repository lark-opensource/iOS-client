//
//  TabRepresentable.swift
//  LarkTab
//
//  Created by Supeng on 2020/12/16.
//

import UIKit
import Foundation
import RxCocoa

public extension NSNotification.Name {
    static let LKTabDownloadIconSucceedNotification = NSNotification.Name(rawValue: "LKTabDownloadIconSucceedNotification")
}

// swiftlint:disable missing_docs
public protocol TabRepresentable {
    var tab: Tab { get }

    // title
    var mutableTitle: BehaviorRelay<String>? { get }

    // icon
    var mutableIcon: BehaviorRelay<UIImage>? { get }
    var mutableSelectedIcon: BehaviorRelay<UIImage>? { get }
    var mutableQuickIcon: BehaviorRelay<UIImage>? { get }
    // 图标显示样式：居中、平铺
    var quickIconStyle: TabIconStyle? { get }

    // customView
    var customView: UIControl? { get }
    var customQuickView: UIView? { get }

    // openMode
    var openMode: TabOpenMode? { get }

    // badge
    var badge: BehaviorRelay<BadgeType>? { get }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? { get }
    var badgeVersion: BehaviorRelay<String?>? { get }
    // 快捷导航里是否外漏
    var badgeOutsideVisiable: BehaviorRelay<Bool>? { get }
    // 是否相加 反映到桌面Badge
    var springBoardBadgeEnable: BehaviorRelay<Bool>? { get }
}

public extension TabRepresentable {
    var mutableTitle: BehaviorRelay<String>? { return nil }
    var mutableIcon: BehaviorRelay<UIImage>? { return nil }
    var mutableSelectedIcon: BehaviorRelay<UIImage>? { return nil }
    var quickIconStyle: TabIconStyle? { return nil }
    var customView: UIControl? { return nil }
    var openMode: TabOpenMode? { return nil }
    var badge: BehaviorRelay<BadgeType>? { return nil }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? { return nil }
    var badgeVersion: BehaviorRelay<String?>? { return nil }
    var badgeOutsideVisiable: BehaviorRelay<Bool>? { return nil }
    var springBoardBadgeEnable: BehaviorRelay<Bool>? { return nil }
    var customQuickView: UIView? { return nil }
    var mutableQuickIcon: BehaviorRelay<UIImage>? { return nil }
}

public class DefaultTabRepresentable: TabRepresentable {
    public var tab: Tab
    public init(tab: Tab) {
        self.tab = tab
    }
}
// swiftlint:enable missing_docs
