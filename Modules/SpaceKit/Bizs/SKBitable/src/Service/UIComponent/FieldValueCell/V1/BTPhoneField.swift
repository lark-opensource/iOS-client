//
//  BTPhoneField.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/5/22.
//  

import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignDialog
import Foundation
import SKUIKit
import SKResource
import SKCommon
import ContactsUI
import SKInfra

final class BTPhoneField: BTBaseTextField, CNContactPickerDelegate, BTFieldPhoneCellProtocol {
    
    var editAgent: BTPhoneEditAgent?
    
    // 为了埋点而配置的状态
    private var isFirstSetup = true
    private var isFirstShowTelBtn = true
    private var isFirstShowContactBtn = true
    
    private var isPasteOperation = false
    
    private lazy var contactButton: BTHighlightableButton = {
        let btn = createButton(icon: UDIcon.organizationBookOutlined)
        btn.addTarget(self, action: #selector(showContactBtnPressed), for: .touchUpInside)
        return btn
    }()
    
    private lazy var callChatButton: BTHighlightableButton = {
        let btn = createButton(icon: UDIcon.callMessageOutlined)
        btn.addTarget(self, action: #selector(showPhoneActionSheet), for: .touchUpInside)
        return btn
    }()
    
    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(contactButton)
        containerView.addSubview(callChatButton)
        textView.textContainerInset.right = 0
        textView.isScrollEnabled = false
        textView.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(callChatButton.snp.left)
        }
        contactButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            make.centerY.equalTo(textView)
            make.width.height.equalTo(BTFieldLayout.Const.rightAssistIconWidth)
        }
        callChatButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
            make.centerY.equalTo(textView)
            make.width.height.equalTo(BTFieldLayout.Const.rightAssistIconWidth)
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        DocsLogger.debug("==phone== loadModel")
        super.loadModel(model, layout: layout)
        let phoneValues = model.phoneValue.map(\.fullPhoneNum)
        let currentValue = phoneValues.reduce("", { (partialResult, newStr) -> String in
            if partialResult.isEmpty {
                return "\(newStr)"
            } else {
                return "\(partialResult),\(newStr)"
            }
        })
        textView.text = currentValue
        textView.editPermission = model.editable
        textView.keyboardType = .phonePad
        textView.pasteOperation = { [weak self] in
            // 标记输入为粘贴的操作
            self?.isPasteOperation = true
        }
        setupButton(editing: currentValue.isEmpty)
        setupButton(editable: model.editable, phoneCount: phoneValues.count)
        let newEditAgent = BTPhoneEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        editAgent = newEditAgent
    }
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        DocsLogger.btInfo("==phone== textViewShouldBeginEditing")
        return fieldModel.editable
    }
    
    override func textViewDidBeginEditing(_ textView: UITextView) {
        fieldModel.update(isEditing: true)
        super.textViewDidBeginEditing(textView)
        DocsLogger.btInfo("==phone== textViewDidBeginEditing")
        if let editAgent = editAgent {
            delegate?.startEditing(inField: self, newEditAgent: editAgent)
        }
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let shouldChange = editAgent?.textView(textView, shouldChangeTextIn: range, replacementText: text,
                                               isPasteOperation: isPasteOperation) ?? false
        isPasteOperation = false
        return shouldChange
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        editAgent?.textViewDidChange()
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        DocsLogger.btInfo("==phone== textViewDidEndEditing")
        super.textViewDidEndEditing(textView)
        editAgent?.textViewDidEndEditing()
        fieldModel.update(isEditing: false)
    }
    
    func startEditing() {
        DocsLogger.btInfo("==phone== startEditing")
        fieldModel.update(isEditing: true)
        setupButton(editing: true)
    }
    
    override func stopEditing() {
        DocsLogger.btInfo("==phone== stopEditing")
        fieldModel.update(isEditing: false)
        setupButton(editing: false)
        textView.resignFirstResponder()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    private func setupButton(editing: Bool) {
        contactButton.isHidden = !editing
        callChatButton.isHidden = editing
        trackFirstShowButton(showTelBtn: !editing)
    }
    
    private func setupButton(editable: Bool, phoneCount: Int) {
        if phoneCount > 1 {
            // 存在多个电话号码时(引用字段情况下)，隐藏所有操作按钮
            callChatButton.isHidden = true
            contactButton.isHidden = true
            return
        }
        callChatButton.normalBackgroundColor = fieldModel.editable ? UDColor.bgBody : .clear
        if editable == false {
            // 无编辑权限下，拨打电话按钮仍需可用
            callChatButton.isHidden = textView.text.isEmpty ? true : false
            contactButton.isHidden = true
        }
    }

    @objc
    private func showContactBtnPressed() {
        textView.resignFirstResponder()
        let params: [String: Any] = [
            "click": "contact",
            "target": "none",
            "tel_permission": "true"
        ]
        delegate?.track(event: DocsTracker.EventType.bitaleTelContactClick.rawValue, params: params)
        
        guard shouldShowReadContactDisclaimer() else {
            showContactPicker()
            return
        }
        showReadContactDisclaimer { [weak self] in
            self?.showContactPicker()
        }
    }

    @objc
    private func showPhoneActionSheet(_ sender: UIButton) {
        let needPopover = SKDisplay.pad && (self.isMyWindowRegularSize())
        var popSource: UDActionSheetSource?
        if needPopover {
            popSource = UDActionSheetSource(sourceView: sender,
                                            sourceRect: sender.bounds,
                                            arrowDirection: .right)
        }
        let currentValue = textView.text ?? ""
        let actionSheet = UDActionSheet.actionSheet(title: currentValue, popSource: popSource,
                                                    dismissedByTapOutside: { [weak self] in
            self?.trackTelIconClick("cancel")
        })
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_PhoneNumber_Call_Mobile,
                            textColor: UDColor.textTitle) { [weak self] in
            self?.phoneCall()
            self?.trackTelIconClick("call")
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_PhoneNumber_Message_Mobile,
                            textColor: UDColor.textTitle) { [weak self] in
            self?.sendMSM()
            self?.trackTelIconClick("msg")
        }
        if !needPopover {
            actionSheet.addItem(text: BundleI18n.SKResource.Doc_Facade_Cancel, style: .cancel) { [weak self] in
                self?.trackTelIconClick("cancel")
            }
        }
        delegate?.presentViewController(actionSheet)
    }
    
    private func sendMSM() {
        let phone = textView.text ?? ""
        guard let url = URL(string: "sms://\(phone)"), UIApplication.shared.canOpenURL(url) else {
            DocsLogger.btError("==phone== sms url is not available")
            return
        }
        UIApplication.shared.open(url)
        /*
        // 引入 MessageUI 会导致 Lark 在 iOS 11.4 启动崩溃
        if !MFMessageComposeViewController.canSendText() {
            DocsLogger.btError("==phone== SMS services are not available")
            return
        }
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        composeVC.recipients = [textView.text ?? ""]
        delegate?.presentViewController(composeVC)
         */
    }
    
    private func phoneCall() {
        let phone = textView.text ?? ""
        guard let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) else {
            DocsLogger.btError("==phone== call url is not available")
            return
        }
        UIApplication.shared.open(url)
    }
    
    private func createButton(icon: UIImage) -> BTHighlightableButton {
        let btn = BTHighlightableButton()
        btn.normalBackgroundColor = UDColor.bgBody
        btn.highlightBackgroundColor = UDColor.fillHover
        btn.layer.cornerRadius = 4
        btn.clipsToBounds = true
        btn.isHidden = true
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        btn.setImage(icon.ud.withTintColor(UDColor.iconN2).ud.resized(to: CGSize(width: 18, height: 18)), for: .normal)
        return btn
    }
    
    /// 判断是否需要展示通讯录免责声明
    private func shouldShowReadContactDisclaimer() -> Bool {
        let result = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.bitableReadContactNotice)
        if result == false {
            CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.bitableReadContactNotice)
        }
        return !result
    }
    
    /// 展示Bitable读取通讯录免责声明
    private func showReadContactDisclaimer(completeBlock: @escaping () -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_PhoneNumber_ImportContactPopupTitle_Mobile)
        dialog.setContent(text: BundleI18n.SKResource.Bitable_PhoneNumber_ImportContactPopupContent_Mobile, alignment: .center)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonGotIt, dismissCompletion: { [weak self] in
            completeBlock()
            let params: [String: Any] = [
                "click": "know",
                "target": "none"
            ]
            self?.delegate?.track(event: DocsTracker.EventType.bitableTelContactGuideClick.rawValue, params: params)
        })
        delegate?.presentViewController(dialog)
        delegate?.track(event: DocsTracker.EventType.bitableTelContactGuideView.rawValue, params: [:])
    }
    
    private func showContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        // 设置为 false，可以触发默认操作，即能进入选择的联系人的二级详情页面
        contactPicker.predicateForSelectionOfContact = NSPredicate(value: false)
        delegate?.presentViewController(contactPicker)
    }
    
    private func trackTelIconClick(_ click: String) {
        let params: [String: Any] = [
            "click": click,
            "target": "none"
        ]
        delegate?.track(event: DocsTracker.EventType.bitableTelIconClick.rawValue, params: params)
    }
    
    private func trackFirstShowButton(showTelBtn: Bool) {
        if isFirstShowTelBtn && showTelBtn {
            isFirstShowTelBtn = false
            DocsLogger.btInfo("==phone== ccm_bitable_tel_card_icon_view")
            delegate?.track(event: DocsTracker.EventType.bitableTelIconView.rawValue, params: [:])
        }
        if isFirstShowContactBtn && !showTelBtn {
            isFirstShowContactBtn = false
            DocsLogger.btInfo("==phone== ccm_bitable_tel_contact_icon_view")
            delegate?.track(event: DocsTracker.EventType.bitaleTelContactView.rawValue, params: [:])
        }
    }
    
    // MARK: - 通讯录 CNContactPickerDelegate
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        guard let phoneNumber = contactProperty.value as? CNPhoneNumber else { return }
        let phoneText = editAgent?.trimPhone(input: phoneNumber.stringValue) ?? ""
        let newEditAgent = BTPhoneEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        editAgent = newEditAgent
        self.textView.becomeFirstResponder()
        self.textView.text = phoneText
        self.editAgent?.textViewDidChange()
    }
}
