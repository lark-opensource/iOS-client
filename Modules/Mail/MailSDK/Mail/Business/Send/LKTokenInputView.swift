//
//  CLTokenInputView.swift
//  CLTokenInputView
//
//  Created by majx on 05/26/19 from CLTokenInputView-Swift by Robert La Ferla.
//  
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

protocol LKTokenInputViewDelegate: AnyObject {
    func tokenInputViewDidEndEditing(aView: LKTokenInputView)
    func tokenInputViewDidBeginEditing(aView: LKTokenInputView)
    func tokenInputViewShouldReturn(aView: LKTokenInputView)
    func tokenInputView(aView: LKTokenInputView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    func tokenInputView(aView: LKTokenInputView, didChangeText text: String?)
    func tokenInputView(aView: LKTokenInputView, didAddToken token: LKToken, isDragAction: Bool)
    func tokenInputView(aView: LKTokenInputView, didRemoveToken token: LKToken, index: Int)
    func tokenInputView(aView: LKTokenInputView, tokenForText text: String?) -> LKToken?
    func tokenInputView(aView: LKTokenInputView, didChangeHeightTo height: CGFloat)
    func tokenInputView(aView: LKTokenInputView, needShowTipAt tokenView: LKTokenView)
    func tokenInputView(aView: LKTokenInputView)
    func tokenInputView(aView: LKTokenInputView, didSelected tokenView: LKTokenView)
    func tokenInputView(unresignLeftKeymand aView: LKTokenInputView)
    func tokenInputView(unresignRightKeymand aView: LKTokenInputView)
    func tokenInputView(resignLeftKeymand aView: LKTokenInputView)
    func tokenInputView(resignRightKeymand aView: LKTokenInputView)
    /// drag drop
    func tokenInputView(aView: LKTokenInputView, didStartDragDrop tokenView: LKTokenView)
    func tokenInputView(aView: LKTokenInputView, didDrag tokenView: LKTokenView, focusAt target: LKTokenInputView)
    func tokenInputView(aView: LKTokenInputView, didDrag tokenView: LKTokenView, dropTo target: LKTokenInputView)
    func tokenInputView(aView: LKTokenInputView, didEndDragDrop tokenView: LKTokenView)
    /// contact search
    func tokenInputView(aView: LKTokenInputView, searchTextAddressInfo address: String) -> Observable<Bool>
    func ifViewWillDisappear() -> Bool
    func emailDomains() -> [String]?
}

// MARK: default imp
extension LKTokenInputViewDelegate {
    func tokenInputView(aView: LKTokenInputView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
}

class LKTokenInputView: UIView, LKBackspaceDetectingTextFieldDelegate, LKTokenViewDelegate {
    weak var delegate: LKTokenInputViewDelegate?
    var dragDropTargetInputViews: [WeakBox<LKTokenInputView>]?
    var dragingTokenView: LKTokenView?

    var didChangeTextObservable: PublishSubject<(LKTokenInputView, String?)> = PublishSubject<(LKTokenInputView, String?)>()

    var fieldLabel: UILabel = .init()
    var fieldView: UIView? {
        willSet {
            if self.fieldView != newValue {
                self.fieldView?.removeFromSuperview()
            }
        }

        didSet {
            if oldValue != self.fieldView {
                if self.fieldView != nil {
                    self.addSubview(self.fieldView!)
                }
                self.repositionViews()
            }
        }
    }
    var fieldName: String? {
        didSet {
            if oldValue != self.fieldName {
                self.fieldLabel.text = self.fieldName
                self.fieldLabel.sizeToFit()
                let showField: Bool = !self.fieldName!.isEmpty
                self.fieldLabel.isHidden = !showField
                if showField && self.fieldLabel.superview == nil {
                    self.addSubview(self.fieldLabel)
                } else if !showField && self.fieldLabel.superview != nil {
                    self.fieldLabel.removeFromSuperview()
                }

                if oldValue == nil || oldValue != self.fieldName {
                    self.repositionViews()
                }
            }

        }
    }
    var fieldFont: UIFont? {
        didSet {
            fieldLabel.font = fieldFont
        }
    }
    var textFont: UIFont? {
        didSet {
            textField.font = fieldFont
        }
    }
    var fieldColor: UIColor? {
        didSet {
            fieldLabel.textColor = fieldColor
        }
    }
    var placeholderText: String? {
        didSet {
            if oldValue != placeholderText {
                updatePlaceholderTextVisibility()
            }
        }
    }
    // 
    var accessoryView: UIView? {
        willSet {
            if self.accessoryView != newValue {
                self.accessoryView?.removeFromSuperview()
            }
        }

        didSet {
            if oldValue != self.accessoryView {
                if self.accessoryView != nil {
                    addSubview(self.accessoryView!)
                }
                repositionViews()
            }
        }
    }
    // 只会在成为firstResponder时出现，位于accessoryView的左边（如果有）
    var firstRespAccessoryView: UIView? {
        willSet {
            if self.firstRespAccessoryView != newValue {
                self.firstRespAccessoryView?.removeFromSuperview()
            }
        }

        didSet {
            if oldValue != self.firstRespAccessoryView {
                if self.firstRespAccessoryView != nil {
                    addSubview(self.firstRespAccessoryView!)
                }
                repositionViews()
            }
        }
    }

    var keyboardType: UIKeyboardType! {
        didSet {
            textField.keyboardType = keyboardType
        }
    }
    var autocapitalizationType: UITextAutocapitalizationType! {
        didSet {
            textField.autocapitalizationType = autocapitalizationType
        }
    }
    var autocorrectionType: UITextAutocorrectionType! {
        didSet {
            textField.autocorrectionType = autocorrectionType
        }
    }
    var highLightBackgroundView: UIView = .init()
    var showHighLight: Bool = false {
        didSet {
            highLightBackgroundView.isHidden = !showHighLight
        }
    }

    var tokenizationCharacters: Set<String> = Set<String>()
    var drawBottomBorder: Bool = false {
        didSet {
            if oldValue != self.drawBottomBorder {
                setNeedsDisplay()
            }
        }
    }

    /// Handle tap on TextField when TextField cursor hidden
    private var textFieldTapGesture: UITapGestureRecognizer?

    private var hideTextFieldCursor: Bool = false {
        didSet {
            textField.tintColor = hideTextFieldCursor ? .clear : .systemBlue
        }
    }

    var tokens: [LKToken] = []
    var tokenViews: [LKTokenView] = []
    var textField: LKBackspaceDetectingTextField
    var intrinsicContentHeight: CGFloat = 0
    var additionalTextFieldYOffset: CGFloat = 0
    var autoToken: Bool = true
    var disposeBag = DisposeBag()
    private var _countToken: LKToken?
    private var _countTokenView: LKTokenView?
    // 是否显示全部token
    var showAllTokens: Bool = false {
        didSet {
            if oldValue != showAllTokens {
                /// 重新布局
                repositionViews()
            }
        }
    }

    let HSPACE: CGFloat = 6.0
    let ACCESSORY_SPACE: CGFloat = 18.0
    let TEXT_FIELD_HSPACE: CGFloat = 5.0 // Note: Same as LKTokenView.PADDING_X
    let VSPACE: CGFloat = 6.0
    let MINIMUM_TEXTFIELD_WIDTH: CGFloat = 12.0
    let PADDING_TOP: CGFloat = 10.0
    let PADDING_BOTTOM: CGFloat = 12.0
    let PADDING_LEFT: CGFloat = 16.0
    let PADDING_RIGHT: CGFloat = 21.0
    let STANDARD_ROW_HEIGHT: CGFloat = 24.0
    let FIELD_MARGIN_X: CGFloat = 4.0
    let TOKEN_MIN_WIDTH: CGFloat = 44.0

    func commonInit() {
        self.backgroundColor = UIColor.ud.bgBody
        highLightBackgroundView = UIView(frame: self.bounds.insetBy(dx: 8, dy: 0))
        highLightBackgroundView.backgroundColor = UIColor.ud.bgBase
        highLightBackgroundView.isHidden = true
        highLightBackgroundView.clipsToBounds = true
        highLightBackgroundView.layer.cornerRadius = 8
        addSubview(highLightBackgroundView)

        textFieldTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didClickMe))
        textFieldTapGesture?.delegate = self
        textField = LKBackspaceDetectingTextField(frame: self.bounds)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor.clear
        textField.keyboardType = .emailAddress
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .sentences
        textField.delegate = self
        if let textFieldTapGesture = textFieldTapGesture {
            textField.addGestureRecognizer(textFieldTapGesture)
        }
        textField.addTarget(self, action: #selector(LKTokenInputView.onTextFieldDidChange(sender: )), for: .editingChanged)
        addSubview(textField)
        fieldLabel = UILabel(frame: .zero)
        fieldLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldLabel.font = textField.font
        fieldColor = UIColor.ud.textCaption
        fieldLabel.textColor = fieldColor
        fieldLabel.font = UIFont.systemFont(ofSize: 14.0)
        addSubview(fieldLabel)
        fieldLabel.isHidden = true

        intrinsicContentHeight = STANDARD_ROW_HEIGHT

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickMe))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }

    override init(frame: CGRect) {
        textField = LKBackspaceDetectingTextField(frame: .zero)
        super.init(frame: frame)
        textField.frame = bounds
        self.commonInit()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRemoveNotification(notification:)), name: lkTokenViewRemoveNotificationName, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mailAddressChange),
                                               name: Notification.Name.Mail.MAIL_ADDRESS_NAME_CHANGE,
                                               object: nil)
    }

    @objc
    func didReceiveRemoveNotification(notification: Notification) {
        guard let domains = delegate?.emailDomains() else { return }
        checkRemove(domains: domains)
    }
    @objc
    func mailAddressChange() {
        for tokenView in tokenViews {
            tokenView.mailAddressChange()
        }
        tokenViewDidUpdate()
    }

    func checkRemove(domains: [String]) {
        if let idx = tokens.firstIndex(where: { (token) -> Bool in
            return domains.first(where: { token.address.contains($0) }) == nil
        }) {
            removeTokenAtIndex(index: idx)
            checkRemove(domains: domains)
        }
    }

    /// 接收到点击，则进入编辑状态
    @objc
    func didClickMe() {
        if !isEditing || hideTextFieldCursor {
            beginEditing()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        textField = LKBackspaceDetectingTextField(frame: .zero)
        super.init(coder: aDecoder)
        textField.frame = bounds
        self.commonInit()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                          height: max(45, self.intrinsicContentHeight))
    }

    override func tintColorDidChange() {
        self.tokenViews.forEach { $0.tintColor = tintColor }
    }

    @discardableResult
    func addToken(token: LKToken,
                  _ delay: TimeInterval = 0,
                  shouldClearText: Bool = true,
                  isDragAction: Bool = false,
                  reposition: Bool = true) -> LKTokenView? {
        tokens.append(token)
        let tokenView: LKTokenView = LKTokenView(with: token, nil)
        tokenView.translatesAutoresizingMaskIntoConstraints = false
        tokenView.tintColor = tintColor
        tokenView.delegate = self
        tokenView.replaceNameIfNeed()

        if let window = self.window {
            tokenView.dragDropConfig.dragFloatView = window
            tokenView.dragDropConfig.targetInputViews = dragDropTargetInputViews
        }

        // 计算标签尺寸
        let intrinsicSize: CGSize = tokenView.intrinsicContentSize
        tokenView.frame = CGRect(x: 0.0, y: 0, width: min(intrinsicSize.width, TOKEN_MIN_WIDTH), height: intrinsicSize.height)
        tokenViews.append(tokenView)
        addSubview(tokenView)

        if shouldClearText {
            textField.text = ""
        }
        delegate?.tokenInputView(aView: self, didAddToken: token, isDragAction: isDragAction)
        onTextFieldDidChange(sender: textField)

        updatePlaceholderTextVisibility()
        if reposition {
            repositionViews()
        }
        tokenView.alpha = 0
        UIView.animate(withDuration: 0, delay: delay, animations: {
            tokenView.alpha = 1.0
        }) { (_) in
        }
        return tokenView
    }

    // 计数 token view
    func updateCountTokenView(count: Int) -> LKTokenView {
        if _countToken == nil {
            _countToken = LKToken()
        }
        _countToken?.forceDisplay = "+\(count)"
        if _countTokenView == nil {
            _countTokenView = LKTokenView(with: _countToken!, nil)
            _countTokenView?.translatesAutoresizingMaskIntoConstraints = false
            _countTokenView?.tintColor = tintColor
            _countTokenView?.isUserInteractionEnabled = false
            addSubview(_countTokenView!)
        }
        /// 更新token
        _countTokenView?.token = _countToken
        let intrinsicSize: CGSize = _countTokenView?.intrinsicContentSize ?? .zero
        _countTokenView?.frame = CGRect(x: 0.0, y: 0, width: max(intrinsicSize.width, TOKEN_MIN_WIDTH), height: intrinsicSize.height)
        return _countTokenView!
    }

    func removeTokenAtIndex(index: Int) {
        if index == -1 {
            return
        }
        guard let tokenView = tokenViews[safeIndex: index] else {
            return
        }
        tokenView.removeFromSuperview()
        tokenViews.remove(at: index)
        let removedToken = tokens[index]
        tokens.remove(at: index)
        delegate?.tokenInputView(aView: self, didRemoveToken: removedToken, index: index)
        updatePlaceholderTextVisibility()
        repositionViews()
    }

    func removeToken(token: LKToken) {
        if let index: Int = tokens.firstIndex(of: token) {
            removeTokenAtIndex(index: index)
        }
    }

    func removeAllToken() {
        let tokens = allTokens()
        for token in tokens {
            removeToken(token: token)
        }
    }

    func allTokens() -> [LKToken] {
        return Array(tokens)
    }

    func tokenizeTextfieldText() -> LKToken? {
        let token: LKToken? = nil
        if let text: String = self.text, !text.isEmpty {
            if let token = self.delegate?.tokenInputView(aView: self, tokenForText: text) {
                addToken(token: token)
                self.text = ""
                onTextFieldDidChange(sender: textField)
            }
        }

        return token
    }

    func repositionViews() {
        let bounds: CGRect = self.bounds
        let rightBoundary: CGFloat = bounds.width - PADDING_RIGHT
        var firstLineRightBoundary: CGFloat = rightBoundary
        var curX: CGFloat = PADDING_LEFT
        var curY: CGFloat = PADDING_TOP
        var totalHeight: CGFloat = STANDARD_ROW_HEIGHT
        var isOnFirstLine: Bool = true
        _countTokenView?.isHidden = true
        // Position field view (if set)
        if fieldView != nil {
            var fieldViewRect: CGRect = fieldView!.frame
            fieldViewRect.origin.x = curX
            fieldViewRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - fieldViewRect.height / 2.0)) - PADDING_TOP
            self.fieldView?.frame = fieldViewRect

            curX = fieldViewRect.maxX + FIELD_MARGIN_X
        }

        // Position field label (if field name is set)
        if !(fieldLabel.isHidden) {
            var fieldLabelRect: CGRect = self.fieldLabel.frame
            fieldLabelRect.origin.x = curX
            fieldLabelRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - fieldLabelRect.height / 2.0)) - PADDING_TOP - 2
            fieldLabel.frame = fieldLabelRect

            curX = fieldLabelRect.maxX + FIELD_MARGIN_X
        }

        // Position accessory view (if set)
        if accessoryView != nil {
            var accessoryRect: CGRect = accessoryView!.frame
            accessoryRect.origin.x = bounds.width - PADDING_RIGHT - accessoryRect.width
            accessoryRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - accessoryRect.height / 2.0)) - PADDING_TOP - 2
            accessoryView!.frame = accessoryRect

            firstLineRightBoundary = accessoryRect.minX - HSPACE
        }

        // Position accessory view (if set)
        if let view = firstRespAccessoryView {
            var rect = view.frame
            rect.origin.x = bounds.width - PADDING_RIGHT - rect.width + 2
            rect.origin.y = curY + ((STANDARD_ROW_HEIGHT - rect.height / 2.0)) - PADDING_TOP - 2
            if let rightView = accessoryView {
                rect.origin.x = rightView.frame.left - rect.width - ACCESSORY_SPACE
                rect.centerY = rightView.frame.centerY
            }
            view.frame = rect

            if !view.isHidden {
                firstLineRightBoundary = view.frame.minX - HSPACE
            }
        }

        // Position token views
        var tokenRect: CGRect = CGRect.null
        var needShowCountToken: Bool = false
        let firstLineX = curX
        for (index, tokenView) in tokenViews.enumerated() {
            if !showAllTokens && !isOnFirstLine {
                // 如果是折叠状态，只需要排版第一行
                tokenView.isHidden = true
                tokenView.clickEnable = false
                continue
            } else {
                tokenView.isHidden = false
                tokenView.clickEnable = true
            }
            tokenView.frame = CGRect(x: tokenView.frame.minX,
                                     y: tokenView.frame.minY,
                                     width: tokenView.intrinsicContentSize.width,
                                     height: tokenView.intrinsicContentSize.height)
            tokenRect = tokenView.frame
            /// 会有单个 tokenView 宽度就占满一行的情况，所以要确保 tokenViews.count > 1，才显示计数
            var tokenBoundary: CGFloat = isOnFirstLine ? firstLineRightBoundary : rightBoundary
            needShowCountToken = isOnFirstLine && tokenViews.count > 1 && !showAllTokens
            if needShowCountToken {
                let foldTokenCount = tokenViews.count - index
                let countTokenView = updateCountTokenView(count: foldTokenCount)
                tokenBoundary -= countTokenView.intrinsicContentSize.width
            }
            /// 限制 tokenView 的最大宽度，不超出一行
            var maxWidth = tokenBoundary - HSPACE
            if isOnFirstLine {
                maxWidth = tokenBoundary - HSPACE - firstLineX
            }
            tokenRect.size.width = min(maxWidth, tokenRect.size.width)
            tokenView.style.maxWidth = maxWidth
            /// 换行
            if curX + tokenRect.width > tokenBoundary && index > 0 {
                /// 当需要显示全部 token 的时候，继续添加下一行
                /// 否则只显示一行，并在结尾添加计数
                if needShowCountToken {
                    var countTokenRect = _countTokenView?.frame ?? .zero
                    countTokenRect.origin.x = curX
                    countTokenRect.origin.y = curY
                    _countTokenView?.frame = countTokenRect
                    _countTokenView?.isHidden = false
                }
                /// 新加一行
                curX = PADDING_LEFT
                curY += STANDARD_ROW_HEIGHT + VSPACE
                totalHeight += STANDARD_ROW_HEIGHT
                isOnFirstLine = false
            }

            tokenRect.origin.x = curX
            tokenRect.origin.y = curY + ((STANDARD_ROW_HEIGHT - tokenRect.height) / 2.0) + 0.5
            tokenView.frame = tokenRect

            /// 设置下一个tokenView的位置
            curX = tokenRect.maxX + HSPACE

            /// 只有展开后，tokenView 才可以点击选择
            if showAllTokens {
                tokenView.clickEnable = true
                tokenView.isHidden = false
            } else {
                tokenView.clickEnable = false
                /// 折叠后，只显示第一行的内容
                tokenView.isHidden = !isOnFirstLine
            }
            if let dragingTokenView = dragingTokenView {
                tokenView.token.selected = tokenView == dragingTokenView
                tokenView.updateStatus()
            }
            tokenView.updateBgColor()
        }

        // Always indent textfield by a little bit
        curX += TEXT_FIELD_HSPACE
        let textBoundary: CGFloat = isOnFirstLine ? firstLineRightBoundary : rightBoundary
        var availableWidthForTextField: CGFloat = textBoundary - curX
        if availableWidthForTextField < MINIMUM_TEXTFIELD_WIDTH {
            isOnFirstLine = false
            curX = PADDING_LEFT + TEXT_FIELD_HSPACE
            curY += STANDARD_ROW_HEIGHT + VSPACE
            totalHeight += STANDARD_ROW_HEIGHT
            // Adjust the width
            availableWidthForTextField = rightBoundary - curX
        }

        var textFieldRect: CGRect = textField.frame
        textFieldRect.origin.x = curX
        textFieldRect.origin.y = curY + additionalTextFieldYOffset
        textFieldRect.size.width = availableWidthForTextField
        textFieldRect.size.height = STANDARD_ROW_HEIGHT
        let width = textField.text?.getTextWidth(fontSize: textField.font?.pointSize ?? 18, height: STANDARD_ROW_HEIGHT) ?? 0.0
        // 需要换行处理
        if width > 0 && width > availableWidthForTextField {
            textFieldRect.origin.x = PADDING_LEFT
            textFieldRect.origin.y = curY + STANDARD_ROW_HEIGHT + VSPACE + additionalTextFieldYOffset
            textFieldRect.size.width = rightBoundary
            textFieldRect.size.height = STANDARD_ROW_HEIGHT
        }
        textField.frame = textFieldRect

        let oldContentHeight: CGFloat = intrinsicContentHeight

        if showAllTokens {
            intrinsicContentHeight = textFieldRect.maxY + PADDING_BOTTOM
        } else {
            intrinsicContentHeight = STANDARD_ROW_HEIGHT + PADDING_TOP + PADDING_BOTTOM
        }
        invalidateIntrinsicContentSize()

        if oldContentHeight != intrinsicContentHeight {
            delegate?.tokenInputView(aView: self, didChangeHeightTo: intrinsicContentSize.height)
        }

        setNeedsDisplay()
        highLightBackgroundView.frame = self.bounds.insetBy(dx: 8, dy: 0)
    }

    func updatePlaceholderTextVisibility() {
        if tokens.isEmpty, let text = placeholderText, !text.isEmpty {
            textField.attributedPlaceholder = NSAttributedString(
                string: text,
                attributes: [.foregroundColor: UIColor.ud.textPlaceholder]
            )
        } else {
            textField.attributedPlaceholder = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        repositionViews()
    }

    // MARK: LKBackspaceDetectingTextFieldDelegate
    func textFieldDidDeleteBackwards(textField: UITextField) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if let selectedTokenView = strongSelf.tokenViews.first(where: { $0.selected }) {
                strongSelf.tokenViewDidRequestDelete(tokenView: selectedTokenView, replaceWithText: nil)
            } else if textField.text?.isEmpty ?? false {
                if let tokenView: LKTokenView = strongSelf.tokenViews.last {
                    strongSelf.selectTokenView(tokenView: tokenView, animated: true)
                    strongSelf.hideTextFieldCursor = true
                }
            }
        }
    }

    func textFieldDidPaste() {
        delegate?.tokenInputView(aView: self)
    }

    func textFieldDidSelectAll() {
    }

    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.tokenInputViewDidBeginEditing(aView: self)
        unselectAllTokenViewsAnimated(animated: true)
        showAllTokens = true

        self.firstRespAccessoryView?.isHidden = false
        repositionViews()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.tokenInputViewDidEndEditing(aView: self)
        unselectAllTokenViewsAnimated(animated: true)
        // 如果是vc将消失导致的隐藏键盘，不收起token
        if let viewWillDisappear = delegate?.ifViewWillDisappear(), !viewWillDisappear {
            showAllTokens = false
        }
        if self.autoToken == true {
            _ = tokenizeTextfieldText()
        }
        self.firstRespAccessoryView?.isHidden = true
        repositionViews()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /// if text is empty, call delegate's tokenInputViewShouldReturn
        if let delegate = delegate, textField.text?.isEmpty ?? true {
            delegate.tokenInputViewShouldReturn(aView: self)
        }
        if let text = textField.text {
            self.delegate?
                .tokenInputView(aView: self, searchTextAddressInfo: text)
                .timeout(.seconds(1), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] flag in
                if !flag {
                    _ = self?.tokenizeTextfieldText()
                }
            }, onError: { [weak self] error in
                _ = self?.tokenizeTextfieldText()
            }).disposed(by: disposeBag)
        }
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.isEmpty && tokenizationCharacters.contains(string) {
            _ = tokenizeTextfieldText()
            return false
        }
        if let selectedTokenView = tokenViews.first(where: { $0.selected }) {
            tokenViewDidModifiy(tokenView: selectedTokenView, replaceWithText: string)
        }
        return delegate?.tokenInputView(aView: self, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }

    @objc
    func onTextFieldDidChange(sender: UITextField) {
        if (self.textField.text.isEmpty) {
            delegate?.tokenInputView(resignLeftKeymand: self)
            delegate?.tokenInputView(resignRightKeymand: self)
        } else {
            delegate?.tokenInputView(unresignLeftKeymand: self)
            delegate?.tokenInputView(unresignRightKeymand: self)
        }
        didChangeTextObservable.onNext((self, text))
        _ = delegate?.tokenInputView(aView: self, didChangeText: text)
    }

    var text: String? {
        get {
            return self.textField.text
        }
        set {
            self.textField.text = newValue
        }
    }
    
    func tokenViewDidModifiy(tokenView: LKTokenView, replaceWithText replacementText: String?) {
        textField.becomeFirstResponder()
        hideTextFieldCursor = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        guard let index: Int = tokenViews.firstIndex(of: tokenView) else {
            return
            }
            self.removeTokenAtIndex(index: index)
    }

    func tokenViewDidRequestDelete(tokenView: LKTokenView, replaceWithText replacementText: String?) {
        self.becomeFirstResponder()
        guard let index: Int = tokenViews.firstIndex(of: tokenView) else {
            return
        }
        
        self.removeTokenAtIndex(index: index)
        self.selectTokenView(at: index-1, animated: true)
    }

    func tokenViewDidRequestSelection(tokenView: LKTokenView) {
    
        /// if tokenView is selected, click again show tip
        if tokenView.selected {
            /// if is group address, show '暂不支持显示聊天群地址' tip
            /// else show address tip
            delegate?.tokenInputView(aView: self, needShowTipAt: tokenView)
        }
        hideTextFieldCursor = true
        selectTokenView(tokenView: tokenView, animated: true)
        delegate?.tokenInputView(aView: self, didSelected: tokenView)
    }

    func selectTokenView(tokenView: LKTokenView, animated aBool: Bool) {
        tokenView.setSelected(selectedBool: true, animated: aBool)
        for otherTokenView: LKTokenView in tokenViews where otherTokenView != tokenView {
            otherTokenView.setSelected(selectedBool: false, animated: aBool)
        }
    }

    func selectTokenView(at index: Int, animated aBool: Bool) {
        if index >= 0 && index < tokenViews.count {
            let tokenView = tokenViews[index]
            tokenView.setSelected(selectedBool: true, animated: aBool)
        }
    }

    func unselectAllTokenViewsAnimated(animated: Bool) {
        for tokenView: LKTokenView in tokenViews {
            tokenView.setSelected(selectedBool: false, animated: animated)
        }
    }

    var isEditing: Bool {
        return textField.isEditing
    }

    func beginEditing() {
        textField.becomeFirstResponder()
        hideTextFieldCursor = false
        unselectAllTokenViewsAnimated(animated: false)
        if (self.textField.text.isEmpty) {
            delegate?.tokenInputView(resignLeftKeymand: self)
        } else {
            delegate?.tokenInputView(unresignLeftKeymand: self)
            delegate?.tokenInputView(unresignRightKeymand: self)
        }
    }

    func endEditing() {
        textField.resignFirstResponder()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if drawBottomBorder {
            if let context: CGContext = UIGraphicsGetCurrentContext() {
                let mWidth = bounds.width
                let mHeight = bounds.height
                context.setStrokeColor(UIColor.ud.lineBorderCard.cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: mWidth, y: mHeight))
                context.addLine(to: CGPoint(x: mWidth, y: mHeight))
                context.strokePath()
            }
        }
    }
    
    // MARK: - left & right
    func selectPreToken() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if let selectedTokenView = strongSelf.tokenViews.first(where: { $0.selected }) { // 有选中的标签
                guard let index: Int = strongSelf.tokenViews.firstIndex(of: selectedTokenView) else {
                    return
                }
                if index == 0 {
                    return
                }
                selectedTokenView.setSelected(selectedBool: false, animated: true)
                strongSelf.selectTokenView(at: index - 1, animated: true)
            } else { // 无选中标签
                if strongSelf.textField.text.isEmpty {
                    let count = strongSelf.tokenViews.count
                    if count == 0 {
                        return
                    }
                    strongSelf.selectTokenView(at: count - 1, animated: true)
                    strongSelf.hideTextFieldCursor = true
                }
            }
            
        }
    }
    
    func selectNextToken() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if let selectedTokenView = strongSelf.tokenViews.first(where: { $0.selected }) {
                guard let index: Int = strongSelf.tokenViews.firstIndex(of: selectedTokenView) else {
                    return
                }
                if index + 1 == strongSelf.tokenViews.count {
                    strongSelf.beginEditing()
                    strongSelf.hideTextFieldCursor = false
                }
                if index + 1 > strongSelf.tokenViews.count {
                    return
                }
                selectedTokenView.setSelected(selectedBool: false, animated: true)
                strongSelf.selectTokenView(at: index + 1, animated: true)
            }
        }
    }

    // MARK: - Drag & Drop
    func tokenViewDidStartDragDrop(tokenView: LKTokenView) {
        dragingTokenView = tokenView
        beginEditing()
        selectTokenView(tokenView: tokenView, animated: true)
        delegate?.tokenInputView(aView: self, didStartDragDrop: tokenView)
    }

    func tokenViewDidDragFocus(at target: LKTokenInputView, tokenView: LKTokenView) {
        delegate?.tokenInputView(aView: self, didDrag: tokenView, focusAt: target)
        target.beginEditing()
    }

    func tokenViewDidDragDrop(to target: LKTokenInputView, tokenView: LKTokenView) -> LKTokenView? {
        delegate?.tokenInputView(aView: self, didDrag: tokenView, dropTo: target)
        if let token = tokenView.token {
            removeToken(token: token)
            target.showHighLight = false
            //target.beginEditing()
            if let tokenView = target.addToken(token: token, 0.25, isDragAction: true) {
                target.endEditing()
                target.selectTokenView(tokenView: tokenView, animated: true) 
                return tokenView
            }
        }
        return nil
    }

    func tokenViewDidEndDragDrop(target: LKTokenInputView?, tokenView: LKTokenView) {
        dragingTokenView = nil
        if target == nil {
            beginEditing()
            unselectAllTokenViewsAnimated(animated: true)
            //selectTokenView(tokenView: tokenView, animated: true)
        }
        delegate?.tokenInputView(aView: self, didEndDragDrop: tokenView)
    }
    func tokenViewDidUpdate() {
        repositionViews()
    }
}

extension LKTokenInputView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if textFieldTapGesture == gestureRecognizer {
            return hideTextFieldCursor
        }
        return true
    }
}
