//
//  OPBlockWebComponent.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import OPSDK
import ECOInfra
import LarkOPInterface
import OPBlockInterface
import LarkContainer

// block component: 目前使用web作为render/component; 后续支持内部切换render和component
// 后续架构为：component同构，render/worker按不同block形态挂载
class OPBlockWebComponent: OPNode, OPComponentProtocol, OPRenderLifeCycleProtocol {

    let context: OPComponentContext

    /// bridge 通信协议
    var bridge: OPBridgeProtocol
    /// 渲染层，主要负责加载block，可支持web & lynx
    public let render: OPRenderProtocol
    /// 逻辑层，主要负责API通信，可支持web & lynx
    public let worker: OPWorkerProtocol

    // 生命周期监听者
    private var lifeCycleListeners = WeakArray<OPComponentLifeCycleProtocol>([])

    /// 通过 fileReader 可以获取特定 Component 依赖的资源
    required public init(fileReader: OPPackageReaderProtocol, context: OPContainerContext) {
        // OPSDK 未完整适配用户态隔离
        let userResolver = Container.shared.getCurrentUserResolver()
        let componentContext = OPComponentContext(context: context)
        self.context = componentContext
        // todo: block dsl迁移后根据block类型做provider切换
        let (render, worker) = OPBlockWebWorkerAndRenderProvider.makeRenderAndWorker(
            userResolver: userResolver,
            fileReader: fileReader,
            context: componentContext
        )
        self.render = render
        self.worker = worker
        let bridge = OPBaseBridge()
        self.bridge = bridge
        super.init()
        addChild(node: render)
        addChild(node: worker)
        render.delegate = self
        bridge.delegate = worker
    }

    // OPComponentProtocol, 负责转发外部的生命周期及流程，并调度render和worker
    /// 添加生命周期观察者，同一个观察者可以添加多次，内部不做去重处理
    func addLifeCycleListener(listener: OPComponentLifeCycleProtocol) {
        lifeCycleListeners.append(listener)
    }

    /// 内部会转 data 的类型，如果转换失败会抛出错误
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws {
        context.containerContext.trace?.info("component begin render",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        do {
            try render.render(slot: slot, data: data)
            lifeCycleListeners.forEach { (listener) in
                listener?.onComponentReady?()
            }
        } catch {
            context.containerContext.trace?.error("component render fail", error: error)
            let err = error as? OPError ?? error.newOPError(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail)
            lifeCycleListeners.forEach { (listener) in
                listener?.onComponentFail?(err: err)
            }
        }
    }

    /// 重刷当前page
    func reRender() {
        context.containerContext.trace?.info("component begin rerender",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        render.reRender()
    }

    /// 内部会转 initData 的类型，如果转换失败会抛出错误
    func update(data: OPComponentTemplateDataProtocol) throws {
        context.containerContext.trace?.info("component begin update",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        try render.update(data: data)
    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件
    func onShow() {
        context.containerContext.trace?.info("component onShow",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        render.onShow()
        worker.onShow()
    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件
    func onHide() {
        context.containerContext.trace?.info("component onHide",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        render.onHide()
        worker.onHide()
    }

    /// Container 在 destroy 时，告诉 Component 要 destroy 了
    func onDestroy() {
        context.containerContext.trace?.info("component onDestory",
                                             additionalData: ["unqiueID": context.containerContext.uniqueID.fullString])
        render.onDestroy()
        worker.onDestroy()
    }

}

// OPRenderLifeCycleProtocol, 负责处理render的生命周期事件，并且按需像外部（container、router、host）转发对应事件
extension OPBlockWebComponent {

    /// 页面开始渲染
    func onPageStartRender(info: OPRenderPageDataProtocol) {
        lifeCycleListeners.forEach { (listener) in
            listener?.onPageStartRender?(component: self, pageInfo: info)
        }
    }

    /// 页面渲染完成
    func onPageSuccess(info: OPRenderPageDataProtocol) {
        lifeCycleListeners.forEach { (listener) in
            listener?.onPageRenderSuccess?(component: self, pageInfo: info)
        }
    }

    /// 页面渲染失败
    func onPageError(info: OPRenderPageDataProtocol, error: OPError) {
        lifeCycleListeners.forEach { (listener) in
            listener?.onPageRenderFail?(component: self, pageInfo: info, error: error)
        }
    }

    /// 页面崩溃
    func onPageCrash(info: OPRenderPageDataProtocol, error: OPError?) {
        lifeCycleListeners.forEach { (listener) in
            listener?.onPageRenderCrash?(component: self, pageInfo: info, error: error)
        }
    }

    /// 页面size发生变化，用于通知外部进行大小自适应，高度单位为px
    func contentHeightDidChange(height: CGFloat) {
        lifeCycleListeners.forEach { (listener) in
            listener?.contentHeightDidChange?(component: self, height: height)
        }
    }

}
