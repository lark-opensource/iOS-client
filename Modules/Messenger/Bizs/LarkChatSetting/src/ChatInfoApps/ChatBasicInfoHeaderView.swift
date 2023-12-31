//
//  ChatBasicInfoHeaderView.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/21.
//

import Foundation
import UIKit
import LarkTag
import LarkBizAvatar

protocol ChatBasicInfoHeaderViewDelegate: AnyObject {
    func iconTouch()
}

struct ChatBasicInfo {
    var avatarKey: String = ""
    var entityId: String = ""
    var name: String = ""
    var details: [String] = []
    var tags: [TagType] = []
}

final class ChatBasicInfoHeaderView: UIView {
    weak var delegate: ChatBasicInfoHeaderViewDelegate?
    let avatarWrapper: UIView
    private let nameLabel: UILabel
    private let tagView: TagWrapperView
    private var detailStack: UIStackView?
    private let avatarImageView: BizAvatar
    private let avatarSize: CGFloat = 72

    init(basicInfo: ChatBasicInfo) {
        self.avatarWrapper = UIView(frame: .zero)
        self.nameLabel = UILabel(frame: .zero)
        self.tagView = TagWrapperView()
        self.avatarImageView = BizAvatar()
        super.init(frame: .zero)
        self.addSubview(avatarWrapper)
        avatarWrapper.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(9)
            make.centerX.equalToSuperview()
        }
        avatarImageView.setAvatarByIdentifier(basicInfo.entityId, avatarKey: basicInfo.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        avatarWrapper.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }
        avatarWrapper.lu.addTapGestureRecognizer(action: #selector(iconTouch), target: self)

        self.nameLabel.text = basicInfo.name
        nameLabel.numberOfLines = 1
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.textAlignment = .center
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarWrapper.snp.bottom).offset(8)
            make.left.greaterThanOrEqualTo(16)
        }

        self.addSubview(tagView)
        tagView.setTags(basicInfo.tags)
        tagView.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(6)
            make.right.lessThanOrEqualTo(-16)
            make.centerY.equalTo(nameLabel)
        }
        self.layout(details: basicInfo.details)
    }

    func update(basicInfo: ChatBasicInfo) {
        nameLabel.text = basicInfo.name
        avatarImageView.setAvatarByIdentifier(basicInfo.entityId, avatarKey: basicInfo.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        tagView.setTags(basicInfo.tags)
        self.layout(details: basicInfo.details)
    }

    private func layout(details: [String]) {
        self.detailStack?.removeFromSuperview()
        self.detailStack = UIStackView(frame: .zero)
        detailStack?.axis = .vertical
        detailStack.flatMap { self.addSubview($0) }
        detailStack?.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        for detail in details where !detail.isEmpty {
            let detailLabel = UILabel(frame: .zero)
            detailLabel.numberOfLines = 1
            detailLabel.textAlignment = .center
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.textColor = UIColor.ud.textPlaceholder
            detailLabel.text = detail
            detailStack?.addArrangedSubview(detailLabel)
        }
    }

    @objc
    private func iconTouch() {
        self.delegate?.iconTouch()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
