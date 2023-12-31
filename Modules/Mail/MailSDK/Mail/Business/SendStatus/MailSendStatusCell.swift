//
//  MailSendStatusCell.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/8/17.
//

import Foundation
import RxSwift

class MailSendStatusCell: UITableViewCell {
    static let identifier = "MailSendStatusCell"
    static let cellHeight: CGFloat = 84
    var detailModel: SendStatusDetail?
    private var disposeBag = DisposeBag()

    private lazy var avatarImageView: MailAvatarImageView = {
        let imageView = MailAvatarImageView()
        imageView.layer.cornerRadius = 22.5
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .right
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var sendStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layer.zPosition = 0
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(sendStatusLabel)
        contentView.addSubview(timeLabel)
        avatarImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
            make.size.equalTo(45)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.height.equalTo(18)
            make.width.equalTo(100)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.right.equalTo(timeLabel.snp.left).offset(-8)
            make.height.equalTo(22)
        }
        addressLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom)
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(20)
        }

        sendStatusLabel.snp.makeConstraints { (make) in
            make.top.equalTo(addressLabel.snp.bottom).offset(2)
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(18)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // todo
        avatarImageView.isHidden = true
        avatarImageView.setImageTask?.cancel()
    }

    func updateDetailModel(model: SendStatusDetail) {
        self.detailModel = model
        let displayName = model.recipients.name.isEmpty ?
            String(model.recipients.address.prefix(while: { $0 != "@" })) : model.recipients.name
        self.nameLabel.text = displayName
        self.addressLabel.text = model.recipients.address
        var timestamp = model.lastUpdatedTime.value
        if model.lastUpdatedTime.unit == .ms {
            timestamp = timestamp / 1000
        }
        let timeStr = ProviderManager.default.timeFormatProvider?.mailSendStatusTimeFormat(timestamp) ?? ""
        self.timeLabel.text = timeStr
        let sendInfo = self.getSendStatusInfo(status: model.detailStatus)
        self.sendStatusLabel.text = sendInfo.0
        self.sendStatusLabel.textColor = sendInfo.1

        let timeWidth = timeStr.getTextWidth(fontSize: 12) + 10
        self.timeLabel.snp.remakeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.height.equalTo(18)
            make.width.equalTo(timeWidth)
        }
        avatarImageView.isHidden = false
        MailModelManager.shared.getUserAvatarKey(userId: String(model.recipients.larkEntityID)).subscribe(onNext: { [weak self] (key) in
            guard let `self` = self else { return }
            if !key.isEmpty {
                self.avatarImageView.set(avatarKey: key, image: nil)
            } else {
                self.avatarImageView.setAvatar(with: displayName, setBackground: true)
            }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            self.avatarImageView.setAvatar(with: displayName, setBackground: true)
        }).disposed(by: disposeBag)
        
        if MailAddressChangeManager.shared.addressNameOpen() {
            // 检查是否需要换名字
            var item = AddressRequestItem()
            item.address =  model.recipients.address
            item.larkEntityID = String(model.recipients.larkEntityID)
            if model.recipients.larkEntityType == .user {
                item.addressType = .larkUser
            } else if model.recipients.larkEntityType == .group {
                item.addressType = .chatGroup
            } else if model.recipients.larkEntityType == .sharedMailbox {
                item.addressType = .mailShare
            }
            MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
                guard let `self` = self else { return }
                if let newItem = MailAddressNameResponse.addressNameList.first {
                    if !newItem.name.isEmpty &&
                        newItem.name != model.recipients.name &&
                        !MailAddressChangeManager.shared.noUpdate(type: newItem.addressType) {
                        // update name
                        self.nameLabel.text = newItem.name
                    }
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("send status getAddressNames resp error \(error)")
            }).disposed(by: disposeBag)
        }
    }

    func getSendStatusInfo(status: SendStatus) -> (String, UIColor) {
        var res = (BundleI18n.MailSDK.Mail_Send_Sending, UIColor.ud.blue)
        switch status {
        case .delivering:
            res = (BundleI18n.MailSDK.Mail_Send_Sending, UIColor.ud.blue)
        case .delivered:
            res = (BundleI18n.MailSDK.Mail_Send_SentToRecipient, UIColor.ud.textPlaceholder)
        case .retry:
            res = (BundleI18n.MailSDK.Mail_Send_FailedToSendReSend, UIColor.ud.blue)
        case .deferred:
            res = (BundleI18n.MailSDK.Mail_Send_FailedToSendBounceBack, UIColor.ud.functionDangerContentDefault)
        case .unknown: break
        @unknown default:
            break
        }
        return res
    }

}
