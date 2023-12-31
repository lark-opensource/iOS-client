//
//  BTTextEditAgent.swift
//  DocsSDK
//
//  Created by Webster on 2020/3/17.
//

import Foundation
import UIKit
import RxSwift
import SKCommon
import SKBrowser
import SKFoundation
import UniverseDesignColor
import SpaceInterface
import SKInfra
/// 文本能力
struct BTTextCapabilityOptions: OptionSet {
    let rawValue: UInt

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    static let activeAtInfoWhenInput = BTTextCapabilityOptions(rawValue: 1 << 0)
    static let parseAtInfoWhenPaste = BTTextCapabilityOptions(rawValue: 1 << 1)
}

final class BTTextEditAgent: BTBaseEditAgent {
    /// 富文本如何更新链接属性
    enum FormateUrlType {
        case full
        case diff(NSRange)
    }
    /// 富文本如何更新链接属性当文本变化的时候
    private var formateUrlTypeWhenTextDidChange: FormateUrlType = .full
    
    private let urlParser = BTURLParser()
    
    private var _editingPanelRect: CGRect = .zero

    lazy var atListManager: BTAtListManager = {
        let manager = BTAtListManager()
        manager.delegate = self
        return manager
    }()

    private var editingTextCell: BTFieldTextCellProtocol?
    
    private var editInputType: BTTextEditType?
    
    private var forbiddenTextCapabilities: BTTextCapabilityOptions {
        return editingTextCell?.fieldModel.forbiddenTextCapabilities ?? []
    }

    private lazy var lastTextViewSelectedRange = NSRange(location: 0, length: 0)
    
    var initialAttrString: NSAttributedString?
    
    var isPrimaryField: Bool = false
    
    override var editType: BTFieldType { .text }

    override var editingPanelRect: CGRect {
        if _editingPanelRect != .zero {
            return editingTextCell?.window?.convert(_editingPanelRect, to: inputSuperview) ?? .zero
        } else {
            return .zero
        }
    }
    
    override func startEditing(_ cell: BTFieldCellProtocol) {
        guard let cell = cell as? BTFieldTextCellProtocol else { return }
        editingTextCell = cell
        initialAttrString = cell.textView.attributedText
        debugPrint("textField startEditing cell \(editingTextCell)")
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        if let textCell = editingTextCell {
            textCell.stopEditing()
        } else {
            baseDelegate?.didStopEditing()
        }
        atListManager.hideAtListView()
        debugPrint("textField stopEditing cell \(editingTextCell)")
        guard editingTextCell != nil else { return }
        if sync {
            if coordinator?.shouldContinueEditing(fieldID: fieldID, inRecordID: recordID) == false {
                editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
            } else {
                tellViewModelFinishTextFieldEdit()
            }
        }
        coordinator?.invalidateEditAgent()
        initialAttrString = nil
        editingTextCell = nil
    }
}

// MARK: - handle TextView Delegate Event
extension BTTextEditAgent {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView.text.count + text.count > 10_000 {
            return false
        }
        let attributedString: NSAttributedString = textView.attributedText
        resetTypingAttributes(of: textView)
        // 所有链接类型的 attribute key 见 BTRichTextSegmentModel.linkAttributes
        if text.isEmpty { // 即将删除
            if handleAttrsKeyDeleteIfNeed(textView, attributedString: attributedString, range: range) {
                return false
            }
        }
        let diffRange = text.isEmpty ?
        NSRange(location: range.location, length: 0) :
        NSRange(location: range.location, length: text.utf16.count)
        formateUrlTypeWhenTextDidChange = .diff(diffRange)
        activeAtInfoWhenTextShouldChangeIfNeed(text: text, range: range)
        return true
    }
    
    ///Mark 重复代码可抽离
    func textViewDidChangeSelection(_ textView: UITextView) {
        lastTextViewSelectedRange = BTAttributedTextUtil.textViewDidChangeSelection(textView,
                                                                                    lastTextViewSelectedRange: lastTextViewSelectedRange,
                                                                                    editable: editingTextCell?.fieldModel.editable ?? false,
                                                                                    attributedKeys: [BTRichTextSegmentModel.attrStringBTAtInfoKey,
                                                                                                     BTRichTextSegmentModel.attrStringBTEmbeddedImageKey,
                                                                                                     AtInfo.attributedStringAtInfoKey])
    }

    func textViewDidChange(_ textView: UITextView) {
        
        defer {
            formateUrlTypeWhenTextDidChange = .full
            editingTextCell?.setCursorBootomOffset()
            scrollTillFieldVisible()
        }
        if textView.markedTextRange?.isEmpty == false {
            // 说明还有候选词，先不扫描 URL，否则 editingTextView.attributedText = attrText 会直接退出候选状态
        } else {
            guard let originalAttrText = textView.attributedText else { return }
            let selectedRange = lastTextViewSelectedRange
            let attributedText = parseWhenTextChange(textView: textView, originalAttrText: originalAttrText)
            textView.attributedText = attributedText
            textView.selectedRange = selectedRange
        }
        guard let originalAttrText = textView.attributedText else { return }
        let fixedAttrText = attributedTextForFixHeight(with: originalAttrText)
        handleAtInfoWhenTextChangeIfNeed(for: textView)
        tellViewModelModifyTextField(fieldID: fieldID, attText: fixedAttrText)
    }
    
    // 解决高度不一致的问题
    func attributedTextForFixHeight(with attributedText: NSAttributedString) -> NSAttributedString {
        let fixedAttrText = NSMutableAttributedString()
        attributedText.enumerateAttribute(AtInfo.attributedStringAtInfoKeyStart,
                                            in: NSRange(location: 0, length: attributedText.length),
                                            options: []) { (attr, range, _) in
            guard attr == nil else {
                return
            }
            let subStr = attributedText.attributedSubstring(from: range)
            fixedAttrText.append(subStr)
        }
        return fixedAttrText
    }
    
    /// 重置 textview 的输入文本属性。注：这个对黏贴无效。
    func resetTypingAttributes(of textView: UITextView) {
        if UserScopeNoChangeFG.ZYS.recordCardV2, let cell = editingTextCell, cell.textView == textView {
            cell.resetTypingAttributes()
            return
        }
        let font = BTFieldLayout.Const.getFont(isPrimaryField: isPrimaryField)
        let textColor = isPrimaryField ? UDColor.primaryPri900 : UDColor.textTitle
        var attrs = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
        attrs[.foregroundColor] = textColor
        textView.typingAttributes = attrs
    }
    
    ///Mark 重复代码可抽离
    /// 如果删除的是 at 信息，需要整块都移除掉
    func handleAttrsKeyDeleteIfNeed(_ textView: UITextView, attributedString: NSAttributedString, range: NSRange) -> Bool {
        let indivisibleAttrRanges = BTAttributedTextUtil.getIndivisibleAttrRanges(attributedString: attributedString, changedRange: range)
        
        for attrRange in indivisibleAttrRanges {
            if attrRange.contains(range.location) {
                let tempAttrString = NSMutableAttributedString(attributedString: attributedString)
                tempAttrString.replaceCharacters(in: attrRange, with: "")
                textView.attributedText = tempAttrString
                textView.selectedRange = NSRange(location: attrRange.location, length: 0)
                textViewDidChange(textView)
                return true
            }
        }
        return false
    }
}

extension BTTextEditAgent {

    func didEndEditingText() {
        tellViewModelFinishTextFieldEdit()
        stopEditing(immediately: false)
    }
    
    func didEndAssistInput(content: String?) {
        if let content = content {
            if let textView = editingTextCell?.textView {
                textView.text = content
                textViewDidChange(textView)
            }
        }
        self.editInputType = content != nil ? .scan : nil
        didEndEditingText()
    }
    
    func tellViewModelModifyTextField(fieldID: String, attText: NSAttributedString, finish: Bool = false) {
        editHandler?.didModifyText(fieldID: fieldID, attText: attText, finish: finish, editType: editInputType)
        editInputType = nil
    }

    func tellViewModelFinishTextFieldEdit() {
        guard let editingCell = editingTextCell else { return }
        let editingTextView = editingCell.textView
        guard initialAttrString != editingTextView.attributedText else {
            editHandler?.didFinishEditingWithoutModify(fieldID: fieldID)
            return
        }
        editHandler?.didEndModifyingText(fieldID: fieldID)
        tellViewModelModifyTextField(fieldID: fieldID, attText: editingTextView.attributedText, finish: true)
    }
    
    /// 将当前 cell 滚动到可见的地方
    /// - Parameter heightOfContentAboveKeyBoard: 键盘顶部内容的高度
    func scrollTillFieldVisible() {
        guard let field = relatedVisibleField else { return }
        guard let coordinator = coordinator else { return }
        guard let window = coordinator.inputSuperview.window else { return }
        let bottomHeight = coordinator.keyboardHeight + (editingTextCell?.heightOfContentAboveKeyBoard ?? 0)
        let bottomY = window.frame.height - bottomHeight -
                      coordinator.inputSuperviewDistanceToWindowBottom + (editingTextCell?.cursorBootomOffset ?? 0)
        let bottomRect = CGRect(x: 0, y: bottomY, width: window.frame.width, height: bottomHeight)
        self._editingPanelRect = bottomRect
        coordinator.currentCard?.scrollTillFieldBottomIsVisible(field)
    }
}

extension BTTextEditAgent: BTKeyboardInputAccessoryViewDelegate {
    func didRequestFinishEdit(_ view: BTKeyboardInputAccessoryView) {
        stopEditing(immediately: false, sync: true)
    }
}

// MARK: URL 解析
extension BTTextEditAgent {
    
    private func parseWhenTextChange(textView: UITextView, originalAttrText: NSAttributedString) -> NSAttributedString {
        let attributedText: NSAttributedString
        switch formateUrlTypeWhenTextDidChange {
        case .full:
            var _attributedText = originalAttrText
            _attributedText = _attributedText.docs.removedURLKeyAttributes(for: _attributedText,
                                                                           range: NSRange(location: 0, length: _attributedText.length))
            attributedText = _attributedText.docs.newUrlAttributed
        case .diff(let range):
            attributedText = originalAttrText.docs.urlAttributedDiff(range: range,
                                                                     filterKeys: [BTRichTextSegmentModel.attrStringBTAtInfoKey,
                                                                                  BTRichTextSegmentModel.attrStringBTEmbeddedImageKey,
                                                                                  AtInfo.attributedStringAtInfoKey],
                                                                     notChangeForegroundColor: true)
        }
        return attributedText
    }
}

// MARK: 处理黏贴内容
extension BTTextEditAgent {
    // 黏贴时去请求看看是不是内部文档链接，如果是内部文档链接的话会进行替换。
    // 黏贴时，如果是英文字母会自动添加一个空格。
    func doPaste() {
        guard !forbiddenTextCapabilities.contains(.parseAtInfoWhenPaste) else {
            return
        }
        guard let url = SKPasteboard.string(psdaToken: PSDATokens.Pasteboard.base_multi_line_text_edit_do_paste) else { return }
        urlParser.parseAtInfoFormURL(url) { [weak self] atInfo in
            guard let self = self, let atInfo = atInfo else {
                return
            }
            atInfo.href = url
            self.convertURLToTitle(url, with: atInfo)
        }
    }
    
    // 将 url 转为标题
    func convertURLToTitle(_ url: String, with info: AtInfo) {
        guard let editingCell = editingTextCell else { return }
        if let attributedText = BTURLToTitleConverter.convertURLToTitle(url, with: info, by: editingCell.textView) {
            tellViewModelModifyTextField(fieldID: fieldID, attText: attributedText)
        }
    }
}

// MARK: 处理 at 信息
extension BTTextEditAgent: BTAtListMangerDelegate {
    
    private func activeAtInfoWhenTextShouldChangeIfNeed(text: String, range: NSRange) {
        guard !forbiddenTextCapabilities.contains(.activeAtInfoWhenInput) else {
            return
        }
        if text.hasSuffix("@") {
            atListManager.showAtListView()
            atListManager.atContext = ("", range.location + text.count )
        } else if let context = atListManager.atContext, range.location <= context.location - 1 {
            atListManager.hideAtListView()
            atListManager.atContext = nil
        }
    }

    private func handleAtInfoWhenTextChangeIfNeed(for textView: UITextView) {
        guard !forbiddenTextCapabilities.contains(.activeAtInfoWhenInput) else {
            return
        }
        atListManager.handleAtIfNeeded(textView)
    }
    
    // MARK: BTAtListMangerDelegate
    func atListGetCoordinator() -> BTEditCoordinator? {
        return coordinator
    }
    
    func atListDidSelect(keyword: String, with info: AtInfo) {
        convertURLToTitle(keyword, with: info)
    }
    
    func atListGetRelateTextView() -> UITextView? {
        return self.editingTextCell?.textView
    }
    
    func atListViewDidShow() {
        editingTextCell?.heightOfContentAboveKeyBoard = atListManager.atListViewHeight
        scrollTillFieldVisible()
    }
    
    func atListViewDidHide() {
        editingTextCell?.heightOfContentAboveKeyBoard = 0
        self._editingPanelRect = .zero
    }
}
