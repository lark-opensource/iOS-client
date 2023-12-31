//
//  PSTNAreaCodeCell.swift
//  ByteView
//
//  Created by yangyao on 2020/4/14.
//

import UIKit
import UniverseDesignIcon

class PSTNAreaCodeCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var selectedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.doneOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20))
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.ud.bgBody

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView

        contentView.addSubview(titleLabel)
        contentView.addSubview(selectedImageView)
        addSubview(separator)

        titleLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(22).priority(.high)
            maker.right.lessThanOrEqualToSuperview().inset(16)
        }
        selectedImageView.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { (maker) in
            maker.height.equalTo(0.5)
            maker.bottom.equalToSuperview()
            maker.left.equalTo(titleLabel)
            maker.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
