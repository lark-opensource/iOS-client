//
//  SheetInputView+UIMode.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/11.
//

import Foundation
import SKCommon
import SpaceInterface
// MARK: - 数字化键盘的输入接口
extension SheetInputView {

    //往当前选中区插入text
    public func numberKeyboardAdd(txt: String) {
        addTextAtDefaultRange(txt: txt)
    }

    public func changeTextSign() {
        var currentAttTxt = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        let signText = NSMutableAttributedString(string: "-", attributes: normalAttribution)
        if currentAttTxt.string.count > 0 {
            let startIndex = currentAttTxt.string.startIndex
            let firstChar = currentAttTxt.string[startIndex]
            if firstChar == "-" {
                let range = NSRange(location: 0, length: 1)
                currentAttTxt.deleteCharacters(in: range)
            } else {
                currentAttTxt.insert(signText, at: 0)
            }
        } else {
            currentAttTxt = signText
        }
        inputTextView.attributedText = currentAttTxt
        let newRange = NSRange(location: currentAttTxt.length, length: 0)
        inputTextView.selectedRange = newRange
        inputTextView.scrollRangeToVisible(newRange)
        currentText = currentAttTxt.string
        modifyNonFullModeIfNeed()
        callJSForTextChanged(text: currentAttTxt, editState: .editing)
    }

    @discardableResult
    public func mockDelete() -> Bool {
        //删除At
        let deleteSpecial = AtInfo.removeAtString(from: inputTextView)
        if deleteSpecial {
            callJSForTextChanged(text: inputTextView.attributedText, editState: .editing)
            return true
        }
        let currentAttTxt = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        guard currentAttTxt.string.count > 0 else { return false }
        var deletedRange = inputTextView.selectedRange
        if let context = atContext, deletedRange.location <= context.location {
            hideAtView()
            exitFullAtMode()
            atContext = nil
        }
        if deletedRange.length <= 0 {
            if deletedRange.location <= 0 {
                return false
            } else {
                deletedRange.location -= 1
                deletedRange.length = 1
            }
        }
        currentAttTxt.deleteCharacters(in: deletedRange)
        let newRange = NSRange(location: deletedRange.location, length: 0)
        inputTextView.attributedText = currentAttTxt
        inputTextView.selectedRange = newRange
        inputTextView.scrollRangeToVisible(newRange)
        currentText = currentAttTxt.string
        updateAtContextIfNeed()
        modifyNonFullModeIfNeed()
        callJSForTextChanged(text: currentAttTxt, editState: .editing)
        return true
    }

    public func replaceCurrentAttText(with newText: String, editState: SheetEditMode) {
        let newAttributes = self.cellAttributes ?? inputTextView.typingAttributes
        var newAttText: NSAttributedString
        if editState == .editing {
            let reformedText = String(newText.map { $0 == "-" ? "/" : $0 })
            newAttText = NSAttributedString(string: reformedText, attributes: newAttributes)
            inputTextView.attributedText = newAttText
            updateAtContextIfNeed()
            modifyNonFullModeIfNeed()
            currentText = newAttText.string
        } else {
            newAttText = NSAttributedString(string: newText, attributes: newAttributes)
        }
        callJSForTextChanged(text: newAttText, editState: editState)
    }
}
