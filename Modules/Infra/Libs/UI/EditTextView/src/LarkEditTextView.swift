//
//  EditTextView.swift
//  Lark
//
//  Created by lichen on 2018/4/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit
import LarkFoundation
import UniverseDesignColor

//@objc的协议才会走动态消息转发,不可以使用swift extension默认实现方式
//NSObjectProtocol约束实现类要继承自NSObject
@objc public protocol EditTextViewTextDelegate: NSObjectProtocol {
    @objc optional func textChange(text: String, textView: LarkEditTextView)
}

open class LarkEditTextView: BaseEditTextView, UITextPasteDelegate {

    public struct Config {
        public var log: EditTextViewLog?
        public init(log: EditTextViewLog? = nil) {
            self.log = log
        }
    }
    var tapGestureRecognizer: UITapGestureRecognizer?
    /// 是否支持与其他手势共存 默认维持原来支持逻辑
    public var gestureRecognizeSimultaneously = true

    /// 是否支持自定义换行菜单
    public var supportNewLine = false {
        didSet {
            if supportNewLine {
                let item = UIMenuItem(title: BundleI18n.EditTextView.Lark_IM_TextBoxNewLine_Button, action: #selector(newline))
                UIMenuController.shared.menuItems = [item]
            } else {
                UIMenuController.shared.menuItems = []
            }
        }
    }

    public var defaultTypingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 17),
        .foregroundColor: UIColor.ud.N600,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            return paragraphStyle
        }()
    ] {
        didSet {
            self.typingAttributes = self.defaultTypingAttributes
        }
    }

    override public var typingAttributes: [NSAttributedString.Key: Any] {
        // swiftlint:disable:next unused_setter_value
        set {
            super.typingAttributes = self.defaultTypingAttributes
        }
        get {
            return super.typingAttributes
        }
    }

    fileprivate let disposebag: DisposeBag = DisposeBag()

    // 管理 attachment
    lazy var attachmantManager: AttachmentManager = {
        var manager = AttachmentManager()
        manager.textView = self
        return manager
    }()

    /// 这里走线上逻辑
    var containerView: UIView? {
        return nil
    }

    private(set) var logger: EditTextViewLog?

    public convenience init (frame: CGRect = CGRect.zero,
                             textContainer: NSTextContainer? = nil,
                             config: Config?) {
        self.init(frame: frame, textContainer: textContainer)
        self.logger = config?.log
    }

    public override init(frame: CGRect = CGRect.zero,
                         textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        self.setupDelegateObserve()
        /// observe selectedRange and selectedTextRange to update attachment selected state and typingAttributes
        self.addObserver(self, forKeyPath: "selectedTextRange", options: [.old, .new], context: nil)
        self.addObserver(self, forKeyPath: "selectedRange", options: [.old, .new], context: nil)
        self.layoutManager.delegate = self
        self.pasteDelegate = self
        self.setupTapGesture()
    }

    @objc
    func newline() {
        self.insertText("\n")
    }

    private var wrapper = WrapperUITextViewDelegate()
    private var storageWrapper = WrapperUITextViewStorageDelegate()

    public var proxyCount: Int {
        return delegateProxy.delegates.count
    }
    private var delegateProxy: UITextViewProxyDelegate = UITextViewProxyDelegate()
    override weak public var delegate: UITextViewDelegate? {
        didSet {
            //为了不影响Rx的调用RxTextViewDelegateProxy要允许设置，RX框架内部会帮助维护之前被替换掉的delegate
            if let delegate = delegate, !(delegate is UITextViewProxyDelegate || delegate is RxTextViewDelegateProxy) {
                delegateProxy.add(delegate: delegate)
                self.delegate = delegateProxy
            }
        }
    }

    private var textDelegateProxy: EditTextViewTextProxyDelegate = EditTextViewTextProxyDelegate()
    public weak var textDelegate: EditTextViewTextDelegate? {
        didSet {
            if let textDelegate = textDelegate, !(textDelegate is EditTextViewTextProxyDelegate) {
                textDelegateProxy.add(delegate: textDelegate)
                self.textDelegate = textDelegateProxy
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self, forKeyPath: "selectedTextRange")
        self.removeObserver(self, forKeyPath: "selectedRange")
    }

    // swiftlint:disable:next block_based_kvo
    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        if keyPath == "selectedTextRange" || keyPath == "selectedRange" {
            self.updateTypingAttributes()
            self.attachmantManager.updateAttachmentSelectedState()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func updateTypingAttributes() {
        self.typingAttributes = defaultTypingAttributes
    }

    public override func insertText(_ text: String) {
        self.updateTypingAttributes()
        super.insertText(text)
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == NSSelectorFromString("paste:") {
            if super.canPerformAction(action, withSender: sender) {
                return true
            }
            /* (可能是)系统 bug:
             设置 pasteConfiguration 后，直接拖拽可以粘贴成功，但菜单中没有“粘贴”选项，也不能用 cmd + v 粘贴
             原因是因为 super.canPerformAction() 会返回 false，导致没有粘贴按钮，在此手动判定一遍 */
            let pasteItemUTIs = Set(UIPasteboard.general.itemProviders.flatMap({ $0.registeredTypeIdentifiers }))
            let pasteConfigUTIs = Set(pasteConfiguration?.acceptableTypeIdentifiers ?? [])
            return !pasteItemUTIs.isDisjoint(with: pasteConfigUTIs)
        } else if action == NSSelectorFromString("newline") {
            return supportNewLine && !(self.selectedRange.length > 0)
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    // 全量替换文本
    public func replace(
        _ attributedString: NSAttributedString,
        useDefaultAttributes: Bool = true,
        transform: ((NSAttributedString) -> NSAttributedString)? = nil) {

        var replaceString = NSMutableAttributedString(attributedString: attributedString)
        if useDefaultAttributes {
            let attributes: [NSAttributedString.Key: Any] = self.defaultTypingAttributes
            replaceString.addAttributes(attributes, range: NSRange(location: 0, length: replaceString.length))
        }
        if let transform = transform,
            let transformText = transform(replaceString).mutableCopy() as? NSMutableAttributedString {
            replaceString = transformText
        }
        self.attributedText = replaceString
        self.autoScrollToSelectionIfNeeded()
    }

    // 插入文本
    public func insert(
        _ attributedString: NSAttributedString,
        useDefaultAttributes: Bool = true,
        transform: ((NSAttributedString) -> NSAttributedString)? = nil) {

        var insertString = NSMutableAttributedString(attributedString: attributedString)
        if useDefaultAttributes {
            let attributes: [NSAttributedString.Key: Any] = defaultTypingAttributes
            insertString.addAttributes(attributes, range: NSRange(location: 0, length: insertString.length))
        }
        let attributedText = NSMutableAttributedString(attributedString: self.attributedText)
        let selectedRange = self.selectedRange
        if let transform = transform,
            let transformText = transform(insertString).mutableCopy() as? NSMutableAttributedString {
            insertString = transformText
        }
        attributedText.replaceCharacters(in: selectedRange, with: insertString)
        self.attributedText = attributedText
        self.selectedRange = NSRange(location: selectedRange.location + insertString.length, length: 0)
        self.autoScrollToSelectionIfNeeded()
    }

    /// 自动滚动选中区域
    public func autoScrollToSelectionIfNeeded() {
        let selectorString = "scrollSelectionToVisible:"
        let sel = NSSelectorFromString(selectorString)
        self.perform(sel, with: true)
    }

    // MARK: UIPasteDelegate
    /// 粘贴内容格式重置为 defaultTypingAttributes
    /// Note: 重置格式后可能会导致无法粘贴图片
    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString], for textRange: UITextRange
    ) -> NSAttributedString {
        let mutableString = NSMutableAttributedString()
        itemStrings.forEach {
            let string = NSMutableAttributedString(attributedString: $0)
            string.setAttributes(defaultTypingAttributes, range: NSRange(location: 0, length: string.length))
            mutableString.append(string)
        }
        return mutableString
    }
    /**
     解决光标height变长的问题 https://juejin.cn/post/6844903969454555149
     因为文章中没有图片等类似的问题 使用height = self.font.lineHeight + 2;
     文章中使用2 是个粗估的值，实际观察光标会比文字高2左右
     lark中不单单只有文字 还会有图片等, 采用对比的方式
      */
    open override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        /// 没有段落样式 直接返回
        guard let paragraphStyle = self.defaultTypingAttributes[.paragraphStyle] as? NSParagraphStyle else {
            return rect
        }
        /// 如果是最后位置的光标 直接返回
        if position == self.endOfDocument {
            return rect
        }
        let endCursorRect = super.caretRect(for: self.endOfDocument)
        /// 光标的底部是否和最后一个文字的一致，系统最后一样不会添加lineSpacing 不需要处理
        if endCursorRect.maxY == rect.maxY {
            return rect
        }
        let actualHeight = rect.size.height - paragraphStyle.lineSpacing
        rect.size.height = actualHeight
        return rect
    }
}

//因系统framework问题，UITextView不能把delegate设置为self，会引发崩溃，这里包一层
final class WrapperUITextViewDelegate: NSObject, UITextViewDelegate {
    weak var delegate: UITextViewDelegate?

    public func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewDidChange?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll?(scrollView)
    }
}

//因系统framework问题，UITextView的storage不能把delegate设置为self，否则会有异常
final class WrapperUITextViewStorageDelegate: NSObject, NSTextStorageDelegate {
    weak var delegate: NSTextStorageDelegate?

    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        self.delegate?.textStorage?(textStorage,
                                    didProcessEditing: editedMask,
                                    range: editedRange,
                                    changeInLength: delta)
    }
}

extension LarkEditTextView: UITextViewDelegate {
    func setupDelegateObserve() {
        wrapper.delegate = self
        self.delegate = wrapper
        storageWrapper.delegate = self
        self.textStorage.delegate = storageWrapper
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.updateTypingAttributes()
        self.attachmantManager.updateAttachmentSelectedState()
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.updateTypingAttributes()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        /// unselected when textview unregister first responsder
        self.attachmantManager.updateAttachmentSelectedState()
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.updateTypingAttributes()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.attachmantManager.updateAllAttachmentShowState()
    }
}

extension LarkEditTextView: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        self.textDelegate?.textChange?(text: self.textStorage.string, textView: self)
    }
}

// 优化点击逻辑
extension LarkEditTextView: UIGestureRecognizerDelegate {

    func setupTapGesture() {
        // 添加点击优化
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapContent(gesture:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
    }

    // 这里添加手势 优化点击TextAttachment切换光标问题
    @objc
    fileprivate func handleTapContent(gesture: UITapGestureRecognizer) {
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer

        // 计算手势相对位置
        var location = gesture.location(in: self)
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // 获取点击位置对应的文字索引
        let index = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        let string = self.textStorage.string

        // 超出正文范围不处理
        if index >= string.count { return }

        // 点击字符
        let char = string[string.index(string.startIndex, offsetBy: index)]

        // NSTextAttachment and space char
        let attachmentCharacter = Character(UnicodeScalar(NSTextAttachment.character)!)
        let spaceCharacter = Character(" ")

        // 如果点击 NSTextAttachemnt, 判断点击位置相对, 设置游标位置
        if char == attachmentCharacter {
            // 获取字形索引以及字形 rect
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
            let glyphRange = NSRange(location: glyphIndex, length: 1)
            let attachmentRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            if attachmentRect.contains(location) {
                // 判断相对靠左还是相对靠右 设置 selectedRange
                var selectedRange = NSRange(location: index, length: 0)
                if location.x > attachmentRect.minX + attachmentRect.width / 2 {
                    selectedRange = NSRange(location: index + 1, length: 0)
                }
                DispatchQueue.main.async {
                    if !self.selectedRange.contains(selectedRange.location) &&
                        self.selectedRange != selectedRange {
                        self.selectedRange = selectedRange
                    }
                }
            }
        }
        // 优化 NSTextAttachemnt 前连续空格， 如出现同一行连续空格连着附件，则设置游标到 attachment 前
        else if char == spaceCharacter && index < string.count - 1 {
            var connectAttachmentIndex: Int?
            // 取到连续空格之后第一个字符 判断是否是 attachment
            for i in (index + 1)..<string.count {
                let nextChar = string[string.index(string.startIndex, offsetBy: i)]
                if nextChar != spaceCharacter {
                    if nextChar == attachmentCharacter {
                        connectAttachmentIndex = i
                    }
                    break
                }
            }
            // 如果有连续的, 判断是否是同一行，如果是同一行 直接把光标移动到 attachment 前
            if let connectAttachmentIndex = connectAttachmentIndex {
                // 获取 space line rect
                let spaceGlyphIndex = layoutManager.glyphIndexForCharacter(at: index)
                let spaceLineRect = layoutManager.lineFragmentRect(forGlyphAt: spaceGlyphIndex, effectiveRange: nil)

                // 获取 attachment rect
                let attachmentGlyphIndex = layoutManager.glyphIndexForCharacter(at: connectAttachmentIndex)
                let attachmentLineRect = layoutManager.lineFragmentRect(
                    forGlyphAt: attachmentGlyphIndex,
                    effectiveRange: nil
                )

                var selectedRange = NSRange(location: index, length: 0)

                if spaceLineRect.origin.y == attachmentLineRect.origin.y {
                    selectedRange = NSRange(location: connectAttachmentIndex, length: 0)
                }
                DispatchQueue.main.async {
                    if !self.selectedRange.contains(selectedRange.location) &&
                        self.selectedRange != selectedRange {
                        self.selectedRange = selectedRange
                    }
                }
            }
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if self.gestureRecognizeSimultaneously {
                return true
            }
            /// 如果自己添加的tap手势，支持和其他手势共存，其他的使用系统的默认的处理false
            if let tapGestureRecognizer = self.tapGestureRecognizer,
               (tapGestureRecognizer == gestureRecognizer || tapGestureRecognizer == otherGestureRecognizer) {
                return true
            }
            return false
        }
}

final class UITextViewProxyDelegate: BaseMultiProxyDelegate, MultiProxyDelegate, UITextViewDelegate {
    typealias D = UITextViewDelegate
}

final class EditTextViewTextProxyDelegate: BaseMultiProxyDelegate, MultiProxyDelegate, EditTextViewTextDelegate {
    typealias D = EditTextViewTextDelegate
}
