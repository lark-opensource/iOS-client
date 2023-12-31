//
//  OpenNativeComponentManager.swift
//  OPPlugin
//
//  Created by yi on 2021/8/23.
//
// 组件管理模块

import Foundation
import WebKit
import LKCommonsLogging
import ECOProbe
import LarkWebViewContainer
import ECOInfra
import LarkOpenAPIModel

final public class OpenNativeComponentManager: NSObject {
    static let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "NativeComponent")

    public var componentMap: [AnyHashable: OpenNativeComponentWrapper] = [:] // 组件实例map
    
    public required override init() {
        super.init()
    }
    
    // 覆盖渲染的同层view管理者
    lazy var overlayManager: OpenOverlayComponentManager = {
        OpenOverlayComponentManager()
    }()
    
    // 插入组件
    /*
     * type: 组件类别 input map ...
     * componentID: renderID 渲染器的id
     * identify: 前端传过来的ID
     *
    */
    func insertComponent(webView: LarkWebView, type: String, componentID: String, identify: String, renderType: OpenNativeComponentRenderType, data: [AnyHashable: Any], trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        // 获取render
        let componentRender = OpenComponentRenderFactory.componentRender(type: renderType)

        if let wrapper = componentMap[componentID] {
            if wrapper.insertStatus != .fail {
                trace.error("NativeComponentManager, insertComponent fail, component exist, type \(type) componentID \(componentID) identify \(identify)")
                let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                    .setNativeComponentError(OpenNativeComponentBridgeAPIError.insertComponentExist)
                callback(.failure(error: error))
                OpenNativeComponentInterceptor.classType(type, webView: webView)?.receivedJSInsertEvent(with: componentID, params: data, error: error)
                return
            } else {
                trace.info("NativeComponentManager, insert component exist, will clear manager, type \(type) componentID \(componentID) identify \(identify)")
                // 插入失败要清理
                wrapper.nativeComponent.delete(trace: trace)
                _ = componentRender.removeComponent(webView: webView, componentID: componentID)

                componentMap.removeValue(forKey: componentID)
            }
        }
        OpenNativeComponentInterceptor.classType(type, webView: webView)?.receivedJSInsertEvent(with: componentID, params: data, error: nil)
        guard let componentClass = webView.op_typeManager?.componentClass(type: type) as? NSObject.Type,
        let nativeComponent = componentClass.init() as? OpenNativeBaseComponent else {
            trace.error("NativeComponentManager, insertComponent fail, component type init error, type \(type) componentID \(componentID) identify \(identify) renderType: \(renderType)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.initComponentError)
            callback(.failure(error: error))
            OpenNativeComponentInterceptor.classType(type, webView: webView)?.renderViewOnCreate(with: componentID, params: data, error: error)
            return
        }
        OpenNativeComponentInterceptor.classType(type, webView: webView)?.renderViewOnCreate(with: componentID, params: data, error: nil)
        nativeComponent.renderType = renderType
        nativeComponent.type = type
        nativeComponent.setupWebView(view: webView)
        nativeComponent.componentID = componentID
        nativeComponent.identify = identify
        
        let componentWrapper = OpenNativeComponentWrapper(nativeComponent: nativeComponent)
        trace.info("NativeComponentManager, insertComponent enter webview, type \(type) componentID \(componentID) renderType: \(renderType)")
        
        let apiContext = APIContext(type: type,
                                    identify: identify,
                                    renderId: componentID,
                                    renderType: renderType,
                                    data: data,
                                    trace: trace,
                                    completion: callback)
        apiContext.webView = webView
        apiContext.componentWrapper = componentWrapper
        
        // 调用业务组件插入视图
        let dealedData = processComponentFrame(data: data, renderType: renderType)
        
        if let componentRender = componentRender as? OpenComponentNativeSyncRender.Type {
            /// MARK: 新同层渲染逻辑
            /// APIContext已经准备好（同步方案满足条件之二）
            /// 设置syncManager的delegate，并且将APIContext加入到APIContextPool中
            componentRender.addAPIContext(apiContext: apiContext, syncDelegate: self)
        } else {
            // 插入web图层
            componentWrapper.insertStatus = .inserting
            
            /// MARK: 旧同层渲染逻辑
            nativeComponent.getNativeView(dealedData: dealedData, trace: trace, webView: webView) {
                response in
                switch response {
                case .failure(let error):
                    trace.error("NativeComponentManager, insertComponent fail, biz component return nil view, type \(type) componentID \(componentID) renderType: \(renderType)")
                    callback(.failure(error: error))
                    OpenNativeComponentInterceptor.classType(type, webView: webView)?.componentAdd(with: componentID, params: data, error: error)
                    apiContext.componentWrapper?.insertStatus = .fail
                    return
                case .success(let nativeView):
                    guard let webView = apiContext.webView else {
                        trace.error("NativeComponentManager, insertComponent failed because APIContext's LarkWebView is nil")
                        let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                            .setNativeComponentError(OpenNativeComponentBridgeAPIError.noWebView)
                        callback(.failure(error: error))
                        return
                    }
                    componentRender.insertComponent(webView: webView, view: nativeView, componentID: componentID, style: dealedData["style"] as? [String: Any]) { success in
                        Self.afterInsert(apiContext: apiContext, nativeView: nativeView, success: success, callback: callback)
                        apiContext.componentWrapper?.nativeComponent.viewDidInsert(success: success)
                    }
                }
            }
        }
        // 需要在本次调用堆栈存入字典，而非callback后再调用。以便callback未调用时，其他访问者也能感知到此componentID
        self.componentMap[componentID] = componentWrapper
    }
    
    static func afterInsert(apiContext: APIContext, nativeView: UIView, success: Bool, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        if let componentWrapper = apiContext.componentWrapper, success {
            let result = OpenComponentBaseResult()
            result.extraData = ["id": apiContext.identify, "renderID": apiContext.renderId]
            callback(.success(data: result))
            componentWrapper.insertStatus = .success
            componentWrapper.nativeView = nativeView
            apiContext.logComponentAdd(error: nil)
        } else {
            Self.logger.error("NativeComponentManager, insertComponent fail, componentRender error, type \(apiContext.type) componentID \(apiContext.renderId) identify \(apiContext.identify) renderType: \(apiContext.renderType)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.insertRenderError)
            callback(.failure(error: error))
            apiContext.componentWrapper?.insertStatus = .fail
            apiContext.componentWrapper?.nativeView = nativeView
            apiContext.logComponentAdd(error: error)
        }
    }

    // 移除组件
    func removeComponent(webView: LarkWebView, componentID: String, trace: OPTrace? = nil) -> Bool {
        guard let wrapper = componentMap[componentID] else {
            Self.logger.warn("NativeComponentManager, removeComponent fail, can not find biz component, componentID \(componentID)")
            return false
        }
        
        let componentRender = OpenComponentRenderFactory.componentRender(type: wrapper.nativeComponent.renderType)
        
        wrapper.nativeComponent.delete(trace: trace)
        let result = componentRender.removeComponent(webView: webView, componentID: componentID)
        componentMap.removeValue(forKey: componentID) // 不关注渲染层失败与否，componentMap决定业务侧不会被多次delete
        if !result {
            // result 为false 表示已经不存在了
            Self.logger.warn("NativeComponentManager, removeComponent fail, componentRender remove fail, componentID \(componentID)")
        }
        return true
    }

    // 更新组件
    func updateComponent(webView: LarkWebView, componentID: String, data: [AnyHashable: Any], trace: OPTrace) -> Bool {
        guard let wrapper = componentMap[componentID] else {
            trace.warn("NativeComponentManager, removeComponent fail, can not find biz component, componentID \(componentID)")
            return false
        }
        
        let componentRender = OpenComponentRenderFactory.componentRender(type: wrapper.nativeComponent.renderType)
        
        let component = wrapper.nativeComponent
        let nativeView = componentRender.component(webView: webView, componentID: componentID)
        if let nativeView = nativeView {
            // 处理display:none的情况
            if nativeView.superview == nil, let style = data["style"] as? [AnyHashable: Any], let hidden = style["hide"] as? Bool, !hidden {
                reRender(webView: webView, componentID: componentID, nativeView: nativeView, data: data, trace: trace) { _ in
                }
            }
        } else {
            let error = OpenAPIError(errno: OpenNativeInfraErrnoUpdate.internalError).setNativeComponentError(OpenNativeComponentBridgeAPIError.updateComponentFail)
            OpenNativeComponentInterceptor.classType(component)?.updateComponentBounds(with: componentID, params: data, error: error)
            trace.warn("NativeComponentManager, updateComponent invoke, nativeView can not find, componentID \(componentID) renderType: \(component.renderType)")
        }
        // 给到组件的frame origin 应该是0
        let dealedData = processComponentFrame(data: data, renderType: component.renderType)
        component.update(nativeView: nativeView, params: dealedData, trace: trace)
        // 这里只是留一个口子，不再有具体逻辑了
        componentRender.updateComponent(webView: webView, componentID: componentID, style: dealedData["style"] as? [String: Any])
        OpenNativeComponentInterceptor.classType(component)?.updateComponentBounds(with: componentID, params: data, error: nil)
        return true
    }

    // 派发组件事件
    func nativeComponentDispatchAction(webView: LarkWebView, componentID: String, method: String, data: [AnyHashable: Any], trace: OPTrace, webview: LarkWebView, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        guard let wrapper = componentMap[componentID] else {
            trace.error("NativeComponentManager, nativeComponentDispatchAction fail, can not find biz component, componentID \(componentID) method\(method)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.dispatchActionNoComponent)
            callback(.failure(error: error))
            return
        }
        
        if method == "reRender" {
            if let nativeView = wrapper.nativeView {
                reRender(webView: webView, componentID: componentID, nativeView: nativeView, data: data, trace: trace, callback: callback)
            } else {
                let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                    .setNativeComponentError(OpenNativeComponentBridgeAPIError.dispatchActionNoComponent)
                callback(.failure(error: error))
            }
            return
        }
        
        wrapper.nativeComponent.dispatchAction(methodName: method, data: data, trace: trace, webView: webview) { response in
            switch response {
            case let .failure(error: error):
                callback(.failure(error: error))
            case let .success(data: data):
                callback(.success(data: data))
            }
        }
    }

    private func reRender(webView: LarkWebView, componentID: String, nativeView: UIView, data: [AnyHashable: Any], trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        guard let component = componentMap[componentID]?.nativeComponent else {
            trace.error("NativeComponentManager, reRender fail, componentRender is nil, componentID \(componentID)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noRender)
            callback(.failure(error: error))
            return
        }
        
        let componentRender = OpenComponentRenderFactory.componentRender(type: component.renderType)

        if let componentWrapper = componentMap[componentID] {
            let disableInsertingControl = EMAFeatureGating.boolValue(forKey: "gadget.native_component.disable.inserting_control")
            if !disableInsertingControl {
                if componentWrapper.insertStatus == .inserting || componentWrapper.insertStatus == .none {
                    trace.error("NativeComponentManager, reRender fail, inserting, componentID \(componentID)")
                    let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                        .setNativeComponentError(OpenNativeComponentBridgeAPIError.reRenderError)
                    callback(.failure(error: error))
                    return

                }
            } else {
                trace.info("NativeComponentManager, disableInsertingControl is true, componentID \(componentID)")
            }
            
            /// 一次insert是先加池子，再生成native view，再往scrollview上add
            /// 另外一次是scrollview因为css变更dealloc，需要在有native view的情况下，重新加池子，等ready后往scrollview add。
            
            let apiContext = APIContext(type: component.type,
                                        identify: component.identify,
                                        renderId: componentID,
                                        renderType: component.renderType,
                                        data: data,
                                        trace: trace,
                                        completion: callback)
            apiContext.webView = webView
            apiContext.componentWrapper = componentWrapper
            
            if let componentRender = componentRender as? OpenComponentNativeSyncRender.Type {
                apiContext.existNativeView = nativeView
                componentRender.addAPIContext(apiContext: apiContext, syncDelegate: self)
            } else {
                componentWrapper.insertStatus = .inserting
                componentRender.insertComponent(webView: webView, view: nativeView, componentID: componentID, style: nil) { success in
                    if success {
                        if !disableInsertingControl {
                            apiContext.componentWrapper?.insertStatus = .success
                        }
                        callback(.success(data: nil))
                    } else {
                        if !disableInsertingControl {
                            apiContext.componentWrapper?.insertStatus = .fail
                        }
                        trace.error("NativeComponentManager, reRender fail, componentRender insert error, nativeView from manager \(apiContext.componentWrapper?.nativeView != nil), componentID \(componentID)")
                        let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                            .setNativeComponentError(OpenNativeComponentBridgeAPIError.reRenderInsertError)
                        callback(.failure(error: error))
                    }
                }
            }
        } else {
            trace.error("NativeComponentManager, reRender fail, component is nil, componentID \(componentID)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.reRenderNoComponent)
            callback(.failure(error: error))
        }
    }

    // 移除webview下所有组件实例
    func removeAllComponents(webView: LarkWebView) {
        for item in componentMap {
            if let componentID = item.key as? String {
                _ = removeComponent(webView: webView, componentID: componentID)
            }
        }
    }
    // 处理组件frame信息, 新框架下组件本身的frame的x, y应该都是0，父视图的布局才是js传过来的位置信息
    func processComponentFrame(data: [AnyHashable: Any], renderType: OpenNativeComponentRenderType) -> [AnyHashable: Any] {
        if renderType == .native_component_overlay {
            // 非同层需要保留
            return data
        }
        if let style = data["style"] as? [String: AnyHashable] {
            var newStyle = style
            newStyle["top"] = 0
            newStyle["left"] = 0
            var newData = data
            newData["style"] = newStyle
            return newData
        }
        return data
    }
}

// MARK: - Component Check

extension OpenNativeComponentManager {
    public func checkComponentUnique(component: OpenNativeBaseComponent) -> Bool {
        var result = true
        let type = type(of: component.self)
        componentMap.forEach { (key: AnyHashable, value: OpenNativeComponentWrapper) in
            if value.nativeComponent != component, value.nativeComponent.isKind(of: type) {
                if value.insertStatus == .success || value.insertStatus == .inserting {
                    result = false
                }
            }
        }
        return result
    }
}

final public class OpenNativeComponentWrapper {
    var nativeComponent: OpenNativeBaseComponent
    var nativeView: UIView?
    var insertStatus: OpenNativeComponentInsertStatus = .none

    public init(nativeComponent: OpenNativeBaseComponent) {
        self.nativeComponent = nativeComponent
    }
}

// 组件插入状态
enum OpenNativeComponentInsertStatus {
    case none // 初始化状态
    case success // 插入成功
    case fail // 插入失败
    case inserting
}
