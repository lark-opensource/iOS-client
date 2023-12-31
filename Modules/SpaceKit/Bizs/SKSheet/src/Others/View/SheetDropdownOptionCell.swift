//
// Created by duanxiaochen.7 on 2019/8/20.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - SheetDropdown List - TableVIewCell

import Foundation
import SKCommon
import LarkTag
import SKResource
import UniverseDesignIcon
import UniverseDesignColor

class SheetDropdownOptionCell: UITableViewCell {
    private lazy var pLabel: PaddingUILabel = {
        let label = PaddingUILabel()
        label.paddingLeft = 12
        label.paddingRight = 12
        label.paddingTop = 1
        label.paddingBottom = 1
        label.layer.masksToBounds = true
        label.text = "option"
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.color = .clear
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        return label
    }()

    private lazy var checkmark: UIImageView = {
        let view = UIImageView(image: UDIcon.doneOutlined.ud.withTintColor(UIColor.ud.colorfulBlue))
        return view
    }()

    private lazy var bgView: UIView = {
        let view = UIView(frame: frame)
        view.backgroundColor = UDColor.fillPressed
        return view
    }()

    private lazy var separator: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width - 16, height: 0.5))
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectedBackgroundView = bgView
        contentView.addSubview(pLabel)
        pLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(24)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-36)
        }
        contentView.addSubview(checkmark)
        checkmark.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
            make.right.equalToSuperview().offset(-16)
        }
        checkmark.isHidden = true
        contentView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String, bgColor: UIColor?, textColor: UIColor, isSelected: Bool) {
        pLabel.text = text
        pLabel.textColor = textColor
        if let bgColor = bgColor {
            pLabel.color = bgColor
        } else {
            pLabel.color = .clear
        }
        checkmark.isHidden = !isSelected
    }

}
