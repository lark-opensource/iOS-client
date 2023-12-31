//
//  RadioButtonSettingCell.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/28.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignCheckBox
import LarkOpenSetting
import LarkSettingUI

final class RadioButtonCellProp: CheckboxNormalCellProp {
    var onClickButton: ClickHandler?
    var isEditButtonEnabled: Bool = false

    init(title: String,
         detail: String? = nil,
         isOn: Bool,
         isEnabled: Bool = true,
         isEditButtonEnabled: Bool = false,
         cellIdentifier: String = "RadioButtonCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil,
         onClick: ClickHandler? = nil,
         onClickButton: ClickHandler? = nil) {
        self.isEditButtonEnabled = isEditButtonEnabled
        self.onClickButton = onClickButton
        super.init(title: title,
                   detail: detail,
                   boxType: .single,
                   isOn: isOn,
                   isEnabled: isEnabled,
                   cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: isEnabled ? selectionStyle : .none,
                   id: id,
                   onClick: onClick)
    }
}

final class RadioButtonCell: CheckboxNormalCell {
    lazy var editButton: UIButton = {
        let btn = UIButton()
        btn.setImage(Resources.message_edit_icon, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(tapHandler), for: UIControl.Event.touchUpInside)
        btn.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
        }
        return btn
    }()

    override func getTrailingView() -> UIView? {
        ViewHelper.createSizedView(size: CGSize(width: 16, height: 16))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.editButton)
        self.editButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? RadioButtonCellProp else { return }
        let img = info.isEditButtonEnabled ? Resources.message_edit_icon : Resources.message_disable_icon.ud.withTintColor(UIColor.ud.iconN3)
        self.editButton.setImage(img, for: UIControl.State.normal)
    }

    @objc
    func tapHandler() {
        guard let info = self.prop as? RadioButtonCellProp, info.isEditButtonEnabled else { return }
        info.onClickButton?(self)
    }
}
