//
//  SchedulerChangeHostView.swift
//  Calendar
//
//  Created by tuwenbo on 2023/4/3.
//

import Foundation
import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignCheckBox
import UniverseDesignTag
import UniverseDesignIcon
import LarkBizAvatar

protocol SchedulerHostDataType {
    var userID: String { get }
    var userName: String { get }
    var avatarKey: String { get }
    var isOwner: Bool { get }
    var isAvailable: Bool { get }
}

final class SchedulerChangeHostView: UIView {

    private let cellIdentifier = "RescheduleViewHostCell"

    var viewData: [SchedulerHostDataType] = [] {
        didSet {
            hostListView.reloadData()
        }
    }

    var selectedHostID: String = ""

    private lazy var hostListView = UITableView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        hostListView.register(SchedulerChangeHostCell.self, forCellReuseIdentifier: cellIdentifier)
        hostListView.dataSource = self
        hostListView.delegate = self
        hostListView.showsVerticalScrollIndicator = false
        hostListView.showsHorizontalScrollIndicator = false
        hostListView.backgroundColor = UIColor.ud.bgBody
        hostListView.separatorStyle = .none

        self.addSubview(hostListView)
        hostListView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension SchedulerChangeHostView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = viewData[indexPath.row]
        selectedHostID = user.userID
        tableView.reloadData()
    }
}


extension SchedulerChangeHostView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SchedulerChangeHostCell,
              let hostData = viewData[safeIndex: indexPath.row] else {
            return UITableViewCell()
        }

        cell.update(with: hostData, selectedID: selectedHostID)
        
        return cell
    }
}

extension SchedulerChangeHostView {
    final class SchedulerChangeHostCell: UITableViewCell {

        private lazy var checkbox: UDCheckBox = {
            let check = UDCheckBox()
            check.isUserInteractionEnabled = false
            return check
        }()

        private lazy var avatar: BizAvatar = {
            let imageView = BizAvatar()
            imageView.setAvatarUIConfig(.init(style: .circle))
            imageView.layer.masksToBounds = true
            return imageView
        }()

        private lazy var nameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body0(.fixed)
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            return label
        }()

        private lazy var hostTag: UDTag = {
            var tag = UDTag(withText: I18n.Calendar_Share_Owner)
            tag.sizeClass = .mini
            tag.colorScheme = .blue
            return tag
        }()

        private lazy var unavaiableIcon: UIImageView = {
            let image = UIImageView(image: UDIcon.getIconByKey(.timeFilled, iconColor: UIColor.ud.O400, size: CGSize(width: 14, height: 14)))
            return image
        }()

        // 包含名字、owner 标签、是否空闲图标
        private lazy var nameWarpper: UIStackView = {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 8
            stack.alignment = .center
            return stack
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.backgroundColor = UIColor.ud.bgBody
            layoutView()
        }

        let avatarSize: CGFloat = 40.auto()

        private lazy var paddingContent = UIView()

        private func layoutView() {
            contentView.addSubview(paddingContent)
            paddingContent.snp.makeConstraints { make in
                make.height.equalTo(66)
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }

            paddingContent.addSubview(checkbox)
            checkbox.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
                make.left.equalToSuperview()
            }

            paddingContent.addSubview(avatar)
            avatar.snp.makeConstraints { make in
                make.width.height.equalTo(avatarSize)
                make.centerY.equalToSuperview()
                make.left.equalTo(checkbox.snp.right).offset(12)
            }

            paddingContent.addSubview(nameWarpper)
            nameWarpper.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(avatar.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview()
            }

            nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            nameWarpper.addArrangedSubview(nameLabel)
            nameWarpper.addArrangedSubview(hostTag)
            nameWarpper.addArrangedSubview(unavaiableIcon)
        }

        func update(with data: SchedulerHostDataType, selectedID: String) {
            avatar.setAvatarByIdentifier(data.userID, avatarKey: data.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
            nameLabel.text = data.userName
            unavaiableIcon.isHidden = data.isAvailable
            hostTag.isHidden = !data.isOwner
            checkbox.isSelected = data.userID == selectedID
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
