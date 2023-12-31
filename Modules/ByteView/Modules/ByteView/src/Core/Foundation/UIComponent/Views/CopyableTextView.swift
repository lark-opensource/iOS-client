//
//  CopyableTextView.swift
//  ByteView
//
//  Created by kiri on 2020/8/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

class CopyableTextView: UITextView, UITextInputDelegate {

    private var selectionChangedCount = 0
    // 为了复制后消除选择状态
    private var shouldDeslectedText: Bool = true
    var customIntrinsicContentSize: CGSize?
    var shouldLimit: Bool = false

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.backgroundColor = .clear
        self.isEditable = false
        self.isScrollEnabled = false
        self.textContainerInset = UIEdgeInsets(top: -1, left: 0, bottom: 1, right: 0)
        self.textContainer.lineFragmentPadding = 0
        self.layoutManager.allowsNonContiguousLayout = false
        let longGr = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        self.addGestureRecognizer(longGr)
        self.inputDelegate = self
        self.delegate = self
        self.setContentHuggingPriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        NotificationCenter.default.addObserver(self, selector: #selector(didHideMenu),
                                               name: UIMenuController.didHideMenuNotification, object: nil)
    }

    convenience init(shouldLimit: Bool) {
        self.init(frame: .zero, textContainer: nil)
        self.shouldLimit = shouldLimit
        self.textContainer.maximumNumberOfLines = 1
        self.textContainer.lineBreakMode = .byTruncatingTail
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func longPress() {
        selectAll(self)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    @objc private func didHideMenu() {
        if selectionChangedCount == 0 {
            // safely end editing, else in changing selection.
            endEditing(false)
        }
    }

    func selectionWillChange(_ textInput: UITextInput?) {
        selectionChangedCount += 1
    }

    func selectionDidChange(_ textInput: UITextInput?) {
        selectionChangedCount -= 1
        self.shouldDeslectedText = false
    }

    func textWillChange(_ textInput: UITextInput?) {
    }

    func textDidChange(_ textInput: UITextInput?) {
    }
}

extension CopyableTextView: UITextViewDelegate {
#if swift(>=5.7)
    @available(iOS 16.0, *)
    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        self.shouldDeslectedText = true
        for action in suggestedActions {
            // 只取编辑菜单，过滤其他菜单的影响
            if let item = action as? UIMenu, item.identifier == UIMenu.Identifier.standardEdit {
                return item
            }
        }
        return nil
    }

    @available(iOS 16.0, *)
    func textView(_ textView: UITextView, willDismissEditMenuWith aniamtor: UIEditMenuInteractionAnimating) {
        // 加入延时是为了防止滑动光标的时候把菜单取消了
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) { [weak self] in
            guard let self = self else { return }
            if self.shouldDeslectedText {
                self.endEditing(false)
            }
        }
    }
#endif
}
