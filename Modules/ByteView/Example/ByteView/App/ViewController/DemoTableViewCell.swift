//
//  BaseTableViewCell.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/11.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewUI
import ByteViewCommon

class DemoTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .ud.bgFloat
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = .ud.fillHover
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.selectionStyle = .default
        self.titleLabel.textColor = UIColor.ud.N900
        self.titleLabel.font = .systemFont(ofSize: 16)
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }
    }

    func updateItem(_ row: DemoCellRow) {
        self.titleLabel.text = row.title
    }
}

class DemoSwitchCell: DemoTableViewCell {
    let switchControl = UISwitch()
    private var action: ((Bool) -> Void)?

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .none
        contentView.addSubview(switchControl)
        switchControl.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(8)
        }
        switchControl.addTarget(self, action: #selector(didSwitchControl), for: .valueChanged)
    }


    override func updateItem(_ row: DemoCellRow) {
        super.updateItem(row)
        self.switchControl.isOn = row.isOn
        self.action = row.swAction
    }

    @objc private func didSwitchControl() {
        self.action?(switchControl.isOn)
    }
}

class DemoCheckmarkCell: DemoTableViewCell {
    private static let checkmark = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
    let checkView = UIImageView(image: DemoCheckmarkCell.checkmark)

    override func setupViews() {
        super.setupViews()
        contentView.addSubview(checkView)
        checkView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.width.height.equalTo(16)
        }
    }

    override func updateItem(_ row: DemoCellRow) {
        super.updateItem(row)
        self.checkView.isHidden = !row.isOn
    }
}

class DemoUserCell: DemoTableViewCell {
    let avatarView = DemoAvatarView()
    let subtitleLabel = UILabel()

    override func setupViews() {
        super.setupViews()
        contentView.addSubview(avatarView)
        contentView.addSubview(subtitleLabel)
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }

        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .ud.textTitle
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView.snp.centerY).offset(-11)
            make.right.lessThanOrEqualToSuperview()
        }

        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .ud.textPlaceholder
        subtitleLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.centerY.equalTo(avatarView.snp.centerY).offset(14)
            make.right.lessThanOrEqualToSuperview()
        }
    }
}

final class DemoAvatarView: UIView {
    private lazy var avatarView: AvatarView = {
        let view = AvatarView(style: .circle)
        view.tag = 1
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.tag = 2
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    func setAvatarInfo(_ avatarInfo: AvatarInfo) {
        subviews.forEach {
            $0.isHidden = $0.tag != 1
        }
        avatarView.setAvatarInfo(avatarInfo)
    }

    func setImageURL(_ url: String, accessToken: String) {
        subviews.forEach {
            $0.isHidden = $0.tag != 2
        }
        imageView.vc.setImage(url: url, accessToken: accessToken)
    }
}
