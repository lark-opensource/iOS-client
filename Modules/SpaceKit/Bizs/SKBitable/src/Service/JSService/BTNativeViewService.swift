//
//  BTNativeViewService.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/30.
//  

// native 视图前端接口

import SKFoundation
import SKCommon
import SKInfra
import LarkWebViewContainer

final class BTNativeViewService: BaseJSService {
    private let TAG = "[BTNativeViewService]"
    private var hasInit = false
    struct Const {
        static let viewTypeModelMap: [NativeRenderViewType: NativeRenderBaseModel.Type] = [.cardView: CardPageModel.self]
    }
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    var nativeRenderViewManager: BTNativeRenderViewManager? {
        return (registeredVC as? BitableBrowserViewController)?.nativeRenderViewManager
    }
}

extension BTNativeViewService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.setCardViewData]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        guard let container = container else {
            return
        }
        guard let browserController = registeredVC as? BitableBrowserViewController else { return }
        var nativeViewType: NativeRenderViewType = .cardView
        switch DocsJSService(rawValue: serviceName) {
        case .setCardViewData:
            nativeViewType = .cardView
        default:
            DocsLogger.btError("\(TAG) wrong \(serviceName)(\(params))")
            spaceAssertionFailure("unsupport service")
            return
        }
        
        guard let model = Const.viewTypeModelMap[nativeViewType]?.convert(from: params) else {
            DocsLogger.btError("\(TAG) desrialized params failed")
            return
        }
        
        DocsLogger.btInfo("\(TAG) showNativeRender view type:\(nativeViewType)")
        if !hasInit {
            let openBaseTraceId = browserController.fileConfig?.getOpenFileTraceId()
            let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: openBaseTraceId)
            let context = BTNativeRenderContext(id: UUID().uuidString, openBaseTraceId: openBaseTraceId ?? "unkonwn", nativeRenderTraceId: traceId ?? "unkonwn")
            let consumer = BTNativeRenderConsumer()
            BTStatisticManager.shared?.addNormalConsumer(traceId: context.nativeRenderTraceId, consumer: consumer)
            
            guard let vc = nativeRenderViewManager?.creatViewBy(type: nativeViewType,
                                                                model: model,
                                                                service: container,
                                                                context: context) else {
                DocsLogger.btError("\(TAG) showNativeRender create VC failed type:\(nativeViewType)")
                return
            }
            BTNativeRenderReportMonitor.reportStart(traceId: context.nativeRenderTraceId)
            container.nativeRendrePlugin.showNativeRenderView(nativeRenderVC: vc)
            hasInit = true
        } else {
            container.nativeRendrePlugin.updateModel(model: model)
        }
    }
}
