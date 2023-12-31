//
//  BTPhoneEditAgent.swift
//  SKBitable
//
//  Created by ZhangYuanping on 2022/5/27.
//  


import Foundation
import SKFoundation
import UniverseDesignToast
import SKResource

final class BTPhoneEditAgent: BTBaseEditAgent {
    
    private var editingPhoneCell: BTFieldPhoneCellProtocol?
    private var startEdingText: String?
    private let phoneRegex = "^\\+?\\d*$"
    
    override func startEditing(_ cell: BTFieldCellProtocol) {
        editingPhoneCell = cell as? BTFieldPhoneCellProtocol
        startEdingText = editingPhoneCell?.textView.text.trim()
        editingPhoneCell?.startEditing()
        DocsLogger.btInfo("==phone== PhoneEditAgent - startEditing")
    }
    
    override func stopEditing(immediately: Bool, sync: Bool = false) {
        DocsLogger.btInfo("==phone== PhoneEditAgent - stopEditing: \(immediately), sync: \(sync)")
        guard let phoneCell = editingPhoneCell else {
            DocsLogger.btInfo("==phone== no editingPhoneCell")
            baseDelegate?.didStopEditing()
            return
        }
        phoneCell.stopEditing()
        guard sync == true else {
            setupForEndEditing()
            return
        }
        if coordinator?.shouldContinueEditing(fieldID: fieldID, inRecordID: recordID) == false {
            editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
        } else {
            tellViewModelFinishFieldEdit()
        }
        setupForEndEditing()
    }
    
    private var _editingPanelRect: CGRect = .zero
    override var editingPanelRect: CGRect {
        if UserScopeNoChangeFG.ZJ.btCardReform {
            if _editingPanelRect != .zero {
                return editingPhoneCell?.window?.convert(_editingPanelRect, to: inputSuperview) ?? .zero
            } else {
                return .zero
            }
        } else {
            // 对于系统键盘，自动滚动 field 到可视区的逻辑在 BTRecord.handleKeyboard(didTrigger:options:) 中已经处理
            return .zero
        }
    }
}

extension BTPhoneEditAgent {
    enum VerifyResult {
        case valid
        case invalid(reason: String)
        case same
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String, isPasteOperation: Bool) -> Bool {
        var newText = textView.text ?? ""
        newText.insert(contentsOf: text, at: String.Index(utf16Offset: range.location, in: newText))
        if isPasteOperation {
            // 粘贴的输入，过滤掉非法字符
            let result = trimPhone(input: newText)
            textView.text = result
            textViewDidChange()
            return false
        } else {
            let result = verifyPhoneValue(newText)
            if case .invalid = result {
                let host = coordinator?.attachedController.view ?? textView
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_PhoneNumber_CanOnlyEnterPhoneNumber_Mobile, on: host)
                return false
            }
        }
        return true
    }
    
    func textViewDidChange() {
        guard let editingCell = editingPhoneCell else { return }
        let phoneStr = editingCell.textView.text.trim()
        let value = BTPhoneModel(fullPhoneNum: phoneStr)
        editHandler?.didModifyPhoneField(fieldID: fieldID, value: value, isFinish: false)
    }
    
    func textViewDidEndEditing() {
        tellViewModelFinishFieldEdit()
        stopEditing(immediately: true)
    }
    
    func tellViewModelFinishFieldEdit() {
        guard let editingCell = editingPhoneCell else { return }
        let verifyResult = verifyPhoneValue(editingCell.textView.text ?? "")
        switch verifyResult {
        case .valid:
            let phoneStr = editingCell.textView.text.trim()
            let value = BTPhoneModel(fullPhoneNum: phoneStr)
            editHandler?.didModifyPhoneField(fieldID: fieldID, value: value, isFinish: true)
        case .invalid(let reason):
            let host = coordinator?.attachedController.view ?? editingCell
            UDToast.showFailure(with: reason, on: host)
        case .same:
            editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
        }
    }
    
    // 过滤非法字符，得出最长 20 位的电话号码字符串
    func trimPhone(input: String) -> String {
        var result = input.replace(with: "", for: "[^/+0-9]")
        let hasPlus = result.first == "+"
        result = result.filter { !"+".contains($0) }
        result = hasPlus ? "+" + result : result
        if result.count <= 20 {
            return result
        }
        let endIndex = result.index(result.startIndex, offsetBy: 20)
        return String(result[result.startIndex..<endIndex])
    }
    
    private func verifyPhoneValue(_ textValue: String) -> VerifyResult {
        if textValue == startEdingText {
            return .same
        }
        if textValue.isEmpty {
            return .valid
        }
        if textValue.count > 20 {
            return .invalid(reason: BundleI18n.SKResource.Bitable_PhoneNumber_CanOnlyEnterPhoneNumber_Mobile)
        }
        if textValue.isMatch(for: phoneRegex) {
            return .valid
        } else {
            return .invalid(reason: BundleI18n.SKResource.Bitable_PhoneNumber_CanOnlyEnterPhoneNumber_Mobile)
        }
    }
    
    private func setupForEndEditing() {
        DocsLogger.btInfo("==phone== PhoneEditAgent - setupForEndEditing, cell=nil,invalidateEditAgent")
        baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        coordinator?.invalidateEditAgent()
        editingPhoneCell = nil
    }
    
    /// 将当前 cell 滚动到可见的地方
    /// - Parameter heightOfContentAboveKeyBoard: 键盘顶部内容的高度
    func scrollTillFieldVisible() {
        guard let field = relatedVisibleField else { return }
        guard let coordinator = coordinator else { return }
        guard let window = coordinator.inputSuperview.window else { return }
        let bottomHeight = coordinator.keyboardHeight + (editingPhoneCell?.heightOfContentAboveKeyBoard ?? 0)
        let bottomY = window.frame.height - bottomHeight -
                      coordinator.inputSuperviewDistanceToWindowBottom + (editingPhoneCell?.cursorBootomOffset ?? 0)
        let bottomRect = CGRect(x: 0, y: bottomY, width: window.frame.width, height: bottomHeight)
        self._editingPanelRect = bottomRect
        coordinator.currentCard?.scrollTillFieldBottomIsVisible(field)
    }
}
