//
//  SettingDescriptionFooterView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation

extension SettingDisplayFooterType {
    static let descriptionFooter = SettingDisplayFooterType(reuseIdentifier: "descriptionFooter",
                                                            footerViewType: SettingDescriptionFooterView.self)
}

class SettingDescriptionFooterView: SettingBaseFooterView {
    private enum Layout {
        static let descriptionLabelTopSpacing: CGFloat = 2.0
        static let descriptionLabelHorizontalSpacing: CGFloat = 16.0
    }

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        addSubview(descriptionLabel)
        descriptionLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.descriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.descriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.descriptionLabelHorizontalSpacing)
        }
    }

    override func config(for footer: SettingDisplayFooter, maxLayoutWidth: CGFloat, showSaperator: Bool = false) {
        super.config(for: footer, maxLayoutWidth: maxLayoutWidth, showSaperator: showSaperator)
        descriptionLabel.attributedText = NSAttributedString(string: footer.description,
                                                             config: footer.descriptionTextStyle,
                                                             textColor: footer.descriptionTextColor)
        descriptionLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.descriptionLabelTopSpacing)
            $0.left.equalToSuperview().offset(Layout.descriptionLabelHorizontalSpacing)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.descriptionLabelHorizontalSpacing)
        }
    }
}
