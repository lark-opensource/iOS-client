//
//  RichTopicView.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/22.
//

import Foundation
import RichLabel
import ByteViewUI
import ByteViewCommon

struct RichTopicConfig {
    var titleStyle: VCFontConfig = .init(fontSize: 16, lineHeight: 24, fontWeight: .medium)
    var tagTextStyle: VCFontConfig = .assist
    var tagInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    let tagOffset: CGFloat = 4
}

class RichTopicView: UIView {

    var title: String?
    let config: RichTopicConfig
    var isExternal: Bool = false
    var isWebinar: Bool = false

    var externalText: String = I18n.View_G_ExternalLabel {
        didSet {
            guard externalText != oldValue else { return }
            externalTag.attributedText = .init(string: externalText, config: .assist, alignment: .center, lineBreakMode: .byTruncatingTail)
        }
    }

    var intrinsicContentWidth: CGFloat {
        return Utils.attributeWidth(attributeString: titleAttributedString, height: 24)
    }

    private lazy var titleParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = config.titleStyle.lineHeight
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = .left
        return style
    }()

    private lazy var titleAttribute: [NSAttributedString.Key: Any] = [.font: config.titleStyle.font, .paragraphStyle: titleParagraphStyle, .foregroundColor: UIColor.ud.textTitle, .baselineOffset: -1.5]

    lazy var titleAttributedString = NSMutableAttributedString(string: "", attributes: titleAttribute)

    private var deviation: CGFloat { tagView.isHidden ? 0 : 1.5 }

    private var tagWidth: CGFloat {
        if isExternal && isWebinar {
            return externalTagWidth + 4 + webinarTagWidth
        } else if isExternal {
            return externalTagWidth
        } else if isWebinar {
            return webinarTagWidth
        } else {
            return 0.0
        }
    }

    private var externalTagWidth: CGFloat {
        let width = externalText.vc.boundingWidth(height: config.tagTextStyle.lineHeight, font: config.tagTextStyle.font)
        return width + config.tagInset.left + config.tagInset.right + 0.5
    }

    private lazy var webinarTagWidth: CGFloat = {
        let width = I18n.View_G_Webinar.vc.boundingWidth(height: config.tagTextStyle.lineHeight, font: config.tagTextStyle.font)
        return width + config.tagInset.left + config.tagInset.right + 0.5
    }()

    lazy var titleLabel: AttachmentLabel = {
        let titleLabel = AttachmentLabel()
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .left
        titleLabel.backgroundColor = .clear
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.contentFont = config.titleStyle.font
        titleLabel.contentParagraphStyle = titleParagraphStyle

        titleLabel.addAttributedString(titleAttributedString)
        titleLabel.addArrangedSubview(tagView)
        return titleLabel
    }()

    private lazy var tagView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.addArrangedSubview(webinarTag)
        stackView.addArrangedSubview(externalTag)
        return stackView
    }()

    private lazy var externalTag: PaddingLabel = {
        let flagView = PaddingLabel(frame: .zero)
        flagView.isHidden = true
        flagView.textInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        flagView.textColor = UIColor.ud.udtokenTagTextSBlue
        flagView.attributedText = .init(string: I18n.View_G_ExternalLabel, config: .assist, alignment: .center, lineBreakMode: .byTruncatingTail)
        flagView.layer.cornerRadius = 4.0
        flagView.layer.masksToBounds = true
        flagView.backgroundColor = UIColor.ud.udtokenTagBgBlue
        flagView.setContentHuggingPriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(.required, for: .vertical)
        return flagView
    }()

    private lazy var webinarTag: PaddingLabel = {
        let flagView = PaddingLabel(frame: .zero)
        flagView.textInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        flagView.isHidden = true
        flagView.textColor = UIColor.ud.udtokenTagTextSBlue
        flagView.attributedText = .init(string: I18n.View_G_Webinar, config: .assist, alignment: .center, lineBreakMode: .byTruncatingTail)
        flagView.layer.cornerRadius = 4.0
        flagView.layer.masksToBounds = true
        flagView.backgroundColor = UIColor.ud.udtokenTagBgBlue
        flagView.setContentHuggingPriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(.required, for: .vertical)
        return flagView
    }()

    init(config: RichTopicConfig) {
        self.config = config
        super.init(frame: .zero)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalTo(intrinsicContentWidth)
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTitle(_ text: String, isExternal: Bool = false, isWebinar: Bool = false) {
        guard !text.isEmpty else { return }
        self.isExternal = isExternal
        self.isWebinar = isWebinar
        title = text
        titleAttributedString.mutableString.setString(text)
        titleAttributedString.setAttributes(titleAttribute, range: NSRange(location: 0, length: text.utf16.count))

        if isWebinar || isExternal {
            externalTag.isHiddenInStackView = !isExternal
            webinarTag.isHiddenInStackView = !isWebinar
            tagView.isHidden = false
            titleLabel.updateArrangedSubview(tagView) { [ weak self] in
                guard let self = self else { return }
                $0.margin = UIEdgeInsets(top: 1, left: self.config.tagOffset, bottom: 0, right: 0)
                $0.size = CGSize(width: self.tagWidth, height: self.config.tagTextStyle.lineHeight + self.config.tagInset.top + self.config.tagInset.bottom)
            }
        } else {
            externalTag.isHiddenInStackView = true
            webinarTag.isHiddenInStackView = true
            tagView.isHidden = true
        }
        titleLabel.reload()
        let contentWidth = isWebinar || isExternal ? intrinsicContentWidth + config.tagOffset + tagWidth : intrinsicContentWidth

        titleLabel.snp.updateConstraints { make in
            make.width.equalTo(contentWidth)
        }
        layoutIfNeeded()
    }

    func updateHeight(with width: CGFloat) {
        let height = getTitleHeight(width: width) + deviation
        titleLabel.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }

    private func getTitleHeight(width: CGFloat) -> CGFloat {
        let lineHeight = config.titleStyle.lineHeight
        let maxHeight = 3 * lineHeight
        let height = Utils.attributeHeight(attributeString: titleLabel.attributedText ?? titleAttributedString, width: width, font: config.titleStyle.font, lineHeight: lineHeight)
        return height < maxHeight ? height : maxHeight
    }
}
