//
//  NameTagView.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/20.
//

import Foundation
import UIKit
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl

class NameTagView: UIStackView {

    var attributedName: NSAttributedString?
    var copyName: String?
    
    var hasTag = false

    func setName(_ name: String) {
        copyName = name
        var tagName = name
        /// 处理含有特殊字符时计算字符位置不准问题
        if ProfileProcessStringUtil.hasSpecialCharacters(tagName) {
            tagName += " "
        }
        attributedName = NSAttributedString(
            string: tagName,
            attributes: [.font: Cons.nameFont]
        )
        nameLabel.text = tagName
        // 中英文混合时系统会自动设置为byWord，需要设置完text后手动设置一下
        nameLabel.lineBreakMode = .byTruncatingTail
//        self.layoutIfNeeded()
        DispatchQueue.main.async {
            self.adjustUserTagsIfNeeded(self.bounds.width)
        }
    }

    func setTags(_ tags: [UIView]) {
        hasTag = !tags.isEmpty
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

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        let font = Cons.nameFont
        label.font = font
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPressLabel)))
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
    
    /// 根据 Label 最后一行的剩余宽度，决定 tagView 是否换行放置
    /// - Parameter maxWidth: Label 的宽度
    func adjustUserTagsIfNeeded(_ maxWidth: CGFloat) {

        guard let text = attributedName else { return }
        
        userTagView.removeFromSuperview()
        var hMargin: CGFloat = 8
        if ProfileProcessStringUtil.hasSpecialCharacters(attributedName?.string ?? ""), ProfileProcessStringUtil.isToProcessLanguage() {
            /// 处理特殊语言下添加额外margin
            hMargin = 20
        } else if ProfileProcessStringUtil.isChinese(),
                    ProfileProcessStringUtil.countBracketsMoreThanApair(attributedName?.string ?? ""),
                    let margin = ProfileProcessStringUtil.getSpecialTypeNameTagReplenishHMargin() {
            hMargin = margin
        }
        let labelEnd = lastLineWidth(message: text, labelWidth: maxWidth) + hMargin
        let availableWidth = maxWidth - labelEnd
        userTagView.snp.removeConstraints()
        if availableWidth >= userTagView.frame.width {
            nameLabel.addSubview(userTagView)
            userTagView.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-(Cons.nameFont.lineHeight - Cons.tagViewHeight) / 2)
                make.leading.equalToSuperview().offset(labelEnd)
                make.height.equalTo(hasTag ? Cons.tagViewHeight : 0)
            }
        } else {
            addArrangedSubview(userTagView)
            userTagView.snp.makeConstraints { make in
                make.width.lessThanOrEqualToSuperview()
                make.height.equalTo(hasTag ? Cons.tagViewHeight : 0)
            }
        }

    }
    
    /// 计算 UILabel 中最后一行的长度
    func lastLineWidth(message: NSAttributedString, labelWidth: CGFloat) -> CGFloat {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let constraintRect = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let attributes = [NSAttributedString.Key.font: Cons.nameFont,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let boundingBox = message.string.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
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

    @objc
    private func didLongPressLabel() {
        guard let text = copyName else { return }
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-profile_name_long_press"))
            try SCPasteboard.generalUnsafe(config).string = text
            if let window = UIApplication.shared.keyWindow {
                UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Legacy_Copied, on: window)
            }
        } catch {
            // 复制失败兜底逻辑
            if let window = UIApplication.shared.keyWindow {
                UDToast.showFailure(with: BundleI18n.LarkProfile.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
    }
}

extension NameTagView {

    enum Cons {
        static var nameFont: UIFont {
            UIFont.systemFont(ofSize: 26, weight: .semibold)
        }
        static var tagViewHeight: CGFloat { 20.0 }
    }
}
