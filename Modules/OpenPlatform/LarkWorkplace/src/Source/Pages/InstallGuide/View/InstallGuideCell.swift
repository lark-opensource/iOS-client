//
//  InstallGuideCell.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/13.
//

import UIKit
import LarkUIKit
import LarkLocalizations
import UniverseDesignIcon

final class InstallGuideCell: UITableViewCell {
    /// 通用边距
    let commonInset: CGFloat = 16.0
    /// checkBox尺寸
    let checkBoxSide: CGFloat = 18.0
    /// checkBox右边距
    let checkBoxRightInset: CGFloat = 25.0
    /// cell高度
    static let cellHeight: CGFloat = 72.0

    enum Action {
        case tapIconOrName(_ model: InstallGuideAppViewModel)
        case select(_ value: Bool, _ model: InstallGuideAppViewModel)
    }

    private let iconView: WPMaskImageView = {
        let vi = WPMaskImageView()
        vi.layer.masksToBounds = true
        vi.sqRadius = WPUIConst.AvatarRadius.middle
        vi.sqBorder = WPUIConst.BorderW.pt1
        return vi
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        label.font = UIFont.systemFont(ofSize: 17)
        // swiftlint:enable init_font_with_token
        label.textColor = UIColor.ud.textTitle
        label.isUserInteractionEnabled = true
        return label
    }()
    private let arrow: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.isUserInteractionEnabled = true
        return label
    }()
    private let checkbox: Checkbox = {
        let box = Checkbox()
        box.setupAppCenterStyle()
        box.minTouchSize = CGSize(width: 72, height: 72)
        return box
    }()
    private let separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private var model: InstallGuideAppViewModel?

    var actionHandler: ((Action) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(checkbox)
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(arrow)
        contentView.addSubview(descLabel)
        contentView.addSubview(separatorLine)

        let ges = UITapGestureRecognizer(target: self, action: #selector(tapCell))
        contentView.addGestureRecognizer(ges)

        checkbox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
            make.left.equalToSuperview().offset(16)
        }
        checkbox.addTarget(self, action: #selector(checkboxChanged(checkbox:)), for: .valueChanged)

        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(WPUIConst.AvatarSize.middle)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(10)
            make.top.equalToSuperview().offset(15)
        }

        arrow.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(10)
            make.bottom.equalToSuperview().offset(-15)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.right.equalTo(arrow.snp.left).offset(-25)
        }

        separatorLine.isHidden = true
        separatorLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(model: InstallGuideAppViewModel) {
        self.model = model
        iconView.bt.setLarkImage(
            with: .avatar(
                key: model.app.iconKey ?? "",
                entityID: "",
                params: .init(sizeType: .size(WPUIConst.AvatarSize.middle))
            )
        )
        nameLabel.text = model.app.name
        descLabel.text = model.app.description
        descLabel.numberOfLines = (LanguageManager.currentLanguage == .zh_CN ? 1 : 2)   // 描述标签：中文语言，最多显示一行；其他语言，最多显示两行
        checkbox.setOn(on: model.isSelected)
    }

    @objc
    private func tapCell() {
        if let model = model {
            self.actionHandler?(.tapIconOrName(model))
        }
    }

    @objc
    private func checkboxChanged(checkbox: Checkbox) {
        if let model = model {
            self.actionHandler?(.select(checkbox.on, model))
        }
    }
}

extension Checkbox {
    func setupAppCenterStyle() {
        lineWidth = 1.0
        strokeColor = UIColor.ud.textPlaceholder
        onCheckColor = UIColor.ud.primaryOnPrimaryFill
        onFillColor = UIColor.ud.primaryContentDefault
    }
}
