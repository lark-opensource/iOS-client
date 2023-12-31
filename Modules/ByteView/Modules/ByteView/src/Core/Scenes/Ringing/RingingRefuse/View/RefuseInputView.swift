//
//  RefuseInputView.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/21.
//

import Foundation
import SnapKit

class RefuseInputView: UIView {
    lazy var textView: UITextView = {
        let view = UITextView()
        view.backgroundColor = UIColor.ud.bgBody
        view.textColor = UIColor.ud.textTitle

        view.isEditable = true
        view.isSelectable = true
        view.isScrollEnabled = false
        view.layoutManager.allowsNonContiguousLayout = false
        view.alwaysBounceHorizontal = false
        view.enablesReturnKeyAutomatically = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false

        view.dataDetectorTypes = UIDataDetectorTypes.all
        view.keyboardAppearance = .default
        view.keyboardType = .default
        view.returnKeyType = .send
        view.textAlignment = .left

        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8

        view.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        view.textContainer.lineFragmentPadding = 0
        view.delegate = self

        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = 22
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = .byWordWrapping
        let font = UIFont.systemFont(ofSize: 16, weight: .regular)
        let offset = (lineHeight - font.lineHeight) / 4.0
        view.typingAttributes = [.paragraphStyle: style, .baselineOffset: offset, .font: font, .foregroundColor: UIColor.ud.textTitle]
        return view
    }()

    private lazy var placeHolderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = .systemFont(ofSize: 16)
        label.text = I18n.View_G_CustomReply
        return label
    }()

    var sendKeyBlock: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {}

    func setupView() {
        backgroundColor = .ud.bgBase
        addSubview(textView)
        addSubview(placeHolderLabel)

        textView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        placeHolderLabel.snp.remakeConstraints { make in
            make.top.left.right.equalTo(textView).offset(12)
            make.height.equalTo(22)
        }
    }

    func layoutView(isRegular: Bool) {
        if isRegular {
            textView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
        } else if isPhoneLandscape {
            textView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(8)
                make.left.right.equalToSuperview().inset(78)
            }
        } else {
            textView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
        }
    }
}

extension RefuseInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty

        guard let text = textView.text else { return }
        let maxLength = 128

        // 中文输入法，正在输入拼音时不进行截取处理
        if let language = textView.textInputMode?.primaryLanguage, language == "zh-Hans" {
            // 获取高亮部分
            let selectRange = textView.markedTextRange ?? UITextRange()
            // 对已输入的文字进行字数统计和限制
            if textView.position(from: selectRange.start, offset: 0) == nil {
                if text.count > maxLength {
                    textView.text = String(text.prefix(maxLength))
                }
            } else {
                // 正在输入拼音时，不对文字进行统计和限制
                return
            }
        } else {
            // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if text.count > maxLength {
                textView.text = String(text.prefix(maxLength))
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendKeyBlock?(textView.text)
            return false
        }
        return true
    }
}
