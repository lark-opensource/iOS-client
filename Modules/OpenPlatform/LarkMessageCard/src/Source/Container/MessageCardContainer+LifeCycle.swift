//
//  MessageCardContainer+LifeCycle.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/11.
//

import Foundation
import Lynx

// MARK: 对外 Container 的生命周期

extension MessageCardContainer {
    
    public func didStartRender() {
        lifeCycleClient?.didStartRender(context: context)
    }
    
    public func didStartLoadTemplate() {
        lifeCycleClient?.didStartLoading(context: context)
    }
    
    public func didFinishLoadTemplate() {
        lifeCycleClient?.didLoadFinished(context: context)
    }
    
    public func didReceiveError(error: MessageCardError) {
        lifeCycleClient?.didReceiveError(context: context, error: error)
    }
    
    public func didFinishRender(info: [AnyHashable : Any]?) {
        lifeCycleClient?.didFinishRender(context: context, info: info)
    }
    
    public func didUpdateContentSize(size: CGSize?) {
        preferSize = size
        lifeCycleClient?.didUpdateContentSize(context: context, size: view?.bounds.size)
    }

    public func didFinishUpdate(info: [AnyHashable : Any]?) {
        lifeCycleClient?.didFinishUpdate(context: context, info: info)
    }
}

// MARK: 内部 LynxView 的的生命周期, 用于处理 Lynx 的逻辑, 处理后转为外部可理解数据, 供外部使用
extension MessageCardContainer: LynxViewLifecycle {

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
        let error = MessageCardError.lynxLoadFail(error)
        logger.error("MessageCardContainer<\(trace.traceId)> didLoadFailedWithUrl code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
        didReceiveError(error: error)
    }

    public func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView?) {
        didUpdateContentSize(size: view?.bounds.size)
    }

    public func lynxViewDidUpdate(_ view: LynxView?) {

    }

    public func lynxView(_ view: LynxView?, didRecieveError error: Error?) {
        let error = MessageCardError.lynxRenderFail(error)
        logger.error("MessageCardContainer<\(trace.traceId)> didRecieveError code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
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
