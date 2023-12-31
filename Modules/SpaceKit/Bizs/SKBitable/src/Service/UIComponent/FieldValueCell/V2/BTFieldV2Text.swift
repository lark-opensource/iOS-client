// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import SKFoundation
import SKBrowser
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import SKUIKit
import QRCode
import SpaceInterface

final class BTFieldV2Text: BTFieldV2BaseText {

    private var textEditAgent: BTTextEditAgent?
    /// ui 配置
    private var uiConfig = BTTextFieldUIConfig()
    
    private var qrCodeManager = QRCodeScanManager()

    /// 键盘辅助工具栏
    private var accView: BTKeyboardInputAccessoryView?

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        uiConfig = BTTextFieldUIConfig(fieldModel: model)
        self.isShowCustomMenuViewWhenLongPress = !uiConfig.isTextSelectable
        textView.isSelectable = uiConfig.isTextSelectable
        textView.editPermission = uiConfig.isTextViewEditable
        textView.attributedText = BTUtil.convert(model.textValue, font: BTFV2Const.Font.fieldValue, forTextView: textView)
        
        textView.pasteOperation = { [weak self] in
            self?.textEditAgent?.doPaste()
        }
        updateEditAgent()
        qrCodeManager.delegate = self
    }

    // MARK: - TextView About
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        resetTypingAttributes()
        let shouldBeginEditing = uiConfig.isTextViewEditable
        setInputAccesssoryView(isSetNil: !shouldBeginEditing)
        return shouldBeginEditing
    }

    override func textViewDidBeginEditing(_ textView: UITextView) {
        fieldModel.update(isEditing: true)
        super.textViewDidBeginEditing(textView)
        self.trackFieldClickEvent(.textInput)
        if let textEditAgent = textEditAgent {
            delegate?.startEditing(inField: self, newEditAgent: textEditAgent)
        }
    }

    override func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        if fieldModel.editable {
            setCursorBootomOffset()
        }
        
        let attributes = BTUtil.getAttributes(in: textView, sender: sender)
        if !attributes.isEmpty {
            handleSingleTapped(with: attributes)
        } else {
            showUneditableToast()
        }
    }

    /// 处理富文本属性单击事件。
    // nolint: duplicated_code
    private func handleSingleTapped(with attributes: [NSAttributedString.Key: Any]) {
        if let docsInfo = textEditAgent?.coordinator?.editorDocsInfo,
           let atInfo = attributes[BTRichTextSegmentModel.attrStringBTAtInfoKey] as? BTAtModel {
            let routerCanOpen = BTRouter.canOpen(atInfo, from: docsInfo)
            if !routerCanOpen.canOpen {
                if let tips = routerCanOpen.tips {
                    UDToast.showFailure(with: tips, on: self.window ?? self)
                }
                return
            }
        }
        if fieldModel.isEditing {
            textEditAgent?.stopEditing(immediately: false, sync: true)
        }
        delegate?.didTapView(withAttributes: attributes, inFieldModel: fieldModel)
    }
    
    override func handleKeyboardShow(options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .willShow, .didShow:
            //滚动字段到可视区，避免被键盘遮挡
            setCursorBootomOffset()
            textEditAgent?.scrollTillFieldVisible()
        default: break
        }
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textEditAgent?.textView(textView, shouldChangeTextIn: range, replacementText: text) ?? false
    }

    override func textViewDidChange(_ textView: UITextView) {
        textEditAgent?.textViewDidChange(textView)
    }

    override func textViewDidChangeSelection(_ textView: UITextView) {
        textEditAgent?.textViewDidChangeSelection(textView)
    }

    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        //如果是 Email 类型，检查文字内容是否符合Email格式规范
        if fieldModel.compositeType.uiType == .email {
            textView.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !textView.text.isEmpty,
               !textView.text.isValidEmail() {
                //如果不符合 Email 格式规范，提示错误。并且清空内容
                textView.text = nil
                if let window = self.window {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_EmailField_EnterValidEmail_Desc, on: window)
                }
            } else {
                //需要指定attribute类型，之后 attchmentType 会转换成 .url
                let mutableAttributeString = NSMutableAttributedString(attributedString: textView.attributedText)
                let fullRange = textView.attributedText.fullRange
                if let URL = URL(string: textView.text),
                   textView.text.isValidEmail() {
                    mutableAttributeString.addAttribute(AtInfo.attributedStringURLKey, value: URL , range: fullRange)
                } else {
                    mutableAttributeString.removeAttribute(AtInfo.attributedStringURLKey, range: fullRange)
                }
                textView.attributedText = mutableAttributeString
            }
        }
        
        textEditAgent?.didEndEditingText()
        fieldModel.update(isEditing: false)
        setInputAccesssoryView(isSetNil: true)
    }
    
    override func stopEditing() {
        _ = textView.resignFirstResponder()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        assistBtnPressed()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        guard uiConfig.isTextViewEditable else {
            showUneditableToast()
            return
        }
        if textViewShouldBeginEditing(textView), textView.canBecomeFirstResponder {
            textView.becomeFirstResponder()
        }
    }
}

// MARK: - TextEditAgent
extension BTFieldV2Text {
    
    func updateEditAgent() {
        let newEditAgent = BTTextEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        newEditAgent.isPrimaryField = fieldModel.isPrimaryField
        self.textEditAgent = newEditAgent
        accView?.delegate = textEditAgent
    }
}


// MARK: - InputAccesssoryView
extension BTFieldV2Text {

    func setInputAccesssoryView(isSetNil: Bool) {
        if isSetNil {
            self.textView.inputAccessoryView = nil
            return
        }
        if let window = window {
            let rect = CGRect(origin: .zero, size: CGSize(width: window.bounds.width, height: 40))
            let accView = BTKeyboardInputAccessoryView(frame: rect)
            accView.delegate = textEditAgent
            self.textView.inputAccessoryView = accView
        }
    }
}
// MARK: - custom Menus
extension BTFieldV2Text {
    
    override func clearContent() {
        guard let textEditAgent = self.textEditAgent else {
            DocsLogger.btError("textEditAgent is nil when clear content")
            return
        }
        delegate?.startEditing(inField: self, newEditAgent: textEditAgent)
        textView.text = nil
        textEditAgent.didEndEditingText()
    }
}

// MARK: - Assist Btns
extension BTFieldV2Text {
    @objc
    private func assistBtnPressed() {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        guard case .inherent(let cmpType) = fieldModel.extendedType, cmpType.uiType == .barcode else {
            // 拦截一下，防止非条码字段走入扫码逻辑，正常不会再走到这里
            return
        }
        _ = textView.resignFirstResponder()
        func beginAndOpenQR() {
            guard let textEditAgent = self.textEditAgent else {
                DocsLogger.btError("textEditAgent is nil when assistBtnPressed")
                return
            }
            delegate?.startEditing(inField: self, newEditAgent: textEditAgent)
            if let hostVC = self.affiliatedViewController {
                self.qrCodeManager.showQRCodeScan(from: hostVC)
                self.trackFieldClickEvent(.scan)
                self.trackCameraEvent(.view)
            }
        }
        /// 这里做异步处理是因为当编辑时 resignFirstResponder 会导致 endEditing。如果立即调 didBeginTextInput 的话，会导致顺序错乱。
        DispatchQueue.main.async {
            beginAndOpenQR()
        }
    }
}


// MARK: - QRCodeScanManagerDelegate
extension BTFieldV2Text: QRCodeScanManagerDelegate {
    
    func qrCodeScanDidTrigerEvent(_ event: QRCodeScanEvent) {
        switch event {
        case let .scanSuccess(text, _, scene):
            if !text.isEmpty, let window = self.window {
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_Barcode_BarcodeInforReplaced_Toast, on: window)
            }
            let content: String? = text.isEmpty ? nil : text
            textEditAgent?.didEndAssistInput(content: content)
            trackCameraEvent(.operate(scene: scene, isSuccess: true))
        case .scanAlbumFail:
            if let window = self.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Barcode_NoVaildBarcode_Toast, on: window)
            }
            trackCameraEvent(.operate(scene: .album, isSuccess: false))
        case .close:
            textEditAgent?.didEndAssistInput(content: nil)
            trackCameraEvent(.click(.back))
        case .clickAlbum:
            trackCameraEvent(.click(.album))
        case .closeAlbum: break
        }
    }
}

// MARK: - Track
extension BTFieldV2Text {
    
    enum FieldClickEvent: String {
        case scan
        case textInput
    }
    
    func trackFieldClickEvent(_ event: FieldClickEvent) {
        let clickEventName: DocsTracker.EventType = fieldModel.isInForm ? .bitableFormClick : .bitableCardClick
        let cardPresentMode = self.delegate?.getCurrentCardPresentMode()
        var trackParams: [String: Any] = [:]
        if !fieldModel.isInForm {
            trackParams["version"] = "v2"
            trackParams["card_type"] = cardPresentMode == .card ? "card" : "drawer"
        }
        
        switch event {
        case .scan:
            let scan_manual = (fieldModel.allowedEditModes.manual ?? false) ? "manual_on" : "manual_off"
            trackParams["click"] = "scan"
            trackParams["target"] = "ccm_bitable_scan_camera_view"
            trackParams["scan_manual"] = scan_manual
            self.delegate?.track(event: clickEventName.rawValue,
                                 params: trackParams)
        case .textInput:
            if (fieldModel.allowedEditModes.manual ?? false), (fieldModel.allowedEditModes.scan ?? false) {
                trackParams["click"] = "input_scan"
                trackParams["target"] = "none"
                trackParams["scan_manual"] = "manual_on"
                self.delegate?.track(event: clickEventName.rawValue,
                                     params: trackParams)
            }
        }
    }
    
    enum CameraTrackEvent {
        enum ClickEvent: String {
            case back
            case album
        }
        case view
        case click(ClickEvent)
        case operate(scene: QRCodeScanScene, isSuccess: Bool)
    }
    
    func trackCameraEvent(_ event: CameraTrackEvent) {
        let entry_type = fieldModel.isInForm ? "form" : "card"
        let scan_manual = (fieldModel.allowedEditModes.manual ?? false) ? "manual_on" : "manual_off"
        
        switch event {
        case .view:
            self.delegate?.track(event: DocsTracker.EventType.bitableScanCameraView.rawValue,
                                 params: ["entry_type": entry_type,
                                         "scan_manual": scan_manual])
        case .click(let subEvent):
            let params = [
                "click": subEvent.rawValue,
                "target": "none",
                "entry_type": entry_type,
                "scan_manual": scan_manual
            ]
            self.delegate?.track(event: DocsTracker.EventType.bitableScanCameraClick.rawValue, params: params)
        case let .operate(scene, isSuccess):
            let params = [
                "scan_status": isSuccess ? "success" : "fail_input",
                "scan_method": scene.rawValue,
                "entry_type": entry_type,
                "scan_manual": scan_manual
            ]
            self.delegate?.track(event: DocsTracker.EventType.bitableScanCameraOperate.rawValue, params: params)
        }
    }
}
