//
//  MailProfileNameTagView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/30.
//

import UIKit
import Foundation
import UniverseDesignToast
import LarkEMM

final class MailProfileNameTagView: UIStackView {

    private var attributedName: NSAttributedString?

    func setName(_ name: String) {
        attributedName = NSAttributedString(
            string: name,
            attributes: [.font: Cons.nameFont]
        )
        nameLabel.text = name
//        self.layoutIfNeeded()
        DispatchQueue.main.async {
            self.adjustUserTagsIfNeeded(self.bounds.width)
        }
    }

    func setTags(_ tags: [UIView]) {
        userTagView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        for tag in tags {
            userTagView.addArrangedSubview(tag)
        }
//        self.layoutIfNeeded()
        DispatchQueue.main.async {
            self.adjustUserTagsIfNeeded(self.bounds.width)
        }
    }

    lazy var nameLabel: MailProfileNameLabel = {
        let label = MailProfileNameLabel()
        let font = Cons.nameFont
        label.font = font
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 2
        return label
    }()

    lazy var userTagView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addArrangedSubview(nameLabel)
    }

    private func setupConstraints() {
        nameLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }

    private func setupAppearance() {
        axis = .vertical
        alignment = .leading
        distribution = .fill
        spacing = 4
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustUserTagsIfNeeded(bounds.width)
    }
}

extension MailProfileNameTagView {

    /// 根据 Label 最后一行的剩余宽度，决定 tagView 是否换行放置
    /// - Parameter maxWidth: Label 的宽度
    private func adjustUserTagsIfNeeded(_ maxWidth: CGFloat) {

        guard let text = attributedName else { return }

        userTagView.removeFromSuperview()
        let labelEnd = lastLineWidth(message: text, labelWidth: maxWidth) + 8
        let availableWidth = maxWidth - labelEnd
        userTagView.snp.removeConstraints()
        if availableWidth >= userTagView.frame.width {
            nameLabel.addSubview(userTagView)
            userTagView.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-(Cons.nameFont.lineHeight - 18) / 2)
                make.leading.equalToSuperview().offset(labelEnd)
                make.height.equalTo(18)
            }
        } else {
            addArrangedSubview(userTagView)
            userTagView.snp.makeConstraints { make in
                make.width.lessThanOrEqualToSuperview()
                make.height.equalTo(18)
            }
        }
    }

    /// 计算 UILabel 中最后一行的长度
    private func lastLineWidth(message: NSAttributedString, labelWidth: CGFloat) -> CGFloat {

        let constraintRect = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let boundingBox = message.string.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: Cons.nameFont],
            context: nil
        )
        if boundingBox.height > Cons.nameFont.lineHeight * 2 {
            return labelWidth
        }

        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let labelSize = CGSize(width: labelWidth, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: message)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping

        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(
            forGlyphAt: lastGlyphIndex,
            effectiveRange: nil
        )
        return lastLineFragmentRect.maxX
    }
}

final class MailProfileNameLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressLabel)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didLongPressLabel() {
        guard let text = text else { return }
        if ContactPasteboard.writeToPasteboard(string: text) {
            if let window = UIApplication.shared.keyWindow {
                UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Legacy_Copied, on: window)
            }
        } else {
            if let window = UIApplication.shared.keyWindow {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
    }
}

extension MailProfileNameTagView {
    enum Cons {
        static var nameFont: UIFont {
            UIFont.systemFont(ofSize: 26, weight: .semibold)
        }
    }
}
