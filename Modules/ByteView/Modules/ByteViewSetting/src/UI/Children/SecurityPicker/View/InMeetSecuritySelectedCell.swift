//
//  InMeetSecuritySelectedCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/11.
//

import Foundation
import ByteViewUI
import UniverseDesignIcon
import ByteViewNetwork

final class InMeetSecuritySelectedCell: UITableViewCell {
    private lazy var avatarView = AvatarView()
    private lazy var statusView = UserFocusTagView()

    var deleteAction: ((InMeetSecurityPickerItem) -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.N650, size: CGSize(width: 20, height: 20)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.N650.withAlphaComponent(0.5), size: CGSize(width: 20, height: 20)), for: .highlighted)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = .ud.fillHover
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        let insets = safeAreaInsets
        let marginLeft = (insets.left > 0) ? 0 : 16
        self.contentView.addSubview(self.avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            make.left.equalToSuperview().offset(marginLeft)
        }

        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(statusView)
        self.contentView.addSubview(deleteButton)

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(deleteButton.snp.left)
        }

        deleteButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-4)
            make.width.height.equalTo(44)
            make.centerY.equalToSuperview()
        }

        deleteButton.addTarget(self, action: #selector(didClickDelete(_:)), for: .touchUpInside)
    }

    var item: InMeetSecurityPickerItem?
    func config(_ item: InMeetSecurityPickerItem, setting: MeetingSettingManager) {
        self.item = item
        self.avatarView.setTinyAvatar(item.avatarInfo)
        self.titleLabel.attributedText = item.title
        self.statusView.setStatus(for: item)
    }

    @objc private func didClickDelete(_ sender: Any) {
        if let item = self.item, let action = self.deleteAction {
            action(item)
        }
    }
}
