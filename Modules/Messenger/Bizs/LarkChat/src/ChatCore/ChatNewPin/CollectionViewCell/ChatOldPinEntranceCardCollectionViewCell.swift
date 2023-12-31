//
//  ChatOldPinEntranceCardCollectionViewCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/17.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessengerInterface
import EENavigator
import LarkModel
import LarkCore

final class ChatOldPinEntranceCardCollectionViewCell: ChatPinListCardBaseCell {

    static var reuseIdentifier: String { return String(describing: ChatOldPinEntranceCardCollectionViewCell.self) }
    static var height: CGFloat = 58 // 46 + 6 * 2

    private struct UIConfig {
        static var iconSize: CGFloat = 16
        static var arrowSize: CGFloat = 12
        static var titleMargin: CGFloat = 8
    }

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.pinFilled, size: CGSize(width: UIConfig.iconSize, height: UIConfig.iconSize)).ud.withTintColor(UIColor.ud.turquoise)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkChat.Lark_IM_NewPin_PinnedMessages_Title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var rightArrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: UIConfig.arrowSize, height: UIConfig.arrowSize)).ud.withTintColor(UIColor.ud.iconN2)
        return imageView
    }()

    private var chat: Chat?
    private weak var targetVC: UIViewController?
    private var nav: Navigatable?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.containerView.addSubview(iconImageView)
        self.containerView.addSubview(rightArrowImageView)
        self.containerView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(UIConfig.iconSize)
        }

        rightArrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(17)
            make.centerY.equalToSuperview()
            make.size.equalTo(UIConfig.arrowSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(UIConfig.titleMargin)
            make.right.lessThanOrEqualTo(rightArrowImageView.snp.left).offset(-UIConfig.titleMargin)
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        self.containerView.addGestureRecognizer(tap)
    }

    func update(chat: Chat, targetVC: UIViewController, nav: Navigatable?) {
        self.chat = chat
        self.targetVC = targetVC
        self.nav = nav
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func click() {
        guard let chat = chat, let targetVC = targetVC else { return }
        let body = PinListBody(chatId: chat.id)
        self.nav?.push(body: body, from: targetVC)
        IMTracker.Chat.Sidebar.Click.open(chat, topId: nil, messageId: nil, type: .pinList)
    }
}
