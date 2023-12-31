//
//  MeetingRoomDetailCellView.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/1/13.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkTag
import Kingfisher

final class MeetingRoomDetailCellView: UIView {

    enum MeetingRoomDetailCellType {
        // basicInfo
        case capcity
        case equipments
        case resourceStrategy
        case remarks
        case picture
        case creator
        // stateInfo
        case scheduledTime
        case booker
        case cantUse
    }

    var leadingIcon: UIImageView?

    var contentView: UIView?

    var cellData: (type: MeetingRoomDetailCellType, content: [String])? {
        didSet {
            guard oldValue?.content != cellData?.content,
                  oldValue?.type != cellData?.type,
                  let cellData = cellData else { return }
            subviews.forEach { (subview) in subview.removeFromSuperview() }
            leadingIcon = getIcon(with: cellData.type)
            contentView = getContentView(content: cellData.content, with: cellData.type)
            addSubview(leadingIcon ?? UIView())
            addSubview(contentView ?? UIView())

            leadingIcon?.snp.makeConstraints {
                $0.left.equalToSuperview().offset(16)
                if cellData.type == .booker {
                    $0.centerY.equalToSuperview()
                } else {
                    $0.centerY.equalTo(10 + 19.5 / 2)
                }
            }
            contentView?.snp.makeConstraints {
                // 水平约束由壳子做
                $0.left.equalToSuperview().offset(48)
                $0.right.equalToSuperview().offset(-16)
                // 纵向约束由 content 处理
                $0.top.bottom.equalToSuperview()
            }
        }
    }

    private func getIcon(with type: MeetingRoomDetailCellType) -> UIImageView {
        let icon = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 16, height: 16)))
        switch type {
        case .capcity:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3)
        case .equipments:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.infoOutlined).renderColor(with: .n3)
        case .resourceStrategy:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.boardsOutlined).renderColor(with: .n3)
        case .remarks:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.fileLinkWordOutlined).renderColor(with: .n3)
        case .picture:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.imageOutlined).renderColor(with: .n3)
        case .scheduledTime:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.timeOutlined).renderColor(with: .n3)
        case .booker:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.memberOutlined).renderColor(with: .n3)
        case .cantUse:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.warningOutlined).renderColor(with: .n3)
        case .creator:
            icon.image = UDIcon.getIconByKeyNoLimitSize(.warningOutlined).renderColor(with: .n3)
        }
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        return icon
    }

    private func getContentView(content: [String], with type: MeetingRoomDetailCellType) -> UIView {
        let contentView = UIView()
        switch type {
        case .capcity, .equipments, .remarks, .scheduledTime, .creator:
            let label = UILabel()
            label.attributedText = getNSAttributeString(text: content.first ?? "")
            label.numberOfLines = 0
            contentView.addSubview(label)
            label.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.right.lessThanOrEqualToSuperview()
                $0.top.equalToSuperview().offset(10)
                $0.bottom.equalToSuperview().offset(-10)
            }
        case .resourceStrategy, .cantUse:
            var labelArray = [UILabel]()
            content.enumerated().forEach { (index, labelText) in
                let label = UILabel()
                label.text = labelText
                label.font = UIFont.systemFont(ofSize: 16)
                label.lineBreakMode = .byWordWrapping
                label.numberOfLines = 0
                contentView.addSubview(label)
                labelArray.append(label)
                label.snp.makeConstraints {
                    $0.left.equalToSuperview()
                    $0.right.lessThanOrEqualToSuperview()
                    // 纵向约束
                    if index == 0 {
                        $0.top.equalToSuperview().offset(10)
                    } else {
                        $0.top.equalTo(labelArray[index - 1].snp.bottom)
                    }
                    if index == content.count - 1 {
                        $0.bottom.equalToSuperview().offset(-10)
                    }
                }
            }
        case .picture:
            let picture = UIImageView()
            picture.layer.cornerRadius = 4
            picture.clipsToBounds = true
            picture.contentMode = .scaleAspectFill
            contentView.addSubview(picture)
            let url = URL(string: content.first ?? "")!
            picture.kf.setImage(with: url)
            picture.kf.indicatorType = .activity
            pictureView = picture
            picture.snp.makeConstraints {
                $0.left.right.centerY.equalToSuperview()
                $0.top.equalToSuperview().offset(10)
                $0.bottom.equalToSuperview().offset(-10)
                $0.height.equalTo(contentView.snp.width).multipliedBy(2.0 / 3.0)
            }
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pictureTapped))
            picture.addGestureRecognizer(tapGesture)
            picture.isUserInteractionEnabled = true
        case .booker:
            // 头像
            let avatar = AvatarView()
            guard content.count == 4 else {
                assertionFailure("参数不足")
                return UIView()
            }
            let avatarData = AvatarImpl(avatarKey: content[0], userName: content[1], identifier: content[2])
            avatar.setAvatar(avatarData, with: 28)
            contentView.addSubview(avatar)
            avatar.snp.makeConstraints {
                $0.left.equalToSuperview()
                $0.centerY.equalToSuperview()
                $0.height.width.equalTo(28)
            }
            // 姓名
            let nameLabel = UILabel()
            nameLabel.text = content[1]
            nameLabel.font = UIFont.systemFont(ofSize: 16)
            // tag
            let tag = TagWrapperView.titleTagView(
                for: Tag(title: BundleI18n.Calendar.Calendar_Detail_Organizer,
                                 style: .blue,
                                 type: .customTitleTag)
            )
            // chatButton
            let chatButton = UIButton()
            chatButton.setImage(UDIcon.getIconByKey(.chatOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 20, height: 20)), for: .normal)
            chatButton.addTarget(self, action: #selector(chatBtnTapped), for: .touchUpInside)
            contentView.addSubview(chatButton)
            chatButton.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(-16)
                $0.size.equalTo(CGSize(width: 20, height: 20))
            }
            chatterID = content[2]

            let nameStack = UIStackView(arrangedSubviews: [nameLabel, tag])
            nameStack.spacing = 4
            contentView.addSubview(nameStack)
            nameStack.snp.makeConstraints {
                $0.top.equalTo(10)
                $0.left.equalTo(avatar.snp.right).offset(8)
                $0.right.lessThanOrEqualTo(chatButton.snp.left).offset(-8)
            }

            // 部门
            let departmentLabel = UILabel()
            departmentLabel.text = content[3]
            departmentLabel.lineBreakMode = .byTruncatingTail
            departmentLabel.font = UIFont.systemFont(ofSize: 12)
            departmentLabel.textColor = UIColor.ud.textPlaceholder
            contentView.addSubview(departmentLabel)
            departmentLabel.snp.makeConstraints {
                $0.left.equalTo(nameLabel.snp.left)
                $0.right.lessThanOrEqualTo(chatButton.snp.left).offset(-8)
                $0.top.equalTo(nameLabel.snp.bottom)
                $0.bottom.equalToSuperview().offset(-10)
            }
        }
        return contentView
    }

    private func getNSAttributeString(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                          NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 16),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        return NSAttributedString(string: text, attributes: attributes)
    }

    // booker 类型中，预定者跳 chat 页面
    var chatBtnClick: ((_ chatterID: String) -> Void)?

    private var chatterID: String?

    @objc
    private func chatBtnTapped() {
        guard let chatterID = chatterID else { return }
        chatBtnClick?(chatterID)
    }

    public var pictureClickHandler: ((_ image: UIImageView) -> Void)?

    private var pictureView: UIImageView?

    @objc
    private func pictureTapped() {
        guard let image = pictureView else { return }
        pictureClickHandler?(image)
    }
}
