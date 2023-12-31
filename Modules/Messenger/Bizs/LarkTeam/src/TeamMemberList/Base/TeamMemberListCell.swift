//
//  TeamMemberListCell.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2022/8/3.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LarkFocus
import LarkListItem
import LarkMessengerInterface
import EENavigator
import UniverseDesignToast
import LarkOpenFeed
import LarkContainer
import Swinject

final class TeamMemberListCell: BaseTableViewCell, TeamMemberCellInterface {
    private(set) var infoView: ListItem

    var isCheckboxHidden: Bool {
        get { return infoView.checkBox.isHidden }
        set {
            guard item?.isSelectedable ?? false else {
                infoView.checkBox.isHidden = true
                return
            }
            infoView.checkBox.isHidden = newValue
        }
    }

    func setCellSelect(canSelect: Bool,
                              isSelected: Bool,
                              isCheckboxHidden: Bool) {
        self.isCheckboxHidden = isCheckboxHidden
        infoView.checkBox.isSelected = isSelected
        infoView.checkBox.isEnabled = canSelect
        self.isUserInteractionEnabled = canSelect
    }
    private(set) var teamId: String = ""

    var isCheckboxSelected: Bool {
        get { return infoView.checkBox.isSelected }
        set { infoView.checkBox.isSelected = newValue }
    }

    let accessButton = UIButton(type: .custom)
    private(set) var item: TeamMemberItem?
    private(set) weak var from: UIViewController?
    private(set) var isTeamOpenChat: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        infoView = ListItem()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(infoView)
        infoView.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        contentView.addSubview(accessButton)
        accessButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.height.equalTo(17)
        }
        accessButton.addTarget(self, action: #selector(enterChat), for: .touchUpInside)
        accessButton.setImage(Resources.chatOutlined, for: .normal)
        infoView.checkBox.isHidden = true
        infoView.statusLabel.isHidden = true
        infoView.additionalIcon.isHidden = true
        infoView.nameTag.isHidden = true
        infoView.nameTag.maxTagCount = 3
        infoView.infoLabel.isHidden = true

        // 禁掉 UserInteractionEnabled 然后使用TableView的didselected回调
        infoView.checkBox.isUserInteractionEnabled = false
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        infoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
        infoView.avatarView.image = nil
        infoView.nameLabel.text = nil
        infoView.nameTag.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    func set(_ item: TeamMemberItem, filterKey: String?, from: UIViewController, teamId: String) {
        self.item = item
        self.from = from
        self.teamId = teamId

        infoView.avatarView.setAvatarByIdentifier(item.itemId, avatarKey: item.itemAvatarKey,
                                                  avatarViewParams: .init(sizeType: .size(infoView.avatarSize)))
        infoView.nameLabel.text = item.itemName
        infoView.infoLabel.text = item.itemDescription
        changeModel(item: item)

        if let tags = item.itemTags {
            infoView.nameTag.isHidden = false
            infoView.nameTag.setElements(tags)
        }
        infoView.bottomSeperator.isHidden = true
    }

    func changeModel(item: TeamMemberItem) {
        guard let item = item as? TeamMemberCellVM else { return }
        if item.isChatter {
            infoView.snp.updateConstraints {
                $0.trailing.equalToSuperview()
            }
            if let text = infoView.infoLabel.text, !text.isEmpty {
                infoView.infoLabel.isHidden = false
            } else {
                infoView.infoLabel.isHidden = true
            }
            accessButton.isHidden = true
        } else {
            infoView.snp.updateConstraints {
                $0.trailing.equalToSuperview().offset(-(-20 + 20 + 16))
            }
            infoView.infoLabel.isHidden = false
            accessButton.isHidden = false
            let image: UIImage
            for teamInfo in item.chatInfo.chat.boundTeamInfos {
                if String(teamInfo.teamID) == teamId {
                    isTeamOpenChat = (teamInfo.teamChatType == .open)
                    break
                }
            }
            if (item.chatInfo.operatorInChat) || isTeamOpenChat {
                image = Resources.chatOutlined
            } else {
                image = Resources.chatDisableOutlined
            }
            accessButton.setImage(image, for: .normal)
        }
    }

    @objc
    func enterChat() {
        // 租户公开群不支持用户跳转
        guard let item = item as? TeamMemberCellVM,
              let from = self.from else { return }
        let chat = item.chatInfo.chat
        if item.chatInfo.operatorInChat {
            let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                     isCrypto: chat.isCrypto,
                                                     isMyAI: chat.isP2PAi,
                                                     chatMode: chat.chatMode)
            TeamTracker.trackTeamMemberListEnterChat(teamId: teamId, chatId: chat.id)
            item.userResolver.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: from)
        } else if isTeamOpenChat {
            let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                     positionStrategy: ChatMessagePositionStrategy.toLatestPositon,
                                                     chatSyncStrategy: .forceRemote,
                                                     fromWhere: .team(teamID: Int64(teamId) ?? 0),
                                                     isCrypto: chat.isCrypto,
                                                     isMyAI: chat.isP2PAi,
                                                     chatMode: chat.chatMode)
            TeamTracker.trackTeamMemberListEnterChat(teamId: teamId, chatId: chat.id)
            item.userResolver.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: from)
        } else {
            UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_CannotJoinGroup_Hover, on: from.view)
        }
    }
}
