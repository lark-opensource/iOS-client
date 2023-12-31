//
//  EventDateInvalidWarningView.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/24.
//

import UniverseDesignIcon
import UIKit
import RichLabel

protocol EventEditDateInvalidWarningViewDataType {
    // 提示内容
    var warningStr: String { get }
    // 是否可点击
    var isClickable: Bool { get }
}

final class EventDateInvalidWarningView: EventEditCellLikeView {

    private let contentLabel = LKLabel()
    private let contentWrapperView = UIView()

    var onClickHandler: (() -> Void)?

    var viewData: EventEditDateInvalidWarningViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            let attrStr = normalTextAttributedString(of: viewData.warningStr)
            if viewData.isClickable {
                attrStr.append(aidActionAttributedString())
            } else {
                onClick = nil
            }
            contentLabel.attributedText = attrStr
            contentLabel.setNeedsLayout()
            contentLabel.layoutIfNeeded()
            contentLabel.preferredMaxLayoutWidth = contentLabel.bounds.width
            contentLabel.invalidateIntrinsicContentSize()
            onClick = onClickHandler

        }
    }

    private var textFont: UIFont = UIFont.ud.caption1
    private let lineHeight: CGFloat = 20

    convenience init(textFont: UIFont) {
        self.init(frame: .zero)
        self.textFont = textFont
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        icon = .none
        accessory = .none
        backgroundColors = (UIColor.ud.functionDangerFillSolid01, UIColor.ud.functionDangerFillSolid01)
        contentLabel.numberOfLines = 0
        contentWrapperView.isUserInteractionEnabled = false
        contentWrapperView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        content = .customView(contentWrapperView)
        contentInset = EventEditUIStyle.Layout.contentLeftPadding
        iconAlignment = .topByOffset(8)
        contentLabel.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func normalTextAttributedString(of text: String) -> NSMutableAttributedString {
        let tipAttrStr = NSMutableAttributedString(string: text)
        let tipRange = (text as NSString).range(of: text)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        tipAttrStr.addAttribute(.paragraphStyle, value: style, range: tipRange)
        tipAttrStr.addAttribute(.foregroundColor, value: UIColor.ud.functionDanger500, range: tipRange)
        tipAttrStr.addAttribute(.font, value: textFont, range: tipRange)

        return tipAttrStr
    }

    private func aidActionAttributedString() -> NSAttributedString {
        let totalAttrStr = NSMutableAttributedString(string: "  ")
        let lineAttachment = getAttachmentAttributedString(font: textFont,
                                                           size: CGSize(width: 1 / UIScreen.main.scale, height: 8)) {
            let lineImage = UIImage.cd.image(
                withColor: UIColor.ud.textPlaceholder,
                size: CGSize(width: 1 / UIScreen.main.scale, height: 10),
                cornerRadius: 0
            )
            let imageView = UIImageView(image: lineImage)
            return imageView
        }
        totalAttrStr.append(lineAttachment)
        totalAttrStr.append(NSAttributedString(string: "  "))

        let label = UILabel()
        label.text = I18n.Calendar_Edit_AutoAdjust
        label.font = textFont
        label.textColor = UIColor.ud.textLinkNormal
        label.sizeToFit()
        let size = label.bounds.size
        totalAttrStr.append(getAttachmentAttributedString(font: textFont, size: size) {
            return label
        })
        return totalAttrStr
    }

    private func getAttachmentAttributedString(font: UIFont, size: CGSize, viewProvider: @escaping () -> UIView) -> NSAttributedString {
        let attachment = LKAsyncAttachment(
            viewProvider: viewProvider,
            size: size
        )
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        attachment.size = size
        attachment.margin = .zero
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachment])
    }
}
