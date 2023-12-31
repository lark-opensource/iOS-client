//
//  SettingTitleAndRedirectDescriptionHeaderView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/12/5.
//

import Foundation
import RichLabel
import SnapKit
import ByteViewCommon

extension SettingDisplayHeaderType {
    static let titleAndRedirectDescriptionHeader = SettingDisplayHeaderType(reuseIdentifier: "titleAndRedirectDescriptionHeader",
                                                                            headerViewType: SettingTitleAndRedirectDescriptionHeaderView.self)
}

class SettingTitleAndRedirectDescriptionHeaderView: SettingBaseHeaderView {
    private enum Layout {
        static let titleLabelTopSpacing: CGFloat = 26.0
        static let titleLabelHorizontalSpacing: CGFloat = 16.0
        static let titleLabelHeight: CGFloat = 24.0
        static let redirectDescriptionLabelTopSpacing: CGFloat = 4.0
        static let redirectDescriptionLabelHorizontalSpacing: CGFloat = 16.0
        /// 文字距离tableView的水平缩进距离
        static let redirectDescriptionLabelTextHorizontalSpacing: CGFloat = 32.0
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    let redirectDescriptionLabel = LKLabel(frame: .zero)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        backgroundColor = .clear

        addSubview(titleLabel)

        titleLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.titleLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.titleLabelHorizontalSpacing)
            $0.right.equalToSuperview().inset(Layout.titleLabelHorizontalSpacing)
            $0.height.equalTo(Layout.titleLabelHeight)
        }

        addSubview(redirectDescriptionLabel)

        redirectDescriptionLabel.backgroundColor = .clear
        redirectDescriptionLabel.numberOfLines = 0
        redirectDescriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        redirectDescriptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        redirectDescriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        redirectDescriptionLabel.setContentHuggingPriority(.required, for: .horizontal)

        redirectDescriptionLabel.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.redirectDescriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.redirectDescriptionLabelHorizontalSpacing)
        }
    }

    override func config(for header: SettingDisplayHeader, maxLayoutWidth: CGFloat, contentInsets: UIEdgeInsets, showSaperator: Bool = false) {
        super.config(for: header, maxLayoutWidth: maxLayoutWidth, contentInsets: contentInsets, showSaperator: showSaperator)

        titleLabel.attributedText = NSAttributedString(string: header.title, config: .r_16_24, textColor: .ud.textTitle)

        guard let description = header.description else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        let lineHeight: CGFloat = VCFontConfig.r_14_22.lineHeight
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedString = redirectDescriptionLabel.vc.config(for: description,
                                                               fontConfig: VCFontConfig.r_14_22,
                                                               paragraphStyle: paragraphStyle,
                                                               serviceTerms: header.serviceTerms)

        let height = attributedString.string.boundingRect(with: CGSize(width: CGFloat(maxLayoutWidth - Layout.redirectDescriptionLabelTextHorizontalSpacing * 2),
                                                                       height: CGFloat(MAXFLOAT)),
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: [.font: VCFontConfig.r_14_22.font,
                                                                       .paragraphStyle: paragraphStyle],
                                                          context: nil).height

        redirectDescriptionLabel.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.redirectDescriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.height.equalTo(height)
        }
    }
}

extension VCExtension where BaseType == LKLabel {
    @discardableResult
    func config(for text: String, fontConfig: VCFontConfig, paragraphStyle: NSParagraphStyle, serviceTerms: String?) -> NSAttributedString {
        let linkText = LinkTextParser.parsedLinkText(from: text)
        let linkFont = fontConfig.font
        for component in linkText.components {
            var link = LKTextLink(range: component.range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                               .font: linkFont],
                                  activeAttributes: [.backgroundColor: UIColor.clear])

            link.linkTapBlock = { (_, _) in
                if let serviceTerms = serviceTerms, let url = URL(string: serviceTerms) {
                    UIApplication.shared.open(url)
                }
            }
            base.addLKTextLink(link: link)
        }
        let attributedString = NSAttributedString(string: linkText.result,
                                                  attributes: [.font: linkFont,
                                                               .paragraphStyle: paragraphStyle,
                                                               .foregroundColor: UIColor.ud.textPlaceholder])
        base.attributedText = attributedString
        return attributedString
    }
}
