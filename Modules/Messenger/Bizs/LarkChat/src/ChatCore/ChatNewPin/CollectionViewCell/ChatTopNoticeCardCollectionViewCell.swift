//
//  ChatTopNoticeCardCollectionViewCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/17.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import RichLabel
import LarkModel
import LarkMessengerInterface
import LarkContainer
import ByteWebImage
import LarkCore

final class ChatTopNoticeCardCollectionViewCell: ChatPinListCardBaseCell {

    static var reuseIdentifier: String { return String(describing: ChatTopNoticeCardCollectionViewCell.self) }

    struct UIConfig {
        static var announcementSize: CGSize { CGSize(width: 16, height: 16) }
        static var avatarSize: CGSize {  CGSize(width: 18, height: 18) }
        static var contentMargin: CGFloat { 12 }
        static var titleLeftMargin: CGFloat { 8 }
        static var horizontalInnerPadding: CGFloat { 6 }
        static var moreIconSize: CGFloat { 16 }
    }

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickIcon))
        iconView.addGestureRecognizer(tap)
        iconView.isUserInteractionEnabled = true
        return iconView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    private lazy var contentLabel: LKLabel = {
        let contentLabel = LKLabel(frame: .zero)
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.autoDetectLinks = false
        return contentLabel
    }()

    private lazy var contentTapView: UIView = {
        let contentTapView = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickContent))
        contentTapView.addGestureRecognizer(tap)
        return contentTapView
    }()

    private lazy var operateLabel: LKLabel = {
        let operateLabel = LKLabel()
        operateLabel.backgroundColor = UIColor.clear
        return operateLabel
    }()

    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.numberOfLines = 1
        return timeLabel
    }()

    private lazy var moreButton: UIButton = {
        let moreButton = UIButton()
        moreButton.setBackgroundImage(UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        moreButton.addTarget(self, action: #selector(clickMore(_:)), for: .touchUpInside)
        return moreButton
    }()

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        return lineView
    }()

    private var cellViewModel: ChatPinCardTopNoticeCellViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.containerView.addSubview(iconView)
        self.containerView.addSubview(titleLabel)
        self.containerView.addSubview(lineView)
        self.containerView.addSubview(timeLabel)
        self.containerView.addSubview(moreButton)
        self.containerView.addSubview(contentLabel)
        self.containerView.addSubview(contentTapView)
        self.containerView.addSubview(operateLabel)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UIConfig.contentMargin)
            make.centerY.equalTo(self.containerView.snp.top).offset(23)
            make.size.equalTo(0)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(UIConfig.titleLeftMargin)
            make.centerY.equalTo(iconView)
        }
        lineView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(UIConfig.horizontalInnerPadding)
            make.centerY.equalTo(iconView)
            make.width.equalTo(1)
            make.height.equalTo(12)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(lineView.snp.right).offset(UIConfig.horizontalInnerPadding)
            make.centerY.equalTo(iconView)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-UIConfig.horizontalInnerPadding)
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        moreButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(15)
            make.right.equalToSuperview().inset(UIConfig.contentMargin)
            make.size.equalTo(UIConfig.moreIconSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickMore(_ botton: UIButton) {
        self.cellViewModel?.handleMore(botton)
    }

    @objc
    private func clickIcon() {
        self.cellViewModel?.onClickIcon()
    }

    @objc
    private func clickContent() {
        self.cellViewModel?.onClickContent()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconView.bt.setLarkImage(with: .default(key: ""))
    }

    func update(cellViewModel: ChatPinCardTopNoticeCellViewModel) {

        let result = cellViewModel.calculateLayoutResult().layoutResult
        self.iconView.snp.updateConstraints { make in
            make.size.equalTo(result.iconFrame.size)
        }
        self.iconView.layer.cornerRadius = cellViewModel.iconHasCorner ? result.iconFrame.size.width / 2 : 0
        self.contentLabel.frame = result.contentFrame
        self.contentLabel.isHidden = (result.contentFrame.height == .zero)
        self.contentTapView.frame = result.contentFrame
        self.contentTapView.isHidden = (result.contentFrame.height == .zero)
        self.operateLabel.frame = result.pinChatterFrame
        self.operateLabel.isHidden = (result.pinChatterFrame.height == .zero)
        cellViewModel.update(contentLabel: self.contentLabel, operaterLable: self.operateLabel)

        self.cellViewModel = cellViewModel
        let fromChat = cellViewModel.fromChat
        let model = cellViewModel.topNoticeModel

        switch model.pbModel.content.type {
        case .announcementType:
            timeLabel.isHidden = true
            lineView.isHidden = true
            if let announcementSender = model.announcementSender {
                titleLabel.text = announcementSender.displayName(chatId: fromChat.id,
                                                                 chatType: fromChat.type,
                                                                 scene: .reply)
                iconView.bt.setLarkImage(.avatar(key: announcementSender.avatarKey,
                                                 entityID: announcementSender.id,
                                                 params: .init(sizeType: .size(iconView.bounds.width))))
            } else {
                titleLabel.text = BundleI18n.LarkChat.Lark_Groups_Announcement
                iconView.bt.setLarkImage(.default(key: ""))
                iconView.image = UDIcon.getIconByKey(.announceFilled, size: iconView.bounds.size).ud.withTintColor(UIColor.ud.orange)
            }
        case .msgType:
            guard let message = model.message,
                  let fromChatter = message.fromChatter else {
                return
            }
            titleLabel.text = fromChatter.displayName(chatId: fromChat.id,
                                                      chatType: fromChat.type,
                                                      scene: .reply)
            iconView.bt.setLarkImage(.avatar(key: fromChatter.avatarKey,
                                             entityID: fromChatter.id,
                                             params: .init(sizeType: .size(iconView.bounds.width))))
            timeLabel.text = message.createTime.lf.cacheFormat("ChatTopNoticeCardCollectionViewCell", formater: {
                $0.lf.formatedTime_v2()
            })
            timeLabel.isHidden = false
            lineView.isHidden = false
        case .unknown:
            break
        @unknown default:
            break
        }
    }

}
