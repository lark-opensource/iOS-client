// 
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
// 
// Description: 支持编辑的 text field，比如 text、number 类型，5.13 版本上 URL 类型


import SKUIKit
import SKFoundation
import SKBrowser
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import LarkEMM

class BTBaseTextField: BTBaseField, BTTextViewDelegate, UITextViewDelegate, BTFieldTextCellProtocol {

    var isShowCustomMenuViewWhenLongPress: Bool = false
    
    ///光标距离textView底部的距离
    var cursorBootomOffset: CGFloat = 0
    ///键盘上方其它view的高度
    var heightOfContentAboveKeyBoard: CGFloat = 0
    
    lazy var textView = BTTextView().construct { it in
        it.btDelegate = self
        it.delegate = self
        it.pasteDelegate = self
        it.bounces = false
        //设置为0会导致换行时滚动到最底部
        it.textContainer.lineFragmentPadding = 0.000_001
        it.isScrollEnabled = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.font = UIFont.systemFont(ofSize: 14)
        it.textContainerInset = BTFieldLayout.Const.normalTextContainerInset
        var attrs = BTUtil.getFigmaHeightAttributes(font: UIFont.systemFont(ofSize: 14), alignment: .left)
        attrs[.foregroundColor] = UDColor.textTitle
        it.typingAttributes = attrs
    }

    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(textView)
        textView.snp.makeConstraints { it in
            it.edges.equalToSuperview()
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(showCustomMenusIfNeed))
        containerView.addGestureRecognizer(longPressGesture)
    }
    
    func setupStyleInStage() {
        if fieldModel.isPrimaryField {
            textView.textContainerInset = BTFieldLayout.Const.textContainerInsetInStageOfPrimaryField
            let font = BTFieldLayout.Const.primaryTextFieldFontInStage
            let placeHolderColor = UDColor.primaryPri900.withAlphaComponent(0.7)
            textView.placeholderLabel.textColor = placeHolderColor
            textView.placeholderLabel.font = font
            textView.enablePlaceHolder(enable: true)
        } else {
            // 恢复原来的样式
            textView.textContainerInset = BTFieldLayout.Const.normalTextContainerInset
            textView.enablePlaceHolder(enable: false)
        }
    }
    
    func setupCustomTypingAttributtes() {
        if fieldModel.isPrimaryField {
            let font = BTFieldLayout.Const.primaryTextFieldFontInStage
            let textColor = UDColor.primaryPri900
            var typingAttributes = BTUtil.getFigmaHeightAttributes(font: font, alignment: .left)
            typingAttributes[.foregroundColor] = textColor
            textView.typingAttributes = typingAttributes
        } else {
            // 正常状态需要reset
            var attrs = BTUtil.getFigmaHeightAttributes(font: UIFont.systemFont(ofSize: 14), alignment: .left)
            attrs[.foregroundColor] = UDColor.textTitle
            textView.typingAttributes = attrs
        }
    }

    // MARK: BTTextViewDelegate
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        let attributes = BTUtil.getAttributes(in: textView, sender: sender)
        if !attributes.isEmpty {
            delegate?.didTapView(withAttributes: attributes, inFieldModel: fieldModel)
        } else {
            showUneditableToast()
        }
    }
    
    func btTextView(_ textView: BTTextView, didDoubleTapped sender: UITapGestureRecognizer) {
        delegate?.didDoubleTap(self, field: fieldModel)
    }
    
    func btTextViewDidOpenUrl() { }
    
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(fieldModel, shouldAppyAction: action) ?? false
    }
    
    func btTextViewDidScroll(toBounce: Bool) {
        delegate?.setRecordScrollEnable(toBounce)
    }
    
    /// 获取光标位置String(describing: )
    func getCursorRect() -> CGRect? {
        if let cursorPosition = textView.selectedTextRange?.start {
            return textView.caretRect(for: cursorPosition)
        } else {
            return nil
        }
    }
    
    func setCursorBootomOffset() {
        guard let cursorRect = getCursorRect() else {
            return
        }

        cursorBootomOffset = textView.bounds.height - cursorRect.maxY - textView.contentOffset.y + textView.textContainerInset.top - textView.textContainerInset.bottom
        cursorBootomOffset = max(0, cursorBootomOffset)
        DocsLogger.btInfo("[BTBaseTextField] setCursorBootomOffset:\(cursorBootomOffset)")
    }
    
    func stopEditing() {
        DocsLogger.btInfo("[BTBaseTextField] stopEditing do nothing in super!")
    }

    // MARK: URL、NSTextAttachment 交互
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // 关掉 attachment 的长按交互
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.startRecordContentOffset()
    }

    // MARK: 文本编辑

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return fieldModel.editable
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        updateBorderMode(.editing)
        textView.reloadInputViews()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateBorderMode(.normal)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 留给子类实现
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        // 留给子类实现
        return
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        // 留给子类实现
        return
    }
}

// MARK: UITextPasteDelegate
extension BTBaseTextField: UITextPasteDelegate {
    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                          shouldAnimatePasteOf attributedString: NSAttributedString,
                                          to textRange: UITextRange) -> Bool {
        return false
    }
}

// MARK: 当字段不可手动编辑的时候长按显示气泡菜单。原因：需要有个可以清除的按钮来允许用户清除内容。
extension BTBaseTextField {
    
    override var canBecomeFirstResponder: Bool {
        return isShowCustomMenuViewWhenLongPress
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) { return true }
        if action == #selector(clearContent), fieldModel.editable {
            return true
        }
        return false
    }
    
    override func copy(_ sender: Any?) {
        guard delegate?.textViewOfField(fieldModel, shouldAppyAction: .copy) ?? false else {
            return
        }
        copyContent()
    }
    
    @objc
    private func showCustomMenusIfNeed(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard isShowCustomMenuViewWhenLongPress else { return }
        guard !textView.text.isEmpty else { return }
        self.becomeFirstResponder()
        let deleteItem = UIMenuItem(title: BundleI18n.SKResource.Bitable_Common_ClearButton, action: #selector(clearContent))
        UIMenuController.shared.menuItems = [deleteItem]
        UIMenuController.shared.docs.showMenu(from: self.containerView, rect: self.containerView.bounds)
    }
    
    @objc
    func clearContent() {
        spaceAssertionFailure("subclass should impl this method")
    }
    
    @objc
    func copyContent() {
        SCPasteboard.generalPasteboard().string = self.textView.text
        UDToast.showTips(with: BundleI18n.SKResource.Bitable_Common_CopiedToClipboard, on: self.window ?? self)
    }
}
