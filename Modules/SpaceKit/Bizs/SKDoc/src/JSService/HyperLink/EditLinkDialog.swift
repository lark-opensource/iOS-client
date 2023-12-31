//
//  EditLinkDialog.swift
//  SKBrowser
//
//  Created by xiongmin on 2022/8/19.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UIKit
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignFont
import UniverseDesignInput
import UniverseDesignStyle
import UniverseDesignToast

private var copyPermissionKey = "kCopyPermissionKey"
// (是否可复制，是否允许单文档复制)
// 改造为直接传一个 PermissionResponse
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
typealias CopyPermission = () -> (Bool, Bool?)


public final class EditLinkDialog: NSObject {
    /// DialogType 用来区分是添加还是编辑
    /// 添加分两种Case 1. text 不为空，文本框disable，text为空，相当于插入
    /// edit 从气泡工具栏"编辑链接" -> 光标落到链接框末尾，如果不包含text，text框默认填入url，并且全选
    ///
    enum DialogType: Equatable {
        case add(text: String? = nil, url: String? = nil)
        case edit(text: String? = nil, url: String? = nil)

        static func from(type: String, text: String? = nil, url: String? = nil) -> DialogType {
            if type == "add" {
                return .add(text: text, url: url)
            } else {
                return .edit(text: text, url: url)
            }
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.add, .add):
                return true
            case (.edit, .edit):
                return true
            default:
                return false
            }
        }
    }

    // ["text": "文本内容", "url": "http://www.baidu.com", "success": true, "errorMsg": "错误原因"]
    typealias CallbackParmas = ([String: AnyHashable]) -> Void

    private(set) var realDialog: UDDialog

    private var textField: UDTextField?
    private var urlField: UDTextField?
    private var confirmButton: UIButton?
    private var callback: CallbackParmas?
    private var type: DialogType?
    private let urlFieldTag = 9999 // url输入框tag
    private var docsInfo: DocsInfo?

    init(docsInfo: DocsInfo?) {
        let config = UDDialogUIConfig(cornerRadius: UDStyle.largeRadius,
                                      titleFont: UDFont.title3(.fixed),
                                      titleColor: UDDialogColorTheme.dialogTextColor,
                                      titleAlignment: .center,
                                      style: .horizontal,
                                      contentMargin: .zero,
                                      splitLineColor: UDDialogColorTheme.dialogBorderColor,
                                      backgroundColor: UDDialogColorTheme.dialogBgColor)
        realDialog = UDDialog(config: config)
        super.init()
        self.docsInfo = docsInfo
        // 单一文档保护加密id
        let encryptId = ClipboardManager.shared.getEncryptId(token: docsInfo?.token)
        var textConfig = UDTextFieldUIConfig()
        textConfig.isShowBorder = true
        textConfig.borderColor = UDColor.lineBorderComponent
        textConfig.clearButtonMode = .whileEditing
        textConfig.font = UDFont.body0
        textField = UDTextField(config: textConfig, textFieldType: HyperLinkTextField.self)
        textField?.delegate = self
        textField?.placeholder = BundleI18n.SKResource.LarkCCM_Docx_EnterText4Link_Placeholder_Mob
        textField?.input.pointId = encryptId
        urlField = UDTextField(config: textConfig, textFieldType: HyperLinkTextField.self)
        urlField?.placeholder = BundleI18n.SKResource.LarkCCM_Docx_PasteLink_Placeholder_Mob
        urlField?.input.keyboardType = .URL
        urlField?.delegate = self
//        urlField?.input.inputDelegate = self
        urlField?.input.tag = urlFieldTag
        urlField?.input.pointId = encryptId
        guard textField != nil,
              urlField != nil
        else { return }
        realDialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docx_AddLink_Title_Mob)
        realDialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Docx_AddLink_Cancel_Button_Mob) {
            [weak self] in
            self?.textField?.resignFirstResponder()
            self?.urlField?.resignFirstResponder()
            let viewType = (self?.type == DialogType.add()) ? "add_link" : "edit_link"
            DocsTracker.newLog(enumEvent: .docsLinkEditDialogClick, parameters: ["click": "cancel", "view_type": viewType])
            return true
        } dismissCompletion: {
            self.callback?(["success": true])
        }

        confirmButton = realDialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Docx_AddLink_Confirm_Button_Mob) {
            [weak self] in
            self?.textField?.resignFirstResponder()
            self?.urlField?.resignFirstResponder()
            let viewType = (self?.type == DialogType.add()) ? "add_link" : "edit_link"
            DocsTracker.newLog(enumEvent: .docsLinkEditDialogClick, parameters: ["click": "confirm", "view_type": viewType])
            return true
        } dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let text = self.textField?.text ?? ""
            let url = self.urlField?.text ?? ""
            self.callback?([
                "url": url,
                "text": text,
                "success": true
            ])
        }
        confirmButton?.isEnabled = false
        confirmButton?.setTitleColor(UDColor.textDisabled, for: .disabled)
        // 外接键盘和第三方输入方不会响应UITextInputDelegate的方法，所以这地方用通知
        NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange(_:)), name: UITextField.textDidChangeNotification, object: nil)
    }

    func show(with type: DialogType, from: BrowserNavigator, callback: @escaping CallbackParmas) {
        self.callback = callback
        self.type = type
        guard let urlField = urlField,
              let textField = textField
        else { return }
        let singleInputClosure = {
            let contentView = UIView()
            contentView.addSubview(urlField)
            urlField.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(48)
            }
            self.realDialog.setContent(view: contentView)
            contentView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(84)
                make.width.equalTo(303)
            }
        }
        
        let doubleInputClosure = {
            let contentView = UIView()
            contentView.addSubview(textField)
            contentView.addSubview(urlField)
            textField.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(48)
            }
            urlField.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20)
                make.height.equalTo(48)
                make.bottom.equalToSuperview().offset(-24)
            }
            self.realDialog.setContent(view: contentView)
            contentView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(144)
                make.width.equalTo(303)
            }
        }
        switch type {
        case let .add(text, url):
            realDialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docx_AddLink_Title_Mob, inputView: false)
            if let text = text, text.count > 0 {
                textField.text = text
                urlField.text = url
                textField.isEnable = false
                textField.input.textColor = UDColor.textPlaceholder
                singleInputClosure()
            } else {
                textField.text = text
                urlField.text = url
                doubleInputClosure()
            }

        case let .edit(text, url):
            // 编辑链接，url和text都会有
            realDialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docx_EditLink_Button_Mob, inputView: false)
            guard let url = url, url.count > 0,
                  let text = text, text.count > 0
            else {
                callback(["success": false, "errorMsg": "url or text should not be empty!"])
                DocsLogger.error("HyperLinkService: params error, url or text should not be empty!")
                return
            }
            textField.text = text
            urlField.text = url
            confirmButton?.isEnabled = true
            doubleInputClosure()
        }
        switch type {
        case .add:
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                // 点击图标后键盘会有0.25s动画，导致工具栏还显示，这里做延时，让工具栏有时间消失
                from.presentViewController(self.realDialog, animated: true) { [weak self] in
                    self?.urlField?.becomeFirstResponder()
                }
            }
        case let .edit(text, url):
            from.presentViewController(realDialog, animated: true) {
                if let text = text, text == url {
                    textField.becomeFirstResponder()
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                        let input = textField.input
                        let end = input.endOfDocument
                        let start = input.position(from: end, offset: -text.count) ?? input.beginningOfDocument
                        input.selectedTextRange = input.textRange(from: start, to: end)
                    }
                } else {
                    urlField.becomeFirstResponder()
                }
            }
        }
        
    }

    // 其他特殊原因取消,
    func dismiss(_ completion: (() -> Void)? = nil) {
        realDialog.dismiss(animated: true) {
            self.reset()
            self.callback?(["success": false, "errorMsg": "unexpected canceled"])
        }
    }

    func reset() {
        textField?.text = ""
        urlField?.text = ""
        textField?.resignFirstResponder()
        urlField?.resignFirstResponder()
        textField?.isEnable = true
        confirmButton?.isEnabled = false
        textField?.input.textColor = UDInputColorTheme.inputInputtingTextColor
    }

    func setCopyPermission(with permission: @escaping CopyPermission) {
        let copyPermission = self.getCopyPermission(with: permission)
        (textField?.input as? HyperLinkTextField)?.copyPermission = copyPermission
    }
    
    // MARK: - Private func
    //输入框复制权限获取判断
    private func getCopyPermission(with permission: @escaping CopyPermission) -> CopyPermission {
        let copyPermission = { [weak self] in
            guard let self = self else { return (true, true) }
            let (hasCopyPermission, allowSingleDocumentCopy) = permission()
            if hasCopyPermission {
                return (true, true)
            }
            if let allowSingleDocumentCopy {
                guard allowSingleDocumentCopy else {
                    return (false, false)
                }
                if let encryptId = ClipboardManager.shared.getEncryptId(token: self.docsInfo?.token), !encryptId.isEmpty {
                    return (true, true)
                } else {
                    return (false, false)
                }
            } else {
                if !AdminPermissionManager.adminCanCopy() {
                    return (false, false)
                } else if let docsInfo = self.docsInfo, DlpManager.status(with: docsInfo.token, type: docsInfo.inherentType, action: .COPY) != .Safe {
                    return (false, false)
                } else if let encryptId = ClipboardManager.shared.getEncryptId(token: self.docsInfo?.token), !encryptId.isEmpty {
                    return (true, true)
                } else {
                    return (false, false)
                }
            }
        }
        return copyPermission
    }
    
    private func enterConfirm() {
        if confirmButton?.isEnabled ?? false {
            realDialog.dismiss(animated: true) { [weak self] in
                let text = self?.textField?.text ?? ""
                let url = self?.urlField?.text ?? ""
                self?.callback?([
                    "url": url,
                    "text": text,
                    "success": true
                ])
            }
        }
    }
    
    @objc
    private func textDidChange(_ notification: Notification) {
        if let input = notification.object as? HyperLinkTextField, input.tag == urlFieldTag {
            let text = urlField?.text ?? ""
            confirmButton?.isEnabled = LinkRegex.looseLinkValid(text)
        }
    }
}

extension EditLinkDialog: UniverseDesignInput.UDTextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == urlFieldTag {
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            confirmButton?.isEnabled = LinkRegex.looseLinkValid(updatedText)
        }
        return true
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.enterConfirm()
        return true
    }
}

class HyperLinkTextField: SKBaseTextField {
    
    var copyPermission: CopyPermission?
    
    override func copy(_ sender: Any?) {
        if let copyPermission = copyPermission, !copyPermission().0 {
            let config = UDToastConfig(toastType: .error, text: BundleI18n.SKResource.Doc_Doc_CopyFailed, operation: nil)
            if let window = self.window {
                UDToast.showToast(with: config, on: window)
            }
            return
        }
        // 上报埋点
        let parameters: [AnyHashable: Any] = ["action_type": "copy"]
        DocsTracker.newLog(enumEvent: .docsBubbleToolBarClick, parameters: parameters)
        super.copy(sender)
    }
    
    override func cut(_ sender: Any?) {
        if let copyPermission = copyPermission, !copyPermission().0 {
            let config = UDToastConfig(toastType: .error, text: BundleI18n.SKResource.Doc_Doc_CopyFailed, operation: nil)
            if let window = self.window {
                UDToast.showToast(with: config, on: window)
            }
            return
        }
        // 上报埋点
        let parameters: [AnyHashable: Any] = ["action_type": "cut"]
        DocsTracker.newLog(enumEvent: .docsBubbleToolBarClick, parameters: parameters)
        super.cut(sender)
    }
    
    override func paste(_ sender: Any?) {
        let parameters: [AnyHashable: Any] = ["action_type": "paste"]
        DocsTracker.newLog(enumEvent: .docsBubbleToolBarClick, parameters: parameters)
        super.paste(sender)
    }
    
    override func select(_ sender: Any?) {
        let parameters: [AnyHashable: Any] = ["action_type": "select"]
        DocsTracker.newLog(enumEvent: .docsBubbleToolBarClick, parameters: parameters)
        super.select(sender)
    }
    
    override func selectAll(_ sender: Any?) {
        let parameters: [AnyHashable: Any] = ["action_type": "selectAll"]
        DocsTracker.newLog(enumEvent: .docsBubbleToolBarClick, parameters: parameters)
        super.selectAll(sender)
    }
    
}
