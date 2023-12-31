//
//  RedPacketResultCell.swift
//  Pods
//
//  Created by ChalrieSu on 2018/10/22.
//

import Foundation
import UIKit
import LarkCore
import DateToolsSwift
import LarkBizAvatar
import LarkEmotion
import LarkSDKInterface

final class RedPacketResultCell: UITableViewCell {
    private let avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 40
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    private let dateLabel = UILabel()
    private let sumOfMoneyLabel = UILabel()
    private let luckiestStackView = UIStackView()
    private let rightStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        return stack
    }()
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .right
        return label
    }()

    private var isLastRow: Bool = false {
        didSet {
            if oldValue != isLastRow { setNeedsLayout() }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.centerY.equalToSuperview()
            make.left.equalTo(20)
        }

        contentView.addSubview(nameLabel)
        contentView.addSubview(rightStackView)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.top.equalTo(avatarImageView.snp.top)
            make.right.lessThanOrEqualTo(rightStackView.snp.left)
        }

        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = UIColor.ud.N500
        contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.bottom.equalTo(avatarImageView.snp.bottom)
        }

        rightStackView.addArrangedSubview(statusLabel)
        statusLabel.snp.makeConstraints { $0.height.equalTo(18) }
        sumOfMoneyLabel.font = UIFont.systemFont(ofSize: 14)
        sumOfMoneyLabel.textAlignment = .right
        rightStackView.addArrangedSubview(sumOfMoneyLabel)
        sumOfMoneyLabel.snp.makeConstraints { $0.height.equalTo(24) }
        rightStackView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let thumbsImageView = UIImageView()

        if let icon = EmotionResouce.shared.imageBy(key: EmotionResouce.ReactionKeys.thumbsup) {
            thumbsImageView.image = icon
        } else {
            assert(false, "can not find Thumbsup in RedPacketResultCell")
        }

        thumbsImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        let bestLuckyLabel = UILabel()
        bestLuckyLabel.font = UIFont.systemFont(ofSize: 12)
        bestLuckyLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoResultBestLuck
        bestLuckyLabel.textColor = UIColor.ud.colorfulRed

        luckiestStackView.alignment = .center
        luckiestStackView.addArrangedSubview(thumbsImageView)
        luckiestStackView.addArrangedSubview(bestLuckyLabel)
        luckiestStackView.isHidden = true
        rightStackView.addArrangedSubview(luckiestStackView)
        luckiestStackView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalTo(dateLabel.snp.centerY)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(model: RedPacketResultCellModel) {
        avatarImageView.setAvatarByIdentifier(model.entityId ?? "",
                                              avatarKey: model.avatarKey ?? "",
                                              avatarViewParams: .init(sizeType: .size(40)))
        nameLabel.text = model.name
        if let openDate = model.openDate {
            dateLabel.isHidden = false
            dateLabel.text = openDate.format(with: "MM-dd HH:mm")
            nameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.top.equalTo(avatarImageView.snp.top)
                make.right.lessThanOrEqualTo(rightStackView.snp.left)
            }
        } else {
            dateLabel.isHidden = true
            nameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.centerY.equalTo(avatarImageView)
                make.right.lessThanOrEqualTo(rightStackView.snp.left)
            }
        }
        sumOfMoneyLabel.attributedText = model.sumOfMoney
        luckiestStackView.isHidden = !model.isLuckiest
        statusLabel.isHidden = !model.isShowStatusLabel
        statusLabel.attributedText = model.statusAttr
    }
}

struct RedPacketResultCellModel {
    var entityId: String?
    var avatarKey: String?
    var name: String
    var openDate: Date?
    var sumOfMoney: NSAttributedString
    var isShowStatusLabel: Bool
    var statusAttr: NSAttributedString
    var isLuckiest: Bool

    static func transfromFrom(detail: RedPacketReceiveDetail,
                              isExclusive: Bool,
                              isLuckiest: Bool) -> RedPacketResultCellModel {
        let status = detail.receiveStatus == .grabbed ? BundleI18n.LarkFinance.Lark_DesignateRedPacket_RedPacketOpened_Status : BundleI18n.LarkFinance.Lark_DesignateRedPacket_ToBeOpened_Unopened
        let statusAttr = getStatusAttr(isGrabbed: detail.receiveStatus == .grabbed, status: status)
        let openDate = detail.receiveStatus == .grabbed ? Date(timeIntervalSince1970: TimeInterval(detail.time / 1000)) : nil
        let model = RedPacketResultCellModel(entityId: detail.chatter.id,
                                             avatarKey: detail.chatter.avatarKey,
                                             name: detail.chatter.localizedName,
                                             openDate: openDate,
                                             sumOfMoney: getMoneyAttr(detail.amount, isExclusive: isExclusive),
                                             isShowStatusLabel: isExclusive,
                                             statusAttr: statusAttr,
                                             isLuckiest: isLuckiest)
        return model
    }

    private static func getStatusAttr(isGrabbed: Bool, status: String) -> NSAttributedString {
        let attr = NSAttributedString(string: status,
                                      attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                 .foregroundColor: isGrabbed ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder]
        )
        return attr
    }

    private static func getMoneyAttr(_ money: Int, isExclusive: Bool) -> NSAttributedString {
        let attr = NSAttributedString(string: String(format: "%.2f", Float(money) / 100.0) + BundleI18n.LarkFinance.Lark_Legacy_HongbaoResultMoneyUnit,
                                       attributes: [.font: UIFont.systemFont(ofSize: isExclusive ? 12 : 14),
                                                    .foregroundColor: isExclusive ? UIColor.ud.textPlaceholder : UIColor.ud.N900]
        )
        return attr
    }
}
