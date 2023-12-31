//
//  SheetInputView+UITextView.swift
//  DocsSDK
//
//  Created by Gill on 2019/11/28.
//

import UIKit
import RxSwift
import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface

public protocol SheetTextViewDelegate: AnyObject {
    func textViewCanCopy(_ textView: SheetTextView, showTips: Bool) -> Bool
    func textViewCanCut(_ textView: SheetTextView, showTips: Bool) -> Bool
    func textViewOnCopy(_ textView: SheetTextView)
    func textViewWillResign(_ textView: SheetTextView)
}

open class SheetTextView: SKBaseTextView {

    let disposeBag = DisposeBag()
    public weak var textViewDelegate: SheetTextViewDelegate?
    
    public override var keyCommands: [UIKeyCommand] { customKeyCommands() }

    public var pasteOperation: (() -> Void)?

    public override func paste(_ sender: Any?) {
        pasteOperation?()
        super.paste(sender)
    }
    
    override open func resignFirstResponder() -> Bool {
        textViewDelegate?.textViewWillResign(self)
        return super.resignFirstResponder()
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let textViewDelegate = self.textViewDelegate else {
            return super.canPerformAction(action, withSender: sender)
        }
        if action == #selector(copy(_:)), !textViewDelegate.textViewCanCopy(self, showTips: false) {
            return false
        }
        if action == #selector(cut(_:)), !textViewDelegate.textViewCanCut(self, showTips: false) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open override func copy(_ sender: Any?) {
        super.copy(sender)
        self.textViewDelegate?.textViewOnCopy(self)
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }
    
    open override func cut(_ sender: Any?) {
        super.cut(sender)
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }

    public func convertToAtAttrString(_ replacement: String, with atInfo: AtInfo) -> (NSAttributedString, Int)? {
        // 1. 获取 At Attributes String
        let atAttrString = atInfo.attributedString(attributes: AtInfo.TextFormat.defaultAttributes(), lineBreakMode: .byWordWrapping)
        atInfo.iconInfo?.image.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            let range = NSRange(location: 0, length: self.attributedText.length)
            self.layoutManager.invalidateDisplay(forCharacterRange: range)
        }).disposed(by: disposeBag)

        // 2. 获取原文
        let textAttrString = NSMutableAttributedString(attributedString: self.attributedText)

        // 3. 获取当前光标的位置，提前插一个空格
        let selectedRange = self.selectedRange
        textAttrString.insert(NSAttributedString(string: " ", attributes: typingAttributes), at: selectedRange.location)

        // 4. 查找光标前的字符创的最后一个需要替换的 keyword 的位置
        let location = selectedRange.location - replacement.count
        let replacementRange = NSRange(location: location, length: replacement.count)

        // 5. 替换 keyword
        guard
            replacementRange.location >= 0,
            replacementRange.location < textAttrString.length,
            replacementRange.location + replacementRange.length <= textAttrString.length
            else {
                DocsLogger.info("at 数组越界 - \(textAttrString) -\(replacementRange)")
                return nil
        }
        textAttrString.replaceCharacters(in: replacementRange, with: atAttrString)
        let newLocation = atAttrString.length + location + 1
        return (textAttrString, newLocation)
    }
    
    public func segmentAtPoint(_ point: CGPoint) -> SheetSegmentBase? {
        return attributeAtPoint(point, attrKey: SheetInputView.attributedStringSegmentKey)
    }
    
    private func attributeAtPoint<T>(_ point: CGPoint, attrKey: NSAttributedString.Key) -> T? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return nil
        }
        var effectiveRange: NSRange = NSRange(location: 0, length: 0)
        guard let component = textStorage.attribute(attrKey, at: index, longestEffectiveRange: &effectiveRange, in: NSRange(location: 0, length: textStorage.length)) as? T else {
            return nil
        }
        var bounds = layoutManager.boundingRect(forGlyphRange: effectiveRange, in: textContainer)
        bounds.origin.x += textContainerInset.left
        bounds.origin.y += textContainerInset.top
        if bounds.contains(point) {
            return component
        } else {
            return nil
        }
    }
    
    private func customKeyCommands() -> [UIKeyCommand] {
        let copy = UIKeyCommand(input: "c", modifierFlags: [.command], action: #selector(handleShortcutCommand(_:)))
        let cut = UIKeyCommand(input: "x", modifierFlags: [.command], action: #selector(handleShortcutCommand(_:)))
        return [copy, cut]
    }
    
    @objc
    private func handleShortcutCommand(_ command: UIKeyCommand) {
        guard self.isEditable,
              let textViewDelegate = self.textViewDelegate else {
            return
        }
        //在条件访问控制后，直接操作快捷键，也需要弹出管控提示
        if command.modifierFlags == [.command], command.input == "c" {
            let canCopy = textViewDelegate.textViewCanCopy(self, showTips: true)
            DocsLogger.info("sheet: copy shortcut:\(canCopy)")
            
        } else if command.modifierFlags == [.command], command.input == "x" {
            let canCut = textViewDelegate.textViewCanCut(self, showTips: true)
            DocsLogger.info("sheet: cut shortcut:\(canCut)")
        }
    }
}
