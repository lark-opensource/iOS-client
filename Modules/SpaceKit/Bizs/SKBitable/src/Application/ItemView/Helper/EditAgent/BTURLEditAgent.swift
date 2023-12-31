//
//  BTURLEditAgent.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/14.
//  


import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import UniverseDesignColor
import LarkEMM
import SpaceInterface
import SKInfra


final class BTURLEditAgent: BTBaseEditAgent {

    private let urlParser = BTURLParser()
    
    private lazy var atListManager: BTAtListManager = {
        let manager = BTAtListManager()
        manager.delegate = self
        manager.atViewFilter = AtDataSource.RequestType.fileTypeSet
        return manager
    }()
    
    /// 超链接编辑面板加上键盘，对应在当前 window 上面的 frame。
    private var _editingPanelRect: CGRect = .zero
    
    private var editingTextCell: BTFieldURLCellProtocol?

    private lazy var lastTextViewSelectedRange = NSRange(location: 0, length: 0)
    
    private var initialAttrString: NSAttributedString?
    
    private var initialLink: String?
    
    override var editType: BTFieldType { .url }

    /// 当调用 currentCard.scrollTillFieldBottomIsVisible 将 Field 滚动到可见地方时，会从这里获取底部遮挡的面积。
    override var editingPanelRect: CGRect {
        if _editingPanelRect != .zero {
            return editingTextCell?.window?.convert(_editingPanelRect, to: inputSuperview) ?? .zero
        } else {
            return .zero
        }
    }
    
    // 开始编辑态
    override func startEditing(_ cell: BTFieldCellProtocol) {
        guard let cell = cell as? BTFieldURLCellProtocol else { return }
        editingTextCell = cell
        initialAttrString = cell.textView.attributedText
        initialLink = BTRichTextSegmentModel.getRealSegmentsForURLField(from: cell.fieldModel.textValue)?.link
    }

    // 退出编辑态
    override func stopEditing(immediately: Bool, sync: Bool = false) {
        if let textCell = editingTextCell {
            textCell.stopEditing()
        } else {
            baseDelegate?.didStopEditing()
        }
        
        baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        atListManager.hideAtListView()
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
        initialLink = nil
        editingTextCell = nil
        _editingPanelRect = .zero
    }
}

// MARK: 编辑 textView 内容
extension BTURLEditAgent {
    
    /// 内容发生变化。
    func didEndEditingText() {
        tellViewModelFinishTextFieldEdit()
        stopEditing(immediately: false)
    }
    
    ///Mark 重复代码可抽离
    /// 处理文档替换
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.text.count + text.count > 10000 {
            return false
        }
        let attributedString = textView.attributedText.docs.urlAttributed
        var attrs = BTUtil.getFigmaHeightAttributes(font: UIFont.systemFont(ofSize: 14), alignment: .left)
        attrs[.foregroundColor] = UDColor.textLinkNormal
        textView.typingAttributes = attrs

        // 所有链接类型的 attribute key 见 BTRichTextSegmentModel.linkAttributes
        if text.count == 0 { // 即将删除
            let indivisibleAttrRanges = BTAttributedTextUtil.getIndivisibleAttrRanges(attributedString: attributedString, changedRange: range)
            
            for attrRange in indivisibleAttrRanges {
                if attrRange.contains(range.location) {
                    let tempAttrString = NSMutableAttributedString(attributedString: attributedString)
                    tempAttrString.replaceCharacters(in: attrRange, with: "")
                    textView.attributedText = tempAttrString
                    textView.selectedRange = NSRange(location: attrRange.location, length: 0)
                    textViewDidChange(textView)
                    return false
                }
            }
        }
        if text.hasSuffix("@"), textView.text.isEmpty {
            atListManager.showAtListView()
            atListManager.atContext = ("", range.location + text.count )
        } else if let context = atListManager.atContext, range.location <= context.location - 1 {
            atListManager.hideAtListView()
            atListManager.atContext = nil
        }
        return true
    }
    
    ///Mark 重复代码可抽离
    /// 文本选中状态
    func textViewDidChangeSelection(_ textView: UITextView) {
        lastTextViewSelectedRange = BTAttributedTextUtil.textViewDidChangeSelection(textView,
                                                                                    lastTextViewSelectedRange: lastTextViewSelectedRange,
                                                                                    editable: editingTextCell?.fieldModel.editable ?? false,
                                                                                    attributedKeys: [BTRichTextSegmentModel.attrStringBTAtInfoKey,
                                                                                                     AtInfo.attributedStringAtInfoKey])
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.markedTextRange?.isEmpty == false {
            // 说明还有候选词，先不扫描 URL，否则 editingTextView.attributedText = attrText 会直接退出候选状态
        } else {
            let currentSelectionRange = lastTextViewSelectedRange
            let attrText = textView.attributedText.docs.urlAttributed
            textView.attributedText = attrText
            textView.selectedRange = currentSelectionRange
        }
        guard let originalAttrText = textView.attributedText else { return }
        // 解决高度不一致的问题
        let fixedAttrText = NSMutableAttributedString()
        originalAttrText.enumerateAttribute(AtInfo.attributedStringAtInfoKeyStart, in: NSRange(location: 0, length: originalAttrText.length), options: []) { (attr, range, _) in
            guard attr == nil else {
                return
            }
            let subStr = originalAttrText.attributedSubstring(from: range)
            fixedAttrText.append(subStr)
        }
        atListManager.handleAtIfNeeded(textView)
        tellViewModelModifyTextField(fieldID: fieldID, attText: fixedAttrText)
        editingTextCell?.setCursorBootomOffset()
        scrollTillFieldVisible()
    }
    
    /// 每次数据改动都会跳到这里来
    func tellViewModelModifyTextField(fieldID: String, attText: NSAttributedString, finish: Bool = false) {
        editHandler?.didModifyURLContent(fieldID: fieldID, modifyType: .editAtext(aText: attText, link: initialLink ?? "", finish: finish))
    }
    
    /// 退出编辑，在这里协同数据出去
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
    func scrollTillFieldVisible(needAddCursorOffset: Bool = true) {
        guard let field = relatedVisibleField else { return }
        guard let coordinator = coordinator else { return }
        guard let window = coordinator.inputSuperview.window else { return }
        let bottomHeight = coordinator.keyboardHeight + (editingTextCell?.heightOfContentAboveKeyBoard ?? 0)
        var bottomY = window.frame.height - bottomHeight - coordinator.inputSuperviewDistanceToWindowBottom
        if needAddCursorOffset {
            bottomY += (editingTextCell?.cursorBootomOffset ?? 0)
        }
        let bottomRect = CGRect(x: 0, y: bottomY, width: window.frame.width, height: bottomHeight)
        self._editingPanelRect = bottomRect
        coordinator.currentCard?.scrollTillFieldBottomIsVisible(field)
    }
}

// MARK: 超链接面板相关的
extension BTURLEditAgent {
    
    func didEndEditBoard(_ item: BTURLEditBoardViewModel?, _ atInfo: AtInfo? = nil) {
        if let atInfo = atInfo {
            var segment = BTRichTextSegmentModel()
            segment.type = .mention
            segment.mentionType = BTMentionSegmentType(rawValue: atInfo.type.rawValue) ?? .unknown
            segment.token = atInfo.token
            segment.link = atInfo.href
            segment.id = atInfo.uuid
            segment.text = atInfo.at
            editHandler?.didModifyURLContent(fieldID: fieldID, modifyType: .editBoard(segment: segment))
        } else if let item = item {
            var segment = BTRichTextSegmentModel()
            segment.type = .url
            segment.text = item.text
            segment.link = item.link
            editHandler?.didModifyURLContent(fieldID: fieldID, modifyType: .editBoard(segment: segment))
        }
        stopEditing(immediately: false)
    }
}

// MARK: BTKeyboardInputAccessoryViewDelegate
extension BTURLEditAgent: BTKeyboardInputAccessoryViewDelegate {
    func didRequestFinishEdit(_ view: BTKeyboardInputAccessoryView) {
        stopEditing(immediately: false, sync: true)
    }
}

// MARK: 处理黏贴内容
extension BTURLEditAgent {
    // 黏贴时去请求看看是不是内部文档链接，如果是内部文档链接的话会进行替换。
    func doPaste() {
        guard let url = SKPasteboard.string(psdaToken: PSDATokens.Pasteboard.base_link_text_edit_do_paste) else { return }
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

// MARK: at 面板
extension BTURLEditAgent: BTAtListMangerDelegate {
    
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
        _editingPanelRect = .zero
    }
}
