//
//  TimePickerSwitchBtnCell.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/8.
//

import Foundation
import UniverseDesignFont

final class TimePickerSwitchBtnCell: UIView {

    var isOn: Bool {
        get { switchBtn.isOn }
        set { switchBtn.isOn = newValue }
    }

    var didSwitch: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    private let switchBtn: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor.ud.functionInfoContentDefault
        return switchControl
    }()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        titleLabel.text = title
        addSubview(titleLabel)
        addSubview(switchBtn)
        switchBtn.addTarget(self, action: #selector(handleTap), for: .valueChanged)

        switchBtn.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.lessThanOrEqualTo(switchBtn.snp.left).offset(-16)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap(_ sender: UISwitch) {
        didSwitch?(sender.isOn)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 60)
    }
}
