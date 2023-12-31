//
//  OpenNativeTextAreaComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/5/13.
//

import Foundation
import TTMicroApp
import OPPluginManagerAdapter
import LarkWebviewNativeComponent
import LKCommonsLogging
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting

final class OpenNativeTextAreaComponent: OpenPluginNativeComponent {
    @FeatureGatingValue(key: "openplatform.component.textarea.refactoring")
    var enableRefactoring: Bool
    
    private static let logger = Logger.oplog(OpenNativeTextAreaComponent.self, category: "LarkWebviewNativeComponent")
    // 组件标签名字
    override class func nativeComponentName() -> String {
        return "textarea"
    }
    
    var cacheParams: [AnyHashable: Any]?
    
    var textArea: BDPTextArea?
    var autoFocus: Bool = false
    
    private var refactoringTextArea: OPTextArea?
    private var textAreaStatus: OPTextAreaStatus = .none
    
    var focusAPIEnable = false
    
    enum OPTextAreaStatus {
        case none
        case inserted
        case insertedAndFocusChecked
    }
    
    // 组件插入接收，返回view
    override func insert(params: [AnyHashable: Any], trace: OPTrace) -> UIView? {
        guard let webView = webView else {
            // 限定BDPWebView范围
            Self.logger.error("webView is not kind of BDPWebView")
            return nil
        }
        
        if let focusAPIEnable = params["focusAPIEnable"] as? Bool {
            self.focusAPIEnable = focusAPIEnable
        }
        trace.info("insertTextArea start \(componentID), focusAPIEnable: \(focusAPIEnable)")
        
        cacheParams = params
        let textAreaModel = OpenNativeTextAreaParams(with: params)
        if enableRefactoring {
            let refactoringTextArea = OPTextArea(params: textAreaModel, webView: webView, componentDelegate: self, componentID: componentID, trace: trace)
            self.refactoringTextArea = refactoringTextArea
            return refactoringTextArea
        } else {
            let bdpTextAreaModel = transform(nativeModel: textAreaModel)
            guard let textArea = BDPTextArea(model: bdpTextAreaModel) else {
                return nil
            }
            BDPKeyboardManager.shared()
            textArea.page = webView
            textArea.pageOriginFrame = webView.frame
            textArea.componentID = componentID
            textArea.fireWebviewEventBlock = { [weak self] (eventName, data) in
                guard let self = self,
                      let event = eventName else {
                    return
                }
                self.fireEvent(event: event, params: data ?? [:])
                // 如果是onkeyboardShow和hide，依然要派发到渲染层
                if let eventType = TextAreaComponentEventType(rawValue: event),
                   eventType == .onKeyboardShow || eventType == .onKeyboardComplete {
                    self.fireEventToRender(event: eventType, data: data, render: self.bdpWebView)
                }
            }

            textArea.fireAppServiceEventBlock = { [weak self] (eventName, data) in
                guard let `self` = self,
                      let event = eventName else {
                    return
                }
                self.fireEvent(event: event, params: data ?? [:])
            }
            autoFocus = textAreaModel.autoFocus || textAreaModel.focus
            self.textArea = textArea
            return textArea
        }
    }

    // 组件更新
    override func update(nativeView: UIView?, params: [AnyHashable: Any], trace: OPTrace) {
        if enableRefactoring {
            guard let nativeView = nativeView as? OPTextArea else {
                trace.error("textarea is not OPTextArea")
                return
            }
            
            trace.info("update textarea \(componentID)")
            var resultParams = params
            if let cacheParams = cacheParams {
                resultParams.merge(cacheParams) { new, _ in new }
            }
            cacheParams = resultParams
            let model = OpenNativeTextAreaParams(with: resultParams)
            nativeView.update(params: model)
            if !focusAPIEnable {
                nativeView.checkFocus(isFirstInsert: false)
            }
        } else {
            guard let nativeView = nativeView as? BDPTextArea else {
                // error
                return
            }
            
            trace.info("updateTextArea start")
            
            var resultParams = params
            if let cacheParams = cacheParams {
                resultParams.merge(cacheParams) { new, cache in new }
            }
            
            let textAreaModel = OpenNativeTextAreaParams(with: resultParams)
            let bdpTextAreaModel = transform(nativeModel: textAreaModel)
            nativeView.update(withNewModel: bdpTextAreaModel)
            cacheParams = resultParams
            
            if !focusAPIEnable {
                checkDidFocus(focus: bdpTextAreaModel.focus, nativeView: nativeView)
            }
        }
    }
    
    override func viewDidInsert(success: Bool) {
        guard success else {
            return
        }
        guard !focusAPIEnable else {
            return
        }
        if enableRefactoring, let refactoringTextArea = refactoringTextArea {
            let vc = (webView as? BDPWebView)?.bridgeController
            if let appController = BDPAppController.currentAppPageController(vc, fixForPopover: false), appController.isAppeared {
                refactoringTextArea.checkFocus(isFirstInsert: true)
                textAreaStatus = .insertedAndFocusChecked
            } else {
                textAreaStatus = .inserted
            }
        } else {
            if let textArea = self.textArea {
                textArea.updateAutoSizeHeight()
                checkDidFocus(focus: autoFocus, nativeView: textArea)
                autoFocus = false
            }
        }
    }
    
    var firstDeveloperFocus = true
    
    func action(
        trace: OPTrace,
        callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void,
        ifRefactor: (OPTextArea) -> Void,
        ifOld: (BDPTextArea) -> Void)
    {
        guard focusAPIEnable else {
            let errno = OpenNativeTextareaDispatchActionErrno.focusAPIDisable
            trace.error(errno.errString)
            let error = OpenAPIError(errno: errno)
            return callback(.failure(error: error))
        }
        
        if enableRefactoring {
            guard let refactoringTextArea = refactoringTextArea else {
                let errno = OpenNativeTextareaDispatchActionErrno.noRefactoringTextArea
                trace.error(errno.errString)
                let error = OpenAPIError(errno: errno)
                return callback(.failure(error: error))
            }
            ifRefactor(refactoringTextArea)
            return callback(.success(data: nil))
        } else {
            guard let textArea = textArea else {
                let errno = OpenNativeTextareaDispatchActionErrno.noTextarea
                trace.error(errno.errString)
                let error = OpenAPIError(errno: errno)
                return callback(.failure(error: error))
            }
            ifOld(textArea)
            return callback(.success(data: nil))
        }
    }
    
    func showKeyboard(params: OpenNativeTextareaShowKeyboardParams, trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        action(trace: trace, callback: callback) { refactoringTextArea in
            refactoringTextArea.showKeyboardWhenFocusAPIEnable(isFirstInsert: firstDeveloperFocus, cursor: params.cursor, selectionStart: params.selectionStart, selectionEnd: params.selectionEnd)
            if firstDeveloperFocus {
                firstDeveloperFocus = false
            }
        } ifOld: { textArea in
            checkDidFocus(focus: true, nativeView: textArea)
        }
    }
    
    func hideKeyboard(trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        action(trace: trace, callback: callback) { refactoringTextArea in
            refactoringTextArea.hideKeyboardWhenFocusAPIEnable()
        } ifOld: { textArea in
            if textArea.isFirstResponder {
                textArea.resignFirstResponder()
            }
        }
    }
    
    override func webviewDidAppear() {
        super.webviewDidAppear()
        guard !focusAPIEnable else {
            return
        }
        if let refactoringTextArea = refactoringTextArea, textAreaStatus == .inserted {
            refactoringTextArea.checkFocus(isFirstInsert: true)
            textAreaStatus = .insertedAndFocusChecked
        }
    }
    
    override var needListenAppPageStatus: Bool { true }
    
    private func checkDidFocus(focus: Bool, nativeView: BDPTextArea) {
        let needFocus = focus && !nativeView.model.hidden && !nativeView.model.disabled
        if needFocus {
            nativeView.updateCursorAndSelection(nativeView.model)
            // 变成第一响应链(如果键盘没有展示则会展示键盘)
            self.makeFirstResponder(for: nativeView, controller: (webView as? BDPWebView)?.bridgeController)
        } else if nativeView.isFirstResponder {
            nativeView.resignFirstResponder()
        }
    }
    
    /// 桥接至OC实现的TextArea
    private func transform(nativeModel: OpenNativeTextAreaParams) -> BDPTextAreaModel {
        let bdpModel = BDPTextAreaModel()
        bdpModel.disabled = nativeModel.disabled
        bdpModel.hidden = nativeModel.hidden
        bdpModel.autoSize = nativeModel.autoSize
        bdpModel.fixed = nativeModel.fixed
        bdpModel.maxLength = nativeModel.maxLength
        bdpModel.data = nativeModel.data
        bdpModel.value = nativeModel.value
        bdpModel.placeholder = nativeModel.placeholder
        bdpModel.adjustPosition = nativeModel.adjustPosition
        bdpModel.showConfirmBar = nativeModel.showConfirmBar
        bdpModel.cursor = nativeModel.cursor
        bdpModel.selectionStart = nativeModel.selectionStart
        bdpModel.selectionEnd = nativeModel.selectionEnd
        bdpModel.disableDefaultPadding = nativeModel.disableDefaultPadding
        bdpModel.focus = nativeModel.focus
        
        let placeHolderStyle = BDPTextAreaPlaceHolderStyleModel()
        placeHolderStyle.fontSize = CGFloat(nativeModel.placeholderStyle?.fontSize ?? 0)
        placeHolderStyle.fontWeight = nativeModel.placeholderStyle?.fontWeight
        placeHolderStyle.fontFamily = nativeModel.placeholderStyle?.fontFamily
        placeHolderStyle.color = nativeModel.placeholderStyle?.color
        bdpModel.placeholderStyle = placeHolderStyle
        
        let style = BDPTextAreaStyleModel()
        style.fontSize = CGFloat(nativeModel.style?.fontSize ?? 0)
        style.fontWeight = nativeModel.style?.fontWeight
        style.fontFamily = nativeModel.style?.fontFamily
        style.color = nativeModel.style?.color
        style.top = CGFloat(nativeModel.style?.top ?? 0)
        style.left = CGFloat(nativeModel.style?.left ?? 0)
        style.width = CGFloat(nativeModel.style?.width ?? 0)
        style.height = CGFloat(nativeModel.style?.height ?? 0)
        style.backgroundColor = nativeModel.style?.backgroundColor ?? ""
        style.minHeight = CGFloat(nativeModel.style?.minHeight ?? 0)
        style.maxHeight = CGFloat(nativeModel.style?.maxHeight ?? 0)
        style.lineHeight = 0
        style.marginBottom = CGFloat(nativeModel.style?.marginBottom ?? 0)
        style.lineSpace = 0
        style.textAlign = nativeModel.style?.textAlign.rawValue
        bdpModel.style = style
        
        return bdpModel
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
        } else {
            responder.becomeFirstResponder()
        }
    }
    
    // fire_event_to_render_disable
    lazy var fireEventToRenderDisable = {
        OPSettings(key: .make(userKeyLiteral: "op_textarea_settings"), tag: "fire_event_to_render_disable", defaultValue: false).getValue()
    }()
    
    private func fireEventToRender(event: TextAreaComponentEventType, data: [AnyHashable: Any]?, render: BDPWebView?) {
        guard let appPage = render, var newData = data else {
            return
        }
        guard !fireEventToRenderDisable else {
            return
        }
        // 向渲染层派发键盘事件必须要带inputId, 否则会影响到在渲染层监听键盘事件, 并用inputId做对比的legacy input
        newData.merge(["inputId": componentID], uniquingKeysWith: { $1 })
        appPage.bdp_fireEventV2(event.rawValue, data: newData)
    }
    
    override init() {
        super.init()
        register()
    }
    
    enum API: String {
        case showKeyboard
        case hideKeyboard
    }
    
    private func register() {
        registerHandler(for: API.showKeyboard.rawValue, paramsType: OpenNativeTextareaShowKeyboardParams.self) { [weak self] params, context, callback in
            self?.showKeyboard(params: params, trace: context.trace, callback: callback)
        }
        registerHandler(for: API.hideKeyboard.rawValue) { [weak self] _, context, callback in
            self?.hideKeyboard(trace: context.trace, callback: callback)
        }
    }
}

extension OpenNativeTextAreaComponent: OPTextAreaComponentDelegate {
    enum TextAreaComponentEventType: String {
        case onKeyboardShow
        case onKeyboardComplete
        case onTextAreaHeightChange
        case onKeyboardValueChange
        case onKeyboardConfirm
        case onKeyboardHeightChange
    }
    
    func onFocus(params: OpenNativeTextAreaFocusResult) {
        fireTextAreaEvent(event: .onKeyboardShow, params: params)
        fireEventToRender(event: .onKeyboardShow, data: params.toJSONDict(), render: self.bdpWebView)
    }
    
    func onBlur(params: OpenNativeTextAreaBlurResult) {
        fireTextAreaEvent(event: .onKeyboardComplete, params: params)
        fireEventToRender(event: .onKeyboardComplete, data: params.toJSONDict(), render: self.bdpWebView)
    }
    
    func onLineChange(params: OpenNativeTextAreaLineChangeResult) {
        fireTextAreaEvent(event: .onTextAreaHeightChange, params: params)
    }
    
    func onInput(params: OpenNativeTextAreaInputResult) {
        fireTextAreaEvent(event: .onKeyboardValueChange, params: params)
    }
    
    func onConfirm(params: OpenNativeTextAreaConfirmResult) {
        fireTextAreaEvent(event: .onKeyboardConfirm, params: params)
    }
    
    func onKeyboardHeightChange(params: OpenNativeTextAreaKeyboardHeightChangeResult) {
        fireTextAreaEvent(event: .onKeyboardHeightChange, params: params)
    }
    
    private func fireTextAreaEvent(event: TextAreaComponentEventType, params: OpenComponentBaseResult) {
        let result = params.toJSONDict()
        Self.logger.info("fireTextAreaEvent, event: \(event), params: \(result)")
        fireEvent(event: event.rawValue, params: result)
    }
}
