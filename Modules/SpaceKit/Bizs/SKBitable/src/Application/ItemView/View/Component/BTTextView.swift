//
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
//
// Description:

import Foundation
import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignToast


public enum BTTextViewMenuAction: String {
    case copy
    case cut
}

protocol BTTextViewDelegate: AnyObject {
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer)
    func btTextView(_ textView: BTTextView, didDoubleTapped sender: UITapGestureRecognizer)
    /// 这个接口是为了让 Field 监听 BTTextView 的 Menu Action
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool
    /// 目前仅提供给BTextView 为 isEnableOpenURlAction 时shying。
    func btTextViewDidOpenUrl()
    ///textView发生滚动，toBounce是否滑动到边界或者isDecelerating
    func btTextViewDidScroll(toBounce: Bool)
}

extension BTTextViewDelegate {
    func btTextView(_ textView: BTTextView, didDoubleTapped sender: UITapGestureRecognizer) {}
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        return true
    }
    func btTextView(_ textView: BTTextView, didApply action: BTTextViewMenuAction) {}
    func btTextViewDidOpenUrl() {}
}

enum BTTextViewType {
    case plainText
    case numberText
    case normal
}

final class BTTextView: SheetTextView, UIGestureRecognizerDelegate {
    
    /// 编辑权限
    var editPermission = true {
        didSet {
            isEditable = editPermission
        }
    }
    /// 自定义气泡菜单事件
    var isEnableOpenURLAction: Bool = false
    
    var type: BTTextViewType = .plainText {
        didSet {
            switch type {
            case .plainText:
                keyboardType = .default
                returnKeyType = .default
            case .numberText:
                keyboardType = .decimalPad
                returnKeyType = .send
            case .normal:
                keyboardType = .default
                returnKeyType = .default
            }
        }
    }

    weak var btDelegate: BTTextViewDelegate? // 用于处理 url 事件，后面换成 link 类型富文本试试能不能干掉这个

    private lazy var singleTapGR = UITapGestureRecognizer().construct { it in
        it.delegate = self
        it.addTarget(self, action: #selector(handleSingleTapGR(_:)))
    }
    // 添加额外其他手势时为了在执行其他手势时不触发单击手势
    private lazy var doubleTapGR = UITapGestureRecognizer().construct { it in
        it.delegate = self
        it.numberOfTapsRequired = 2
        it.addTarget(self, action: #selector(handleDoubleTapGR(_:)))
    }
    private lazy var longPressGR = UILongPressGestureRecognizer().construct { it in
        it.delegate = self
    }
    private lazy var panGR = UIPanGestureRecognizer().construct { it in
        it.delegate = self
    }
    
    private(set) var placeholderLabel: BTInsetLabel = BTInsetLabel()
    private var placeHolderEnable: Bool = false
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderLabel.textInsets = UIEdgeInsets(top: textContainerInset.top + 2,
                                                       left: textContainerInset.left,
                                                       bottom: textContainerInset.bottom + 2,
                                                       right: textContainerInset.right)
        }
    }
    
    override var text: String! {
        didSet {
            contentDidSet()
        }
    }
    
    override var attributedText: NSAttributedString! {
        didSet {
            contentDidSet()
        }
    }
    
    private var lastContentOffset: CGPoint = .zero
    
    override var contentOffset: CGPoint {
        didSet {
            if contentOffset != lastContentOffset {
                updatePlaceholderFrame()
            }
            guard UserScopeNoChangeFG.ZJ.btCellLargeContentOpt,
                  contentOffset != lastContentOffset,
                  self.isScrollEnabled,
                  self.isTracking else {
                btDelegate?.btTextViewDidScroll(toBounce: true)
                return
            }
            
            let isScrollToBounces = ((contentOffset.y + bounds.height) == contentSize.height) || contentOffset == .zero
            btDelegate?.btTextViewDidScroll(toBounce: isScrollToBounces)
            lastContentOffset = contentOffset
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlaceholderFrame()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceHolder()
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byWordWrapping
        self.textContainerInset = .zero
        _ = self.layoutManager
        backgroundColor = .clear
        autocorrectionType = .no
        isScrollEnabled = false
        addGestureRecognizer(singleTapGR)
        addGestureRecognizer(doubleTapGR)
        addGestureRecognizer(longPressGR)
        addGestureRecognizer(panGR)
        singleTapGR.require(toFail: doubleTapGR)
        singleTapGR.require(toFail: longPressGR)
        singleTapGR.require(toFail: panGR)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupPlaceHolder() {
        addSubview(placeholderLabel)
        placeholderLabel.textColor = UDColor.textPlaceholder
        placeholderLabel.font = self.font
        placeholderLabel.numberOfLines = 1
        placeholderLabel.textAlignment = .left
        placeholderLabel.isUserInteractionEnabled = false
    }
    
    private func updatePlaceholderFrame() {
        placeholderLabel.frame = CGRect(x: 0, y: contentOffset.y, width: bounds.width, height: bounds.height - contentOffset.y)
    }
    
    private func contentDidSet() {
        if contentIsEmpty() && placeHolderEnable {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
        }
    }
    
    @objc private func textDidChange(_ notification: Notification) {
        guard let obj = notification.object as? BTTextView, obj == self, placeHolderEnable else {
            return
        }
        let placeHolderIsEmpty = (placeholderLabel.text?.isEmpty ?? true) &&
                               (placeholderLabel.attributedText?.string.isEmpty ?? true)
        let contentIsEmpty = self.text.isEmpty && self.attributedText.string.isEmpty
        placeholderLabel.isHidden = placeHolderIsEmpty || !contentIsEmpty
    }
    
    private func contentIsEmpty() -> Bool {
        return self.text.isEmpty && self.attributedText.string.isEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enablePlaceHolder(enable: Bool) {
        placeHolderEnable = enable
        if enable && contentIsEmpty() {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
        }
    }
    
    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    // MARK: UIGestureRecognizer handles
    @objc
    private func handleSingleTapGR(_ gr: UITapGestureRecognizer) {
        /// 当有选中时，就当成是在做 menu 操作。
        if selectedRange.length == 0 {
            btDelegate?.btTextView(self, didSigleTapped: gr)
        }
        debugPrint("BTTextView handleSingleTapGR btDelegate")
    }
    
    @objc
    private func handleDoubleTapGR(_ gr: UITapGestureRecognizer) {
        btDelegate?.btTextView(self, didDoubleTapped: gr)
        debugPrint("BTTextView handleDoubleTapGR btDelegate")
    }

    // MARK: - 气泡菜单
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        debugPrint("BTTextView handlecanPerformAction action: \(action)")
        if isEnableOpenURLAction, selectedRange.length == 0 {
            return action == #selector(openURL)
        } else {
            if action == #selector(openURL) {
                return false
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
   
    override func copy(_ sender: Any?) {
        guard btDelegate?.btTextView(self, shouldApply: .copy) ?? false else {
            return
        }
        super.copy(sender)
    }
    
    override func cut(_ sender: Any?) {
        guard btDelegate?.btTextView(self, shouldApply: .cut) ?? false else {
            return
        }
        super.cut(sender)
    }
    
    @objc
    func openURL() {
        btDelegate?.btTextViewDidOpenUrl()
    }
}

// 附件 drag & drop 相关代码实现，等需求安排上了取消注释，别忘了激活上面 textDropDelegate = self 的逻辑
/*
extension BTTextView: UITextDropDelegate {
    func textDroppableView(_ textDroppableView: UIView & UITextDroppable, proposalForDrop drop: UITextDropRequest) -> UITextDropProposal {
        if let item = drop.dropSession.items.first,
           let string = item.localObject as? String,
           BTAttachmentModel.deserialize(from: string) != nil {
            return UITextDropProposal(operation: .forbidden)
        }
        return UITextDropProposal(operation: .copy)
    }
}
*/
