//
//  ThreadCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import UIKit
import Foundation
import AsyncComponent
import RxSwift

/// CellViewModel基类，处理cell相关的业务逻辑
open class CellViewModel<C: ViewModelContext>: ViewModel {

    /// 对应cell的reused identifier
    open var identifier: String {
        assertionFailure("must override")
        return "cell"
    }

    /// 区分每个cell的唯一标识符
    open var id: String? {
        return nil
    }

    /// 渲染引擎
    public let renderer: ASComponentRenderer

    /// 负责绑定VM和Component，避免Component对VM造成污染
    public let binder: ComponentBinder<C>

    /// 上下文，容器或者顶层VC提供的能力
    public let context: C

    /// 负责统一回收RX相关的订阅
    public let disposeBag = DisposeBag()

    /// CellViewModel构造方法
    ///
    /// - Parameters:
    ///   - context: 上下文
    ///   - binder: VM和Component的binder，通过传入不同的binder，可以将VM绑定到不同的VM
    ///   - renderer: 渲染能力，对于消息链接化等场景渲染能力需要支持注入
    public init(context: C, binder: ComponentBinder<C>, renderer: ASComponentRenderer? = nil) {
        self.context = context
        self.binder = binder
        self.renderer = renderer ?? ASComponentRenderer(binder.component, useNewPatchView: context.getStaticFeatureGating("im.message.render.patch_view"))
        super.init()
    }

    /// 重新计算布局
    public func calculateRenderer() {
        binder.update(with: self)
        updateRootComponent()
    }

    /// size 发生变化，更新 binder, 并且触发 renderer
    override open func onResize() {
        binder.update(with: self)
        super.onResize()
        updateRootComponent()
    }

    /// 当Renderer外部注入时（如消息链接化场景），binder.component可能不是rootComponent，
    /// updateRootComponent需要由外部决定
    open func updateRootComponent() {
        renderer.update(rootComponent: binder.component)
    }

    /// 获取ReusableCell（通过vm的布局信息和identifier来计算）
    ///
    /// - Parameters:
    ///   - tableView: 目标tableView
    ///   - cellId: cell的唯一标识符（例如消息id）
    /// - Returns: 可重用的MessageCommonCell
    open func dequeueReusableCell(_ tableView: UITableView, cellId: String) -> MessageCommonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MessageCommonCell ??
            MessageCommonCell(style: .default, reuseIdentifier: identifier)
        cell.contentView.tag = 0
        cell.tkDescription = { [weak self] in
            self?.buildDescription() ?? [:]
        }
        cell.update(with: renderer, cellId: cellId)
        return cell
    }

    open func buildDescription() -> [String: String] {
        return [:]
    }
}
