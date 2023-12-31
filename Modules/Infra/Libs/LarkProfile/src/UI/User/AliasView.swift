//
//  AliasView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2022/1/21.
//

import Foundation
import UIKit
import UniverseDesignToast

final class AliasView: UIStackView {

    private var attributedName: NSAttributedString?

    func setAlias(_ alias: String) {
        attributedName = NSAttributedString(
            string: alias,
            attributes: [.font: Cons.aliasFont]
        )
        aliasLabel.text = alias
        DispatchQueue.main.async {
            self.adjustUserTagsIfNeeded(self.bounds.width)
        }
    }

    func setPronouns(_ pronouns: String) {
        pronounsLabel.text = pronouns
        pronounsLabel.isHidden = pronouns.isEmpty
        DispatchQueue.main.async {
            self.adjustUserTagsIfNeeded(self.bounds.width)
        }
    }

    lazy var aliasLabel: UILabel = {
        let label = UILabel()
        let font = Cons.aliasFont
        label.font = font
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 2
        return label
    }()

    lazy var pronounsLabel: UILabel = {
        let label = UILabel()
        let font = Cons.pronounsFont
        label.font = font
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = .clear
        label.numberOfLines = 1
        return label
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
        addArrangedSubview(aliasLabel)
    }

    private func setupConstraints() {
        aliasLabel.snp.makeConstraints { make in
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

extension AliasView {

    /// 根据 Label 最后一行的剩余宽度，决定 tagView 是否换行放置
    /// - Parameter maxWidth: Label 的宽度
    private func adjustUserTagsIfNeeded(_ maxWidth: CGFloat) {

        guard let text = attributedName else { return }

        pronounsLabel.removeFromSuperview()
        var labelEnd: CGFloat = 0
        if !text.string.isEmpty {
            labelEnd = lastLineWidth(message: text, labelWidth: maxWidth) + 8
        }
        let availableWidth = maxWidth - labelEnd
        pronounsLabel.snp.removeConstraints()
        if availableWidth >= pronounsLabel.frame.width {
            aliasLabel.addSubview(pronounsLabel)
            pronounsLabel.snp.remakeConstraints { make in
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.equalToSuperview().offset(-(Cons.aliasFont.lineHeight - 18) / 2)
                make.leading.equalToSuperview().offset(labelEnd)
                make.height.equalTo(18)
            }
        } else {
            addArrangedSubview(pronounsLabel)
            pronounsLabel.snp.makeConstraints { make in
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
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
            attributes: [.font: Cons.aliasFont],
            context: nil
        )
        if boundingBox.height > Cons.aliasFont.lineHeight * 2 {
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

extension AliasView {

    enum Cons {
        static var aliasFont: UIFont {
            UIFont.boldSystemFont(ofSize: 14)
        }

        static var pronounsFont: UIFont {
            UIFont.systemFont(ofSize: 14)
        }
    }
}
