//
//  MergeForwardMessageDetailTitleView.swift
//  LarkChat
//
//  Created by Ping on 2023/5/29.
//

import SnapKit
import RichLabel
import EENavigator
import LarkNavigator
import LarkMessageCore
import UniverseDesignColor
import LarkMessengerInterface

class MergeForwardMessageDetailTitleView: UIView {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    lazy var contentLabel: LKLabel = {
        let contentLabel = LKLabel()
        contentLabel.backgroundColor = .clear
        contentLabel.delegate = self
        contentLabel.isUserInteractionEnabled = true
        contentLabel.outOfRangeText = NSAttributedString(
            string: "\u{2026}",
            attributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.ud.textCaption
            ]
        )
        return contentLabel
    }()

    private var chatInfo: (NSRange, MergeForwardChatInfo)?
    weak var targetVC: UIViewController?
    private let navigator: UserNavigator

    init(navigator: UserNavigator) {
        self.navigator = navigator
        super.init(frame: .zero)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
        }
        addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, chatInfo: MergeForwardChatInfo?) {
        titleLabel.text = title
        guard let chatInfo = chatInfo else {
            contentLabel.isHidden = true
            self.chatInfo = nil
            return
        }
        if chatInfo.isAuth {
            let chatName = NSAttributedString(
                string: chatInfo.chatName,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.ud.textLinkNormal
                ]
            )
            let placeholder = UUID().uuidString
            let contentString = NSMutableAttributedString(
                string: BundleI18n.LarkChat.Lark_IM_MessageLinkFromAllChat_Text(placeholder),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.ud.textCaption
                ]
            )
            var range = contentString.mutableString.range(of: placeholder)
            if range.length <= 0 {
                assertionFailure("error range")
                return
            }
            contentString.insert(chatName, at: range.location)
            let chatNameRange = NSRange(location: range.location, length: chatName.length)
            range = contentString.mutableString.range(of: placeholder)
            if range.length <= 0 {
                assertionFailure("error range")
                return
            }
            contentString.mutableString.deleteCharacters(in: range)
            contentLabel.attributedText = contentString
            contentLabel.tapableRangeList = [chatNameRange]
            self.chatInfo = (chatNameRange, chatInfo)
        } else {
            let contentString = NSAttributedString(
                string: chatInfo.chatName,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.ud.textCaption
                ]
            )
            contentLabel.attributedText = contentString
            self.chatInfo = nil
        }
    }
}

extension MergeForwardMessageDetailTitleView: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        if let (chatNameRange, chatInfo) = chatInfo, chatNameRange == range, let vc = targetVC {
            // replyThread如果copy的全是回复消息，也跳转根消息所在会话，后端所给position也是根消息所在position
            let body = ChatControllerByIdBody(chatId: chatInfo.chatID, position: chatInfo.position)
            navigator.push(body: body, from: vc)
            return false
        }
        return true
    }
}
