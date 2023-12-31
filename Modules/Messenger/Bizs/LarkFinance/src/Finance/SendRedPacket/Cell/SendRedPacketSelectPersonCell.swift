//
//  SendRedPacketSelectPersonCell.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/23.
//

import Foundation
import LarkUIKit
import ByteWebImage
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignColor
import CoreGraphics
import UIKit

// 红包选人cell
final class SendRedPacketSelectPersonCell: SendRedPacketBaseCell {
    // cell点击事件
    var tapHandler: (() -> Void)?

    fileprivate let container: UIView = UIView()

    // 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.LarkFinance.Lark_DesignateRedPacket_SendTo_Text
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // 描述
    private let desciptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkFinance.Lark_DesignateRedPacket_SelectRecipient_PageTitle
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // 向右箭头
    private let arrow: UIImageView = {
        let imageView = UIImageView(image: Resources.right_arrow)
        return imageView
    }()

    // 选中人的列表
    private let personCotainerView: PersonCotainerView = {
        return PersonCotainerView()
    }()

    override func setupCellContent() {
        contentView.addSubview(container)
        container.backgroundColor = UIColor.ud.bgBody
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true
        container.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.bottom.equalTo(-16)
            $0.height.equalTo(48)
        }

        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
        }

        container.addSubview(arrow)
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }

        container.addSubview(personCotainerView)
        personCotainerView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            maker.right.equalTo(arrow.snp.left).offset(-12)
        }
        personCotainerView.isHidden = true

        container.addSubview(desciptionLabel)
        desciptionLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(20)
            maker.right.equalTo(arrow.snp.left).offset(-12)
        }
    }

    override func updateCellContent(_ result: RedPacketCheckResult) {
        let avatarKeys = result.selectedChatters.map { $0.avatarKey }
        // 最多显示5人
        updatePersonCotainerView(avatarKeys: Array(avatarKeys.prefix(5)),
                                 chatterCount: avatarKeys.count,
                                 chatId: result.chatId)
        desciptionLabel.isHidden = !avatarKeys.isEmpty
    }

    func updatePersonCotainerView(avatarKeys: [String],
                                  chatterCount: Int,
                                  chatId: String) {
        personCotainerView.isHidden = avatarKeys.isEmpty
        personCotainerView.updateHorizontalStack(avatarKeys: avatarKeys,
                                                 chatterCount: chatterCount,
                                                 chatId: chatId)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let tapHandler = tapHandler {
            tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}

private final class PersonCotainerView: UIView {
    var avatarKeys: [String]
    var chatId: String
    let avatarSize: CGFloat = 26

    private var horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = -8
        return stack
    }()

    // 数量描述
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    init(avatarKeys: [String] = [],
         chatterCount: Int = 0,
         chatId: String = "") {
        self.avatarKeys = avatarKeys
        self.chatId = chatId
        super.init(frame: .zero)

        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints { $0.left.top.bottom.equalToSuperview() }
        avatarKeys.forEach { avatarKey in
            self.horizontalStack.addArrangedSubview(getAvatarView(avatarKey: avatarKey, chatId: self.chatId))
        }

        addSubview(countLabel)
        countLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.right.equalToSuperview()
            maker.left.equalTo(horizontalStack.snp.right).offset(2)
        }
        countLabel.text = BundleI18n.LarkFinance.Lark_RedPacket_NumPeople_Text(chatterCount)
    }

    func updateHorizontalStack(avatarKeys: [String] = [],
                               chatterCount: Int = 0,
                               chatId: String = "") {
        self.avatarKeys = avatarKeys
        self.chatId = chatId
        horizontalStack.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        avatarKeys.forEach { avatarKey in
            horizontalStack.addArrangedSubview(getAvatarView(avatarKey: avatarKey, chatId: self.chatId))
        }
        countLabel.text = BundleI18n.LarkFinance.Lark_RedPacket_NumPeople_Text(chatterCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // adapt dark mode color change
        horizontalStack.arrangedSubviews.forEach { view in
            view.layer.borderColor = UIColor.ud.bgBody.cgColor
        }
    }

    private func getAvatarView(avatarKey: String, chatId: String) -> BizAvatar {
        let avatarView = BizAvatar()
        avatarView.layer.borderColor = UIColor.ud.bgBody.cgColor
        avatarView.layer.borderWidth = 2
        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.setAvatarByIdentifier(chatId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        avatarView.snp.makeConstraints({ $0.width.height.equalTo(avatarSize) })
        return avatarView
    }
}
