//
//  BTLynxContainer+LifeCycle.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import Lynx
import SKFoundation

// MARK: 对外 Container 的生命周期

public protocol BTLynxContainerLifeCycle: AnyObject {
    // 容器开始初始化(准备数据)
    func didStartSetup(context: BTLynxContainer.ContainerData)
    // 容器初始化完毕(数据准备完毕)
    func didFinishSetup(context: BTLynxContainer.ContainerData)
    // 开始执行渲染流程(切入主线程, 准备 loadTemplate)
    func didStartRender(context: BTLynxContainer.ContainerData)
    // 容器开始准备加载模板 (load_template开始时的回调)
    func didStartLoading(context: BTLynxContainer.ContainerData)
    // 容器加载模板完毕 (load_template 结束后的回调，可认为完全加载完成)
    func didLoadFinished(context: BTLynxContainer.ContainerData)
    // 消息卡片首屏渲染完成 (Lynx 首屏渲染完成)
    func didFinishRender(context: BTLynxContainer.ContainerData, info: [AnyHashable : Any]?)
    // 消息卡片渲染错误(包含 lynx 错误)
    func didReceiveError(context: BTLynxContainer.ContainerData, error: BTLynxContainerError)
    // 收到更新 ContentSize 通知
    func didUpdateContentSize(context: BTLynxContainer.ContainerData, size: CGSize?)
    // 消息卡片渲染刷新
    func didFinishUpdate(context: BTLynxContainer.ContainerData, info: [AnyHashable : Any]?)
}

extension BTLynxContainer {
    public func didStartSetup() {
        lifeCycleClient?.didStartSetup(context: containerData)
    }
    
    public func didFinishSetup() {
        lifeCycleClient?.didFinishSetup(context: containerData)
    }
    
    public func didStartRender() {
        lifeCycleClient?.didStartRender(context: containerData)
    }
    
    public func didStartLoadTemplate() {
        lifeCycleClient?.didStartLoading(context: containerData)
    }
    
    public func didFinishLoadTemplate() {
        lifeCycleClient?.didLoadFinished(context: containerData)
    }
    
    public func didReceiveError(error: BTLynxContainerError) {
        lifeCycleClient?.didReceiveError(context: containerData, error: error)
    }
    
    public func didFinishRender(info: [AnyHashable : Any]?) {
        lifeCycleClient?.didFinishRender(context: containerData, info: info)
    }
    
    public func didUpdateContentSize(size: CGSize?) {
        lifeCycleClient?.didUpdateContentSize(context: containerData, size: view?.bounds.size)
    }

    public func didFinishUpdate(info: [AnyHashable : Any]?) {
        lifeCycleClient?.didFinishUpdate(context: containerData, info: info)
    }
}

// MARK: 内部 LynxView 的的生命周期, 用于处理 Lynx 的逻辑, 处理后转为外部可理解数据, 供外部使用
extension BTLynxContainer: LynxViewLifecycle {

    public func lynxViewDidStartLoading(_ view: LynxView?) {
        didStartLoadTemplate()
    }
    
    public func lynxView(_ view: LynxView?, didLoadFinishedWithUrl url: String?) {
    }

    public func lynxView(_ view: LynxView?, didLoadFinishedWith info: LynxConfigInfo?) {
        didFinishLoadTemplate()
    }

    public func lynxViewDidFirstScreen(_ view: LynxView?) {
        
    }

    public func lynxView(_ view: LynxView?, didLoadFailedWithUrl url: String?, error: Error?) {
        let error = BTLynxContainerError.lynxLoadFail(error)
        DocsLogger.error("BTLynxContainerError didLoadFailedWithUrl code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
        didReceiveError(error: error)
    }

    public func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView?) {
        didUpdateContentSize(size: view?.bounds.size)
    }

    public func lynxViewDidUpdate(_ view: LynxView?) {

    }

    public func lynxView(_ view: LynxView?, didRecieveError error: Error?) {
        let error = BTLynxContainerError.lynxRenderFail(error)
        DocsLogger.error("BTLynxContainerError didRecieveError code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
        didReceiveError(error: error)
    }

    public func lynxViewDidConstructJSRuntime(_ view: LynxView?) {
        
    }

    public func lynxView(_ lynxView: LynxView?, onSetup info: [AnyHashable : Any]?) {
        didFinishRender(info: info)
    }

    public func lynxViewDidCreateElement(_ element: LynxUI<UIView>?, name: String?) {
        
    }

    public func lynxView(_ lynxView: LynxView?, onUpdate info: [AnyHashable : Any]?, timing updateTiming: [AnyHashable : Any]?) {
        didFinishUpdate(info: info)
    }
}

