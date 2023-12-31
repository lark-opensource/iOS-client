//
//  OpenNativeInputComponent.swift
//  OPPlugin
//
//  Created by xiongmin on 2022/3/9.
//

import Foundation
import LarkOpenPluginManager
import TTMicroApp
import OPPluginManagerAdapter
import ECOProbe
import LarkWebviewNativeComponent
import LKCommonsLogging
import UIKit

final class OpenNativeInputComponent: OpenNativeBaseComponent, BDPInputEventDelegate {
    private static let logger = Logger.oplog(OpenNativeInputComponent.self, category: "LarkWebviewNativeComponent")
    
    var input: BDPInputView?
    var focusAPIEnable = false
    
    // 组件标签名字
    override class func nativeComponentName() -> String {
        return "input"
    }
    
    // 组件插入接收，返回view
    override func insert(params: [AnyHashable: Any], trace: OPTrace) -> UIView? {
        do {
            // 需要初始化才能开启input组件内部需要的监听
            BDPKeyboardManager.shared()
            if let focusAPIEnable = params["focusAPIEnable"] as? Bool {
                self.focusAPIEnable = focusAPIEnable
            }
            let model = try BDPInputViewModel(dictionary: params)
            input = BDPInputView(model: model, isNativeComponent: true, isOverlay: renderType == .native_component_overlay)
            input?.componentID = Int(componentID) ?? 0
            input?.page = webView
            if renderType == .native_component_overlay {
                // 如果是新同层的overlay，就先把input改为alpha为0
                // 在需要显示的时候, 在该次调用中更新布局
                input?.setOverlayStatus(false)
                // overlay强制走focusAPIEnable
                self.focusAPIEnable = true
            }
            input?.eventDelegate = self
            trace.info("input insert componentID:\(componentID), focusAPIEnable: \(focusAPIEnable)")
            return input
        } catch {
            Self.logger.error("input component, insert error, BDPInputViewModel init error: \(error)")
        }
        return nil
    }
    
    // 组件更新
    override func update(nativeView: UIView?, params: [AnyHashable: Any]) {
        if let input = nativeView as? BDPInputView {
            input.update(with: params)
            // 在focusAPIEnable为false时, 如果传了focus，那么需要唤起键盘
            if input.model.focus != input.isFirstResponder, !focusAPIEnable {
                // focus 和本身状态不同，则需要进行切换
                if input.model.focus {
                    self.toBeFirstResponder(input)
                } else {
                    input.resignFirstResponder()
                }
            }
            if input.model.disabled == input.isEnabled {
                input.isEnabled = !input.model.disabled
            }
        }
    }
    
    override func viewDidInsert(success: Bool) {
        if success, let input = input, !focusAPIEnable {
            let shouldFocus = (input.model.focus || input.model.autoFocus)
            if shouldFocus != input.isFirstResponder {
                // focus 和本身状态不同，则需要进行切换
                if shouldFocus {
                    self.toBeFirstResponder(input)
                } else {
                    input.resignFirstResponder()
                }
            }
            if input.model.disabled == input.isEnabled {
                input.isEnabled = !input.model.disabled
            }
            // 根据font计算高度
            input.updateHeight()
        }
    }
    
    // 组件删除
    override func delete() {
        input?.removeFromSuperview()
        input = nil
    }
    
    // 接收JS派发的消息
    override func dispatchAction(methodName: String, data: [AnyHashable: Any]) {
        guard let input = input else {
            Self.logger.error("input component, dispatchAction error, inputView is nil")
            return
        }
        if methodName == "setKeyboardValue" {
            do {
                let parmas = try OpenNativeAPISetKeyboardParams(with: data)
                input.text = parmas.value
                input.model.cursor = parmas.cursor
                input.updateCursorAndSelection(input.model)
            } catch {
                Self.logger.error("input commponent setKeyboardValue error, generate parmas failed: \(data) error: \(error)")
            }
        } else if methodName == "showKeyboard", focusAPIEnable {
            if !input.isFirstResponder {
                self.toBeFirstResponder(input)
            }
        } else if methodName == "hideKeyboard", focusAPIEnable {
            if input.isFirstResponder {
                input.resignFirstResponder()
            }
        }
    }
    
    private func toBeFirstResponder(_ responder: BDPInputView) {
        if renderType == .native_component_overlay {
            // 更新可用状态
            // 布局在update里完成
            responder.setOverlayStatus(true)
        }
        if let unwrapperedController = responder.op_findFirstViewController(),
           let controller = BDPAppController.currentAppPageController(unwrapperedController, fixForPopover: false) {
            if controller.isAppeared {
                responder.becomeFirstResponder()
            } else {
                // Trick Code: VC DidAppear准备好前不展示键盘
                DispatchQueue.main.asyncAfter(deadline:  .now() + 0.5) {
                    responder.becomeFirstResponder()
                }
            }
        } else {
            responder.becomeFirstResponder()
        }
    }
    
    func fireInputEvent(_ event: String, data: [AnyHashable : Any]) {
        Self.logger.info("fireInputEvent, event: \(event), data: \(data)")
        // 派发至同层框架事件
        fireEvent(event: event, params: data)
        // 派发至渲染层事件, 使得其他onKeyboardShow可被响应
        fireEventToRender(event: event, data: data)
    }
    
    // fire_event_to_render_disable
    lazy var fireEventToRenderDisable = {
        OPSettings(key: .make(userKeyLiteral: "op_textarea_settings"), tag: "fire_event_to_render_disable", defaultValue: false).getValue()
    }()
    
    private func fireEventToRender(event: String, data: [AnyHashable: Any]?) {
        guard let appPage = input?.page as? BDPWebView,
        event == "onKeyboardShow" || event == "onKeyboardComplete",
        var newData = data else {
            return
        }
        guard !fireEventToRenderDisable else {
            return
        }
        newData.merge(["inputId": componentID], uniquingKeysWith: { $1 })
        appPage.bdp_fireEventV2(event, data: newData)
    }
}

