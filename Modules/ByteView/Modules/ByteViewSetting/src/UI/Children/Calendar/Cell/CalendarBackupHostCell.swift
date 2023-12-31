//
//  CalendarBackupHostCell.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/8/30.
//

import Foundation
import ByteViewUI
import ByteViewCommon
import UniverseDesignIcon
import ByteViewNetwork

extension SettingCellType {
    static let calendarBackupHostCell = SettingCellType("calendarBackupHostCell", cellType: CalendarBackupHostCell.self)
}

extension SettingSectionBuilder {
    @discardableResult
    func calendarBackupHostCell(userInfo: ParticipantUserInfo, removeCallback: @escaping (String) -> Void) -> Self {
        return row(.backupHost, reuseIdentifier: .calendarBackupHostCell, title: I18n.View_G_AddHosts, cellStyle: .blankPaper, data: ["userInfo": userInfo, "removeCallback": removeCallback])
    }
}

final class CalendarBackupHostCell: SettingCell {
    let avatarImageView: AvatarView = AvatarView()
    lazy var tapView: UIView = {
        let view = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(gesture)
        return view
    }()

    lazy var iconView: UIView = {
        let img = UDIcon.getIconByKey(.closeBoldOutlined, iconColor: .ud.iconN2, size: CGSize(width: 12, height: 12))
        let imgView = UIImageView(image: img)
        return imgView
    }()

    override func setupViews() {
        super.setupViews()
        self.selectionStyle = .none
        self.leftView.addSubview(avatarImageView)
        self.rightView.addSubview(iconView)
        self.contentView.addSubview(tapView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(12)
        }
        tapView.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.width.equalTo(40)
        }
    }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        if let userInfo = row.data["userInfo"] as? ParticipantUserInfo {
            avatarImageView.setAvatarInfo(userInfo.avatarInfo, size: .large)
            titleLabel.attributedText = NSAttributedString(string: userInfo.name, config: cellStyle.titleStyleConfig)
        }
    }

    @objc
    func handleTap() {
        guard let userInfo = row?.data["userInfo"] as? ParticipantUserInfo, let removeCallback = row?.data["removeCallback"] as? (String) -> Void else { return }
        removeCallback(userInfo.id)
    }
}
