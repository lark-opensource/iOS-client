//
//  BubbleReactionView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/12.
//

import UIKit
import SnapKit
import ByteViewCommon
import ByteViewUI
import RichLabel
import UniverseDesignFont

/// 配置项 Reaction Display Mode 为 Bubble 类型时的表情气泡
class BubbleReactionView: UIView {
    private enum Layout {
        static let reactionHeight: CGFloat = 28
    }

    private var reactionRightConstraint: Constraint?
    private let avatarView = AvatarView()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    private let colonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.text = ":"
        return label
    }()

    private let reactionView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let xLabel: UDLabel = {
        let label = UDLabel()
        let font = UDFont.systemFont(ofSize: 16, weight: .semibold).boldItalic
        let offset = font.italicOffset()
        label.font = font
        label.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: offset)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        label.text = "x "
        return label
    }()

    private let countLabel: UDLabel = {
        let label = UDLabel()
        let font = UDFont.systemFont(ofSize: 16, weight: .semibold).boldItalic
        let offset = font.italicOffset()
        label.font = font
        label.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: offset)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.lineBreakMode = .byWordWrapping
        label.isHidden = true
        return label
    }()

    private let emotion: EmotionDependency
    init(emotion: EmotionDependency) {
        self.emotion = emotion
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(senderName: String, avatar: AvatarInfo, reactionKey: String, count: Int) {
        nameLabel.text = senderName
        avatarView.setAvatarInfo(avatar)
        if let image = ExclusiveReactionResource.getExclusiveReaction(by: reactionKey) {
            reactionView.image = image
            updateReactionImage(image)
        } else  if let image = emotion.imageByKey(reactionKey) {
            reactionView.image = image
            updateReactionImage(image)
        } else if let imageKey = emotion.imageKey(by: reactionKey) {
            reactionView.vc.setReaction(imageKey) { [weak self] result in
                if case .success(let img) = result, let image = img {
                    self?.updateReactionImage(image)
                }
            }
        }

        if count > 1 {
            reactionRightConstraint?.isActive = false

            xLabel.isHidden = false
            xLabel.snp.remakeConstraints { make in
                make.left.equalTo(reactionView.snp.right).offset(4)
                make.centerY.equalToSuperview()
            }

            countLabel.text = "\(count)"
            countLabel.isHidden = false
            countLabel.snp.remakeConstraints { make in
                make.left.equalTo(xLabel.snp.right)
                make.right.equalToSuperview().inset(10)
                make.centerY.equalToSuperview()
            }
        } else {
            reactionRightConstraint?.isActive = true
            xLabel.isHidden = true
            xLabel.snp.removeConstraints()
            countLabel.isHidden = true
            countLabel.snp.removeConstraints()
        }
    }

    // MARK: - Private

    private func setupSubviews() {
        layer.cornerRadius = 20
        layer.masksToBounds = true
        backgroundColor = UIColor.ud.vcTokenMeetingBgFeed

        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 14
        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(6)
            make.size.equalTo(28)
        }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(6)
            make.centerY.equalToSuperview()
        }

        addSubview(colonLabel)
        colonLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.left.equalTo(nameLabel.snp.right)
        }

        addSubview(reactionView)
        reactionView.snp.makeConstraints { make in
            // 适配宽表情：表情的高度固定，宽度在获取到表情图片后动态调整
            make.width.height.equalTo(Layout.reactionHeight)
            make.centerY.equalToSuperview()
            make.left.equalTo(nameLabel.snp.right).offset(8)
            reactionRightConstraint = make.right.equalToSuperview().inset(10).constraint
        }
        reactionRightConstraint?.activate()

        addSubview(xLabel)
        addSubview(countLabel)
    }

    private func updateReactionImage(_ image: UIImage) {
        reactionView.snp.updateConstraints { make in
            make.width.equalTo(image.size.width / image.size.height * Layout.reactionHeight)
        }
    }
}
