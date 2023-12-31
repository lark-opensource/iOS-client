//
//  SwitchSettingTableCell.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/27.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class SwitchSettingTableCell: NormalSettingTableCell {

    public var onSwitch: ((Bool) -> Void)?

    public var isOn: Bool = false {
        didSet {
            switcher.isOn = isOn
        }
    }

    private lazy var switchWrapper = UIView()

    lazy var switcher: UISwitch = {
        let switcher = UISwitch()
        switcher.onTintColor = UIColor.ud.primaryContentDefault
        return switcher
    }()

    override func setupSubclass() {
        let index = contentContainer.arrangedSubviews.count - 1
        contentContainer.insertArrangedSubview(switchWrapper, at: index)
        switchWrapper.addSubview(switcher)
        switchWrapper.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.equalTo(50)
        }
        switcher.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        selectionStyle = .none
        switcher.addTarget(self,
                           action: #selector(didChangeSwitch(_:)),
                           for: .valueChanged)
    }

    @objc
    private func didChangeSwitch(_ sender: UISwitch) {
        onSwitch?(sender.isOn)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // iOS 13 以下 UILabel 在自适应 Cell 中布局有问题
        if #available(iOS 13, *) {} else {
            titleLabel.preferredMaxLayoutWidth = bounds.width - 85
            detailLabel.preferredMaxLayoutWidth = bounds.width - 85
        }
    }
}
