//
//  RichTopicView.swift
//  ByteView
//
//  Created by lutingting on 2023/2/23.
//

import Foundation
import RichLabel
import ByteViewCommon
import ByteViewUI

struct RichTopicConfig {
    var titleStyle: VCFontConfig = .h1
    var tagTextStyle: VCFontConfig = .assist
    var tagInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    let tagOffset: CGFloat = 10
}

class RichTopicView: UIView {

    var title: String?
    let config: RichTopicConfig

    var intrinsicContentWidth: CGFloat {
        return Util.attributeWidth(attributeString: titleAttributedString, height: 32)
    }


    private lazy var titleParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = config.titleStyle.lineHeight
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = .center
        return style
    }()

    private lazy var titleAttribute: [NSAttributedString.Key: Any] = [.font: config.titleStyle.font, .paragraphStyle: titleParagraphStyle, .foregroundColor: UIColor.ud.textTitle]

    lazy var titleAttributedString = NSMutableAttributedString(string: "", attributes: titleAttribute)

    private lazy var webinarTagWidth: CGFloat = {
        let width = I18n.View_G_Webinar.vc.boundingWidth(height: config.tagTextStyle.lineHeight, font: config.tagTextStyle.font)
        return width + config.tagInset.left + config.tagInset.right + 0.5
    }()

    lazy var titleLabel: AttachmentLabel = {
        let titleLabel = AttachmentLabel()
        titleLabel.numberOfLines = 3
        titleLabel.backgroundColor = .clear
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.contentFont = config.titleStyle.font
        titleLabel.contentParagraphStyle = titleParagraphStyle

        titleLabel.addAttributedString(titleAttributedString)
        titleLabel.addArrangedSubview(webinarTagLabel)
        return titleLabel
    }()

    private lazy var webinarTagLabel: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.ud.udtokenTagBgBlue
        view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999.0), for: .horizontal)
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_G_Webinar, config: config.tagTextStyle, alignment: .center, lineBreakMode: .byTruncatingTail, textColor: .ud.udtokenTagTextSBlue)

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(config.tagInset.left)
            make.top.bottom.equalToSuperview().inset(config.tagInset.top)
        }

        return view
    }()

    init(config: RichTopicConfig) {
        self.config = config
        super.init(frame: .zero)
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.equalTo(intrinsicContentWidth)
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(getTitleHeight(width: bounds.width))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTitle(_ text: String, isWebinar: Bool = false) {
        guard !text.isEmpty else { return }

        title = text
        titleAttributedString.mutableString.setString(text)
        titleAttributedString.setAttributes(titleAttribute, range: NSRange(location: 0, length: text.utf16.count))

        if isWebinar {
            webinarTagLabel.isHidden = false
            titleLabel.updateArrangedSubview(webinarTagLabel) { [ weak self] in
                guard let self = self else { return }
                $0.margin = UIEdgeInsets(top: 2, left: self.config.tagOffset, bottom: 0, right: 0)
                $0.size = CGSize(width: self.webinarTagWidth, height: self.config.tagTextStyle.lineHeight + self.config.tagInset.top + self.config.tagInset.bottom)
            }
        } else {
            webinarTagLabel.isHidden = true
        }
        titleLabel.reload()
        let contentWidth = isWebinar ? intrinsicContentWidth + config.tagOffset + webinarTagWidth : intrinsicContentWidth
        titleLabel.snp.updateConstraints { make in
            make.width.equalTo(contentWidth)
        }
        layoutIfNeeded()
    }

    func updateHeight(with height: CGFloat) {
        titleLabel.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }

    func getTitleHeight(width: CGFloat) -> CGFloat {
        let lineHeight = config.titleStyle.lineHeight
        let height = Util.attributeHeight(attributeString: titleAttributedString, width: width, font: config.titleStyle.font, lineHeight: lineHeight)
        return height
    }
}
