//
//  OldBaseKeyboardView.swift
//  LarkKeyboardView
//
//  Created by JackZhao on 2021/9/10.
//

import Foundation
import UIKit
import LarkUIKit
import EditTextView
import LarkKeyCommandKit
import LarkInteraction

public protocol OldBaseKeyboardDelegate: AnyObject {
    func clickExpandButton()
    func inputTextViewWillSend()
    func inputTextViewSend(attributedText: NSAttributedString)
    func inputTextViewBeginEditing()
    func keyboardframeChange(frame: CGRect)
    func inputTextViewFrameChange(frame: CGRect)
    func inputTextViewDidChange(input: OldBaseKeyboardView)
    /// 插入图片，返回值是 是否应该继续向输入框插入图片，默认为 返回 false 的空实现
    func inputTextViewWillInput(image: UIImage) -> Bool
}

public extension OldBaseKeyboardDelegate {
    func inputTextViewWillInput(image: UIImage) -> Bool { false }
}

// 为了不对之前的baseKeyboardview造成污染，将其rename为OldBaseKeyboardView by zhaodong
// 目前只有公司圈使用，后续将被逐步替换掉
open class OldBaseKeyboardView: UIControl, KeyboardPanelDelegate, UITextViewDelegate, EditTextViewTextDelegate {

    public enum ChatInputExpandType {
        case show
        case hide
    }

    /// 是否使用 mac 风格输入框样式，目前默认 iPad 设备此参数为 true
    public private(set) var macInputStyle: Bool = Display.pad

    open var expandType: ChatInputExpandType = .show {
        didSet {
            self.updateExpandType()
        }
    }
    open var expandAlert: Bool = false {
        didSet {
            self.updateExpandAlert()
        }
    }
    fileprivate lazy var expandAlertView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        return view
    }()

    open func updateExpandType() {
        switch self.expandType {
        case .show:
            self.expandButton.isHidden = false
        case .hide:
            self.expandButton.isHidden = true
        }
        self.updateTextViewConstraints()
    }

    open func updateExpandAlert() {
        if self.expandAlert {
            if self.expandAlertView.superview != self.expandButton {
                self.expandButton.addSubview(self.expandAlertView)
                self.expandAlertView.snp.makeConstraints({ (make) in
                    make.width.height.equalTo(6)
                    make.top.equalToSuperview().offset(5)
                    make.right.equalToSuperview().offset(2)
                })
            }
        } else {
            self.expandAlertView.removeFromSuperview()
        }
    }

    var previousRect = CGRect.zero

    open weak var delegate: OldBaseKeyboardDelegate?
    open var items: [InputKeyboardItem] = []
    open var keyboardViewCache: [Int: UIView] = [:]

    open var inputPlaceHolder: String = BundleI18n.LarkKeyboardView.Lark_Legacy_Windowboxhint {
        didSet {
            self.updatePlaceholder(placeholder: self.inputPlaceHolder)
        }
    }

    open var textViewInputProtocolSet = TextViewInputProtocolSet() {
        didSet {
            self.textViewInputProtocolSet.register(textView: self.inputTextView)
        }
    }

    open func hasFirstResponder() -> Bool {
        return hasFirstResponder(in: self)
    }

    private func hasFirstResponder(in view: UIView) -> Bool {
        if view.isFirstResponder { return true }
        for subview in view.subviews {
            if hasFirstResponder(in: subview) {
                return true
            }
        }
        return false
    }

    // ui
    open var controlContainer: UIView = .init()

    open fileprivate(set) var inputTextView: LarkEditTextView = {
        var inputTextView = LarkEditTextView()
        inputTextView.isScrollEnabled = false
        inputTextView.placeholder = BundleI18n.LarkKeyboardView.Lark_Legacy_Windowboxhint
        inputTextView.placeholderTextColor = UIColor.ud.textPlaceholder
        inputTextView.font = Cons.textFont
        inputTextView.contentInset = .zero
        inputTextView.textColor = UIColor.ud.textTitle
        inputTextView.defaultTypingAttributes = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.linkTextAttributes = [:]
        inputTextView.backgroundColor = UIColor.ud.bgBody
        return inputTextView
    }()

    open fileprivate(set) var expandButton: UIButton!

    open var lock: Bool {
        get {
            return self.keyboardPanel.lock
        }
        set {
            self.keyboardPanel.lock = newValue
        }
    }

    open var observeKeyboard: Bool {
        get {
            return self.keyboardPanel.observeKeyboard
        }
        set {
            self.keyboardPanel.observeKeyboard = newValue
        }
    }

    open func viewControllerDidAppear() {
        if self.hasFirstResponder() {
            self.observeKeyboard = true
        }
    }

    open func viewControllerWillDisappear() {
        if self.hasFirstResponder() {
            self.observeKeyboard = false
        }
    }

    open func deleteBackward() {
        var range = self.inputTextView.selectedRange
        if range.length == 0 {
            range.length = 1
            range.location -= 1
        }

        if self.textViewInputProtocolSet.textView(self.inputTextView, shouldChangeTextIn: range, replacementText: "") {
            self.inputTextView.deleteBackward()
        }
    }

    open var keyboardNewStyleEnable: Bool = false

    /*
     +-------------------------+
     | +---------------------+ |
     | | +-----------------+ |-|----> inputStackWrapper(UIView)
     | | | +-------------+ |-|-|----> inputStackCanvas(UIView)
     | | | |             |-|-|-|----> inputStackView(UIStackView)
     | | | +-------------+ | | |
     | | +-----------------+ | |
     | +---------------------+ |
     |                         |----> containerStackView(UIStackView)
     | +---------------------+ |
     | |                     |—|----> keyboardPanel(相当于UIStackView)
     | +---------------------+ |
     +-------------------------+
     */
    /// 容器 stack view
    /// 目前拥有两部分
    ///     1. inputStackWrapper 输入框容器
    ///     2. keyboardPanel 键盘容器
    open var containerStackView: UIStackView = UIStackView()

    /// 用于 mac 样式输入框 wraper， 处理 insets
    open fileprivate(set) var inputStackWrapper: UIView = UIView()
    /// 用于 mac 样式输入框 wraper，用于添加 mac 风格边框
    /// 层级上低于 inputStackWrapper，高于 inputStackView
    open fileprivate(set) var inputStackCanvas: UIView = UIView()

    /// 输入框容器，区别 iPhone iPad 不同输入样式
    open fileprivate(set) var inputStackView: UIStackView = UIStackView()

    open fileprivate(set) var keyboardPanel: KeyboardPanel!

    /// items整体是否支持点击
    private var subViewsEnable: Bool = true
    /// 不支持点击的items
    public var disableItems: Set<String> = []

    private var debouncer: Debouncer = Debouncer()

    open func setSubViewsEnable(enable: Bool) {
        self.expandButton.isEnabled = enable
        self.expandButton.isUserInteractionEnabled = enable
        self.inputTextView.isUserInteractionEnabled = enable
        self.subViewsEnable = enable
        self.keyboardPanel.reloadPanel()
    }

    open func setupItems(_ items: [InputKeyboardItem]) {
        self.items = items
        self.keyboardViewCache.removeAll()
        self.keyboardPanel.reloadPanel()
    }

    public init(frame: CGRect,
                keyboardNewStyleEnable: Bool = false) {
        super.init(frame: frame)
        self.keyboardNewStyleEnable = keyboardNewStyleEnable
        self.backgroundColor = UIColor.ud.bgBody

        containerStackView.axis = .vertical
        containerStackView.spacing = 0
        containerStackView.alignment = .center
        addSubview(containerStackView)
        containerStackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        var inputWrapperInset: CGFloat = 0
        var inputCanvasInset: UIEdgeInsets = UIEdgeInsets.zero
        var inputStackInset: UIEdgeInsets = UIEdgeInsets.zero
        if macInputStyle {
            inputStackCanvas.layer.cornerRadius = 6
            inputStackCanvas.layer.borderWidth = 1
            inputStackCanvas.ud.setLayerBorderColor(UIColor.ud.N300)
            inputWrapperInset = 20
            inputStackInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
            inputCanvasInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        } else {
            self.ud.setLayerShadowColor(UIColor.ud.shadowDefaultLg)
            self.ud.setValue(forKeyPath: \.layer.shadowOpacity, light: 0.05, dark: 0.5)
            self.ud.setValue(forKeyPath: \.layer.shadowOffset, light: CGSize(width: 0, height: -0.5), dark: CGSize(width: 0, height: -4.0))
            self.ud.setValue(forKeyPath: \.layer.shadowRadius, light: 3, dark: 10)
        }
        containerStackView.addArrangedSubview(inputStackWrapper)
        inputStackWrapper.snp.makeConstraints { (maker) in
            maker.left.equalTo(inputWrapperInset)
            maker.right.equalTo(-inputWrapperInset)
        }

        inputStackWrapper.addSubview(inputStackCanvas)
        inputStackCanvas.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(inputCanvasInset)
        }

        inputStackCanvas.addSubview(inputStackView)
        inputStackView.axis = .vertical
        inputStackView.spacing = 0
        inputStackView.alignment = .center
        inputStackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(inputStackInset)
        }

        // 输入wrapper
        let controlContainer = UIView()
        inputStackView.addArrangedSubview(controlContainer)
        controlContainer.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.controlContainer = controlContainer

        // 放大按钮
        let expandButton = self.buildButton(normalImage: Resources.expand, selectedImage: Resources.expand_selected)
        controlContainer.addSubview(expandButton)
        expandButton.snp.makeConstraints { make in
            make.size.equalTo(Cons.buttonSize)
            make.right.equalTo(-10)
            make.top.equalTo(macInputStyle ? Cons.macStyleButtonTopMargin : Cons.buttonTopMargin)
        }
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        if #available(iOS 13.4, *) {
            expandButton.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (Cons.buttonHotspotSize, 8)
                }),
                targetProvider: .init { (interaction, _) -> UITargetedPreview? in
                    guard let view = interaction.view, let superview = view.superview?.superview else {
                        return nil
                    }
                    let targetCenter = view.convert(view.bounds.center, to: superview)
                    let target = UIPreviewTarget(container: superview, center: targetCenter)
                    let parameters = UIPreviewParameters()
                    return UITargetedPreview(
                        view: view,
                        parameters: parameters,
                        target: target
                    )
                })
        }
        self.expandButton = expandButton

        // 输入框
        inputTextView.pasteDelegate = self
        inputTextView.delegate = self
        inputTextView.textDelegate = self
        if !keyboardNewStyleEnable {
            inputTextView.returnKeyType = .send
            inputTextView.enablesReturnKeyAutomatically = true
        }
        controlContainer.addSubview(inputTextView)
        self.updateTextViewConstraints()

        self.keyboardPanel = KeyboardPanel()
        self.keyboardPanel.keyboardNewStyleEnable = keyboardNewStyleEnable
        self.keyboardPanel.delegate = self
        self.keyboardPanel.iconHitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        containerStackView.addArrangedSubview(keyboardPanel)
        keyboardPanel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        if !macInputStyle {
            let borderView = UIView(frame: CGRect.zero)
            self.addSubview(borderView)
            borderView.backgroundColor = UIColor.ud.N300
            borderView.snp.makeConstraints { (make) in
                make.top.equalTo(0)
                make.left.right.equalToSuperview()
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
        self.addObservers()
        self.updateExpandType()
        self.updateExpandAlert()
        self.updatePlaceholder(placeholder: BundleI18n.LarkKeyboardView.Lark_Legacy_Windowboxhint)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self, forKeyPath: "bounds")
        self.inputTextView.removeObserver(self, forKeyPath: "bounds")
    }

    // swiftlint:disable:next block_based_kvo
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds",
            let newRect = change?[NSKeyValueChangeKey.newKey] as? CGRect,
            let oldRect = change?[NSKeyValueChangeKey.oldKey] as? CGRect,
            newRect == oldRect {
            return
        }

        if object is LarkEditTextView {
            self.delegate?.inputTextViewFrameChange(frame: self.inputTextView.frame)
        } else if object is OldBaseKeyboardView {
            self.delegate?.keyboardframeChange(frame: self.frame)
        }
    }

    private func addObservers() {
        //经验证，使用swift4新的kvo语法，执行效率明显低于老的监听方式，此处还使用老的kvo调用方式
        self.inputTextView.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
        self.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
    }

    public func textChange(text: String, textView: LarkEditTextView) {
        debouncer.debounce(indentify: "textChange", duration: 0.3) { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.inputTextViewDidChange(input: self)
            if self.keyboardNewStyleEnable {
                self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
            }
        }
    }

    override open func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (self.inputTextView.isFirstResponder ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .shift,
                discoverabilityTitle: BundleI18n.LarkKeyboardView.Lark_Legacy_iPadShortcutsNewline
            ).binding(
                target: self,
                selector: #selector(insertLineFeedCode)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkKeyboardView.Lark_Legacy_iPadShortcutsNewline
            ).binding(
                target: self,
                selector: #selector(insertLineFeedCode)
            ).wraper
        ] : [])
    }

    open var text: String {
        return self.inputTextView.text
    }

    open var attributedString: NSAttributedString {
        get {
            return self.inputTextView.attributedText
        }
        set {
            self.inputTextView.replace(newValue, useDefaultAttributes: false)
        }
    }

    open func inputViewBecomeFirstResponder() {
        self.inputTextView.becomeFirstResponder()
    }

    open func inputViewIsFirstResponder() -> Bool {
        return self.inputTextView.isFirstResponder
    }

    let buttonSize = CGSize(width: 32, height: 32)
    fileprivate func buildButton(normalImage: UIImage, selectedImage: UIImage) -> UIButton {
        let button = UIButton()
        button.setImage(normalImage, for: .normal)
        button.setImage(selectedImage, for: .selected)
        button.setImage(selectedImage, for: .highlighted)
        return button
    }

    @objc
    func expandButtonTapped() {
        self.endEditing(true)
        self.delegate?.clickExpandButton()
    }

    func sendPostEnable() -> Bool {
        let content = self.inputTextView.text?.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail) ?? ""
        return !content.isEmpty
    }

    open func sendNewMessage() {
        self.delegate?.inputTextViewWillSend()
        var attributedText = inputTextView.attributedText ?? NSAttributedString()
        attributedText = OldBaseKeyboardView.trimTailAttributedString(attr: attributedText, set: .whitespaces)
        self.delegate?.inputTextViewSend(attributedText: attributedText)
    }

    open func fold() {
        self.endEditing(true)
        self.keyboardPanel.closeKeyboardPanel(animation: true)
    }

    // KeyboardPanelDelegate

    public func keyboardItemKey(index: Int) -> String {
        return self.items[index].key
    }

    open func numberOfKeyboard() -> Int {
        return self.items.count
    }

    open func keyboardIcon(index: Int, key: String) -> (UIImage?, UIImage?, UIImage?) {
        return self.items[index].keyboardIcon
    }

    open func willSelected(index: Int, key: String) -> Bool {
        if let action = self.items[index].selectedAction {
            return action()
        }

        return true
    }

    open func keyboardItemOnTap(index: Int, key: String) -> (KeyboardPanelEvent) -> Void {
        return self.items[index].onTapped
    }

    open func didSelected(index: Int, key: String) {
        self.inputTextView.endEditing(true)
    }

    open func keyboardView(index: Int, key: String) -> (UIView, Float) {
        var item = self.items[index]
        var height = item.keyboardHeightBlock()
        if let keyboardView = self.keyboardViewCache[index] {
            return (keyboardView, height)
        }
        let keyboardView = item.keyboardViewBlock()
        self.keyboardViewCache[index] = keyboardView
        return (keyboardView, height)
    }

    open func keyboardContentHeightWillChange(_ height: Float) {
        self.superview?.layoutIfNeeded()
        for (idx, item) in self.items.enumerated() {
            if let keyboardView = self.keyboardViewCache[idx] {
                item.keyboardStatusChange?(keyboardView, height == 0)
            }
        }
    }

    open func keyboardViewCoverSafeArea(index: Int, key: String) -> Bool {
        return self.items[index].coverSafeArea
    }

    open func keyboardSelectEnable(index: Int, key: String) -> Bool {
        // 整体不能点击，则都不能点击
        guard self.subViewsEnable else { return false }

        // 发送按钮需要特殊处理，需要额外判断内容是否为空
        if key == KeyboardItemKey.send.rawValue {
            return !self.disableItems.contains(key) && sendPostEnable()
        }
        // 其他的直接读取disableItems
        return !self.disableItems.contains(key)
    }

    open func keyboardIconBadge(index: Int, key: String) -> KeyboardIconBadgeType {
        return self.items[index].badgeTypeBlock()
    }

    open func systemKeyboardPopup() {
        self.delegate?.inputTextViewBeginEditing()
    }

    public func didLayoutPanelIcon() { }
    open func keyboardContentHeightDidChange(_ height: Float) { }
    open func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView) { }

    // UITextViewDelegate
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    open func textViewDidChange(_ textView: UITextView) {
        self.textViewInputProtocolSet.textViewDidChange(textView)
        if keyboardNewStyleEnable {
            keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
        }
    }

    @objc
    func insertLineFeedCode() {
        self.inputTextView.insertText("\n")
    }

    private func updateTextViewConstraints() {
        inputTextView.snp.remakeConstraints({ make in
            make.left.equalTo(15)
            make.top.equalTo(macInputStyle ? Cons.macStyleTextFieldTopMargin : Cons.textFieldTopMargin)
            make.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(Cons.textFieldMinHeight)
            make.height.lessThanOrEqualTo(Cons.textFieldMaxHeight)
            switch self.expandType {
            case .show:
                make.right.equalTo(self.expandButton.snp.left).offset(-5)
            case .hide:
                make.right.equalTo(self.controlContainer).offset(-15)
            }
        })
    }

    private func updatePlaceholder(placeholder: String) {
        let attributedPlaceholder = NSMutableAttributedString(
            string: placeholder,
            attributes: [
                .font: Cons.textFont,
                .foregroundColor: UIColor.ud.textPlaceholder,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byTruncatingTail
                    return paragraphStyle
                }()
            ])
        self.inputTextView.attributedPlaceholder = attributedPlaceholder
    }
}

// MARK: - Insert NSAttributedString
public extension OldBaseKeyboardView {

    static func trimTailString(text: String, set: CharacterSet) -> String {
        let invertedSet = set.inverted
        let range: NSRange = (text as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let location = 0
        let length = (range.length > 0 ? NSMaxRange(range) : text.count) - location
        let newText = (text as NSString).substring(with: NSRange(location: location, length: length))
        return newText
    }

    static func trimTailAttributedString(attr: NSAttributedString, set: CharacterSet) -> NSAttributedString {
        let invertedSet = set.inverted
        let modifyAttributeText = NSMutableAttributedString(attributedString: attr)
        let range: NSRange = (attr.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)

        let location = 0
        let length = (range.length > 0 ? NSMaxRange(range) : modifyAttributeText.string.count) - location
        let newText = modifyAttributeText.attributedSubstring(from: NSRange(location: location, length: length))
        return newText
    }
}

extension OldBaseKeyboardView: UITextPasteDelegate {
    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                                 transform item: UITextPasteItem) {
        // 处理粘贴图片
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] object, error in
                // 调用发送图片
                guard error == nil, let image = object as? UIImage, let `self` = self else {
                    // log error
                    return
                }
                DispatchQueue.main.async {
                    let shouldContinuePaste = self.delegate?.inputTextViewWillInput(image: image) ?? false
                    if shouldContinuePaste {
                        item.setDefaultResult()
                    }
                }
            })
        } else {
            item.setDefaultResult()
        }
    }

    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
        guard let string = itemStrings.first else {
            return NSAttributedString()
        }
        let mutableString = NSMutableAttributedString(attributedString: string)
        let attributes = self.inputTextView.defaultTypingAttributes
        let range = NSRange(location: 0, length: string.length)
        mutableString.setAttributes(attributes, range: range)
        string.enumerateAttribute(.attachment, in: range, options: [], using: { raw, range, _ in
            if let custom = raw as? CustomTextAttachment {
                mutableString.replaceCharacters(in: range, with: NSAttributedString(attachment: custom))
            }
        })
        return mutableString
    }

    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        shouldAnimatePasteOf attributedString: NSAttributedString,
        to textRange: UITextRange) -> Bool {
        return false
    }
}

extension OldBaseKeyboardView {

    enum Cons {
        static var textFont: UIFont { UIFont.ud.body0 }
        static var buttonSize: CGSize { .square(32) }
        static var buttonHotspotSize: CGSize { .square(44) }
        static var textFieldMinHeight: CGFloat { 35.auto() }
        static var textFieldMaxHeight: CGFloat { 125 }
        static var textFieldTopMargin: CGFloat { 5 }
        static var buttonTopMargin: CGFloat {
            textFieldTopMargin + (textFieldMinHeight - buttonSize.height) / 2 - 2
        }
        static var macStyleTextFieldTopMargin: CGFloat { 0 }
        static var macStyleButtonTopMargin: CGFloat {
            macStyleTextFieldTopMargin + (textFieldMinHeight - buttonSize.height) / 2
        }
    }
}
