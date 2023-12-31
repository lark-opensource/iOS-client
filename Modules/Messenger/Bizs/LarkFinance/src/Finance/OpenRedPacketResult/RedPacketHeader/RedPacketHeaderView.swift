//
//  RedPacketHeaderView.swift
//  LarkFinance
//
//  Created by SuPeng on 3/29/19.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkModel
import LarkSDKInterface
import LarkReleaseConfig
import LarkBizAvatar
import UniverseDesignIcon
import ByteWebImage

protocol RedPacketHeaderViewDelegate: AnyObject {
    func headerViewDidClickBackOrCloseButton(_ headerView: RedPacketHeaderView)
    func headerViewBarDidClickHistoryButton(_ headerView: RedPacketHeaderView)
    func headerViewBarDidClickDetailButton(_ headerView: RedPacketHeaderView)
}

private enum RedPacketHeaderViewStyle {
    case error
    case grabAmount
    case noGrabAmout
}

final class RedPacketHeaderView: UIView {
    weak var delegate: RedPacketHeaderViewDelegate?

    // 显示"恭喜获得专属红包"
    private let descriptionLabel = UILabel()
    private let infoLabel = UILabel()
    private let sumOfMoneyLabel = UILabel()
    private let unitLabel = UILabel()
    private let detailButton = UIButton()
    private let avatarView = OpenRedPacketAvatarView()
    private let avatarSize: CGFloat = 36
    private let instructionLabel = UILabel()
    private lazy var arrow = UIImageView(image: UDIcon.rightOutlined.ud.withTintColor(yellowColor))

    private var lastFrame: CGRect = .null
    private let yellowColor = UIColor.ud.Y600.alwaysLight
    private var defaultHeight: CGFloat?

    private var style: RedPacketHeaderViewStyle = .grabAmount {
        didSet {
            update(style: style)
        }
    }

    private lazy var nameContainer: UIView = {
        let view = UIView()
        return view
    }()

    private var detailButtonBottom: Constraint?
    private var infoLabelBottom: Constraint?
    private var instructionLabelBottom: Constraint?

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear

        addSubview(nameContainer)
        nameContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.left.top.equalToSuperview()
        }
        nameContainer.addSubview(descriptionLabel)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.bottom.top.equalToSuperview()
        }
        nameContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(16)
            make.right.lessThanOrEqualTo(-16)
            make.top.equalTo(30)
        }

        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(instructionLabel)
        instructionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(10)
            make.right.lessThanOrEqualTo(-10)
            make.top.equalTo(nameContainer.snp.bottom).offset(8)
            make.height.equalTo(20)
            instructionLabelBottom = make.bottom.equalTo(-30).constraint
        }
        instructionLabelBottom?.deactivate()

        sumOfMoneyLabel.font = UIFont(name: "DINAlternate-Bold", size: 44)
        sumOfMoneyLabel.textColor = yellowColor
        addSubview(sumOfMoneyLabel)
        sumOfMoneyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.height.equalTo(50)
        }

        unitLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        unitLabel.textColor = yellowColor
        unitLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoResultMoneyUnit
        addSubview(unitLabel)
        unitLabel.snp.makeConstraints { make in
            make.left.equalTo(sumOfMoneyLabel.snp.right).offset(4)
            make.bottom.equalTo(sumOfMoneyLabel.snp.bottom).offset(-8)
            make.height.equalTo(22)
        }

        infoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        infoLabel.textColor = yellowColor
        infoLabel.isHidden = true
        addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.height.equalTo(22)
            infoLabelBottom = make.bottom.equalTo(-30).constraint
        }
        infoLabelBottom?.deactivate()

        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        detailButton.setTitleColor(yellowColor, for: .normal)
        detailButton.addTarget(self, action: #selector(detailButtonDidClick), for: .touchUpInside)
        /// 海外版本飞书不显示跳转钱包按钮
        detailButton.alpha = ReleaseConfig.isFeishu ? 1 : 0
        addSubview(detailButton)
        detailButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(sumOfMoneyLabel.snp.bottom).offset(4)
            make.height.equalTo(20)
            detailButtonBottom = make.bottom.equalTo(-30).constraint
        }
        detailButtonBottom?.deactivate()
        addSubview(arrow)
        arrow.alpha = ReleaseConfig.isFeishu ? 1 : 0
        arrow.snp.makeConstraints { make in
            make.centerY.equalTo(detailButton)
            make.size.equalTo(15)
            make.left.equalTo(detailButton.snp.right).offset(4)
        }
        arrow.isHidden = true

        descriptionLabel.textColor = UIColor.ud.textTitle
        instructionLabel.textColor = UIColor.ud.textCaption
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }

    private func update(style: RedPacketHeaderViewStyle) {
        switch style {
        case .error:
            infoLabel.isHidden = false
            sumOfMoneyLabel.isHidden = true
            unitLabel.isHidden = true
            detailButton.isHidden = true
            arrow.isHidden = true
            detailButtonBottom?.deactivate()
            infoLabelBottom?.activate()
            instructionLabelBottom?.deactivate()
        case .grabAmount:
            infoLabel.isHidden = true
            sumOfMoneyLabel.isHidden = false
            unitLabel.isHidden = false
            detailButton.isHidden = false
            arrow.isHidden = true
            detailButtonBottom?.activate()
            infoLabelBottom?.deactivate()
            instructionLabelBottom?.deactivate()
        case .noGrabAmout:
            infoLabel.isHidden = true
            sumOfMoneyLabel.isHidden = true
            unitLabel.isHidden = true
            detailButton.isHidden = true
            arrow.isHidden = true
            detailButtonBottom?.deactivate()
            infoLabelBottom?.deactivate()
            instructionLabelBottom?.activate()
        }
    }

    func setContent(currentChatterId: String,
                    preferMaxWidth: CGFloat,
                    isShowAvatar: Bool,
                    description: String,
                    redPacketInfo: RedPacketInfo,
                    dismissType: RedPacketHeaderViewDismissType) {
        let isMeSentP2p = (redPacketInfo.chatter?.id ?? "") == currentChatterId &&
            redPacketInfo.type == .p2P
        descriptionLabel.text = description
        if isShowAvatar {
            avatarView.isHidden = false
            /// 如果是B2C红包，需要展示公司logo
            if redPacketInfo.isB2C {
                var passThrough = ImagePassThrough()
                passThrough.key = redPacketInfo.cover?.companyLogo.key
                passThrough.fsUnit = redPacketInfo.cover?.companyLogo.fsUnit
                avatarView.avatarView.avatarType = .company(passThrough: passThrough)
            } else {
                if let chatter = redPacketInfo.chatter {
                    avatarView.avatarView.avatarType = .user(identifier: chatter.id,
                                                             avatarKey: chatter.avatarKey,
                                                             avatarViewParams: .init(sizeType: .size(avatarSize)))
                }
            }
            let height = descriptionLabel.sizeThatFits(CGSize(width: preferMaxWidth - 64, height: CGFloat.greatestFiniteMagnitude)).height
            descriptionLabel.snp.remakeConstraints { make in
                make.left.equalTo(avatarView.snp.right).offset(8)
                make.right.bottom.top.equalToSuperview()
                make.height.equalTo(max(height, 24))
            }
            nameContainer.snp.updateConstraints { make in
                make.top.equalTo(30)
            }
        } else {
            avatarView.isHidden = true
            let height = descriptionLabel.sizeThatFits(CGSize(width: preferMaxWidth - 64, height: CGFloat.greatestFiniteMagnitude)).height
            descriptionLabel.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(max(height, 24))
            }
            nameContainer.snp.updateConstraints { make in
                make.top.equalTo(40)
            }
        }
        if let grabAmount = redPacketInfo.grabAmount, grabAmount != 0 {
            //已领取
            style = .grabAmount
            sumOfMoneyLabel.text = String(format: "%.2f", Float(grabAmount) / 100.0)
            detailButton.isEnabled = true
            detailButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_HongbaoResultCashOut,
                                  for: .normal)
            arrow.isHidden = false
        } else {
            let canShowGrbbedFinish: Bool
            if redPacketInfo.type == .exclusive {
                // 专属红包是发送才显示已领完
                canShowGrbbedFinish = redPacketInfo.userID == currentChatterId
            } else {
                canShowGrbbedFinish = true
            }
            if redPacketInfo.isGrabbedFinish, canShowGrbbedFinish {
                //已领完
                if isMeSentP2p {
                    style = .grabAmount
                    sumOfMoneyLabel.text = String(format: "%.2f", Float(redPacketInfo.totalAmount) / 100.0)
                    detailButton.isEnabled = false
                    detailButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_P2pOpened, for: .normal)
                } else {
                    style = .error
                    infoLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoNoneLeft
                }
            } else if redPacketInfo.isExpired {
                //已过期
                style = .error
                infoLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoExpired
            } else {
                //没领过
                if isMeSentP2p {
                    style = .grabAmount
                    sumOfMoneyLabel.text = String(format: "%.2f", Float(redPacketInfo.totalAmount) / 100.0)
                    detailButton.isEnabled = false
                    detailButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_P2pNotOpen, for: .normal)
                } else {
                    style = .noGrabAmout
                }
            }
        }
        instructionLabel.text = redPacketInfo.subject
        let instructionLabelHeight = instructionLabel.sizeThatFits(CGSize(width: preferMaxWidth - 32, height: CGFloat.greatestFiniteMagnitude)).height
        instructionLabel.snp.updateConstraints { make in
            make.height.equalTo(instructionLabelHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func detailButtonDidClick() {
        delegate?.headerViewBarDidClickDetailButton(self)
    }
}
