//
//  SettingTitleHeaderView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation

extension SettingDisplayHeaderType {
    static let titleHeader = SettingDisplayHeaderType(reuseIdentifier: "titleHeader",
                                                      headerViewType: SettingTitleHeaderView.self)
}

class SettingTitleHeaderView: SettingBaseHeaderView {
    private enum Layout {
        static let titleLabelLeftSpacing: CGFloat = 16.0
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

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(contentInsets.top)
            make.bottom.equalToSuperview().inset(contentInsets.bottom)
            make.left.equalToSuperview().offset(Layout.titleLabelLeftSpacing)
            make.right.equalToSuperview()
        }
    }

    override func config(for header: SettingDisplayHeader, maxLayoutWidth: CGFloat, contentInsets: UIEdgeInsets, showSaperator: Bool = false) {
        super.config(for: header, maxLayoutWidth: maxLayoutWidth, contentInsets: contentInsets, showSaperator: showSaperator)
        titleLabel.attributedText = NSAttributedString(string: header.title,
                                                       config: header.titleTextStyle,
                                                       textColor: header.titleStyle.color)
        titleLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(contentInsets.top)
            $0.bottom.equalToSuperview().inset(contentInsets.bottom)
            $0.left.equalToSuperview().offset(Layout.titleLabelLeftSpacing)
            $0.right.equalToSuperview()
        }
    }
}
