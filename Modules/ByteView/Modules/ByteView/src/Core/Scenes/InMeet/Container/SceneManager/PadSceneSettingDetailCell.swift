//
//  PadSceneSettingDetailCell.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/11/17.
//

import Foundation
import ByteViewCommon

class PadSceneSettingDetailCell: PadSceneSettingBaseCell {

    private lazy var bgView: UIView = {
        let innerView = UIView()
        innerView.backgroundColor = .ud.fillHover
        innerView.layer.cornerRadius = 8

        let view = UIView()
        view.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgFloat
        selectedBackgroundView = bgView

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(8)
            make.right.lessThanOrEqualToSuperview().offset(-12)
            make.left.equalTo(20)
        }
    }

    override func setCellInfo() {
        guard let currItem = self.item else { return }
        titleLabel.attributedText = NSAttributedString(string: currItem.title, config: .r_14_22)
        updateConstraints()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0))
    }
}
