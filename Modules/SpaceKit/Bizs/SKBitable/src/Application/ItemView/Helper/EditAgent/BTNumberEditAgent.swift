//
//  BTNumberEditAgent.swift
//  SKBrowser
//
//  Created by Webster on 2020/7/26.
//

import Foundation
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignColor

final class BTNumberEditAgent: BTBaseEditAgent {

    private var startEditingTxt: String?

    private var currentEditingTxt: String?

    private var startEditingValue: Double?

    private var clickDone = false

    private var editingNumberCell: BTFieldNumberCellProtocol?

    var syncErrorHandle: ((String) -> Void)?

    override var editType: BTFieldType { .number }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        editingNumberCell = cell as? BTFieldNumberCellProtocol
        editingNumberCell?.commonTrackParams = coordinator?.viewModel.getCommonTrackParams()
        startEditingTxt = editingNumberCell?.textView.text
        currentEditingTxt = editingNumberCell?.textView.text
        startEditingValue = Double(startEditingTxt ?? "")
        editHandler?.didUpdateNumberField(fieldID: fieldID, draft: currentEditingTxt)
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        if let editingNumberCell = editingNumberCell {
            editingNumberCell.stopEditing()
        } else {
            baseDelegate?.didStopEditing()
        }
        guard let bindField = editingNumberCell else {
            return
        }
        let result = syncInterceptor()
        if sync, coordinator?.shouldContinueEditing(fieldID: fieldID, inRecordID: recordID) == false {
            bindField.reloadData()
            editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
        } else if sync, result.pass {
            editHandler?.didModifyNumberField(fieldID: fieldID, value: result.value, didClickDone: clickDone)
        } else if sync, !result.pass {
            bindField.reloadData()
            if result.errorLog.isEmpty {
                editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
            } else {
                syncErrorHandle?(result.errorLog)
                if !UserScopeNoChangeFG.ZYS.numberFieldIllegalFixRevert {
                    editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
                }
            }
        }
        self.baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        self.coordinator?.invalidateEditAgent()
        editingNumberCell = nil
    }

    private var _editingPanelRect: CGRect = .zero
    override var editingPanelRect: CGRect {
        if UserScopeNoChangeFG.ZJ.btCardReform {
            if _editingPanelRect != .zero {
                return editingNumberCell?.window?.convert(_editingPanelRect, to: inputSuperview) ?? .zero
            } else {
                return .zero
            }
        } else {
            // 对于系统键盘，自动滚动 field 到可视区的逻辑在 BTRecord.handleKeyboard(didTrigger:options:) 中已经处理
            return .zero
        }
    }

    private func syncInterceptor() -> (pass: Bool, value: Double?, errorLog: String) {
        let result = BTNumberEditAgent.parseNumber(value: editingNumberCell?.textView.text)
        
        //相同内容不要同步
        if result.textValue == startEditingTxt {
            return (false, 0, "")
        }

        return (result.pass, result.value, result.errorLog)
    }

    func userDidModifyText() {
        if BTNumberEditAgent.trapMaxInput(text: editingNumberCell?.textView.text) {
            editingNumberCell?.textView.text = currentEditingTxt
        } else {
            currentEditingTxt = editingNumberCell?.textView.text
        }
        editHandler?.didUpdateNumberField(fieldID: fieldID, draft: currentEditingTxt)
    }

    func didEndEditingNumber() {
        stopEditing(immediately: true, sync: true)
    }
    
    func finishEdit() -> Bool {
        clickDone = true
        stopEditing(immediately: false, sync: true)
        clickDone = false
        return true
    }
    
    /// 将当前 cell 滚动到可见的地方
    /// - Parameter heightOfContentAboveKeyBoard: 键盘顶部内容的高度
    func scrollTillFieldVisible() {
        guard let field = relatedVisibleField else { return }
        guard let coordinator = coordinator else { return }
        guard let window = coordinator.inputSuperview.window else { return }
        let bottomHeight = coordinator.keyboardHeight + (editingNumberCell?.heightOfContentAboveKeyBoard ?? 0)
        let bottomY = window.frame.height - bottomHeight -
                      coordinator.inputSuperviewDistanceToWindowBottom + (editingNumberCell?.cursorBootomOffset ?? 0)
        let bottomRect = CGRect(x: 0, y: bottomY, width: window.frame.width, height: bottomHeight)
        self._editingPanelRect = bottomRect
        coordinator.currentCard?.scrollTillFieldBottomIsVisible(field)
    }
}

extension BTNumberEditAgent {
    
    /// 是否超过了最大长度
    static func trapMaxInput(text: String?) -> Bool {
        var trapMaxInput = false
        let maxNumber: Double = pow(10, 308)
        let txt = text ?? ""
        let length = txt.count
        if length > 307 {
            let value = Double(txt)
            if value == nil {
                trapMaxInput = true
            } else {
                trapMaxInput = (value ?? 0) > maxNumber
            }
        }
        return trapMaxInput
    }
    
    static func parseNumber(value: String?) -> (pass: Bool, value: Double?, textValue: String?, errorLog: String) {
        var txtValue = value?.trim() ?? ""
        if let value = value, !value.isEmpty, txtValue.isEmpty {
            // 不允许粘贴纯空格，保持与其他端一致 https://meego.feishu.cn/larksuite/issue/detail/8314367
            return (false, nil, value, BundleI18n.SKResource.Doc_Block_OnlySupportNumber)
        }
        if txtValue.hasPrefix(".") {
            txtValue = "0" + txtValue
        } else if txtValue.hasPrefix("-.") {
            txtValue.insert("0", at: txtValue.index(txtValue.startIndex, offsetBy: 1))
        }
        
        let value = Double(txtValue)
        let dotCount = txtValue.map { return String($0) }.filter { $0 == "." }.count
        if dotCount > 1 {
            return (false, nil, txtValue, BundleI18n.SKResource.Doc_Block_NotSupportMultiplePoints)
        }
        if (!txtValue.isDoubleFormat && !txtValue.isEmpty) || (value == nil  && !txtValue.isEmpty) {
            return (false, nil, txtValue, BundleI18n.SKResource.Doc_Block_OnlySupportNumber)
        }

        if txtValue.isEmpty {
            return (true, nil, txtValue, "")
        }

        return (true, value, txtValue, "")
    }
    
}
