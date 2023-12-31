////
////  SceneDetailSwitchCell.swift
////  LarkAI
////
////  Created by Zigeng on 2023/10/10.
////

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignColor
import LarkFeatureGating
import SnapKit
import UniverseDesignSwitch

class SceneDetailSwitchCell: UITableViewCell, SceneDetailCell {
    typealias VM = SceneDetailSwitchCellViewModel
    static let identifier = "SceneDetailSwitchCell"

    private let switchButton: UDSwitch = {
        let btn = UDSwitch()
        btn.backgroundColor = .clear
        return btn
    }()

    @objc
    func updateSwitchStatus() {
        self.switchButton.setOn(!switchButton.isOn, animated: true)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textPlaceholder
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.height.equalTo(86)
            make.edges.equalToSuperview()
        }
        container.addSubview(switchButton)
        switchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(switchButton.snp.left).offset(-12)
        }
        container.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(switchButton.snp.left).offset(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCell(vm: VM) {
        self.titleLabel.text = vm.title
        self.subTitleLabel.text = vm.subTitle
        self.switchButton.setOn(vm.isSelected, animated: true)
        self.switchButton.valueChanged = { value in
            vm.isSelected = value
        }
    }
}
