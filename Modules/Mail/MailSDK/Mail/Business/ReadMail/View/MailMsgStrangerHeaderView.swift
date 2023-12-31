//
//  MailMsgStrangerHeaderView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/6/27.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import RxSwift

protocol MailMsgStrangerHeaderDelegate: AnyObject {
    func avatarClickHandler(mailAddress: MailAddress)
}

class MailMsgStrangerHeaderView: UIView {

    weak var delegate: MailStrangerManageDelegate?
    weak var avatarDelegate: MailMsgStrangerHeaderDelegate?
    private var actionItems: [MailActionItem] = []

    private let avatarView = MailAvatarImageView()
    private let senderTitle = UILabel()
    private let senderAddress = UILabel()

    private let allowButton = UIButton()
    private let rejectButton = UIButton()

    private let bottomBorder = UIView()

    private let avatarWidth: CGFloat = 40
    private let buttonWidth: CGFloat = 40
    private let buttonInset: CGFloat = 8

    private let disposeBag = DisposeBag()

    private var mailItem: MailItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgBody

        rejectButton.setImage(UDIcon.noOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        rejectButton.tintColor = .ud.functionDanger500
        rejectButton.imageEdgeInsets = UIEdgeInsets(top: buttonInset, left: buttonInset, bottom: buttonInset, right: buttonInset)
        rejectButton.addTarget(self, action: #selector(didClickReject), for: .touchUpInside)
        addSubview(rejectButton)
        rejectButton.snp.makeConstraints { make in
            make.trailing.equalTo(-buttonInset)
            make.width.height.equalTo(buttonWidth)
            make.centerY.equalToSuperview()
        }

        allowButton.setImage(UDIcon.yesOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        allowButton.tintColor = .ud.functionSuccess500
        allowButton.imageEdgeInsets = UIEdgeInsets(top: buttonInset, left: buttonInset, bottom: buttonInset, right: buttonInset)
        allowButton.addTarget(self, action: #selector(didClickAllow), for: .touchUpInside)
        addSubview(allowButton)
        allowButton.snp.makeConstraints { make in
            make.trailing.equalTo(rejectButton.snp.leading)
            make.width.height.equalTo(buttonWidth)
            make.centerY.equalToSuperview()
        }

        avatarView.dafaultBackgroundColor = UIColor.clear
        avatarView.layer.cornerRadius = avatarWidth / 2.0
        avatarView.layer.masksToBounds = true
        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(14)
            make.width.height.equalTo(avatarWidth)
            make.centerY.equalToSuperview()
        }
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAvatarClick)))

        senderTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        senderTitle.textColor = UIColor.ud.textTitle
        addSubview(senderTitle)
        senderTitle.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.top)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.equalTo(allowButton.snp.leading)
            make.height.equalTo(22)
        }

        senderAddress.font = UIFont.systemFont(ofSize: 12)
        senderAddress.textColor = UIColor.ud.textCaption
        addSubview(senderAddress)
        senderAddress.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.equalTo(allowButton.snp.leading)
            make.height.equalTo(18)
        }

        bottomBorder.isHidden = true
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { make in
            make.bottom.width.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBottomBorderIsHidden(_ isHidden: Bool) {
        bottomBorder.isHidden = isHidden
    }

    func updateActionItemsForStranger(_ newActionItems: [MailActionItem], mailItem: MailItem?) {
        actionItems = newActionItems
        self.mailItem = mailItem
        let firstMsgSender = mailItem?.messageItems.first?.message.from
        let larkEntityID: Int64 = firstMsgSender?.larkEntityType == .group ? 0 : (firstMsgSender?.larkEntityID ?? 0)

        MailModelManager.shared.getUserAvatarKey(userId: String(larkEntityID)).subscribe(onNext: { [weak self] (key) in
            guard let `self` = self else { return }
            if !key.isEmpty {
                self.avatarView.set(avatarKey: key, image: nil)
            } else {
                self.avatarView.setAvatar(with: firstMsgSender?.mailDisplayName ?? "", setBackground: true)
            }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            self.avatarView.loadAvatar(name: firstMsgSender?.mailDisplayName ?? "",
                                       avatarKey: "", entityId: "",
                                       setBackground: true) { _, error in
                if let error = error {
                    MailLogger.debug("[mail_stranger] MailMsgStrangerHeaderView load avatar Fail: \(error)")
                }
            }
        }).disposed(by: disposeBag)

        senderTitle.text = firstMsgSender?.mailDisplayName
        senderAddress.text = firstMsgSender?.address
    }

    func didClickStrangerReply(status: Bool) {
        if status {
            if let actionItem = actionItems.first(where: { $0.actionType == .allowStranger }) {
                actionItem.actionCallBack(self)
            }
        } else {
            if let actionItem = actionItems.first(where: { $0.actionType == .rejectStranger }) {
                actionItem.actionCallBack(self)
            }
        }
    }

    @objc func didClickAllow() {
        didClickStrangerReply(status: true)
    }

    @objc func didClickReject() {
        didClickStrangerReply(status: false)
    }

    @objc func handleAvatarClick() {
        if let fromAddress = mailItem?.messageItems.first?.message.from {
            avatarDelegate?.avatarClickHandler(mailAddress: MailAddress(with: fromAddress))
        }
    }
}


