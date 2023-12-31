//
//  ChatWidgetContentViewModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/10.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import RxSwift
import LarkOpenIM

public typealias ChatWidgetContentViewModel = BaseChatWidgetViewModel & ChatWidgetRenderAbility

public struct ChatWidgetCellMetaModel {
    public let chat: Chat
    public let widget: ChatWidget
    public init(chat: Chat, widget: ChatWidget) {
        self.chat = chat
        self.widget = widget
    }
}

/// 卡片计算 size 和更新 UI 的能力，业务方需实现
public protocol ChatWidgetRenderAbility: AnyObject {
    func createView(_ size: CGSize) -> UIView
    func updateView(_ view: UIView)
    func sizeToFit(_ size: CGSize) -> CGSize
}

/// Widget 基类 VM，不包含size计算以及视图更新
open class BaseChatWidgetViewModel {
    public private(set) var metaModel: ChatWidgetCellMetaModel
    public let context: ChatWidgetContext
    private weak var render: ChatWidgetCellRender?
    /// UI 视图重用标识符
    open var identifier: String {
        assertionFailure("must override")
        return ""
    }

    public init(metaModel: ChatWidgetCellMetaModel, context: ChatWidgetContext) {
        self.metaModel = metaModel
        self.context = context
    }

    public func initRenderer(_ renderer: ChatWidgetCellRender) {
        self.render = renderer
    }

    /// 重新计算卡片 size && 更新 UI 视图
    public func update() {
        self.render?.update { [weak self] in
            guard let self = self else { return }
            self.context.refresh()
        }
    }

    /// 数据更新
    open func update(metaModel: ChatWidgetCellMetaModel) {
        self.metaModel = metaModel
    }

    /// 视图将要显示
    open func willDisplay() {}

    /// 视图不再显示
    open func didEndDisplay() {}

    /// 容器尺寸发生变化
    open func onResize() {}
}

/// 业务方继承，在子类里完成业务逻辑、卡片 size 计算、卡片视图更新
open class ChatWidgetViewModel<U: UIView>: BaseChatWidgetViewModel {
    /// 卡片高度计算，子线程
    open func sizeToFit(_ size: CGSize) -> CGSize { return .zero }
    /// 初始化视图
    open func create(_ size: CGSize) -> U { return U(frame: CGRect(origin: .zero, size: size)) }
    /// 更新视图
    open func update(view: U) {}
}

extension ChatWidgetViewModel: ChatWidgetRenderAbility {
    public func createView(_ size: CGSize) -> UIView {
        return create(size)
    }

    public func updateView(_ view: UIView) {
        guard let view = view as? U else {
            return
        }
        update(view: view)
    }
}

/// widget 卡片自更新
public protocol ChatWidgetCellRender: NSObject {
    func update(_ invalidate: @escaping () -> Void)
}
