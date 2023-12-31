//
//  OpenPluginAppInputComponent.swift
//  OPPlugin
//
//  Created by Nicholas Tau on 2021/4/27.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import ECOInfra
import LarkContainer
import TTMicroApp

final class OpenPluginAppInputComponent: OpenBasePlugin {
    func hideKeyboard(params: OpenAPIKeyboardParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        // Native小程序 / H5 的键盘
        if let page = context.enginePageForComponent {
            // Input 非同层级组件
            let componentId = params.inputId
            let input = BDPComponentManager.shared()?.findComponentView(byID: componentId)
            context.apiTrace.info("hideKeyboard inputId:\(componentId)")
            if let _ = input as? BDPInputView {
                context.apiTrace.info("hideKeyboard BDPInputView")
                BDPComponentManager.shared()?.removeComponentView(byID: componentId)
                callback(.success(data: nil))
                return
            }
            // TextArea 同层级组件
            if let view = page.bdp_component(fromIndex: params.stringInputId) as? BDPTextArea {
                context.apiTrace.info("hideKeyboard BDPTextArea")
                view.resignFirstResponder()
                callback(.success(data: nil))
                return
            }
            context.apiTrace.warn("hideKeyboard not found the input view")
        } else {
            context.apiTrace.warn("engine is not a WKWebView instance")
        }
        // 来自 AppService 调用直接关掉键盘
        gadgetContext.controller?.view.endEditing(true)
        callback(.success(data: nil))
    }
    
    func showKeyboard(params: OpenAPIKeyboardParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIKeyboardResult>) -> Void) {
        // BDPKeyboardManager在init时监听系统通知，然后组件内部依赖了BDPKeyboardManager接受到的系统通知后调整里的属性，需要将BDPKeyboardManager前置监听，确保组件使用时对应属性正确，后续refactor掉BDPKeyboardManager
        BDPKeyboardManager.shared()
        let uniqueID = gadgetContext.uniqueID
        
        guard let page = context.enginePageForComponent as? WKWebView else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("请在 H5 / Native-App 运行环境下执行。")
            callback(.failure(error: error))
            return
        }
        // CallBack回调一定要比becomeFirstResponder早，这样JS才能提前拿到inputID
        // becomeFirstResponder会发送onKeyboardShow消息，如果becomeFirstResponder比回调早，JS收到消息时并没有inputID，键盘会无法拉起。
        // 具体表现为键盘出现又收起。
        let componentID = BDPComponentManager.shared()?.generateComponentID() ?? 0
        context.apiTrace.info("showKeyboard inputId:\(componentID)")
        callback(.success(data: OpenAPIKeyboardResult(inputId: componentID)))
        if let model = params.model,
           let input = BDPInputView(model: model, isNativeComponent: false, isOverlay: false) {
            let webViewID = params.frameId ?? 0
            input.webViewID = webViewID
            input.componentID = componentID
            input.page = page
            input.fireWebviewEventBlock = { [weak self] (eventName, data) in
                guard let `self` = self,
                      let event = eventName else {
                    context.apiTrace.error("textArea \(componentID) can not fire webview event \(eventName), data \(data?.count ?? 0)")
                    return
                }
                self.fireEvent(toWebView: true, context: context, event: event, sourceID: webViewID, data: data)
            }

            input.fireAppServiceEventBlock = { [weak self, context] (eventName, data) in
                guard let `self` = self,
                      let event = eventName else {
                    context.apiTrace.error("textArea \(componentID) can not fire app service event \(eventName), data \(data?.count ?? 0)")
                    return
                }
                self.fireEvent(toWebView: false, context: context, event: event, sourceID: webViewID, data: data)
            }
            
            let view = model.fixed ? page : page.scrollView
            BDPComponentManager.shared()?.insertComponentView(input, to: view)
            // 变成第一响应链(如果键盘没有展示则会展示键盘)
            if(ECOSetting.gadgetBugfixInputFocusPreventDefaultEnable()) {
                toBeFirstResponder(input, viewController: gadgetContext.controller, context: context)
            } else if #available(iOS 15.0, *) {
                if (EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetIos15InputKeyboardWakeUpAfterDelay)) {
                    // iOS 15 input组件拉起键盘问题 - 临时方案，需要进一步讨论解决方案 @doujian
                    let delayTime = ECOSetting.gadgetBugfixInputFocusPreventDefaultDelayTime()
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [self] in
                        toBeFirstResponder(input, viewController: gadgetContext.controller, context: context)
                    }
                } else {
                    toBeFirstResponder(input, viewController: gadgetContext.controller, context: context)
                }
            } else {
                toBeFirstResponder(input, viewController: gadgetContext.controller, context: context)
            }
        }
    }
    
    func updateInput(params: OpenAPIKeyboardParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        
        // Native小程序 / H5 的键盘
        let componentID = params.inputId
        let view = BDPComponentManager.shared()?.findComponentView(byID: componentID)
        context.apiTrace.info("updateInput inputId:\(componentID)")
        if let view = view as? BDPInputView {
            view.update(with: params.originalParams)
            callback(.success(data: nil))
            return
        }
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("inputId有误")
        callback(.failure(error: error))
    }
    
    func setKeyboardValue(params: OpenAPISetKeyboardParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        
        
        // Native小程序 / H5 的键盘
        let componentID = params.inputId
        let cursor = params.cursor
        let value = params.value
        
        let view = BDPComponentManager.shared()?.findComponentView(byID: componentID)
        context.apiTrace.info("setKeyboardValue inputId:\(componentID)")
        if let inputView = view as? BDPInputView {
            inputView.text = value
            inputView.model.cursor = cursor
            inputView.updateCursorAndSelection(inputView.model)
            callback(.success(data: nil))
            return
        }
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("inputId有误")
        callback(.failure(error: error))
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
            case .success(data: _):
                context.apiTrace.info("fire event \(event) success")
            default:
                context.apiTrace.info("fire event \(event) enter default flow")
            }
        } catch {
            context.apiTrace.info("generate fire event params error \(error)")
        }
    }
    
    private func toBeFirstResponder(_ responder: UIResponder?, viewController: UIViewController?, context: OpenAPIContext) {
        if let responder = responder {
            context.apiTrace.info("toBeFirstResponder")
            if let unwrapperedController = viewController,
               let controller = BDPAppController.currentAppPageController(unwrapperedController, fixForPopover: false) as? BDPAppPageController {
                if controller.isAppeared {
                    responder.becomeFirstResponder()
                } else {
                    // Trick Code: VC DidAppear准备好前不展示键盘
                    DispatchQueue.main.asyncAfter(deadline:  .now() + 0.5) {
                        responder.becomeFirstResponder()
                    }
                }
            } else if (UIDevice.current.systemVersion as? NSString)?.floatValue ?? 0.0 < 10.0 {
                // Trick Code: 修复投票小程序在iOS 9上首次不能弹起键盘的问题
                DispatchQueue.main.asyncAfter(deadline:  .now() + 0.35) {
                    responder.becomeFirstResponder()
                }
            } else {
                responder.becomeFirstResponder()
            }
        } else {
            context.apiTrace.error("toBeFirstResponder responder is nil")
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "hideKeyboard", pluginType: Self.self, paramsType: OpenAPIKeyboardParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.hideKeyboard(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "showKeyboard", pluginType: Self.self, paramsType: OpenAPIKeyboardParams.self, resultType: OpenAPIKeyboardResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.showKeyboard(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "updateInput", pluginType: Self.self, paramsType: OpenAPIKeyboardParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.updateInput(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "setKeyboardValue", pluginType: Self.self, paramsType: OpenAPISetKeyboardParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.setKeyboardValue(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
