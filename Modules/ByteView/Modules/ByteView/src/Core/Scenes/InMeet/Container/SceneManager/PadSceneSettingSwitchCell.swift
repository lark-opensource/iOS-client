//
//  PadSceneSettingCellView.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/8/30.
//

import Foundation
import ByteViewCommon

class PadSceneSettingSwitchCell: PadSceneSettingBaseCell {

    private let titleLabel = UILabel()
    private lazy var switchView: VCSwitch = {
        let view = VCSwitch()
        view.setWidth(40)
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgFloat

        switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(switchView)
        // NOTE: @liujianlong 控件尺寸与 UD 设计规范不符合
        switchView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20.0)
//            make.height.equalTo(22.0)
//            make.width.equalTo(40.0)
        }
        switchView.valueChanged = { [weak self] (isOn) in
            guard let self = self, let currItem = self.item else { return }
            currItem.switchHandler?(isOn)
        }

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(8)
            make.right.equalTo(switchView.snp.left).offset(-12)
            make.left.equalTo(20)
        }
    }

    static var attributes: [NSAttributedString.Key: Any] = {
        return VCFontConfig.r_14_22.toAttributes()
    }()

    override func setCellInfo() {
        guard let currItem = self.item else { return }
        titleLabel.attributedText = NSAttributedString(string: currItem.title, attributes: Self.attributes)
        switchView.setOn(currItem.status, animated: false)
        switchView.displayMode = currItem.displayMode

        if currItem.displayMode == .normal {
            switchView.onTintColor = UIColor.ud.primaryContentDefault
            titleLabel.textColor = UIColor.ud.textTitle
        } else {
            switchView.onTintColor = UIColor.ud.primaryFillSolid03
            titleLabel.textColor = UIColor.ud.textDisabled
        }

        updateConstraints()
        layoutIfNeeded()
    }
}
