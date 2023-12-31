//
//  ChatOpenService.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/21.
//

import UIKit
import Foundation
import LarkModel
import LarkBadge

public enum ChatSelectMode {
    case normal
    case multiSelecting
}

/// ChatContainerVC对外暴露的能力
public protocol ChatOpenService: AnyObject {
    /// ChatContainerVC
    func chatVC() -> UIViewController

    func currentSelectMode() -> ChatSelectMode

    /// 退出多选模式
    func endMultiSelect()

    /// Chat实体变化信号
    var chatPath: Path { get }

    /// 隐藏/展示顶部区域视图（导航栏、banner、tabs ）
    func setTopContainerShowDelay(_ show: Bool)

    /// 置顶通知变化
    func chatTopNoticeChange(updateNotice: @escaping ((ChatTopNotice?) -> Void))

    /// 锁定顶部区域的的显隐
    func lockTopContainerCompressedStateTo(_ isCompressed: Bool)
}

public extension ChatOpenService {
    var chatPath: Path { return Path() }
    /// 隐藏/展示顶部区域视图（导航栏、banner、tabs ）
    func setTopContainerShowDelay(_ show: Bool) { }

    /// 置顶通知变化
    func chatTopNoticeChange(updateNotice: @escaping ((ChatTopNotice?) -> Void)) { }
    func currentSelectMode() -> ChatSelectMode { return .normal }
    func endMultiSelect() {}
    func lockTopContainerCompressedStateTo(_ isCompressed: Bool) { }
}

/// 默认的ChatOpenService实现：为了方便使用方书写逻辑，保证可以从容器里取到ChatOpenService
public final class DefaultChatOpenService: ChatOpenService {
    public init() {}
    public func chatVC() -> UIViewController { return UIViewController() }
}
