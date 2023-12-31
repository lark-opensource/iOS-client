//
//  BaseKeyboardView.swift
//  Lark
//
//  Created by lichen on 2018/1/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import EditTextView
import LarkKeyCommandKit
import LarkInteraction
import LKCommonsLogging

public class EditTextViewLogger: EditTextViewLog {
    static let logger = Logger.log(EditTextViewLogger.self, category: "EditTextViewLog")

    public func debug(message: String, params: [String : String]?) {
        Self.logger.debug(message, additionalData: params)
    }

    public func info(message: String, params: [String : String]?) {
        Self.logger.debug(message, additionalData: params)

    }

    public func warn(message: String, params: [String : String]?) {
        Self.logger.debug(message, additionalData: params)

    }

    public func error(message: String, params: [String : String]?) {
        Self.logger.debug(message, additionalData: params)
    }

    public init() {}
}

/**
 LKKeyboardView 为以及基础的UI组件，不包含任何的业务逻辑，基本功能
 1. 提供了一套通用的UI样式，业务放可以继承后自定定制
 2. 提供一些快捷的方法&回调，方便业务使用
 3. 将textView & panel绑定，业务方无需感受到panel的存在
 如果LKKeyboardView不满足需求，建议使用textview & panel直接组合
 */

public protocol LKKeyboardViewDelegate: AnyObject {
    func inputTextViewBeginEditing()
    func keyboardframeChange(frame: CGRect)
    func inputTextViewFrameChange(frame: CGRect)
    func inputTextViewDidChange(input: LKKeyboardView)
    /// 插入图片，返回值是 是否应该继续向输入框插入图片，默认为 返回 false 的空实现
    func inputTextViewWillInput(image: UIImage) -> Bool
    func keyboardContentHeightWillChange(_ isFold: Bool)
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString?
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                          transform item: UITextPasteItem) -> Bool
    func replaceViewWillChange(_ view: UIView?)
}

public protocol KeyboardFoldProtocol {
    func fold()
}

public struct InputAreaStyle {

    static public func empty() -> InputAreaStyle {
        return InputAreaStyle(inputWrapperMargin: 0, inputCanvasInset: .zero, inputStackInset: .zero)
    }

    let inputWrapperMargin: CGFloat
    let inputCanvasInset: UIEdgeInsets
    let inputStackInset: UIEdgeInsets

    public init(inputWrapperMargin: CGFloat,
                inputCanvasInset: UIEdgeInsets,
                inputStackInset: UIEdgeInsets) {
        self.inputWrapperMargin = inputWrapperMargin
        self.inputCanvasInset = inputCanvasInset
        self.inputStackInset = inputStackInset
    }
}

public extension LKKeyboardViewDelegate {
    func inputTextViewWillInput(image: UIImage) -> Bool { false }
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
                                          for textRange: UITextRange) -> NSAttributedString? { return nil }
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                          transform item: UITextPasteItem) -> Bool { return false }
}

public struct KeyboardLayouConfig {
    let padStyle: InputAreaStyle
    let phoneStyle: InputAreaStyle

    public init(phoneStyle: InputAreaStyle,
                padStyle: InputAreaStyle) {
        self.phoneStyle = phoneStyle
        self.padStyle = padStyle
    }
}

open class LKKeyboardView: UIControl,
                                KeyboardPanelDelegate,
                                UITextViewDelegate,
                             EditTextViewTextDelegate {
    /// 是否使用 mac 风格输入框样式，目前默认 iPad 设备此参数为 true
    public private(set) var macInputStyle: Bool = Display.pad

    /// 开放区域，业务可以自行放置View default: make.height.equalTo(0)
    public let inputFooterView = UIView()

    open var placeholderTextAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textPlaceholder,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byTruncatingTail
                return paragraphStyle
            }()
        ]
    }

    open weak var delegate: LKKeyboardViewDelegate?

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

    public var keyboardContentIsFold: Bool {
        return self.keyboardPanel.contentHeight == 0
    }

    // ui 容器View 放置输入框等
    open var controlContainer: UIView = .init()

    open fileprivate(set) var inputTextView: LarkEditTextView = {
        var inputTextView = LarkEditTextView(config: LarkEditTextView.Config(log: EditTextViewLogger()))
        inputTextView.isScrollEnabled = false
        inputTextView.placeholder = BundleI18n.LarkKeyboardView.Lark_Legacy_Windowboxhint
        inputTextView.placeholderTextColor = UIColor.ud.textPlaceholder
        inputTextView.font = Cons.textFont
        inputTextView.contentInset = .zero
        inputTextView.textColor = UIColor.ud.textTitle
        return inputTextView
    }()

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

    open var keyboardPanel: KeyboardPanel!

    /// items整体是否支持点击
    public private(set) var subViewsEnable: Bool = true
    /// 不支持点击的items
    public var disableItems: Set<String> = []

    /// 处理频繁的操作
    private var debouncer: Debouncer = Debouncer()

    /// 代替 ContainerStackView 的位置
    /// 调用replaceKeyboardContentViewTo(view: UIView)方法将 ContainerStackView 替换掉
    /// 调用recoverKeyboardContentView()将 ContainerStackView 还原
    public private(set) weak var replaceView: UIView?

    open func setSubViewsEnable(enable: Bool) {
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
                config: KeyboardLayouConfig,
                keyboardNewStyleEnable: Bool = false) {
        super.init(frame: frame)
        self.keyboardNewStyleEnable = keyboardNewStyleEnable
        self.configInputTextView()
        self.configKeyboardView()
        self.configInputStackWrapper(config)
        self.configControlContainer()
        self.configControlContainerSubViews()
        inputStackView.addArrangedSubview(inputFooterView)
        //默认footer不展示
        inputFooterView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        inputFooterView.clipsToBounds = true
        self.configKeyboardPanel()
        self.addObservers()
        self.updatePlaceholder(placeholder: BundleI18n.LarkKeyboardView.Lark_Legacy_Windowboxhint)
    }

    /// 配置TextView
    open func configInputTextView() {
        inputTextView.textContainerInset = UIEdgeInsets(top: 0, left: inputTextView.textContainerInset.left, bottom: 0, right: inputTextView.textContainerInset.right)
        inputTextView.maxHeight = 90
        inputTextView.defaultTypingAttributes = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.backgroundColor = UIColor.ud.bgBody

        // 输入框
        inputTextView.pasteDelegate = self
        inputTextView.delegate = self
        inputTextView.textDelegate = self
        if !keyboardNewStyleEnable {
            inputTextView.returnKeyType = .send
            inputTextView.enablesReturnKeyAutomatically = true
        }
    }

    /// 配置mac上的样式
    open func configInputStackWrapper(_ config: KeyboardLayouConfig) {
        /// 这里抽个macInputStyle config就可以了
        let inputWrapperInset: CGFloat = macInputStyle ? config.padStyle.inputWrapperMargin : config.phoneStyle.inputWrapperMargin
        let inputCanvasInset: UIEdgeInsets = macInputStyle ? config.padStyle.inputCanvasInset : config.phoneStyle.inputCanvasInset
        let inputStackInset: UIEdgeInsets = macInputStyle ? config.padStyle.inputStackInset : config.phoneStyle.inputStackInset
        if macInputStyle {
            inputStackCanvas.layer.cornerRadius = 8
            inputStackCanvas.backgroundColor = UIColor.ud.bgBodyOverlay
            inputStackCanvas.ud.setLayerBorderColor(UIColor.ud.N300)
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
    }

    /// 配置KeyboardView
    open func configKeyboardView() {
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        containerStackView.axis = .vertical
        containerStackView.spacing = 0
        containerStackView.alignment = .center
        addSubview(containerStackView)
        recoverKeyboardContentView()
    }

    /// 配置controlContainer区域的内容, 业务放如果不满足，override后自行定制
    open func configControlContainerSubViews() {
        self.controlContainer.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 8))
        }
    }

    open func configControlContainer() {
        // 输入wrapper
        let controlContainer = UIView()
        inputStackView.addArrangedSubview(controlContainer)
        controlContainer.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.controlContainer = controlContainer
    }

    open func initKeyboardPanel() {
        self.keyboardPanel = KeyboardPanel()
    }

    open func configKeyboardPanel() {
        self.initKeyboardPanel()
        self.keyboardPanel.buttonSpace = 32
        self.keyboardPanel.keyboardNewStyleEnable = keyboardNewStyleEnable
        self.keyboardPanel.delegate = self
        self.keyboardPanel.iconHitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        containerStackView.addArrangedSubview(keyboardPanel)
        keyboardPanel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// kVO监听bounds的变化
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
        } else if object is LKKeyboardView {
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
            self.reloadSendButton()
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

    /// 工具方法
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

    /// TODO: 李洛斌
    /// 1. 这个地方 keyboardNewStyleEnable 将来不应该存在
    /// 2. reloadSendButton() 将来也应该尝试干掉
    open func reloadSendButton() {
        if keyboardNewStyleEnable {
            self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
        }
    }

    public func sendPostEnable() -> Bool {
        let content = self.inputTextView.text?.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail) ?? ""
        return !content.isEmpty
    }

    open func fold() {
        if let replaceView = replaceView, let pro = replaceView as? KeyboardFoldProtocol {
            self.endEditing(true)
            pro.fold()
        } else {
            self.foldContainerStackView()
        }
    }

    private func foldContainerStackView() {
        self.endEditing(true)
        self.containerStackView.subviews.forEach { view in
            if !view.isHidden, let pro = view as? KeyboardFoldProtocol {
                pro.fold()
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if let replaceView = self.replaceView {
            self.bringSubviewToFront(replaceView)
        }
    }

    /// 替换键盘内容 替换完成后 键盘上所有的view都会被隐藏
    /// - Parameter view: 需要替换的view
    public func replaceKeyboardContentViewTo(view: UIView, foldKeyboardIfNeeded: Bool = true) {
        if self.replaceView != nil {
            self.replaceView?.removeFromSuperview()
        }
        self.delegate?.replaceViewWillChange(view)
        self.replaceView = view
        if foldKeyboardIfNeeded {
            self.foldContainerStackView()
        }
       self.containerStackView.snp.removeConstraints()
       self.containerStackView.isHidden = true
       self.addSubview(view)
       view.snp.makeConstraints { (make) in
           make.edges.equalToSuperview()
       }
    }

    /// 回复最初键盘最初的样子，如果之前有替换的view 将会被移除
    public func recoverKeyboardContentView() {
        self.delegate?.replaceViewWillChange(nil)
        self.replaceView?.removeFromSuperview()
        self.replaceView = nil
        containerStackView.isHidden = false
        containerStackView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
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
        self.keyboardPanel.contentWrapper.backgroundColor = key == KeyboardItemKey.picture.rawValue ? UIColor.ud.bgBody : .clear
    }

    open func keyboardView(index: Int, key: String) -> (UIView, Float) {
        let item = self.items[index]
        let height = item.keyboardHeightBlock()
        if let keyboardView = self.keyboardViewCache[index] {
            return (keyboardView, height)
        }
        let keyboardView = item.keyboardViewBlock()
        self.keyboardViewCache[index] = keyboardView
        return (keyboardView, height)
    }

    open func keyboardContentHeightWillChange(_ height: Float) {
        self.superview?.layoutIfNeeded()
        self.delegate?.keyboardContentHeightWillChange(height == 0)
        for (idx, item) in self.items.enumerated() {
            if let keyboardView = self.keyboardViewCache[idx] {
                item.keyboardStatusChange?(keyboardView, height == 0)
            }
        }
    }

    public func closeKeyboardPanel() {
        self.keyboardPanel.contentWrapper.backgroundColor = .clear
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

    /// panel的代理方法
    open func didLayoutPanelIcon() {}
    open func keyboardIconViewCustomization(index: Int, key: String, iconView: UIView) { }
    open func keyboardContentHeightDidChange(_ height: Float) { }

    // UITextViewDelegate
    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.textViewInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
  
    open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }
        
    open func textViewDidChange(_ textView: UITextView) {
        self.textViewInputProtocolSet.textViewDidChange(textView)
        reloadSendButton()
    }

    @objc
    func insertLineFeedCode() {
        self.inputTextView.insertText("\n")
    }

    open func updatePlaceholder(placeholder: String) {
        let attributedPlaceholder = NSMutableAttributedString(
            string: placeholder,
            attributes: placeholderTextAttributes)
        self.inputTextView.attributedPlaceholder = attributedPlaceholder
    }
}

extension LKKeyboardView: UITextPasteDelegate {
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
        } else if !(self.delegate?.textPasteConfigurationSupporting(textPasteConfigurationSupporting, transform: item) == true) {
            item.setDefaultResult()
        }
    }

    /// 粘贴的时候调用
    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
        guard !itemStrings.isEmpty else {
            return NSAttributedString()
        }
        if let attr = self.delegate?.textPasteConfigurationSupporting(textPasteConfigurationSupporting,
                                                                      combineItemAttributedStrings: itemStrings,
                                                                      for: textRange) {
                return attr
        }
        /// 粘贴的文字 不携带特殊样式
        var attributes: [NSAttributedString.Key: Any] = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        /// 如果defaultTypingAttributes当前有段落样式 需要应用
        attributes[.paragraphStyle] = inputTextView.defaultTypingAttributes[.paragraphStyle]
        let transform: (NSAttributedString) -> NSAttributedString = { [weak self] (attr) in
            guard let self = self else {
                return NSAttributedString()
            }
            let range = NSRange(location: 0, length: attr.length)
            let mutableString = NSMutableAttributedString(attributedString: attr)
            mutableString.setAttributes(attributes, range: range)
            attr.enumerateAttribute(.attachment, in: range, options: [], using: { raw, range, _ in
                if let custom = raw as? CustomTextAttachment {
                    mutableString.replaceCharacters(in: range, with: NSAttributedString(attachment: custom))
                }
            })
            return mutableString
        }
        let muAttr = NSMutableAttributedString()
        itemStrings.forEach { attr in
            muAttr.append(transform(attr))
        }
        return muAttr
    }

    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        shouldAnimatePasteOf attributedString: NSAttributedString,
        to textRange: UITextRange) -> Bool {
        return false
    }
}

public extension LKKeyboardView {
    enum Cons {
        public static var textFont: UIFont { UIFont.ud.body0 }
    }
}
