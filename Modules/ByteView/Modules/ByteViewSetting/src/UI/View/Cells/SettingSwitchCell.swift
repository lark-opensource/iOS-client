//
//  SettingSwitchCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

extension SettingCellType {
    static let switchCell = SettingCellType("switchCell", cellType: SettingSwitchCell.self)
    static let upgradableSwitchCell = SettingCellType("upgradableSwitchCell", cellType: UpgradableSettingSwitchCell.self)
}

extension SettingSectionBuilder {
    @discardableResult
    func switchCell(_ item: SettingDisplayItem, title: String, subtitle: String? = nil,
                    serviceTerms: String? = nil, useLKLabel: Bool? = false, cellStyle: SettingCellStyle = .insetCorner,
                    isOn: Bool, isEnabled: Bool = true, showsDisabledButton: Bool = false,
                    autoJump: Bool = false, data: [String: Any] = [:],
                    if condition: @autoclosure () -> Bool = true,
                    action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        var data = data
        data["showsDisabledButton"] = showsDisabledButton
        return row(SettingDisplayRow(
            item: item, cellType: .switchCell, title: title, subtitle: subtitle, serviceTerms: serviceTerms, useLKLabel: useLKLabel, cellStyle: cellStyle,
            isOn: isOn, isEnabled: isEnabled, showsRightView: true, autoJump: autoJump, data: data, action: action
        ), if: condition())
    }
}

protocol SettingSwitchCellDelegate: AnyObject {
    func didClickSwitchCell(_ cell: SettingSwitchCell, isOn: Bool)
    func didClickDisabledSwitchCell(_ cell: SettingSwitchCell, sender: UIView)
}

class SettingSwitchCell: SettingCell {
    let switchControl = UISwitch()
    let disableButton = UIButton()
    weak var delegate: SettingSwitchCellDelegate?

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .none
        self.rightView.addSubview(switchControl)
        self.rightView.addSubview(disableButton)
        disableButton.isHidden = true
        disableButton.addTarget(self, action: #selector(didClickDisableButton), for: .touchUpInside)

        let size = CGSize(width: 46.0, height: 28.0)
        let intrinsicSize = CGSize(width: 51.0, height: 31.0)
        /// https://stackoverflow.com/questions/25104605/changing-uiswitch-width-and-height
        switchControl.transform = CGAffineTransform(scaleX: size.width / intrinsicSize.width, y: size.height / intrinsicSize.height)
        switchControl.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        disableButton.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.edges.equalToSuperview()
        }

        switchControl.addTarget(self, action: #selector(didChangeSwitchValue), for: .valueChanged)
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        self.switchControl.isEnabled = row.isEnabled
        self.switchControl.isOn = row.isOn
        if let showsDisabledButton = row.data["showsDisabledButton"] as? Bool, showsDisabledButton {
            self.disableButton.isHidden = row.isEnabled
        } else {
            self.disableButton.isHidden = true
        }

        if !row.isEnabled {
            self.switchControl.tintColor = .ud.lineBorderCard // 关闭状态下的背景空色
            self.switchControl.onTintColor = .ud.primaryFillSolid03 // 打开状态下的背景颜色
            self.switchControl.thumbTintColor = .ud.primaryOnPrimaryFill // 滑块的颜色
        } else {
            self.switchControl.tintColor = .ud.lineBorderComponent // 关闭状态下的背景空色
            self.switchControl.onTintColor = .ud.primaryContentDefault // 打开状态下的背景颜色
            self.switchControl.thumbTintColor = .ud.primaryOnPrimaryFill // 滑块的颜色
        }
    }

    @objc private func didChangeSwitchValue() {
        delegate?.didClickSwitchCell(self, isOn: switchControl.isOn)
    }

    @objc private func didClickDisableButton() {
        delegate?.didClickDisabledSwitchCell(self, sender: self.disableButton)
    }
}

final class UpgradableSettingSwitchCell: SettingSwitchCell {
    let upgradeButton = UIButton()

    override func setupViews() {
        super.setupViews()
        upgradeButton.setImage(UDIcon.getIconByKey(.infoOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16)), for: .normal)
        addSubview(upgradeButton)
        upgradeButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(32)
        }
        upgradeButton.addTarget(self, action: #selector(didClickUpgrade), for: .touchUpInside)
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        self.disableButton.isHidden = true
        let shouldUpgrade = (row.data["shouldUpgrade"] as? Bool) ?? !row.isEnabled
        self.upgradeButton.isHidden = !shouldUpgrade
    }

    @objc private func didClickUpgrade() {
        delegate?.didClickDisabledSwitchCell(self, sender: self.upgradeButton)
    }
}
