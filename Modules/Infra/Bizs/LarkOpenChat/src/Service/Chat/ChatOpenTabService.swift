//
//  ChatOpenTabService.swift
//  LarkOpenChat
//
//  Created by 赵家琛 on 2021/6/16.
//

import UIKit
import Foundation
import RustPB

/// Tab 框架提供的全局能力
public protocol ChatOpenTabService: AnyObject {
    /// 添加新 Tab 的能力
    func addTab(type: ChatTabType, name: String, jsonPayload: String?, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error, _ type: ChatTabType) -> Void)?)
    /// 业务方根据 tab id 获取最新数据
    func getTab(id: Int64) -> ChatTabContent?
    /// 跳转到指定tab
    func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController)
    /// 更新 tab 内容
    func updateChatTabDetail(tab: ChatTabContent, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error) -> Void)?)
}

public final class DefaultChatOpenTabService: ChatOpenTabService {
    public init() {}
    public func addTab(type: ChatTabType, name: String, jsonPayload: String?, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error, _ type: ChatTabType) -> Void)?) {}
    public func getTab(id: Int64) -> ChatTabContent? { return nil }
    public func jumpToTab(_ tab: ChatTabContent, targetVC: UIViewController) {}
    public func updateChatTabDetail(tab: ChatTabContent, success: ((ChatTabContent) -> Void)?, failure: ((_ error: Error) -> Void)?) {}
}

/// 业务方需要实现的协议
@available(*, deprecated, message: "old desgin")
public protocol ChatTabContentViewDelegate: AnyObject {
    /// 返回视图
    /// eg. VC.view
    func contentView() -> UIView

    /// 视图将要显示的时候调用
    func contentWillAppear()

    /// 视图显示的时候调用
    func contentDidAppear()

    /// 视图将要消失的时候调用
    func contentWillDisappear()

    /// 视图消失的时候调用
    func contentDidDisappear()

    /// 业务方将要被销毁
    func willDestroy()
}

public extension ChatTabContentViewDelegate {
    func contentWillAppear() {}

    func contentDidAppear() {}

    func contentWillDisappear() {}

    func contentDidDisappear() {}

    func willDestroy() {}
}

extension UIViewController: ChatTabContentViewDelegate {
    public func contentView() -> UIView {
        return self.view
    }
}
