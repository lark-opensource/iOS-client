//
//  OpenComponentNativeSyncRender.swift
//  LarkWebviewNativeComponent
//
//  Created by wangjin on 2022/10/19.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe
import LarkOpenAPIModel

final class OpenComponentNativeSyncRender: OpenComponentRenderProtocol {
    static private let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "LarkWebviewNativeComponent")
    
    static func insertComponent(webView: LarkWebView, view: UIView, componentID: String, style: [String : Any]?, completion: @escaping (Bool) -> Void) {
        webView.insertComponentSync(view: view, atIndex: componentID, existContainer: nil, completion: completion)
    }
    
    static func updateComponent(webView: LarkWebView, componentID: String, style: [String : Any]?) {
        /// 不做处理
    }
    
    static func removeComponent(webView: LarkWebView, componentID: String) -> Bool {
        return webView.removeComponentSync(index: componentID)
    }
    
    static func component(webView: LarkWebView, componentID: String) -> UIView? {
        let componentWrapper = webView.op_nativeComponentManager().componentMap[componentID]
        return componentWrapper?.nativeView
    }
    
    static func addAPIContext(apiContext: APIContext, syncDelegate: NativeComponentSyncDelegate) {
        guard let webView = apiContext.webView else {
            return
        }
        let type = apiContext.type
        let identify = apiContext.identify
        let componentID = apiContext.renderId
        let renderType = apiContext.renderType
        let data = apiContext.data
        let callback = apiContext.completion
        guard let manager = webView.op_getNativeComponentSyncManager() else {
            /// settings控制关闭了新同层渲染逻辑
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noSyncManagerError)
            callback(.failure(error: error))
            OpenNativeComponentInterceptor.classType(type, webView: webView)?.renderViewOnCreate(with: componentID, params: data, error: error)
            Self.logger.error("NativeComponentManager, insertComponent fail. Because of settings, component sync manager init error, type \(type) componentID \(componentID) identify \(identify) renderType: \(renderType)")
            return
        }
        /// 初始化LarkWebView中负责新同层渲染OpenNativeComponentSyncManager的delegate
        manager.syncRenderDelegate = syncDelegate
        /// 将API上下文对象加入暂存池
        manager.pushAPIContextPool(apiContext)
    }
}

extension OpenNativeComponentManager: NativeComponentSyncDelegate {
    /// 插入组件视图
    public func insertComponent(scrollView: UIScrollView, apiContext: APIContextProtocol) {
        guard let apiContext = apiContext as? APIContext else {
            Self.logger.error("OpenNativeComponentNativeSyncRender, insertComponent fail, api context is nil")
            return
        }
        
        let type = apiContext.type
        let componentID = apiContext.renderId
        let renderType = apiContext.renderType
        let data = apiContext.data
        let dealedData = processComponentFrame(data: data, renderType: renderType)
        let trace = apiContext.trace
        let callback = apiContext.completion
        let componentRender = OpenComponentRenderFactory.componentRender(type: renderType)
        
        guard let webView = apiContext.webView else {
            /// insert API调用上下文中webView为空
            Self.logger.error("NativeSyncRender, insertComponent failed because APIContext's LarkWebView is nil")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noWebView)
            callback(.failure(error: error))
            return
        }
        
        guard let componentWrapper = apiContext.componentWrapper else {
            Self.logger.error("NativeSyncRender, insertComponent failed because APIContext's component wrapper is nil")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noComponentWrapper)
            callback(.failure(error: error))
            OpenNativeComponentInterceptor.classType(type, webView: webView)?.componentAdd(with: componentID, params: data, error: error)
            /// componentWrapper异常，清除此次insert的所有上下文
            webView.op_getNativeComponentSyncManager()?.cleanScrollViewPoolIfNeeded(renderId: componentID)
            webView.op_getNativeComponentSyncManager()?.popAPIContextPoolIfNeeded(renderId: componentID)
            return
        }
        
        /// 当同步工作完成后，插入web图层
        componentWrapper.insertStatus = .inserting
        
        // 如果来源wrapper持有着nativeView
        if let existNativeView = apiContext.existNativeView ?? componentWrapper.nativeView {
            webView.insertComponentSync(view: existNativeView, atIndex: componentID, existContainer: scrollView) { success in
                // 这里是重新插入, 不再需要callback
                Self.afterInsert(apiContext: apiContext, nativeView: existNativeView, success: success) { _ in
                }
            }
        } else {
            componentWrapper.nativeComponent.getNativeView(dealedData: dealedData, trace: trace, webView: webView) { response in
                
                guard let webView = apiContext.webView else {
                    let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                        .setNativeComponentError(OpenNativeComponentBridgeAPIError.noWebView)
                    callback(.failure(error: error))
                    Self.logger.error("OpenNativeComponentNativeSyncRender, init native view fail, LarkWebView is nil, type \(type) componentID \(componentID) renderType: \(renderType)")
                    OpenNativeComponentInterceptor.classType(type, webView: webView)?.componentAdd(with: componentID, params: data, error: error)
                    apiContext.componentWrapper?.insertStatus = .fail
                    return
                }
                
                switch response {
                case .success(view: let nativeView):
                    componentRender.insertComponent(webView: webView, view: nativeView, componentID: componentID, style: dealedData["style"] as? [String: Any]) { success in
                        Self.afterInsert(apiContext: apiContext, nativeView: nativeView, success: success, callback: callback)
                        apiContext.componentWrapper?.nativeComponent.viewDidInsert(success: success)
                    }
                case .failure(error: let error):
                    callback(.failure(error: error))
                    Self.logger.error("OpenNativeComponentNativeSyncRender, insertComponent fail, biz component retun nil view, type \(type) componentID \(componentID) renderType: \(renderType)")
                    OpenNativeComponentInterceptor.classType(type, webView: webView)?.componentAdd(with: componentID, params: data, error: error)
                    apiContext.componentWrapper?.insertStatus = .fail
                    /// 插入操作结束后，无论成功或失败都清除此次insert的所有上下文
                    webView.op_getNativeComponentSyncManager()?.popAPIContextPoolIfNeeded(renderId: componentID)
                }
            }
        }
    }
}
