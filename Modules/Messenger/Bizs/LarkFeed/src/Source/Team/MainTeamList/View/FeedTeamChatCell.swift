//
//  FeedTeamChatCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import UIKit
import LarkSwipeCellKit
import RxSwift
import SnapKit
import LarkBizAvatar
import LarkZoomable
import LarkSceneManager
import ByteWebImage
import RustPB
import LarkModel
import LarkBadge
import LarkMessengerInterface
import UniverseDesignDialog
import LarkOpenFeed
import EENavigator
import LarkUIKit
import LarkNavigator
import LarkFeatureGating
import UniverseDesignColor
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast

final class FeedTeamChatCell: SwipeTableViewCell {
    /// 布局配置
    enum Cons {
        static var vMargin: CGFloat { 12 }
        static var nameFont: UIFont { UIFont.ud.title4 }

        // contentHeight 属性会在列表滑动时多次获取，若为计算变量，会生成大量 UIFont 实例，
        // 这里改用使用静态存储变量提升性能
        private static var _zoom: Zoom?
        private static var _contentHeight: CGFloat = getContentHeight()
        private static func getContentHeight() -> CGFloat {
            _zoom = Zoom.currentZoom
            return nameFont.figmaHeight
        }
        // Zoom 级别变化时，对静态存储变量重新赋值
        static var contentHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _contentHeight = getContentHeight()
            }
            return _contentHeight
        }
        static var cellHeight: CGFloat {
            contentHeight + vMargin * 2
        }
    }

    static var identifier: String = "FeedTeamChatCell"
    static let downsampleSize = CGSize(width: 36, height: 36)
    static let downsampleSizeForAtAvatar = CGSize(width: 22, height: 22)
    var viewModel: FeedTeamChatItemViewModel?
    var highlightColor = UIColor.ud.fillHover
    let avatarView = LarkMedalAvatar()
    let nameLabel = UILabel()
    let atAvatarView = BizAvatar()
    let atAvatarWrapper = UIView()
    let badgeView = BadgeView(with: .label(.number(0)))
    private let disposeBag = DisposeBag()
    var selectedColor = UDMessageColorTheme.imFeedFeedFillActive
    let italicFont: UIFont

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let matrix = CGAffineTransformMake(1, 0, CGFloat(tanf(15 * Float.pi / 180)), 1, 0, 0)
        let desc: UIFontDescriptor = UIFontDescriptor(name: "", matrix: matrix)
        self.italicFont = UIFont(descriptor: desc, size: UIFont.ud.title4.pointSize)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.setBackViewColor(backgroundColor(highlighted))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setBackViewColor(backgroundColor(selected))
    }

    func setupView() {
        selectionStyle = .none
        self.swipeView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = Self.Cons.nameFont
        atAvatarWrapper.isHidden = true
        badgeView.isHidden = true
        badgeView.setMaxNumber(to: 999)
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }

    func layout() {
        swipeView.addSubview(avatarView)
        swipeView.addSubview(nameLabel)
        swipeView.addSubview(atAvatarWrapper)
        atAvatarWrapper.addSubview(atAvatarView)
        swipeView.addSubview(badgeView)

        avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.downsampleSize)
            make.leading.equalToSuperview().offset(16)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        atAvatarWrapper.snp.makeConstraints { make in
            make.size.equalTo(Self.downsampleSizeForAtAvatar)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(badgeView.snp.leading).offset(-8)
            make.leading.equalTo(nameLabel.snp.trailing).offset(5)
        }

        atAvatarWrapper.setContentCompressionResistancePriority(.required, for: .horizontal)
        atAvatarView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(2)
            make.bottom.trailing.equalToSuperview().offset(-2)
        }
    }

    func set(userResolver: UserResolver, _ cellViewModel: FeedTeamChatItemViewModel, mode: SwitchModeModule.Mode, teamID: Int64) {
        viewModel = cellViewModel
        configAvatar(cellViewModel)

        if cellViewModel.chatItem.isHidden && cellViewModel.chatEntity.uiMeta.mention.hasAtInfo {
            nameLabel.font = italicFont
        } else {
            nameLabel.font = UIFont.ud.title4
        }

        if Feed.Feature.teamChatPrivacy {
            if cellViewModel.chatEntity.preview.chatData.chatRole != .member {
                nameLabel.textColor = UIColor.ud.textPlaceholder
            } else {
                nameLabel.textColor = UIColor.ud.textTitle
            }
        } else {
            if cellViewModel.chatEntity.chatFeedPreview?.teamEntity.teamsChatType[teamID] == .open,
               cellViewModel.chatEntity.preview.chatData.chatRole != .member {
                nameLabel.textColor = UIColor.ud.textPlaceholder
            } else {
                nameLabel.textColor = UIColor.ud.textTitle
            }
        }

        self.nameLabel.text = cellViewModel.chatEntity.uiMeta.name
        let leftInset = cellViewModel.getLeftInset(mode: mode)
        avatarView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(leftInset)
        }

        if let badgeInfo = cellViewModel.badgeInfo {
            badgeView.isHidden = false
            badgeView.type = badgeInfo.type
            badgeView.style = badgeInfo.style
            badgeView.snp.updateConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
            }
        } else {
            badgeView.isHidden = true
            badgeView.snp.updateConstraints { make in
                make.trailing.equalToSuperview()
            }
        }
    }

    func configAvatar(_ chat: FeedTeamChatItemViewModel) {
        let feed = chat.chatEntity
        let entityId = feed.id
        let avatarKey = feed.uiMeta.avatarKey
        if (!entityId.isEmpty) && (!avatarKey.isEmpty) {
            avatarView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                medalKey: feed.preview.chatData.avatarMedal.key,
                medalFsUnit: feed.preview.chatData.avatarMedal.name,
                scene: .Feed,
                options: [.downsampleSize(Self.downsampleSize)],
                avatarViewParams: .init(sizeType: .size(Self.downsampleSize.width)))
        } else {
            avatarView.image = nil
        }
        if chat.chatEntity.uiMeta.mention.hasAtInfo {
            atAvatarWrapper.isHidden = false
            atAvatarView.updateBorderSize(Self.downsampleSizeForAtAvatar)
            let entityId = chat.chatEntity.uiMeta.mention.atInfo.userID
            let avatarKey = chat.chatEntity.uiMeta.mention.atInfo.avatarKey
            if (!entityId.isEmpty) && (!avatarKey.isEmpty) {
                atAvatarView.setAvatarByIdentifier(
                    entityId,
                    avatarKey: avatarKey,
                    scene: .Feed,
                    avatarViewParams: .init(sizeType: .size(Self.downsampleSizeForAtAvatar.width)),
                    completion: { result in
                        if case let .failure(error) = result {
                            FeedContext.log.error("teamlog/image/feedAt. \(chat.chatEntity.id), \(chat.chatEntity.uiMeta.mention.atInfo.userID)", error: error)
                        }
                    })
            } else {
                atAvatarView.image = nil
            }
            atAvatarView.updateBorderImage(chat.atBorderImage)
            atAvatarWrapper.snp.updateConstraints { make in
                make.size.equalTo(Self.downsampleSizeForAtAvatar)
                make.trailing.equalTo(badgeView.snp.leading).offset(-8)
            }
        } else {
            atAvatarWrapper.isHidden = true
            atAvatarWrapper.snp.updateConstraints { make in
                make.size.equalTo(CGSize.zero)
                make.trailing.equalTo(badgeView.snp.leading)
            }
        }
    }
}

// 跳转逻辑
extension FeedTeamChatCell {
    func didSelectCell(teamItemModel: FeedTeamItemViewModel, indexPath: IndexPath, from: UIViewController, dependency: FeedTeamDependency) {
        guard let feed = self.viewModel?.chatEntity else { return }
        FeedTracker.Team.Click.Chat(team: teamItemModel.teamEntity, feed: feed)
        let chat = dependency.transform(feed: feed, teamID: teamItemModel.teamEntity.id)
        var info = "teamLog/action/cell/tap. teamItemId: \(teamItemModel.teamItem.id), teamEntityId: \(teamItemModel.teamEntity.id), feedId: \(feed.id), fromChat: \(chat.fromChat), "
        info.append("chatType: \(chat.teamChatType ?? .unknown), chatRole: \(chat.role), chatPosition: \(chat.position), ")
        info.append("feedType: \(feed.chatFeedPreview?.teamEntity.teamsChatType), feedRole: \(feed.preview.chatData.chatRole), feedPosition: \(feed.preview.chatData.lastMessagePosition)")
        FeedContext.log.info(info)
        let isChatMember = chat.role == .member
        if isChatMember {
            //如果是群成员
            pushChatController(resolver: dependency.userResolver, chat, teamID: teamItemModel.teamEntity.id, from: from)
        } else {
            // 如果不是群成员
            if chat.teamChatType == .open {
                // 如果是公开群
                pushChatController(resolver: dependency.userResolver, chat,
                                   positionStrategy: ChatMessagePositionStrategy.toLatestPositon,
                                   chatSyncStrategy: .forceRemote,
                                   teamID: teamItemModel.teamEntity.id,
                                   from: from)
            } else {
                if Feed.Feature.teamChatPrivacy {
                    if chat.teamChatType == .private {
                        // 私密可发现
                        let body = GroupCardTeamJoinBody(chatId: chat.id, teamId: teamItemModel.teamEntity.id)
                        dependency.userResolver.navigator.showDetailOrPush(
                            body: body,
                            wrap: LkNavigationController.self,
                            from: from)
                    } else {
                        // 需弹框拦截，同时移除该 Feed
                        removeFeedCard(chatId: chat.id, dependency: dependency, from: from)
                    }
                } else {
                    // 需弹框拦截，同时移除该 Feed
                    removeFeedCard(chatId: chat.id, dependency: dependency, from: from)
                }
            }
        }
    }

    func pushChatController(resolver: UserResolver,
                            _ chat: ChatData,
                            positionStrategy: ChatMessagePositionStrategy? = nil,
                            chatSyncStrategy: ChatSyncStrategy = .default,
                            teamID: Int64,
                            from: UIViewController) {
        let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                 positionStrategy: positionStrategy,
                                                 chatSyncStrategy: chatSyncStrategy,
                                                 fromWhere: .team(teamID: teamID),
                                                 isCrypto: chat.isCrypto,
                                                 isMyAI: chat.isMyAI,
                                                 chatMode: chat.chatMode,
                                                 extraInfo: ["feedId": chat.id]
        )
        let selectedInfo = FeedSelection(feedId: chat.id)
        let context: [String: Any] = [FeedSelection.contextKey: selectedInfo]
        resolver.navigator.showDetailOrPush(body: body,
                                          context: context,
                                          wrap: LkNavigationController.self,
                                          from: from)
    }
}

// 移除群聊 逻辑
extension FeedTeamChatCell {
    // 如果被踢出群聊，需弹框拦截，同时移除该 Feed
    func removeFeedCard(chatId: String, dependency: FeedTeamDependency, from: UIViewController) {
        dependency.getKickInfo(chatId: chatId)
            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: BundleI18n.LarkFeed.Lark_IM_YouAreNotInThisChat_Text)
            .drive(onNext: { [weak from] (content) in
                guard let from = from else { return }
                let dialog = UDDialog()
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Legacy_IKnow,
                                 dismissCompletion: {
                    var channel = Basic_V1_Channel()
                    channel.type = .chat
                    channel.id = chatId
                    dependency.removeFeedCard(channel: channel, feedPreviewPBType: .chat)
                })
                dependency.navigator.present(dialog, from: from)
            }).disposed(by: self.disposeBag)
    }
}

// 选中逻辑
extension FeedTeamChatCell {
    func backgroundColor(_ highlighted: Bool) -> UIColor {
        var backgroundColor = UIColor.ud.fillHover

        let needShowSelected = (self.viewModel?.isSelected ?? false) &&
            self.horizontalSizeClass == .regular

        if FeedSelectionEnable && needShowSelected {
            backgroundColor = self.selectedColor
        } else {
            backgroundColor = highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
        return backgroundColor
    }
}

// 隐藏群 逻辑
extension FeedTeamChatCell {
    func update() {
        avatarView.isHidden = true
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - 兜底数据
struct ChatData {
    let id: String
    let role: Basic_V1_Chat.Role
    let position: Int32
    let isCrypto: Bool
    let isMyAI: Bool
    let chatMode: Basic_V1_Chat.ChatMode
    let teamChatType: Basic_V1_TeamChatType?
    let fromChat: Bool

    static func transform(chatAPI: ChatAPI, feed: FeedPreview, teamID: Int64) -> ChatData {
        if feed.chatFeedPreview?.teamEntity.teamsChatType[teamID] == .open && feed.preview.chatData.chatRole != .member {
            // 访客群
            if let chat = chatAPI.getLocalChat(by: feed.id) {
                if chat.lastMessagePosition >= feed.preview.chatData.lastMessagePosition {
                    return Self.transform(chat: chat, teamID: teamID)
                } else {
                    return Self.transform(feedEntity: feed, teamID: teamID)
                }
            } else {
                return Self.transform(feedEntity: feed, teamID: teamID)
            }
        } else {
            return Self.transform(feedEntity: feed, teamID: teamID)
        }
    }

    private static func transform(feedEntity: FeedPreview, teamID: Int64) -> ChatData {
        return ChatData(id: feedEntity.id,
                        role: feedEntity.preview.chatData.chatRole,
                        position: Int32(feedEntity.preview.chatData.lastMessagePosition),
                        isCrypto: feedEntity.preview.chatData.isCrypto,
                        isMyAI: feedEntity.preview.chatData.isP2PAi,
                        chatMode: feedEntity.preview.chatData.chatMode,
                        teamChatType: feedEntity.chatFeedPreview?.teamEntity.teamsChatType[teamID],
                        fromChat: false)
    }

    private static func transform(chat: Chat, teamID: Int64) -> ChatData {
        return ChatData(id: chat.id,
                        role: chat.role,
                        position: chat.lastMessagePosition,
                        isCrypto: chat.isCrypto,
                        isMyAI: chat.isP2PAi,
                        chatMode: chat.chatMode,
                        teamChatType: chat.teamEntity.teamsChatType[teamID],
                        fromChat: true)
    }
}
