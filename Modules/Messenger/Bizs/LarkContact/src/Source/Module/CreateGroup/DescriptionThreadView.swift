//
//  DescriptionThreadView.swift
//  LarkContact
//
//  Created by huangjianming on 2020/6/7.
//

import Foundation
import UIKit
import LarkFeatureGating
import UniverseDesignIcon
import LarkMessageCore

final class DescriptionThreadView: UIView {
    private var backgroundImageView = UIImageView(image: Resources.descriptionImage_thread)
    init() {
        super.init(frame: .zero)
        self.addSubview(self.backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(375)
            make.height.equalTo(667)
        }

        let attachment = NSTextAttachment()
        attachment.image = Resources.descriptionImage_thread_share
        attachment.bounds = CGRect(x: 0, y: -1, width: 12, height: 12)
        let attachmentString = NSAttributedString(attachment: attachment)
        let shareLabel = UILabel()
        let attributedString = NSMutableAttributedString(attributedString: attachmentString)
        attributedString.append(NSAttributedString(string: " \(BundleI18n.LarkContact.Lark_Legacy_QrCodeShare)"))
        shareLabel.attributedText = attributedString
        shareLabel.font = UIFont.systemFont(ofSize: 14)
        shareLabel.textColor = .white
        shareLabel.layer.cornerRadius = 14
        shareLabel.layer.borderWidth = 1
        shareLabel.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)
        shareLabel.textAlignment = .center

        self.addSubview(shareLabel)
        shareLabel.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.top.equalTo(64)
            make.width.greaterThanOrEqualTo(70)
            make.height.greaterThanOrEqualTo(28)
        }

        let pageTitleLabel = UILabel()
        pageTitleLabel.attributedText = NSAttributedString(string: BundleI18n.LarkContact.Lark_Legacy_TopicSampleGroupname,
                                                           attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)])
        self.addSubview(pageTitleLabel)
        pageTitleLabel.textColor = .white
        pageTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(67)
            make.left.equalTo(70)
        }

        let allLabel = UILabel()
        allLabel.text = BundleI18n.LarkContact.Lark_Legacy_All
        self.addSubview(allLabel)
        allLabel.font = .systemFont(ofSize: 14)
        allLabel.textColor = UIColor.ud.primaryContentDefault
        allLabel.snp.makeConstraints { (make) in
            make.top.equalTo(144)
            make.left.equalTo(18)
        }

        let subsLabel = UILabel()
        subsLabel.text = BundleI18n.LarkContact.Lark_Groups_TopicFilterFollowed
        self.addSubview(subsLabel)
        subsLabel.font = .systemFont(ofSize: 14)
        subsLabel.textColor = UIColor.ud.textCaption
        subsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(144)
            make.left.equalTo(allLabel.snp.right).offset(24)
        }

        let blueLine = UIView()
        blueLine.backgroundColor = UIColor.ud.primaryContentDefault
        blueLine.layer.cornerRadius = 2
        blueLine.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.addSubview(blueLine)
        blueLine.snp.makeConstraints { (make) in
            make.top.equalTo(allLabel.snp.bottom).offset(8)
            make.height.equalTo(2)
            make.leading.trailing.equalTo(allLabel)
        }

        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { (make) in
            make.top.equalTo(blueLine.snp.bottom)
            make.height.equalTo(0.5)
            make.leading.trailing.equalToSuperview()
        }

        let chat1Reply1 = [BundleI18n.LarkContact.Lark_Legacy_TopicSampleReplyName1,
                           BundleI18n.LarkContact.Lark_Legacy_TopicSampleReply1]
        guard chat1Reply1.count == 2 else {
            return
        }
        let replys = [(chat1Reply1[0], chat1Reply1[1])]
        let chat1 = addChat(name: BundleI18n.LarkContact.Lark_Legacy_TopicSampleName1,
                            chatString: BundleI18n.LarkContact.Lark_Legacy_TopicSampleTopic1,
                            image: Resources.descriptionImage_yellow_people,
                            dateString: BundleI18n.LarkContact.Lark_Legacy_TopicSampleTime1,
                replys: replys)
        chat1.snp.makeConstraints { (make) in
            make.top.equalTo(separatorLine.snp.bottom)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let chat2Reply1 = [BundleI18n.LarkContact.Lark_Legacy_TopicSampleReplyName2, BundleI18n.LarkContact.Lark_Legacy_TopicSampleReply2]
        let chat2Reply2 = [BundleI18n.LarkContact.Lark_Legacy_TopicSampleReplyName3, BundleI18n.LarkContact.Lark_Legacy_TopicSampleReply3]

        let chat2 = addChat(name: BundleI18n.LarkContact.Lark_Legacy_TopicSampleName2,
                            chatString: BundleI18n.LarkContact.Lark_Legacy_TopicSampleTopic2,
                image: Resources.descriptionImage_white_people,
                dateString: BundleI18n.LarkContact.Lark_Legacy_TopicSampleTime2,
                replys: [(chat2Reply1[0], chat2Reply1[1]), (chat2Reply2[0], chat2Reply2[1])])
        chat2.snp.makeConstraints { (make) in
            make.top.equalTo(chat1.snp.bottom)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addChat(name: String, chatString: String, image: UIImage, dateString: String, replys: [(String, String)]) -> UIView {
        let chatContainer = UIView()
        self.addSubview(chatContainer)

        let more_icon = UIImageView(image: UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN3))
        chatContainer.addSubview(more_icon)
        more_icon.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.top.equalTo(16)
        }

        let whitePeopleAvator = UIImageView()
        whitePeopleAvator.image = image
        chatContainer.addSubview(whitePeopleAvator)
        whitePeopleAvator.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.width.height.equalTo(40)
        }

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        chatContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(64)
            make.top.equalTo(whitePeopleAvator.snp.top)
        }

        let dateLabel = UILabel()
        dateLabel.text = dateString
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = UIColor.ud.N500
        chatContainer.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        let chatLabel = UILabel()
        chatLabel.font = UIFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        chatLabel.attributedText = NSAttributedString(string: chatString, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        chatLabel.numberOfLines = 0
        chatLabel.textColor = UIColor.ud.N900
        chatContainer.addSubview(chatLabel)
        chatLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(whitePeopleAvator.snp.bottom).offset(11)
            make.right.equalTo(-8)
        }

        let triangleView = ThreadReplyTriangleView()
        triangleView.color = UIColor.ud.N200
        chatContainer.addSubview(triangleView)
        triangleView.snp.makeConstraints { (make) in
            make.top.equalTo(chatLabel.snp.bottom).offset(5)
            make.left.equalTo(36)
            make.width.equalTo(14)
            make.height.equalTo(7)
        }

        let replyContainer = UIView()
        chatContainer.addSubview(replyContainer)
        replyContainer.backgroundColor = UIColor.ud.N200
        replyContainer.layer.cornerRadius = 8
        replyContainer.layer.masksToBounds = true
        replyContainer.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(triangleView.snp.bottom)
            make.right.equalTo(-15)
        }

        let replyLabel = UILabel()
        let string = NSMutableAttributedString()

        for (index, reply) in replys.enumerated() {
            let paraph = NSMutableParagraphStyle()
            paraph.lineSpacing = 10
            let name: String = reply.0
            let content: String = reply.1
            //除了最后一个,都增加换行符
            let lineBreak = index == replys.count - 1 ? "" : "\n"
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                              NSAttributedString.Key.paragraphStyle: paraph,
                              NSAttributedString.Key.foregroundColor: UIColor.ud.N650]
            let text = NSMutableAttributedString(string: "\(name)\(String(describing: content))\(lineBreak)",
                attributes: attributes)
            text.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium)],
                               range: NSRange(location: 0, length: name.count))
            string.append(text)
        }

        replyLabel.attributedText = string
        replyLabel.numberOfLines = 0
        replyContainer.addSubview(replyLabel)
        replyLabel.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
            make.right.equalTo(-10)
        }

        var bottomImage: UIImage?
        bottomImage = Resources.description_bottom
        let bottomView = UIImageView(image: bottomImage)
        chatContainer.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(replyContainer.snp.bottom)
            make.width.equalToSuperview()
        }

        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.N200
        chatContainer.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.height.equalTo(10)
            make.bottom.width.equalToSuperview()
            make.top.equalTo(bottomView.snp.bottom)
        }
        return chatContainer
    }
}

private final class ThreadReplyTriangleView: UIView {

    var color: UIColor = .clear

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let aPath = UIBezierPath()
        aPath.move(to: CGPoint(x: rect.size.width / 2, y: 0))
        aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
        aPath.close()
        color.setFill()
        aPath.fill()
    }
}

class DescriptionChatView: UIView {
    private var backgroundImageView = UIImageView(image: Resources.descriptionImage_chat)

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    func setupUI() {
        self.addSubview(self.backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(375)
            make.height.equalTo(667)
        }

        let centerStackView = UIStackView()
        centerStackView.axis = .vertical
        centerStackView.alignment = .center
        centerStackView.distribution = .fill
        self.addSubview(centerStackView)
        centerStackView.snp.makeConstraints { (make) in
            make.top.equalTo(22)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 4
        centerStackView.addArrangedSubview(stackView)

        let titleView = UILabel()
        let attributedString = NSMutableAttributedString(string: "\(BundleI18n.LarkContact.Lark_Legacy_ChatSampleGroupname)(6)")
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)],
                           range: NSRange(location: 0, length: attributedString.length))
        titleView.attributedText = attributedString
        titleView.textAlignment = .center
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(titleView)

        let iconImageView = UIImageView()
        iconImageView.image = Resources.descriptionImage_chat_arrow
        stackView.addArrangedSubview(iconImageView)

        let bottomLabel = UILabel()
        bottomLabel.text = BundleI18n.LarkContact.Lark_Legacy_ChatSampleSendToChat
        bottomLabel.font = .systemFont(ofSize: 16)
        self.addSubview(bottomLabel)
        bottomLabel.textColor = UIColor.ud.N500
        bottomLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.bottom.equalTo(-61)
        }

        let white_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_ChatSampleName1,
                                        chatString: BundleI18n.LarkContact.Lark_Legacy_ChatSampleMessage1,
                            image: Resources.descriptionImage_white_people,
                            chatColor: UDMessageColorTheme.imMessageBgBubblesBlue)
        white_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(84)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let yellow_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_ChatSampleName2,
                                         chatString: BundleI18n.LarkContact.Lark_Legacy_ChatEgmessage2,
                            image: Resources.descriptionImage_yellow_people,
                            chatColor: UIColor.ud.N200)
        yellow_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(white_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let black_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_ChatSampleName3,
                                        chatString: BundleI18n.LarkContact.Lark_Legacy_ChatSampleMessage3,
                            image: Resources.descriptionImage_black_people,
                            chatColor: UIColor.ud.N200)
        black_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(yellow_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let indian_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_ChatSampleName4,
                                  chatString: BundleI18n.LarkContact.Lark_Legacy_ChatSampleMessage4,
                            image: Resources.descriptionImage_indian_people,
                            chatColor: UIColor.ud.N200)
        indian_chat.snp.makeConstraints { (make) in
            make.top.equalTo(black_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }
    }

    func addChat(name: String, chatString: String, image: UIImage, chatColor: UIColor, burnTime: String? = nil) -> UIView {
        let chatContainer = UIView()
        self.addSubview(chatContainer)

        let whitePeopleAvator = UIImageView()
        whitePeopleAvator.image = image
        chatContainer.addSubview(whitePeopleAvator)
        whitePeopleAvator.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(0)
            make.width.height.equalTo(28)
        }

        let nameLabel = UILabel()
        nameLabel.textColor = .gray
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textTitle
        chatContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(52)
            make.top.equalTo(whitePeopleAvator)
        }

        let chatContent = UIView()
        chatContainer.addSubview(chatContent)
        chatContent.layer.ud.setBackgroundColor(chatColor)
        chatContent.layer.cornerRadius = 10
        chatContent.layer.masksToBounds = true
        chatContent.snp.makeConstraints { (make) in
            make.left.equalTo(52)
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
            if burnTime == nil {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalToSuperview().inset(22)
            }
            make.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(-47)
        }

        let chatLabel = UILabel()
        chatLabel.text = chatString
        chatLabel.font = UIFont.systemFont(ofSize: 17)
        chatLabel.numberOfLines = 0
        chatLabel.textColor = UIColor.ud.N900
        chatContent.addSubview(chatLabel)
        chatLabel.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.top.equalTo(8)
            make.bottom.equalTo(-8)
            make.right.equalTo(-12)
        }

        if let burnTime = burnTime {
            let burnLabel = UILabel()
            burnLabel.text = burnTime
            burnLabel.font = UIFont.systemFont(ofSize: 12)
            burnLabel.numberOfLines = 1
            burnLabel.textColor = UIColor.ud.N500
            chatContainer.addSubview(burnLabel)
            burnLabel.snp.makeConstraints { (make) in
                make.left.equalTo(52)
                make.top.equalTo(chatContent.snp.bottom).offset(4)
                make.bottom.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        }
        return chatContainer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DescriptionSecretView: DescriptionChatView {
    private var backgroundImageView = UIImageView(image: Resources.descriptionImage_secret)

    override func setupUI() {
        self.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(375)
            make.height.equalTo(667)
        }

        let centerStackView = UIStackView()
        centerStackView.axis = .vertical
        centerStackView.alignment = .center
        centerStackView.distribution = .fill
        self.addSubview(centerStackView)
        centerStackView.snp.makeConstraints { (make) in
            make.top.equalTo(22)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 4
        centerStackView.addArrangedSubview(stackView)

        let titleView = UILabel()
        let attributedString = NSMutableAttributedString(string: "\(BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleGroupname)(6)")
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)],
                           range: NSRange(location: 0, length: attributedString.length))
        titleView.attributedText = attributedString
        titleView.textColor = .white
        titleView.textAlignment = .center
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(titleView)

        let iconImageView = UIImageView()
        iconImageView.image = Resources.descriptionImage_secret_title_icon
        stackView.addArrangedSubview(iconImageView)

        let bottomLabel = UILabel()
        bottomLabel.text = BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleSendToChat
        bottomLabel.font = .systemFont(ofSize: 16)
        bottomLabel.textColor = UIColor.ud.N500
        self.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.bottom.equalTo(-61)
        }

        let white_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleName1,
                                        chatString: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleMessage1,
                                        image: Resources.descriptionImage_white_people,
                                        chatColor: UDMessageColorTheme.imMessageBgBubblesBlue,
                                        burnTime: "00h:32m:20s")
        white_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(84)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let yellow_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleName2,
                                         chatString: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleMessage2,
                                         image: Resources.descriptionImage_yellow_people,
                                         chatColor: UIColor.ud.N200,
                                         burnTime: "00h:40m:28s")
        yellow_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(white_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let black_people_chat = addChat(name: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleName3,
                                        chatString: BundleI18n.LarkContact.Lark_Legacy_SecretChatSampleMessage3,
                                        image: Resources.descriptionImage_black_people,
                                        chatColor: UIColor.ud.N200,
                                        burnTime: "00h:45m:32s")
        black_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(yellow_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }
    }
}

final class DescriptionPrivateChatView: DescriptionChatView {
    private var backgroundImageView = UIImageView(image: Resources.descriptionImage_chat)

    override func setupUI() {
        self.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(375)
            make.height.equalTo(667)
        }

        let centerStackView = UIStackView()
        centerStackView.axis = .vertical
        centerStackView.alignment = .center
        centerStackView.distribution = .fill
        self.addSubview(centerStackView)
        centerStackView.snp.makeConstraints { (make) in
            make.top.equalTo(22)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 2
        centerStackView.addArrangedSubview(stackView)

        let titleView = UILabel()
        let attributedString = NSMutableAttributedString(string: "\(BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_ChatName)(6)")
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium)],
                           range: NSRange(location: 0, length: attributedString.length))
        titleView.attributedText = attributedString
        titleView.textAlignment = .center
        titleView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(titleView)

        let privateIconBgView = UIView()
        privateIconBgView.layer.cornerRadius = 3
        privateIconBgView.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        let privateIconImageView = UIImageView()
        privateIconImageView.image = UDIcon.getIconByKey(
            .safeFilled,
            iconColor: UIColor.ud.udtokenTagNeutralTextNormal,
            size: CGSize(width: 14, height: 14)
        )
        privateIconBgView.addSubview(privateIconImageView)
        stackView.addArrangedSubview(privateIconBgView)
        privateIconBgView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(18)
        }
        privateIconImageView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }

        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.descriptionImage_chat_arrow
        stackView.addArrangedSubview(arrowImageView)

        let bottomLabel = UILabel()
        bottomLabel.text = BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_Placeholder
        bottomLabel.font = .systemFont(ofSize: 16)
        self.addSubview(bottomLabel)
        bottomLabel.textColor = UIColor.ud.N500
        bottomLabel.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.bottom.equalTo(-61)
        }

        let white_people_chat = addChat(name: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_User1,
                                        chatString: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_Message1,
                                        image: Resources.descriptionImage_white_people,
                                        chatColor: UDMessageColorTheme.imMessageBgBubblesBlue)
        white_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(84)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let yellow_people_chat = addChat(name: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_User2,
                                         chatString: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_Message2,
                                         image: Resources.descriptionImage_yellow_people,
                                         chatColor: UIColor.ud.N200)
        yellow_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(white_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }

        let black_people_chat = addChat(name: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_User3,
                                        chatString: BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_Message3,
                                        image: Resources.descriptionImage_black_people,
                                        chatColor: UIColor.ud.N200)
        black_people_chat.snp.makeConstraints { (make) in
            make.top.equalTo(yellow_people_chat.snp.bottom).offset(24)
            make.left.equalTo(0)
            make.width.equalToSuperview()
        }
    }
}
