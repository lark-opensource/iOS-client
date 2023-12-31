//
//  SettingSubTitleCell.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/25.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

/// Todo Setting 通用 UI ，右半部分为 SubTitle
final class SettingSubTitleCell: UIView {

    private let vStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        return stack
    }()

    private let hStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        return label
    }()

    private lazy var indicatorView: UIImageView = {
        let icon = UDIcon.getIconByKey(
            .rightOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 16, height: 16)
        )
        return UIImageView(image: icon.ud.withTintColor(UIColor.ud.iconN3))
    }()

    private var clickHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 10
        layer.masksToBounds = true

        addSubview(vStackView)
        addSubview(hStackView)
        vStackView.addArrangedSubview(titleLabel)
        vStackView.addArrangedSubview(descriptionLabel)

        hStackView.addArrangedSubview(subTitleLabel)
        hStackView.addArrangedSubview(indicatorView)

        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        layoutStackView(true)
        indicatorView.setContentCompressionResistancePriority(.required, for: .horizontal)
        indicatorView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(22)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTap() {
        clickHandler?()
    }

    func setup(title: String, description: String?, subTitle: String?, handler: (() -> Void)?) {
        titleLabel.text = title
        if let description = description, !description.isEmpty {
            descriptionLabel.isHidden = false
            descriptionLabel.text = description
        } else {
            descriptionLabel.isHidden = true
        }
        if let subTitle = subTitle, !subTitle.isEmpty {
            subTitleLabel.isHidden = false
            subTitleLabel.text = subTitle
        } else {
            subTitleLabel.isHidden = true
        }
        layoutStackView(!subTitleLabel.isHidden)
        clickHandler = handler
    }

    func updateTitle(title: String) {
        titleLabel.text = title
    }

    private func layoutStackView(_ hasSubTitle: Bool) {
        if hasSubTitle {
            vStackView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-16)
                make.width.lessThanOrEqualToSuperview().multipliedBy(0.67)
            }
            hStackView.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.left.greaterThanOrEqualTo(vStackView.snp.right).offset(12)
            }
        } else {
            hStackView.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
                make.width.equalTo(16)
            }
            vStackView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-16)
                make.right.equalTo(hStackView.snp.left).offset(-12)
            }
        }
    }

}
