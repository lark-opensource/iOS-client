//
//  UniversalCardLynxLifeCycle.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/16.
//

import Lynx
import Foundation
import LarkSetting
import LKCommonsLogging
import UniversalCardInterface

// lynx 生命周期代理, 专门用于处理 lynx 的回调, 不对外公开.
// 与卡片分开, 避免两层逻辑混在一起, 以及避免卡片对外开放了 lynx 生命周期
class LynxLifeCycleClient: NSObject, LynxViewLifecycle {
    public static let logger = Logger.log(
        LynxLifeCycleClient.self,
        category: "UniversalCardLynxLifeCycle"
    )
    // 监听的卡片实例(暂时没有做成协议的必要, 就是为了卡片服务的)
    weak var card: UniversalCard?


    public func lynxViewDidStartLoading(_ view: LynxView?) {
        guard let context = card?.cardSource?.context, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }
        lifeCycle.didStartLoading(context: context)
    }

    public func lynxView(_ view: LynxView?, didLoadFinishedWithUrl url: String?) {
        guard let context = card?.cardSource?.context, let _ = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }
        // 这个代理即使非 url 也会调用, 所以不调用 loadfinished 否则会调用两次
    }

    public func lynxView(_ view: LynxView?, didLoadFinishedWith info: LynxConfigInfo?) {
        guard let context = card?.cardSource?.context, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }
        lifeCycle.didLoadFinished(context: context)
    }

    public func lynxViewDidFirstScreen(_ view: LynxView?) {
        guard let context = card?.cardSource?.context, let _ = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }

    }

    public func lynxView(_ view: LynxView?, didLoadFailedWithUrl url: String?, error: Error?) {
        guard let context = card?.cardSource?.context, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            Self.logger.info("LynxLifeCycle call \(#function) with error:\(String(describing: error))")
            return
        }
        let error = UniversalCardError.lynxLoadFail(error)
        let traceID = context.renderingTrace?.traceId ?? "unknown"
        Self.logger.error("UniversalCard<\(traceID)> didLoadFailedWithUrl code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
        lifeCycle.didReceiveError(context: context, error: error)
    }

    public func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView?) {
        Self.logger.info(
            "UniversalCard Lifecycle didChange contentSize:\(view?.bounds.size ?? CGSizeZero)",
            additionalData: [
                "trace":  card?.cardSource?.context.renderingTrace?.traceId ?? "",
        ])
        guard let context = card?.cardSource?.context, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            Self.logger.info("LynxLifeCycle call \(#function) with view:\(view?.bounds.size ?? CGSizeZero)")
            return
        }
        lifeCycle.didUpdateContentSize(
            context: context,
            size: view?.bounds.size
        )
    }

    public func lynxViewDidUpdate(_ view: LynxView?) {
        guard let context = card?.cardSource?.context, let _ = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }

    }

    public func lynxView(_ view: LynxView?, didRecieveError error: Error?) {
        guard let context = card?.cardSource?.context, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            Self.logger.info("LynxLifeCycle call \(#function) with error:\(String(describing: error))")
            return
        }
        let error = UniversalCardError.lynxRenderFail(error)
        let traceID = context.renderingTrace?.traceId ?? "unknown"
        Self.logger.error("LynxLifeCycle<\(traceID)> didReceiveError code: \(error.errorCode), message: \(error.errorMessage), errorType: \(error.errorType), errorDomain: \(error.domain)")
        lifeCycle.didReceiveError(context: context, error: error)
    }

    public func lynxViewDidConstructJSRuntime(_ view: LynxView?) {
        guard let context = card?.cardSource?.context, let _ = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }

    }

    public func lynxView(_ lynxView: LynxView?, onSetup info: [AnyHashable : Any]?) {
        guard let context = card?.getTraceContext(forKey: UniversalCard.SetupContextKey), let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            Self.logger.info("LynxLifeCycle call \(#function) with info:\(String(describing: info))")
            return
        }
        Self.logger.info(
            "UniversalCard Lifecycle onSetup size:\(lynxView?.bounds.size ?? CGSizeZero)",
            additionalData: [
                "trace":  card?.cardSource?.context.renderingTrace?.traceId ?? "",
        ])
        lifeCycle.didFinishRender(context: context, info: info)
        card?.removeTraceContext(forKey: UniversalCard.SetupContextKey)
    }

    public func lynxViewDidCreateElement(_ element: LynxUI<UIView>?, name: String?) {
        guard let context = card?.cardSource?.context, let _ = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            return
        }

    }

    public func lynxView(_ lynxView: LynxView?, onUpdate info: [AnyHashable : Any]?, timing updateTiming: [AnyHashable : Any]?) {
        Self.logger.info(
            "UniversalCard Lifecycle onUpdate size:\(lynxView?.bounds.size ?? CGSizeZero)",
            additionalData: [
                "trace":  card?.cardSource?.context.renderingTrace?.traceId ?? "",
        ])
        guard let timing = updateTiming, let lifeCycle = card?.lifeCycleDelegate else {
            Self.logger.error("LynxLifeCycle call \(#function) without card or card lifecycle delegate")
            Self.logger.info("LynxLifeCycle call \(#function) with info:\(String(describing: info))")
            return
        }
    
        guard let traceID = LynxData.getTraceID(fromTiming: timing), 
              let context = card?.getTraceContext(forKey: traceID) else {
            Self.logger.error("LynxLifeCycle call \(#function) without card context")
            return
        }
        lifeCycle.didFinishUpdate(context: context, info: info)
        card?.removeTraceContext(forKey: traceID)
    }
    
    func lynxViewOnTasmFinish(byNative view: LynxView?) {
        Self.logger.info(
            "UniversalCard Lifecycle lynxViewOnTasmFinish view:\(view?.bounds.size ?? CGSizeZero)",
            additionalData: [
                "trace":  card?.cardSource?.context.renderingTrace?.traceId ?? "",
                "isLayoutFinished": String(card?.isLayoutFinished ?? false)
        ])
        guard FeatureGatingManager.shared.featureGatingValue(with: "universalcard.async_render.enable") else { return }
        guard let isLayoutFinished = card?.isLayoutFinished, !isLayoutFinished else { return }
        card?.isLayoutFinished = true
        card?.tasmFinishSemaphore.signal()
    }

}
