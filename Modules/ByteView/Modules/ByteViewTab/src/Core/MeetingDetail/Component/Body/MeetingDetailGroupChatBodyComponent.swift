//
//  MeetingDetailGroupChatBodyComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import RxSwift
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

class MeetingDetailGroupChatBodyComponent: MeetingDetailComponent {

    private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(string: I18n.View_G_MeetingStartedFromGroup,
                                                       config: .boldBodyAssist,
                                                       textColor: UIColor.ud.textCaption)
        return titleLabel
    }()

    private lazy var groupChatView: UIButton = {
        let groupChatView = UIButton()
        groupChatView.layer.masksToBounds = true
        groupChatView.layer.cornerRadius = 14
        groupChatView.setBackgroundColor(UIColor.ud.N900.dynamicColor.withAlphaComponent(0.1), for: .normal)
        groupChatView.setBackgroundColor(UIColor.ud.N900.dynamicColor.withAlphaComponent(0.2), for: .highlighted)
        groupChatView.addTarget(self, action: #selector(handleClick), for: .touchUpInside)
        return groupChatView
    }()

    private lazy var avatarView = AvatarView()

    private lazy var groupNameLabel: UILabel = UILabel()

    override func setupViews() {
        super.setupViews()

        backgroundColor = UIColor.ud.bgFloat
        translatesAutoresizingMaskIntoConstraints = false


        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview().inset(16)
        }

        addSubview(groupChatView)
        groupChatView.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(titleLabel)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        groupChatView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.left.equalTo(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        groupChatView.addSubview(groupNameLabel)
        groupNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(8)
        }
    }

    override func updateViews() {
        super.updateViews()

        guard let viewModel = self.viewModel, let appLinkInfo = viewModel.appLinkInfo.value,
                appLinkInfo.type == .group, let param = appLinkInfo.paramGroup else {
            isHidden = true
            return
        }

        viewModel.httpClient.getResponse(GetChatsRequest(chatIds: [param.chatID])) { [weak self] result in
            Util.runInMainThread {
                switch result {
                case .success(let resp):
                    guard let self = self, let chat = resp.chats.first(where: { $0.type == .group }) else { return }
                    self.isHidden = false
                    let title = NSAttributedString(string: chat.name, config: .bodyAssist, textColor: UIColor.ud.textTitle)
                    self.groupNameLabel.attributedText = title
                    self.avatarView.setAvatarInfo(.remote(key: chat.avatarKey, entityId: chat.id))
                case .failure(let error):
                    Logger.ui.error("Failed to get group info. MeetigGroupChatView will hide. Error: \(error)")
                    self?.isHidden = true
                }
            }
        }
    }

    @objc
    private func handleClick() {
        guard let linkInfo = viewModel?.appLinkInfo.value, let param = linkInfo.paramGroup else { return }
        VCTracker.post(name: .vc_meeting_lark_detail, params: [.action_name: "origin_group"])
        viewModel?.gotoChatViewController(userID: param.chatID, isGroup: true, shouldSwitchFeedTab: !(traitCollection.horizontalSizeClass == .compact))
    }
}

extension MeetingDetailGroupChatBodyComponent: MeetingDetailAppLinkInfoObserver {
    func didReceive(data: MeetingSourceAppLinkInfo) {
        updateViews()
    }
}
