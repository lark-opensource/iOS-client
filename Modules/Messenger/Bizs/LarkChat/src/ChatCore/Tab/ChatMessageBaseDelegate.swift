//
//  ChatMessageBaseDelegate.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/7/13.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkModel
import SnapKit

protocol ChatMessageBaseDelegate: AnyObject {
    /// 容器 VC 顶部视图高度
    var contentTopMargin: CGFloat { get }
    /// 首屏消息渲染完成
    func messagesBeenRendered()
    func showNaviBarMultiSelectCancelItem(_ isShow: Bool)
    func showTopContainerWithAnimation(isShown: NSNumber)
    /// 添加/删除占位图
    func showPlaceholderView(_ isShow: Bool)
    func showChatModeThreadClosedAlert()

    func getTopContainerBottomConstraintItem() -> SnapKit.ConstraintItem?
    /// 输入框是否展开
    func keyboardContentHeightWillChange(_ isFold: Bool)
    /// 卡片是否展开
    var widgetExpandDriver: Driver<Bool>? { get }
    /// 卡片是否展开到极限态
    var widgetExpandLimit: BehaviorRelay<Bool>? { get }
}

final class DefaultChatMessageBaseDelegate: ChatMessageBaseDelegate {
    func messagesBeenRendered() {}
    var contentTopMargin: CGFloat { return .zero }
    func showNaviBarMultiSelectCancelItem(_ isShow: Bool) {}
    func showTopContainerWithAnimation(isShown: NSNumber) {}
    func showPlaceholderView(_ isShow: Bool) {}
    func showChatModeThreadClosedAlert() {}
    func getTopContainerBottomConstraintItem() -> SnapKit.ConstraintItem? { return nil }
    func keyboardContentHeightWillChange(_ isFold: Bool) {}
    var widgetExpandDriver: Driver<Bool>? { return nil }
    var widgetExpandLimit: BehaviorRelay<Bool>? { return nil }
}
