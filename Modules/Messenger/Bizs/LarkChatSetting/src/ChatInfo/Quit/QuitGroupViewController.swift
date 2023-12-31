//
//  QuitGroupViewController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/12/22.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkCore
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LarkBizAvatar
import LarkSuspendable

final class QuitGroupViewController: BaseSettingController {
    fileprivate var disposeBag = DisposeBag()
    fileprivate var contentView: GroupQuitBasicInformationView = .init(frame: .zero, tips: "")

    fileprivate var chatId: String
    fileprivate var chat: Chat
    fileprivate var groupName: String
    fileprivate var avatarKey: String
    fileprivate var ownerId: String
    fileprivate var currentTenantId: String
    fileprivate var membersCount: Int
    private let currentChatterId: String
    private let chatAPI: ChatAPI
    private let pushLeave: PushLocalLeaveGroupHandler
    private let tips: String
    private let isThread: Bool

    fileprivate lazy var quitButtonText: String = {
        return isThread ? BundleI18n.LarkChatSetting.Lark_Groups_LeaveCircleDialogLeaveButton : BundleI18n.LarkChatSetting.Lark_Legacy_LeaveChat
    }()
    fileprivate var quitButtonTextWidth: CGFloat {
        return quitButtonText.lu.width(font: UIFont.systemFont(ofSize: 16))
    }

    fileprivate lazy var transferButtonText: String = {
        return isThread ? BundleI18n.LarkChatSetting.Lark_Groups_LeaveCircleDialogAssignNewOwnerButton : BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner
    }()
    fileprivate var transferButtonTextWidth: CGFloat {
        return transferButtonText.lu.width(font: UIFont.systemFont(ofSize: 16))
    }

    private let buttonsWrapperView = UIView()
    private lazy var quitButton: UIButton = {
        return self.creatButton(
            title: quitButtonText,
            textColor: UIColor.ud.functionDangerContentDefault,
            backgroundColor: UIColor.ud.bgFloatBase,
            borderColor: UIColor.ud.functionDangerContentDefault,
            action: #selector(quitButtonTapped))
    }()
    private lazy var transferButton: UIButton = {
        return self.creatButton(
            title: transferButtonText,
            textColor: UIColor.ud.primaryOnPrimaryFill,
            backgroundColor: UIColor.ud.primaryContentDefault,
            hasBorder: false,
            action: #selector(transferButtonTapped))
    }()

    static let logger = Logger.log(QuitGroupViewController.self, category: "Module.IM.GroupCard")
    private let navi: Navigatable
    init(
        chat: Chat,
        currentChatterId: String,
        currentTenantId: String,
        chatAPI: ChatAPI,
        tips: String,
        isThread: Bool,
        navi: Navigatable,
        pushLeave: @escaping PushLocalLeaveGroupHandler
    ) {
        self.chatId = chat.id
        self.chat = chat
        self.groupName = chat.displayName
        self.avatarKey = chat.avatarKey
        self.ownerId = chat.ownerId
        self.membersCount = Int(chat.chatterCount)
        self.currentChatterId = currentChatterId
        self.chatAPI = chatAPI
        self.pushLeave = pushLeave
        self.currentTenantId = currentTenantId
        self.tips = tips
        self.isThread = isThread
        self.navi = navi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = isThread ? BundleI18n.LarkChatSetting.Lark_Groups_GroupsInfoExitGroup : BundleI18n.LarkChatSetting.Lark_Legacy_LeaveChat
        self.setupSubviews()
    }

    fileprivate func setupSubviews() {
        let contentView = GroupQuitBasicInformationView(frame: self.view.bounds, tips: tips)
        contentView.entityId = chatId
        contentView.avatarKey = avatarKey
        contentView.groupName = groupName
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        contentView.layer.cornerRadius = 10
        self.contentView = contentView

        buttonsWrapperView.addSubview(quitButton)
        buttonsWrapperView.addSubview(transferButton)
        self.view.addSubview(buttonsWrapperView)
        buttonsWrapperView.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
        }
    }

    fileprivate func creatButton(
        title: String,
        textColor: UIColor = UIColor.ud.N900,
        backgroundColor: UIColor = UIColor.ud.N00,
        font: CGFloat = 16,
        hasBorder: Bool = true,
        borderColor: UIColor = UIColor.ud.N300,
        cornerRaduis: CGFloat = 6,
        action: Selector
        ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor, for: .highlighted)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.backgroundColor = backgroundColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: font)
        button.layer.cornerRadius = cornerRaduis
        button.layer.masksToBounds = true
        button.addTarget(self, action: action, for: .touchUpInside)
        if hasBorder {
            button.layer.ud.setBorderColor(borderColor)
            button.layer.borderWidth = 1
        }
        return button
    }

    fileprivate func canShowButtonsInOneLine() -> Bool {
        let widthRequired = quitButtonTextWidth + transferButtonTextWidth + 12 * 4 + 16 * 2 + 24
        return widthRequired <= view.frame.width
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let singleLineButtonMinWidth: CGFloat = 127
        let singleLineButtonHeight: CGFloat = 40

        if canShowButtonsInOneLine() {
            quitButton.snp.remakeConstraints { (make) in
                make.height.equalTo(singleLineButtonHeight)
                make.width.equalTo(max(singleLineButtonMinWidth, quitButtonTextWidth + 24))
                make.top.bottom.left.equalToSuperview()
            }
            transferButton.snp.remakeConstraints { (make) in
                make.height.centerY.equalTo(quitButton)
                make.width.equalTo(max(singleLineButtonMinWidth, transferButtonTextWidth + 24))
                make.left.equalTo(quitButton.snp.right).offset(24)
                make.right.equalToSuperview()
            }
        } else {
            transferButton.snp.remakeConstraints { (make) in
                make.height.equalTo(48)
                make.left.right.top.equalToSuperview()
                make.width.equalTo(self.view).offset(-32)
            }
            quitButton.snp.remakeConstraints { (make) in
                make.height.width.equalTo(transferButton)
                make.top.equalTo(transferButton.snp.bottom).offset(16)
                make.bottom.equalToSuperview()
            }
        }
    }

    @objc
    fileprivate func quitButtonTapped() {
        let contentString: String
        if isThread {
            contentString = BundleI18n.LarkChatSetting.Lark_Groups_MemberLeaveCircleDialogContent
        } else {
            contentString = BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoExitGroupNotify(groupName)
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Legacy_Hint)
        alertController.setContent(text: contentString)
        alertController.addCancelButton(dismissCompletion: {
            NewChatSettingTracker.imQuitGroupConfirmClickCancel(chat: self.chat)
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure, dismissCompletion: {
            [unowned self] in
            ChatSettingTracker.trackExitChatClick(chat: self.chat)
            self.quitGroup()
        })
        self.navi.present(alertController, from: self)
    }

    @objc
    fileprivate func transferButtonTapped() {
        if membersCount <= 1 {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwner)
            alertController.setContent(text: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoTransferOnlyownerContent)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
            self.navi.present(alertController, from: self)
            return
        }
        ChatSettingTracker.newTrackTransferClick(source: .exitGroup, chatId: chat.id, chat: self.chat)
        var body = TransferGroupOwnerBody(chatId: chatId,
                                          mode: .leaveAndAssign,
                                          isThread: isThread)
        let chat = self.chat
        let chatId = self.chatId
        body.lifeCycleCallback = { [weak self] res in
            ChatSettingTracker.trackTransmitChatOwner(chat: chat, source: .chatExit)
            switch res {
            case .before:
                ChatSettingTracker.trackTransmitChatOwner(chat: chat, source: .chatExit)
                self?.pushLeave(chatId, .start)
            case .success:
                self?.transferGroupOnSuccess()
            case .failure(let error, let newOwnerID):
                self?.transferGroupOnError(error, newOwnerID: newOwnerID)
            }
        }
        self.navi.push(body: body, from: self)
    }

    /// 退出群聊: 一人的时候直接退群, 多人以上先转让群主给顺位第二人再退群
    fileprivate func quitGroup() {
        self.transferGroup(newOwnerID: nil)
    }

    private func transferGroupOnSuccess() {
        self.pushLeave(chatId, .success)
        self.pushLeave(chatId, .completed)
        SuspendManager.shared.removeSuspend(byId: chatId)
    }

    private func transferGroupOnError(_ error: Error, newOwnerID: String?) {
        QuitGroupViewController.logger.error(
            "transfer group failed",
            additionalData: ["newOwnerID": newOwnerID ?? ""],
            error: error
        )
        self.showTransferGroupError(error)
        self.pushLeave(chatId, .error)
    }

    /// 转让群主并退群
    fileprivate func transferGroup(newOwnerID: String?) {
        let chatId = self.chatId
        self.pushLeave(chatId, .start)
        self.chatAPI
            .deleteChatters(chatId: chatId, chatterIds: [currentChatterId], newOwnerId: newOwnerID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.transferGroupOnSuccess()
            }, onError: { [weak self] (error) in
                self?.transferGroupOnError(error, newOwnerID: newOwnerID)
            }).disposed(by: self.disposeBag)
    }

    private func showTransferGroupError(_ error: Error) {
        if let error = error.underlyingError as? APIError, let window = self.currentWindow() {
            switch error.type {
            case .transferGroupOwnerFailed(let message):
                UDToast.showFailure(with: message, on: window, error: error)
            default:
                UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ChangeOwnerFailed, on: window, error: error)
            }
        }
    }
}

final class GroupQuitBasicInformationView: UIView {
    fileprivate var avatarImageView: BizAvatar = .init(frame: .zero)
    fileprivate let avatarSize: CGFloat = 60
    fileprivate var nameLabel: UILabel = .init()
    fileprivate var tipsLabel: UILabel = .init()

    var avatarKey: String? {
        didSet {
            avatarImageView.setAvatarByIdentifier(entityId ?? "", avatarKey: avatarKey ?? "",
                                                  avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
    }

    var entityId: String?

    var groupName: String? {
        didSet {
            nameLabel.text = groupName
        }
    }

    init(frame: CGRect, tips: String) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgFloat

        let avatarImageView = BizAvatar()
        self.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.left.equalTo(15)
            make.width.height.equalTo(avatarSize)
        }
        self.avatarImageView = avatarImageView

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.textAlignment = .left
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingTail
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarImageView)
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(-15)
        }
        self.nameLabel = nameLabel

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N300
        self.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.left.equalTo(15)
            make.right.equalTo(15)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let tipsLabel = UILabel()
        tipsLabel.textColor = UIColor.ud.N900
        tipsLabel.textAlignment = .left
        tipsLabel.lineBreakMode = .byTruncatingTail
        tipsLabel.text = tips
        tipsLabel.font = UIFont.systemFont(ofSize: 14)
        tipsLabel.numberOfLines = 0
        self.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(lineView.snp.bottom).offset(22)
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.bottom.equalTo(-22)
        }
        self.tipsLabel = tipsLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
