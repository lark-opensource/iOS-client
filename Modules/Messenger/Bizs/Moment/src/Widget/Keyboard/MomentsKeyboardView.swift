//
//  MomentsKeyboardView.swift
//  Moment
//
//  Created by bytedance on 2021/1/7.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkUIKit
import LarkCore
import RustPB
import LarkRichTextCore
import LarkKeyboardView
import LarkBaseKeyboard

protocol MomentsKeyboardViewDelegate: OldBaseKeyboardDelegate {
    func closeKeyboardViewReplyTipView()
}

final class MomentsKeyboardView: OldBaseKeyboardView {

    var richText: RustPB.Basic_V1_RichText? {
        get {
            if let richText = RichTextTransformKit.transformStringToRichText(string: self.attributedString),
               !richText.elements.isEmpty {
                return richText
            }
            return nil
        }
        set {
            if let richText = newValue {
                let attributedString = RichTextTransformKit.transformRichTextToStr(
                    richText: richText,
                    attributes: self.inputTextView.defaultTypingAttributes,
                    attachmentResult: [:])
                self.attributedString = attributedString
            } else {
                self.attributedString = NSAttributedString()
            }
        }
    }

     var richTextStr: String {
        if let richText = self.richText {
            return (try? richText.jsonString()) ?? ""
        }
        return ""
    }

    fileprivate let disposeBag = DisposeBag()
    private var keyboardViewWidth: CGFloat = UIScreen.main.bounds.width

    private lazy var replayTipView = {
        return MomentsReplayTipView { [weak self] in
            self?.momentsKeyBoardDelegate?.closeKeyboardViewReplyTipView()
        }
    }()

    weak var momentsKeyBoardDelegate: MomentsKeyboardViewDelegate? {
        didSet {
            self.delegate = self.momentsKeyBoardDelegate
        }
    }

    init(keyboardNewStyleEnable: Bool) {
        super.init(frame: CGRect.zero,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        inputTextView.interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: "LARK-PSDA-moments-reply-comment-copy-permission")
        self.inputPlaceHolder = BundleI18n.Moment.Lark_Community_ShareYourComment
        if !keyboardNewStyleEnable {
            self.keyboardPanel.layout = self.createLayout()
        }
        setupView()
        setupObservers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        /// mac 风格输入框，回复栏背景设置为灰色
        if self.macInputStyle {
            replayTipView.contentView.backgroundColor = UIColor.ud.N100
        }
        self.inputStackView.insertArrangedSubview(replayTipView, at: 0)
        replayTipView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        self.controlContainer.snp.remakeConstraints { make in
            make.top.equalTo(replayTipView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.inputTextView.enablesReturnKeyAutomatically = false
    }

    private func setupObservers() {
        self.keyboardPanel.observeKeyboard = false

        self.inputTextView.rx.didEndEditing.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.keyboardPanel.observeKeyboard = false
            // iPad 同一时间可能存在多个输入框切换的情况
            // 失去焦点收起键盘
            // 这里需要延时判断，如果 KeyboardView 仍是第一响应，则不收起键盘
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                if self.keyboardPanel.selectIndex == nil &&
                    Display.pad &&
                    !self.hasFirstResponder() {
                    self.keyboardPanel.closeKeyboardPanel(animation: true)
                }
            }
        }).disposed(by: self.disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !keyboardNewStyleEnable {
            if self.keyboardViewWidth != self.bounds.width {
                self.keyboardViewWidth = self.bounds.width
                self.keyboardPanel.layout = self.createLayout()
            }
        }
    }

    func insert(userName: String, actualName: String, userId: String = "", isOuter: Bool, isAnonymous: Bool = false) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId,
                                     name: userName,
                                     isOuter: isOuter,
                                     actualName: actualName,
                                     isAnonymous: isAnonymous)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: self.inputTextView.defaultTypingAttributes)
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: self.inputTextView.defaultTypingAttributes))
            self.inputTextView.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            self.inputTextView.insertText(userName)
        }
        self.inputTextView.becomeFirstResponder()
        self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
    }

    func insertEmoji(_ emoji: String) {
        let selectedRange: NSRange = self.inputTextView.selectedRange
        if self.textViewInputProtocolSet.textView(self.inputTextView, shouldChangeTextIn: selectedRange, replacementText: emoji) {
            let emojiStr = EmotionTransformer.transformContentToString(emoji, attributes: self.inputTextView.defaultTypingAttributes)
            self.inputTextView.insert(emojiStr, useDefaultAttributes: false)
        }
        self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
    }

    private func createLayout() -> KeyboardPanel.Layout {
        if Display.pad {
            return .left(26)
        } else {
            let screenWidth = keyboardViewWidth
            return .custom({ (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) in
                keyboardIcon.snp.remakeConstraints({ (make) in
                    make.size.equalTo(KeyboardPanel.ButtonSize)
                    make.centerY.equalToSuperview()
                    // 确保按照5个按钮，从左向右排列，第三个保持居中
                    let inset: CGFloat = 10
                    let interval = (screenWidth - KeyboardPanel.ButtonSize.width - inset * 2) / 4
                    let offset = inset + KeyboardPanel.ButtonSize.width / 2 + interval * CGFloat(index)
                    make.centerX.equalTo(panel.snp.left).offset(offset)
                })
            })
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !self.keyboardPanel.observeKeyboard {
            self.keyboardPanel.resetContentHeight()
        }
        self.keyboardPanel.observeKeyboard = true
        return true
    }

    func updateReplyBarWith(attributedString: NSAttributedString?) {
        if let attributedString = attributedString {
            replayTipView.show(true)
            replayTipView.replyText = attributedString
        } else {
            replayTipView.show(false)
            replayTipView.replyText = NSAttributedString(string: "")
        }
        if self.window != nil {
            self.layoutIfNeeded()
        }
    }

    func updateEnable(_ value: Bool) {
        isEnabled = value
        for btn in keyboardPanel.buttons {
            btn.isEnabled = value
        }
    }
}
