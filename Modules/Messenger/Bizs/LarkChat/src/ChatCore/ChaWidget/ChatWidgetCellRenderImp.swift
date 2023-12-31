//
//  ChatWidgetCellRenderImp.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/16.
//

import UIKit
import Foundation
import LarkOpenChat

/// 卡片计算 size && 更新视图逻辑
final class ChatWidgetCellRenderImp: NSObject, ChatWidgetCellRender {
    weak var bindView: UIView?
    private var boundingRect: CGSize = .zero
    private var containerSize: CGSize = .zero
    private let renderAbility: ChatWidgetRenderAbility

    public init(renderAbility: ChatWidgetRenderAbility) {
        self.renderAbility = renderAbility
    }

    /// 绑定视图逻辑
    func bind(to view: UIView) {
        assert(Thread.isMainThread, "bind view to Renderer can only be on main thread!")
        // 同一View实例只能绑定到一个Renderer上
        self.unbind(from: view)
        if let bindView = self.bindView {
            self.unbind(from: bindView)
        }
        self.bindView = view
        renderToViewVTable[view.widgetViewIdentifier] = WeakRef(self)
    }

    private func unbind(from view: UIView) {
        if let oldRender = renderToViewVTable[view.widgetViewIdentifier] {
            oldRender.ref?.bindView = nil
            renderToViewVTable[view.widgetViewIdentifier] = nil
        }
    }

    func size() -> CGSize {
        return boundingRect
    }

    /// 计算布局
    func layout(_ containerSize: CGSize) {
        self.containerSize = containerSize
        self.boundingRect = self.renderAbility.sizeToFit(containerSize)
    }

    /// 更新视图
    func renderView() {
        guard let bindView = bindView else { return }
        /// 找到可更新的视图
        if let targetView = bindView.subviews.first {
            targetView.frame = CGRect(origin: .zero, size: self.boundingRect)
            self.renderAbility.updateView(targetView)
            return
        }
        /// 没找到的话先创建一个再更新
        let targetView = self.renderAbility.createView(self.boundingRect)
        targetView.frame = CGRect(origin: .zero, size: self.boundingRect)
        bindView.addSubview(targetView)
        self.renderAbility.updateView(targetView)
    }

    /// 计算布局并更新视图
    func update(_ invalidate: @escaping () -> Void) {
        widgetProcessQueue.async {
            self.boundingRect = self.renderAbility.sizeToFit(self.containerSize)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let bindView = self.bindView else { return }
                guard let targetView = bindView.subviews.first else { return }
                if targetView.frame.size == self.boundingRect {
                    self.renderAbility.updateView(targetView)
                } else {
                    invalidate()
                }
            }
        }
    }
}

private var _widgetViewIdentifierKey = "_widgetViewIdentifierKey"
extension UIView {
    // view实例标识
    public var widgetViewIdentifier: Int {
        if let identifier = objc_getAssociatedObject(self, &_widgetViewIdentifierKey) as? Int { return identifier }
        let identifier = ObjectIdentifier(self).hashValue
        objc_setAssociatedObject(self, &_widgetViewIdentifierKey, identifier, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return identifier
    }
}

private struct WeakRef<T: AnyObject> {
    weak var ref: T?

    init(_ ref: T) {
        self.ref = ref
    }
}
private var renderToViewVTable: [Int: WeakRef<ChatWidgetCellRenderImp>] = [:]

private let widgetProcessQueue = DispatchQueue(label: "ChatWidgetCellRender", qos: .default)
