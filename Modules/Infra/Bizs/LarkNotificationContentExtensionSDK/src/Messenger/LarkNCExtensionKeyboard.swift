//
//  LarkNCExtensionKeyboard.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/27.
//

import Foundation
import UIKit

final public class LarkNCExtensionKeyboard: UIView {
    public var textView: UITextView = UITextView()
    var textPlaceholder: UILabel = UILabel()
    public var sendCallBack: ((String)-> Void)?
    public var sendEmotionCallBack: ((String)-> Void)?

    private var sendIcon: UIButton = UIButton()
    private var switchIcon: UIButton = UIButton()
    private var emotionKeyboard: LarkNCExtensionEmotionKeyboardView = LarkNCExtensionEmotionKeyboardView(frame: CGRect(x: 0, y: 0, width: 375, height: 390))

    private var sendImage: UIImage?
    private var senddisableImage: UIImage?

    private var textConstraint: NSLayoutConstraint = NSLayoutConstraint()

    private let maxHeight: CGFloat = 90

    public override var intrinsicContentSize: CGSize {
            // Calculate intrinsicContentSize that will fit all the text
        let textSize = self.textView.sizeThatFits(CGSize(width: self.textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        var height = textSize.height + 16
        self.textView.isScrollEnabled = false
        if height <= 62 {
            height = 62
        } else if height >= 80 {
            height = 80
            self.textView.isScrollEnabled = true
        }
        return CGSize(width: self.bounds.width, height: height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSubViews() {

        sendImage = UIImage(named: "send", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        senddisableImage = UIImage(named: "senddisable", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)

        switchIcon.setImage(UIImage(named: "larkmore", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil), for: .normal)
        switchIcon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(switchIcon)
        switchIcon.addTarget(self, action: #selector(switchEmotion), for: .touchUpInside)

        sendIcon.setImage(senddisableImage, for: .normal)
        sendIcon.isEnabled = false
        sendIcon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(sendIcon)
        sendIcon.addTarget(self, action: #selector(send), for: .touchUpInside)

        textView.backgroundColor = UIColor(named: "input_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        textView.textColor = UIColor(named: "text_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.layer.cornerRadius = 4
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        self.addSubview(textView)

        textPlaceholder.textColor = UIColor(named: "placeholder_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        textPlaceholder.font = UIFont.systemFont(ofSize: 16)
        textPlaceholder.text = BundleI18n.LarkNotificationContentExtensionSDK.Lark_Core_QuickReply_ReplyButton
        textPlaceholder.isHidden = false
        textPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(textPlaceholder)

        textConstraint = textView.leadingAnchor.constraint(equalTo: switchIcon.trailingAnchor, constant: 13)

        NSLayoutConstraint.activate([
            textConstraint,
            textView.trailingAnchor.constraint(equalTo: sendIcon.leadingAnchor, constant: -12),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 46)
        ])

        NSLayoutConstraint.activate([
            textPlaceholder.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            textPlaceholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 15),
            textPlaceholder.heightAnchor.constraint(equalToConstant: 22)
        ])

        NSLayoutConstraint.activate([
            sendIcon.widthAnchor.constraint(equalToConstant: 26),
            sendIcon.heightAnchor.constraint(equalToConstant: 26),
            sendIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendIcon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])

        NSLayoutConstraint.activate([
            switchIcon.widthAnchor.constraint(equalToConstant: 22),
            switchIcon.heightAnchor.constraint(equalToConstant: 22),
            switchIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            switchIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13)
        ])

        emotionKeyboard.switchKeyboardCallback = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.textView.resignFirstResponder()
            self.alpha = 1
            self.textView.inputView = nil
            self.textView.becomeFirstResponder()
        }

        emotionKeyboard.didSelectItemCallback = { [weak self] (key) in
            LarkNCESDKLogger.logger.info("EmotionKeyboard Did Select Item key: \(key)")
            self?.sendEmotionCallBack?(key)
        }

        self.backgroundColor = UIColor(named: "bg_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
    }

    @objc
    private func send() {
        self.sendCallBack?(self.textView.text)
        self.sendIcon.isEnabled = false
    }

    @objc
    private func switchEmotion() {
        self.alpha = 0
        self.textView.resignFirstResponder()
        self.textView.inputView = emotionKeyboard
        self.textView.becomeFirstResponder()
    }
}

extension LarkNCExtensionKeyboard: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        invalidateIntrinsicContentSize()

        updateConstraint(isEmpty: textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func updateConstraint(isEmpty: Bool) {
        NSLayoutConstraint.deactivate([textConstraint])
        if isEmpty {
            sendIcon.setImage(senddisableImage, for: .normal)
            sendIcon.isEnabled = false
            switchIcon.isHidden = false
            textPlaceholder.isHidden = false
            textConstraint = textView.leadingAnchor.constraint(equalTo: switchIcon.trailingAnchor, constant: 13)
        } else {
            sendIcon.setImage(sendImage, for: .normal)
            sendIcon.isEnabled = true
            switchIcon.isHidden = true
            textPlaceholder.isHidden = true
            textConstraint = textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        }
        NSLayoutConstraint.activate([textConstraint])
    }
}
