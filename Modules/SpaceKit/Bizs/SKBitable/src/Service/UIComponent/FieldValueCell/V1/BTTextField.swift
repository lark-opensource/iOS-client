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

struct BTTextFieldUIConfig {
    var isShowRightAssistBtn: Bool = false
    var isShowFullAssistBtn: Bool = false
    var assistIcon: UIImage?
    var assistTitle: String?
    var isTextViewEditable: Bool = false
    var isTextSelectable: Bool = true

    init() {}
    
    init(fieldModel: BTFieldModel) {
        let isManualEdit = fieldModel.allowedEditModes.manual ?? false
        isTextViewEditable = fieldModel.editable && isManualEdit
        isTextSelectable = isManualEdit
        if fieldModel.editable, (fieldModel.allowedEditModes.scan ?? false) {
            self.assistIcon = UDIcon.scanOutlined
            self.assistTitle = BundleI18n.SKResource.Bitable_Barcode_ScanBarcode_Button
            if !isManualEdit, fieldModel.textValue.isEmpty {
                self.isShowRightAssistBtn = false
                self.isShowFullAssistBtn = true
            } else {
                self.isShowRightAssistBtn = true
                self.isShowFullAssistBtn = false
            }
        } else {
            self.isShowRightAssistBtn = false
            self.isShowFullAssistBtn = false
            self.assistIcon = nil
            self.assistTitle = nil
        }
    }
}

final class BTTextField: BTBaseTextField {

    private var textEditAgent: BTTextEditAgent?
    /// ui 配置
    private var uiConfig = BTTextFieldUIConfig()
    
    private var qrCodeManager = QRCodeScanManager()
    /// 右边辅助按钮
    private lazy var rightAssistBtn: BTFieldAssistButton = {
        let btn = BTFieldAssistButton()
        btn.addTarget(self, action: #selector(assistBtnPressed), for: .touchUpInside)
        return btn
    }()
    /// 全屏辅助按钮
    private lazy var fullAssistBtn: BTFieldAssistButton = {
        let btn = BTFieldAssistButton()
        btn.isHidden = true
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 2)
        btn.addTarget(self, action: #selector(assistBtnPressed), for: .touchUpInside)
        return btn
    }()
    /// 键盘辅助工具栏
    private var accView: BTKeyboardInputAccessoryView?
    
    private var keyboard = Keyboard()

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        uiConfig = BTTextFieldUIConfig(fieldModel: model)
        self.isShowCustomMenuViewWhenLongPress = !uiConfig.isTextSelectable
        textView.isSelectable = uiConfig.isTextSelectable
        textView.editPermission = uiConfig.isTextViewEditable
        setupStyleInStage()
        if model.isPrimaryField {
            let font = BTFieldLayout.Const.primaryTextFieldFontInStage
            let textColor = UDColor.primaryPri900
            textView.placeholderLabel.text = BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_EnterHere_Placeholder
            textView.showsVerticalScrollIndicator = true
            textView.enablePlaceHolder(enable: true)
            textView.attributedText = BTUtil.convert(model.textValue, font: font, plainTextColor: textColor, forTextView: textView)
        } else {
            textView.attributedText = BTUtil.convert(model.textValue, forTextView: textView)
        }
        
        textView.pasteOperation = { [weak self] in
            self?.textEditAgent?.doPaste()
        }
        updateEditAgent()
        updateAssistBtns(with: uiConfig)
        qrCodeManager.delegate = self
    }
    
    override func setupLayout() {
        super.setupLayout()
        startKeyboardObserver()
        setupAssistBtns()
    }

    // MARK: - TextView About
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        setupCustomTypingAttributtes()
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
        
        textEditAgent?.scrollTillFieldVisible()
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
        
        //如果是 email 类型，去掉收尾的空格和回车。
        if fieldModel.compositeType.uiType == .email {
            textView.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            //需要指定attribute类型，之后 attchmentType 会转换成 .url。否则form格式下email检查会出错
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
        
        textEditAgent?.didEndEditingText()
        fieldModel.update(isEditing: false)
        setInputAccesssoryView(isSetNil: true)
    }
    
    override func stopEditing() {
        _ = textView.resignFirstResponder()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    private func startKeyboardObserver() {
        keyboard = Keyboard(listenTo: [textView])
        keyboard.on(events: [.didShow]) { [weak self] options in
            guard let self = self else { return }
            self.handleKeyboardShow(options: options)
        }
        keyboard.start()
    }
    
    private func handleKeyboardShow(options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .didShow:
            //长按进入编辑态时，光标被键盘遮挡
            setCursorBootomOffset()
            textEditAgent?.scrollTillFieldVisible()
        default: break
        }
    }
}

// MARK: - TextEditAgent
extension BTTextField {
    
    func updateEditAgent() {
        let newEditAgent = BTTextEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        newEditAgent.isPrimaryField = fieldModel.isPrimaryField
        self.textEditAgent = newEditAgent
        accView?.delegate = textEditAgent
    }
}


// MARK: - InputAccesssoryView
extension BTTextField {

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
extension BTTextField {
    
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
extension BTTextField {
    
    private func setupAssistBtns() {
        containerView.addSubview(rightAssistBtn)
        containerView.addSubview(fullAssistBtn)
        textView.snp.remakeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.right.equalTo(rightAssistBtn.snp.left)
        }
        rightAssistBtn.snp.makeConstraints {
            $0.right.top.equalToSuperview()
            $0.width.height.equalTo(0)
        }
        fullAssistBtn.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func updateAssistBtns(with uiConfig: BTTextFieldUIConfig) {
        let size = uiConfig.isShowRightAssistBtn ? BTFieldLayout.Const.rightAssistIconWidth : 0
        let inset = uiConfig.isShowRightAssistBtn ? BTFieldLayout.Const.containerPadding : 0
        rightAssistBtn.config(image: uiConfig.assistIcon)
        rightAssistBtn.isHidden = !uiConfig.isShowRightAssistBtn
        rightAssistBtn.snp.remakeConstraints {
            $0.top.right.equalToSuperview().inset(inset)
            $0.width.height.equalTo(size)
        }
        
        if uiConfig.isShowFullAssistBtn {
            fullAssistBtn.config(image: uiConfig.assistIcon, color: UDColor.iconN1)
            fullAssistBtn.setTitle(uiConfig.assistTitle, for: .normal)
            fullAssistBtn.isHidden = false
        } else {
            fullAssistBtn.isHidden = true
        }
    }
    
    @objc
    private func assistBtnPressed() {
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
extension BTTextField: QRCodeScanManagerDelegate {
    
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
extension BTTextField {
    
    enum FieldClickEvent: String {
        case scan
        case textInput
    }
    
    func trackFieldClickEvent(_ event: FieldClickEvent) {
        let clickEventName: DocsTracker.EventType = fieldModel.isInForm ? .bitableFormClick : .bitableCardClick
        switch event {
        case .scan:
            let scan_manual = (fieldModel.allowedEditModes.manual ?? false) ? "manual_on" : "manual_off"
            self.delegate?.track(event: clickEventName.rawValue,
                                 params: ["click": "scan",
                                          "target": "ccm_bitable_scan_camera_view",
                                          "scan_manual": scan_manual])
        case .textInput:
            if (fieldModel.allowedEditModes.manual ?? false), (fieldModel.allowedEditModes.scan ?? false) {
                self.delegate?.track(event: clickEventName.rawValue,
                                     params: ["click": "input_scan",
                                              "target": "none",
                                              "scan_manual": "manual_on"])
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
