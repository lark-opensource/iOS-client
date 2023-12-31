//
//  SettingRedirectDescriptionFooterView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/31.
//

import Foundation
import RichLabel
import SnapKit
import ByteViewCommon

extension SettingDisplayFooterType {
    static let redirectDescriptionFooter = SettingDisplayFooterType(reuseIdentifier: "redirectDescriptionFooter",
                                                                    footerViewType: SettingRedirectDescriptionFooterView.self)
}

class SettingRedirectDescriptionFooterView: SettingBaseFooterView {
    private enum Layout {
        /// 布局顶部缩进距离
        static let redirectDescriptionLabelTopSpacing: CGFloat = 4.0
        /// 布局水平缩进距离
        static let redirectDescriptionLabelHorizontalSpacing: CGFloat = 16.0
        /// 文字距离tableView的水平缩进距离
        static let redirectDescriptionLabelTextHorizontalSpacing: CGFloat = 32.0
    }

    let redirectDescriptionLabel = LKLabel(frame: .zero)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        backgroundColor = .clear

        addSubview(redirectDescriptionLabel)

        redirectDescriptionLabel.backgroundColor = .clear
        redirectDescriptionLabel.numberOfLines = 0
        redirectDescriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        redirectDescriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        redirectDescriptionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        redirectDescriptionLabel.setContentHuggingPriority(.required, for: .horizontal)

        redirectDescriptionLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.redirectDescriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.redirectDescriptionLabelHorizontalSpacing)
        }
    }

    override func config(for footer: SettingDisplayFooter, maxLayoutWidth: CGFloat, showSaperator: Bool = false) {
        super.config(for: footer, maxLayoutWidth: maxLayoutWidth, showSaperator: showSaperator)

        let paragraphStyle = NSMutableParagraphStyle()
        let lineHeight: CGFloat = footer.descriptionTextStyle.lineHeight
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedString = redirectDescriptionLabel.vc.config(for: footer.description,
                                                                  fontConfig: footer.descriptionTextStyle,
                                                                  paragraphStyle: paragraphStyle,
                                                                  serviceTerms: footer.serviceTerms)

        let height = attributedString.string.boundingRect(with: CGSize(width: CGFloat(maxLayoutWidth - Layout.redirectDescriptionLabelTextHorizontalSpacing * 2),
                                                                       height: CGFloat(MAXFLOAT)),
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: [NSAttributedString.Key.font: footer.descriptionTextStyle.font,
                                                                       NSAttributedString.Key.paragraphStyle: paragraphStyle],
                                                          context: nil).height

        redirectDescriptionLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.redirectDescriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.redirectDescriptionLabelHorizontalSpacing)
            $0.height.equalTo(height)
        }
    }
}
