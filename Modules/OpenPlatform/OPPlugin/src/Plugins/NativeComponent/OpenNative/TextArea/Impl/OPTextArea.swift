//
//  OPTextArea.swift
//  OPPlugin
//
//  Created by zhujingcheng on 7/3/23.
//

import Foundation
import OPPluginManagerAdapter
import TTMicroApp
import OPFoundation
import LarkWebViewContainer
import LarkSetting

protocol OPTextAreaComponentDelegate: AnyObject {
    func onFocus(params: OpenNativeTextAreaFocusResult)
    func onBlur(params: OpenNativeTextAreaBlurResult)
    func onLineChange(params: OpenNativeTextAreaLineChangeResult)
    func onInput(params: OpenNativeTextAreaInputResult)
    func onConfirm(params: OpenNativeTextAreaConfirmResult)
    func onKeyboardHeightChange(params: OpenNativeTextAreaKeyboardHeightChangeResult)
}

final class OPTextArea: UITextView, UITextViewDelegate, OPComponentKeyboardDelegate, LKNativeRenderDelegate {
    var renderState = RenderState()
    
    private var componentID = ""
    private weak var componentDelegate: OPTextAreaComponentDelegate?
    private var keyboardHelper: OPComponentKeyboardHelper
    private var model: OpenNativeTextAreaParams
    private weak var webView: LarkWebView?
    private var trace: OPTrace
    private lazy var placeHolderView: UITextView = {
        let view = UITextView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        addSubview(view)
        return view
    }()
    private lazy var confirmBar: UIToolbar = {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: bounds.height, height: 44))
        let frontBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let centerBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: BundleI18n.OPPlugin.microapp_m_keyboard_done, style: .done, target: self, action: #selector(dismissKeyboard))
        bar.items = [frontBtn, centerBtn, doneBtn]
        return bar
    }()
    
    private var defaultLineFragmentPadding: CGFloat = 5.0
    private var defaultTextContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    private var textHeight: CGFloat = 0
    private var cacheLineCount: Int = 0
    private var keyboardAnimDuration: Double = 0.25
    
    private lazy var heightUpdateFix = {
        OPSettings(key: .make(userKeyLiteral: "op_textarea_settings"), tag: "height_update_fix", defaultValue: false).getValue()
    }()
    
    private lazy var maxLengthPrefixEnable = {
        OPSettings(key: .make(userKeyLiteral: "op_textarea_settings"), tag: "maxlength_prefix_enable", defaultValue: false).getValue()
    }()
    
    private lazy var layoutManagerLineCountFix = {
        OPSettings(key: .make(userKeyLiteral: "op_textarea_settings"), tag: "layout_manager_line_count_fix", defaultValue: false).getValue()
    }()
    
    init(params: OpenNativeTextAreaParams, webView: LarkWebView, componentDelegate: OPTextAreaComponentDelegate, componentID: String, trace: OPTrace) {
        model = params
        self.webView = webView
        self.componentDelegate = componentDelegate
        self.trace = trace
        self.componentID = componentID
        keyboardHelper = OPComponentKeyboardHelper()
        keyboardHelper.componentID = componentID
        super.init(frame: .zero, textContainer: nil)
        delegate = self
        keyboardHelper.delegate = self
        defaultLineFragmentPadding = textContainer.lineFragmentPadding
        defaultTextContainerInset = textContainerInset
        
        update(params: params)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        placeHolderView.frame.size = CGSize(width: bounds.width, height: bounds.height)
    }
    
    func showKeyboardWhenFocusAPIEnable(isFirstInsert: Bool, cursor: Int?, selectionStart: Int?, selectionEnd: Int?) {
        let shouldFocus = !model.hidden && !model.disabled
        if shouldFocus {
            _ = becomeFirstResponder()
            if isFirstInsert {
                updateSelectedRange(cursor: cursor ?? -1, selectionStart: selectionStart ?? -1, selectionEnd: selectionEnd ?? -1)
            }
        } else if isFirstResponder {
            _ = resignFirstResponder()
        }
        traceInfo("showKeyboardWhenFocusAPIEnable shouldFocus:\(shouldFocus), isFirstInsert: \(isFirstInsert)")
    }
    
    func hideKeyboardWhenFocusAPIEnable() {
        traceInfo("hideKeyboardWhenFocusAPIEnable isFirstResponder: \(isFirstResponder)")
        if isFirstResponder {
            _ = resignFirstResponder()
        }
    }
    
    func checkFocus(isFirstInsert: Bool) {
        let focus = model.focus || (isFirstInsert && model.autoFocus)
        let shouldFocus = focus && !model.hidden && !model.disabled
        if shouldFocus {
            _ = becomeFirstResponder()
            if focus && isFirstInsert {
                updateSelectedRange()
            }
        } else if isFirstResponder {
            _ = resignFirstResponder()
        }
        traceInfo("check focus shouldFocus:\(shouldFocus)")
    }
    
    override func becomeFirstResponder() -> Bool {
        let become = super.becomeFirstResponder()
        if become && keyboardHelper.isKeyboardShowing() {
            // 兼容系统键盘willShow通知可能不触发
            keyboardHelper.keyboardWillShow()
        }
        return become
    }
    
    override func resignFirstResponder() -> Bool {
        if renderState.superviewWillBeRemoved {
            traceInfo("superviewWillBeRemoved")
            DispatchQueue.main.async {
                self.traceInfo("resign in next runloop, shouldResign:\(self.renderState.superviewWillBeRemoved)")
                if self.renderState.superviewWillBeRemoved {
                    self.renderState.superviewWillBeRemoved = false
                    _ = self.resignFirstResponder()
                }
            }
            return false
        }
        let resign = super.resignFirstResponder()
        if resign {
            // 兼容系统键盘willHide通知可能不触发
            keyboardHelper.keyboardWillHide()
        }
        return resign
    }
    
    // MARK: - Property Update
    
    func update(params: OpenNativeTextAreaParams) {
        model = params
        
        isUserInteractionEnabled = !model.disabled
        text = (model.maxLength >= 0 && model.value.count > model.maxLength) ? String(model.value.prefix(model.maxLength)) : model.value
        placeHolderView.text = (model.maxLength >= 0 && model.placeholder.count > model.maxLength) ? String(model.placeholder.prefix(model.maxLength)) : model.placeholder
        updateStyle()
        updatePlaceholderStyle()
        inputAccessoryView = model.showConfirmBar ? confirmBar : nil
        updateReturnKeyType()
        
        checkAndUpdateHeight()
    }
    
    private func updateStyle() {
        isHidden = model.hidden
        if let style = model.style {
            font = style.font()
            textAlignment = style.textAlignment()
            textColor = UIColor(hexString: style.color)
            backgroundColor = UIColor(hexString: style.backgroundColor)
        }
        updatePadding(for: self)
    }
    
    private func updateReturnKeyType() {
        switch model.confirmType {
        case .send:
            returnKeyType = .send
        case .search:
            returnKeyType = .search
        case .done:
            returnKeyType = .done
        case .next:
            returnKeyType = .next
        case .go:
            returnKeyType = .go
        default:
            returnKeyType = .`default`
        }
    }
    
    private func updatePlaceholderStyle() {
        updatePlaceholderHidden()
        if let placeholderStyle = model.placeholderStyle {
            placeHolderView.font = placeholderStyle.font()
            placeHolderView.textColor = UIColor(hexString: placeholderStyle.color)
        }
        if let style = model.style {
            placeHolderView.textAlignment = style.textAlignment()
        }
        updatePadding(for: placeHolderView)
    }
    
    private func updatePlaceholderHidden() {
        let hidden = model.hidden || !text.isEmpty
        placeHolderView.isHidden = hidden
    }
    
    private func checkAndUpdateHeight() {
        let textView = text.isEmpty ? placeHolderView : self
        let widthThatFits = heightUpdateFix ? self.frame.width : textView.frame.width
        let targetTextHeight = textView.sizeThatFits(CGSize(width: widthThatFits, height: CGFLOAT_MAX)).height
        let minHeight = max(model.style?.minHeight ?? 0, 0)
        var maxHeight = max(model.style?.maxHeight ?? 0, 0)
        if minHeight > maxHeight {
            maxHeight = 0
        }
        
        frame.size.height = max(minHeight, frame.size.height)
        isScrollEnabled = !model.autoSize || (maxHeight > 0 && targetTextHeight > maxHeight)
        if model.autoSize {
            var realHeight = (maxHeight > 0 && maxHeight < targetTextHeight) ? maxHeight : targetTextHeight
            realHeight = max(realHeight, minHeight)
            frame.size.height = realHeight
        }
        
        if #available(iOS 16.0, *),
           layoutManagerLineCountFix,
           let lineCount = Self.getLineCountUsingTextLayoutManager(textView: textView) {
            if cacheLineCount != lineCount {
                cacheLineCount = lineCount
                textHeight = targetTextHeight
                onLineChange(height: targetTextHeight, lineCount: lineCount)
            }
        } else if textHeight != targetTextHeight {
            textHeight = targetTextHeight
            let lineCount = Self.getLineCount(textView: textView)
            onLineChange(height: targetTextHeight, lineCount: lineCount)
        }
    }
    
    private func onLineChange(height: CGFloat, lineCount: Int) {
        adjustWebViewFrameForHeightChange()
        let textLineChangeResult = OpenNativeTextAreaLineChangeResult(height: height, lineCount: lineCount)
        componentDelegate?.onLineChange(params: textLineChangeResult)
        traceInfo("line changed, lineCount:\(lineCount), textHeight:\(height)")
    }
    
    private func updatePadding(for textView: UITextView) {
        textView.textContainer.lineFragmentPadding = model.disableDefaultPadding ? 0 : defaultLineFragmentPadding
        textView.textContainerInset = model.disableDefaultPadding ? .zero : defaultTextContainerInset
    }
    
    private func updateSelectedRange() {
        updateSelectedRange(cursor: model.cursor, selectionStart: model.selectionStart, selectionEnd: model.selectionEnd)
     }
    
    private func updateSelectedRange(cursor: Int, selectionStart: Int, selectionEnd: Int) {
        var location = cursor
        var length = 0
        
        if selectionStart >= 0 && selectionEnd > selectionStart {
            location = selectionStart
            length = selectionEnd - selectionStart
        }
        
        guard location >= 0 else {
            return
        }
        selectedRange = NSRange(location: location, length: length)
        traceInfo("update selectedRange, location:\(location), length:\(length)")
     }
    
    // MARK: - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" && returnKeyType != .`default` {
            traceInfo("keyboard confirm, confirmHold:\(model.confirmHold)")
            let confirmResult = OpenNativeTextAreaConfirmResult(value: textView.text)
            componentDelegate?.onConfirm(params: confirmResult)
            if !model.confirmHold {
                _ = resignFirstResponder()
            }
            return false
        }
        
        if model.maxLength >= 0 {
            // 中文预输入不受最大长度限制
            if textView.markedTextRange != nil {
                return true
            } else if maxLengthPrefixEnable {
                if range.location >= model.maxLength {
                    return false
                }
            } else if textView.text.count + (text.count - range.length) > model.maxLength {
                return false
            }
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderHidden()
        checkAndUpdateHeight()
        
        if model.maxLength >= 0, let undoManager = textView.undoManager {
            // 解决达到maxLength后进行拼音输入再三指撤销导致的NSInternalInconsistencyException
            if undoManager.isUndoing || undoManager.isRedoing {
                traceInfo("text undo")
                return
            }
        }
        
        if textView.markedTextRange == nil {
            if model.maxLength >= 0 && textView.text.count > model.maxLength {
                // 中文预输入确定词条后受最大长度限制
                textView.text = String(textView.text.prefix(model.maxLength))
            }
            let inputResult = OpenNativeTextAreaInputResult(value: textView.text, cursor: selectedRange.location)
            componentDelegate?.onInput(params: inputResult)
        }
        if layoutManagerLineCountFix {
            scrollRangeToVisible(selectedRange)
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if model.adjustKeyboardTo == .cursor {
            adjustWebViewFrameForHeightChange()
        }
    }
    
    // MARK: - OPComponentKeyboardDelegate
    
    func owningViewFrame() -> CGRect {
        guard let superview = superview else {
            return .zero
        }
        var textViewFrame = superview.convert(frame, to: nil)
        var resultHeight = textViewFrame.height
        if model.adjustKeyboardTo == .cursor, let selectedTextRange = selectedTextRange {
            let cursorRect = caretRect(for: selectedTextRange.end)
            // 兼容在换行时contentOffset.y获取不准确
            resultHeight = min(resultHeight - textContainerInset.bottom, cursorRect.maxY - contentOffset.y)
            traceInfo("cursorRect \(cursorRect)")
        }
        textViewFrame.size.height = resultHeight + (model.style?.marginBottom ?? 0)
        return textViewFrame
    }
    
    func adjustViewFrame() -> CGRect { webView?.frame ?? .zero }
    
    func adjustViewCoordinateSpace() -> UICoordinateSpace? { webView?.superview }
    
    func isOwningViewFirstResponder() -> Bool { isFirstResponder }
    
    func keyboardWillShow(keyboardInfo: OPComponentKeyboardInfo) {
        guard let webViewFrame = webView?.superview?.convert(webView?.frame ?? .zero, to: nil), let textViewFrame = superview?.convert(frame, to: nil) else {
            return
        }
        guard webViewFrame.intersects(textViewFrame) else {
            // 兼容在键盘展示的条件下textarea可能不在webview可视范围内，如：键盘不收起时横竖屏切换
            _ = resignFirstResponder()
            traceInfo("resign for out of screen")
            return
        }
        
        keyboardAnimDuration = keyboardInfo.animDuration
        adjustWebViewFrame(show: true, frame: keyboardInfo.adjustFrame, duration: keyboardInfo.animDuration, options: keyboardInfo.animOption)
        let keyboardHeight = keyboardHelper.getKeyboardHeight()
        let focusResult = OpenNativeTextAreaFocusResult(value: text, height: keyboardHeight)
        componentDelegate?.onFocus(params: focusResult)
        traceInfo("keyboard show, adjustFrame:\(keyboardInfo.adjustFrame), height: \(keyboardHeight)")
    }
    
    func keyboardWillHide(keyboardInfo: OPComponentKeyboardInfo) {
        keyboardAnimDuration = keyboardInfo.animDuration
        adjustWebViewFrame(show: false, frame: keyboardInfo.adjustFrame, duration: keyboardInfo.animDuration, options: keyboardInfo.animOption)
        let blurResult = OpenNativeTextAreaBlurResult(value: text, cursor: selectedRange.location)
        componentDelegate?.onBlur(params: blurResult)
        traceInfo("keyboard hide, adjustFrame:\(keyboardInfo.adjustFrame)")
    }
    
    func keyboardHeightDidChange(height: CGFloat) {
        let keyboardHeightChangeResult = OpenNativeTextAreaKeyboardHeightChangeResult(height: height, duration: keyboardAnimDuration)
        componentDelegate?.onKeyboardHeightChange(params: keyboardHeightChangeResult)
    }
    
    // MARK: - LKNativeRenderDelegate
    
    func lk_render() {
        if renderState.superviewWillBeRemoved {
            renderState.superviewWillBeRemoved = false
        }
    }
    
    // MARK: - Private
    
    private func adjustWebViewFrame(show: Bool, frame: CGRect, duration: TimeInterval, options: UIView.AnimationOptions) {
        guard model.adjustPosition else {
            return
        }
        
        webView?.layer.removeAllAnimations()
        if let webView = webView as? BDPAppPage {
            webView.bap_lockFrameForEditing = show
        }
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.webView?.frame = frame
        } completion: { _ in
            let firstResponder = self.isFirstResponder && self.keyboardHelper.isKeyboardShowing()
            self.traceInfo("adjust completion, show:\(show), frame:\(frame), isFirstResponder:\(firstResponder)")
        }
    }
    
    private func adjustWebViewFrameForHeightChange() {
        // 延迟保证caretRect的准确性
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            guard self.isFirstResponder && self.keyboardHelper.isKeyboardShowing() else {
                return
            }
            
            let adjustFrame = self.keyboardHelper.getAdjustFrame()
            self.adjustWebViewFrame(show: true, frame: adjustFrame, duration: self.keyboardAnimDuration, options: .curveEaseInOut)
            self.traceInfo("adjust webview frame for height change, adjustFrame:\(adjustFrame)")
        })
    }
    
    @objc private func dismissKeyboard() {
        if !model.confirmHold {
            _ = resignFirstResponder()
        }
        let confirmResult = OpenNativeTextAreaConfirmResult(value: text)
        componentDelegate?.onConfirm(params: confirmResult)
        traceInfo("confirmBar confirm, confirmHold: \(model.confirmHold)")
    }
    
    @available(iOS 16.0, *)
    private static func getLineCountUsingTextLayoutManager(textView: UITextView) -> Int? {
        guard let textLayoutManager = textView.textLayoutManager else {
            return nil
        }
        var count = 0
        textLayoutManager.enumerateTextSegments(in: textLayoutManager.documentRange, type: .standard) { _,_,_,_ in
            count += 1
            return true
        }
        if textView.text.last == "\n" {
            count += 1
        }
        return count
    }

    
    private static func getLineCount(textView: UITextView) -> Int {
        let numOfGlyphs = textView.layoutManager.numberOfGlyphs
        if numOfGlyphs <= 0 {
            return 1
        }
        var index = 0, lineCount = 0, lineRange = NSRange()
        while index < numOfGlyphs {
            textView.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            lineCount += 1
        }
        if textView.text.last == "\n" {
            lineCount += 1
        }
        return lineCount
    }
    
    private func traceInfo(_ info: String) {
        trace.info("\(componentID) textarea \(info)")
    }
}
