//
//  OpenPluginTextArea.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/5/7.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LKCommonsLogging
import LarkContainer
import TTMicroApp

final class OpenPluginTextArea: OpenBasePlugin {

    private var currentContext: OpenAPIContext?

    private static let logger = Logger.log(OpenPluginTextArea.self, category: "OpenAPI")

    // implemention of api handlers
    func insertTextArea(params: OpenAPIInsertTextAreaParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPITextAreaResult>) -> Void) {
        context.apiTrace.info("insert Textarea \(params.componentID) in webview \(params.webViewID)")
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("请在 H5 / Native-App 运行环境下执行。")
                .setMonitorMessage("can not get current engine as webview, fail insert Textarea \(params.componentID) in webview \(params.webViewID)")
            callback(.failure(error: error))
            return
        }
        guard let textArea = BDPTextArea(model: params.model) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not generate textarea \(params.componentID) from params for webview \(params.webViewID)")
            callback(.failure(error: error))
            return
        }
        currentContext = context
        // BDPKeyboardManager在init时监听系统通知，然后组件内部依赖了BDPKeyboardManager接受到的系统通知后调整里的属性，需要将BDPKeyboardManager前置监听，确保组件使用时对应属性正确，后续refactor掉BDPKeyboardManager
        BDPKeyboardManager.shared()
        textArea.page = page
        textArea.webViewID = params.webViewID
        textArea.pageOriginFrame = page.frame
        textArea.componentID = params.componentID
        textArea.fireWebviewEventBlock = { [weak self] (eventName, data) in
            guard let `self` = self,
                  let context = self.currentContext,
                  let event = eventName else {
                Self.logger.error("textArea \(params.componentID) can not fire webview event \(eventName), data \(data?.count ?? 0)")
                return
            }
            self.fireEvent(toWebView: true, context: context, event: event, sourceID: params.webViewID, data: data)
        }

        textArea.fireAppServiceEventBlock = { [weak self, context] (eventName, data) in
            guard let `self` = self,
                  let context = self.currentContext,
                  let event = eventName else {
                Self.logger.error("textArea \(params.componentID) can not fire app service event \(eventName), data \(data?.count ?? 0)")
                return
            }
            self.fireEvent(toWebView: false, context: context, event: event, sourceID: params.webViewID, data: data)
        }

        page.bdp_insertComponent(textArea, atIndex: params.componentID) { (success) in
            if (success) {
                callback(.success(data: OpenAPITextAreaResult(componentID: params.componentID)))
                // ⚠️同层渲染组件逻辑变更，需要在组件插入到同层 WKScrollView 后
                // 再检测高度并通过 onTextAreaHeightChange 通知 JSSDK(时机需保证)
                textArea.updateHeight(forAutoSize: params.model)
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("failed insert textarea \(params.componentID) to webview \(params.webViewID)")
                callback(.failure(error: error))
            }
        }
    }

    public func removeTextArea(params: OpenAPITextAreaBaseParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("请在 H5 / Native-App 运行环境下执行。")
                .setMonitorMessage("can not get current engine as webview, fail remove Textarea \(params.componentID)")
            callback(.failure(error: error))
            return
        }
        if page.bdp_removeComponent(atIndex: params.componentID) {
            callback(.success(data: nil))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("inputId有误")
                .setMonitorMessage("fail remove Textarea \(params.componentID)")
            callback(.failure(error: error))
        }
    }

    public func updateTextArea(params: OpenAPIUpdateTextAreaParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("请在 H5 / Native-App 运行环境下执行。")
                .setMonitorMessage("can not get current engine as webview, fail update Textarea \(params.componentID)")
            callback(.failure(error: error))
            return
        }
        guard let textArea = page.bdp_component(fromIndex: params.componentID) as? BDPTextArea else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("inputId有误")
                .setMonitorMessage("can not find textarea ID=\(params.componentID)")
            callback(.failure(error: error))
            return
        }
        textArea.update(with: params.dict)
        page.bdp_insertComponent(textArea, atIndex: params.componentID, completion: nil)
        callback(.success(data: nil))
    }

    public func showTextAreaKeyboard(params: OpenAPIShowTextAreaKeyBoardParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let page = context.enginePageForComponent else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("请在 H5 / Native-App 运行环境下执行。")
                .setMonitorMessage("can not get current engine as webview, fail show keyboard for Textarea \(params.componentID)")
            callback(.failure(error: error))
            return
        }
        guard let textArea = page.bdp_component(fromIndex: params.componentID) as? BDPTextArea else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("inputId有误")
                .setMonitorMessage("can not find textarea ID=\(params.componentID)")
            callback(.failure(error: error))
            return
        }
        textArea.model.cursor = params.cursor
        textArea.model.selectionStart = params.selectionStart
        textArea.model.selectionEnd = params.selectionEnd
        textArea.updateCursorAndSelection(textArea.model)

        // 变成第一响应链(如果键盘没有展示则会展示键盘)
        self.makeFirstResponder(for: textArea, controller: context.controller)
        callback(.success(data: nil))
    }

    private func makeFirstResponder(for responder: UIResponder, controller: UIViewController?) {
        if let vc = controller, let appController = BDPAppController.currentAppPageController(vc, fixForPopover: false) {
            if appController.isAppeared {
                responder.becomeFirstResponder()
            } else {
                // Trick Code: VC DidAppear准备好前不展示键盘
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                    responder.becomeFirstResponder()
                }
            }
        } else if Float(UIDevice.current.systemVersion) ?? 0.0 < 10.0 {
            // Trick Code: 修复投票小程序在iOS 9上首次不能弹起键盘的问题
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35) {
                responder.becomeFirstResponder()
            }
        } else {
            responder.becomeFirstResponder()
        }
    }

    private func fireEvent(toWebView: Bool, context: OpenAPIContext, event: String, sourceID: Int, data: [AnyHashable: Any]?) {
        do {
            let fireEvent = try OpenAPIFireEventParams(event: event,
                                                       sourceID: sourceID,
                                                       data: data ?? [:],
                                                       preCheckType: .none,
                                                       sceneType: toWebView ? .render : .worker)
            let response = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            switch response {
            case let .failure(error: e):
                context.apiTrace.error("fire event \(event) fail \(e)")
            default:
                context.apiTrace.info("fire event \(event) success")
            }
        } catch {
            context.apiTrace.info("generate fire event params error \(error)")
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // register your api handlers here
        registerInstanceAsyncHandler(for: "insertTextArea", pluginType: Self.self, paramsType: OpenAPIInsertTextAreaParams.self, resultType: OpenAPITextAreaResult.self) { (this, params, context, callback) in
            
            this.insertTextArea(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "removeTextArea", pluginType: Self.self, paramsType: OpenAPITextAreaBaseParams.self) { (this, params, context, callback) in
            
            this.removeTextArea(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "updateTextArea", pluginType: Self.self, paramsType: OpenAPIUpdateTextAreaParams.self) { (this, params, context, callback) in
            
            this.updateTextArea(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "showTextAreaKeyboard", pluginType: Self.self, paramsType: OpenAPIShowTextAreaKeyBoardParams.self) { (this, params, context, callback) in
            
            this.showTextAreaKeyboard(params: params, context: context, callback: callback)
        }
    }

}
