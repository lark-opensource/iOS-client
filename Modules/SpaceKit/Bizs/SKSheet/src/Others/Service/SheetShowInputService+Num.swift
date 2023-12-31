//
//  SheetShowInputService+number.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/11.
//

// 数字键盘的输入逻辑
import Foundation

extension SheetShowInputService: SheetNumKeyboardViewDelegate {

    func didSelectItem(at indexPath: IndexPath?, type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView) {
        if let txt = type.inputText() {
            sheetInputView?.numberKeyboardAdd(txt: txt)
        } else {
            handleSpecialNumberItem(type: type)
        }
        logPressNumKeyboardItem(type: type)
    }

    /// +-， 删除， 右边单元格，下个单元格的处理逻辑
    private func handleSpecialNumberItem(type: SheetNumKeyboardButtonType) {
        let attTxt = sheetInputView?.inputTextView.attributedText ?? NSAttributedString()
        switch type {
        case .sign:
            sheetInputView?.changeTextSign()
        case .delete:
            sheetInputView?.mockDelete()
        case .right:
            sheetInputView?.callJSForTextChanged(text: attTxt, editState: .jumpRightItem)
        case .down:
            sheetInputView?.callJSForTextChanged(text: attTxt, editState: .endCellEdit)
        default:
            ()
        }
    }

    func disableCellSwitch(disable: Bool) {
        numberKeyboardView.disableCellSwitch(disable: disable)
    }

    func tellFEExitEdit() {
        let attTxt = sheetInputView?.inputTextView.attributedText ?? NSAttributedString()
        sheetInputView?.callJSForTextChanged(text: attTxt, editState: .endSheetEdit)
    }

    func didStartLongPress(type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView) {
        guard type == .delete else { return }
        startTimer()
    }

    func didStopLongPress(type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView) {
        guard type == .delete else { return }
        stopTimer()
    }
}

extension SheetShowInputService {
    func stopTimer() {
        deletedTimer?.invalidate()
        deletedTimer = nil
    }

    func startTimer() {
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.quickDeleteText()
        }
        RunLoop.main.add(timer, forMode: .common)
        deletedTimer = timer
    }

    func quickDeleteText() {
        let hasDeleted = sheetInputView?.mockDelete() ?? false
        if !hasDeleted {
            stopTimer()
        }
    }
}
