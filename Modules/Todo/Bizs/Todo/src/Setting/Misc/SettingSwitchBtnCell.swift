//
//  SettingSwitchBtnCell.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/25.
//

import Foundation
import UniverseDesignFont

/// Todo Setting 通用 UI ，右半部分为 SwitchButton
final class SettingSwitchBtnCell: UIView {

    let switchBtn: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor.ud.functionInfoContentDefault
        return switchControl
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    var valueChangedHandler: ((_ isOn: Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = 10
        layer.masksToBounds = true
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(switchBtn)

        switchBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(22)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(switchBtn.snp.left).offset(-12)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(switchBtn.snp.left).offset(-12)
            make.bottom.equalToSuperview().offset(-14)
        }
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        switchBtn.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(title: String, description: String, isOn: Bool) {
        titleLabel.text = title
        descriptionLabel.text = description
        switchBtn.isOn = isOn
    }

    @objc
    private func switchChanged(sender: UISwitch) {
        valueChangedHandler?(sender.isOn)
    }

    override var intrinsicContentSize: CGSize {
        let height = max(22 + descriptionLabel.intrinsicContentSize.height + 14 + 12, 48)
        return CGSize(width: Self.noIntrinsicMetric, height: height)
    }

}
