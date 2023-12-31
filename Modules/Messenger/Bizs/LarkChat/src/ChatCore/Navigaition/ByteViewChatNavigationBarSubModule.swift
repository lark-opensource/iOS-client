//
//  ByteViewChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zc09v on 2021/10/27.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkUIKit
import UniverseDesignColor
import LarkMessengerInterface
import LarkInteraction
import EENavigator
import RxSwift
import RxCocoa
import LarkCore
import LarkAccountInterface
import LarkContainer
import LarkBadge
import LarkSDKInterface
import UniverseDesignToast

//密聊场景下使用独立ByteViewCryptoChatNavigationBarSubModule，请注意修改是否需要同步调整
//https://bytedance.feishu.cn/wiki/wikcn1VprnQ1YOuaYpJFLRRplxb
final public class ByteViewChatNavigationBarSubModule: BaseNavigationBarItemSubModule {
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }
    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    private let itemsDisableTintColor: UIColor = UIColor.ud.iconDisabled
    private let itemsInMeetingTintColor: UIColor = UIColor.ud.colorfulGreen
    private let disposeBag: DisposeBag = DisposeBag()
    @ScopedInjectedLazy var byteViewService: ChatByteViewDependency?

    private var hasMeetingPersmission = true

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        if self.context.currentSelectMode() == .multiSelecting {
            self._rightItems = []
            return
        }
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self._rightItems = self.buildRigthItems(metaModel: metaModel)
    }

    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let chat = metaModel.chat
        switch chat.type {
        case .p2P:
            if !chat.isPrivateMode,
               userResolver.userID != chat.chatter?.id,
               chat.chatter?.type == .user {
                items.append(self.phoneItem)
            }
        case .group, .topicGroup:
            // 不是客服群 && 不是服务台 && 不是临时入会用户 && 群未冻结
            if !chat.isCustomerService && !chat.isOncall && byteViewService?.meetingEnable == true && !chat.isSuper && !chat.isPrivateMode
                && !chat.isInMeetingTemporary, !chat.isFrozen {
                switch chat.createVideoConferenceSetting {
                case .allMembers:
                    hasMeetingPersmission = true
                case .onlyManager:
                    hasMeetingPersmission = (chat.ownerId == userResolver.userID) || chat.isGroupAdmin
                case .none, .some(_):
                    assertionFailure("unknown type")
                    hasMeetingPersmission = true
                @unknown default:
                    assertionFailure("unknown type")
                    hasMeetingPersmission = true
                }
                items.append(self.groupMeetingNavibarItem)
            }
        @unknown default:
            break
        }
        return items
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        var needToRefresh = false
        if self.metaModel?.chat.isAllowPost != model.chat.isAllowPost {
            let canJoin = model.chat.isAllowPost && self.hasMeetingPersmission
            groupMeetingNavibarButton.unableJoin = !canJoin
        }
        if self.metaModel?.chat.isFrozen != model.chat.isFrozen {
            needToRefresh = true
        }
        self.metaModel = model
        if needToRefresh {
            self._rightItems = self.buildRigthItems(metaModel: model)
            self.context.refreshRightItems()
        }
    }

    private lazy var phoneButton: UIButton = {
        let button = UIButton()
        Self.addPointerStyle(button)
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.phone_titlebar,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self, weak button] (_) in
                guard let btn = button else { return }
                self?.phoneItemClicked(sender: btn)
            })
            .disposed(by: disposeBag)
        return button
    }()
    private lazy var phoneItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .phoneItem, view: phoneButton)
    }()

    @objc
    func phoneItemClicked(sender: UIButton) {
        guard let metaModel = self.metaModel else { return }
        let chat = metaModel.chat
        let targetVC = self.context.chatVC()
        guard let chatter = chat.chatter else {
            return
        }
        if chat.chatterHasResign {
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ChatterResignPermissionPhone, on: targetVC.view)
            return
        }
        targetVC.view.endEditing(true)

        let callByChannelBody = CallByChannelBody(
            chatterId: chatter.id,
            chatId: chat.id,
            displayName: chatter.displayName,
            // code_next_line tag CryptChat
            inCryptoChannel: false,
            sender: sender,
            isCrossTenant: chat.isCrossTenant,
            channelType: .chat,
            isShowVideo: true,
            accessInfo: chatter.accessInfo,
            chatterName: chatter.name,
            chatterAvatarKey: chatter.avatarKey,
            chat: chat)
        navigator.push(body: callByChannelBody, from: targetVC)
        IMTracker.Chat.Main.Click.MutipleCall(chat, context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))
        IMTracker.Call.Select.View(chat)
    }

    lazy private var groupMeetingNavibarItem: ChatNavigationExtendItem = {
        let view = UIView()
        view.addSubview(groupMeetingNavibarButton)
        groupMeetingNavibarButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.size.equalTo(MeetingNavigationbarButton.Layout.buttonSize)
        }
        return ChatNavigationExtendItem(type: .groupMeetingItem, view: view)
    }()

    lazy private var groupMeetingNavibarButton: MeetingNavigationbarButton = {
        let tintColor = self.context.navigationBarDisplayStyle().elementTintColor()
        let button = MeetingNavigationbarButton(
            tintColor: tintColor,
            disableTintColor: self.itemsDisableTintColor,
            inMeetingTintColor: self.itemsInMeetingTintColor,
            style: .light
        )
        /// 初始化的时候 需要关注下isAllowPost的状态
        let isAllowPost = self.metaModel?.chat.isAllowPost ?? true
        if !hasMeetingPersmission || !isAllowPost {
            button.unableJoin = true
        }
        Self.addPointerStyle(button)
        button.rx.tap
            .throttle(.seconds(2), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak button] _ in
                guard let `self` = self, let button = button else { return }
                if !button.isInMeeting && button.unableJoin {
                    //此时按钮图标状态为不可用
                    if let window = self.context.chatVC().view.window {
                        // 如果是因为群主配置了会议权限走下面的分支
                        if !self.hasMeetingPersmission {
                            UDToast.showTips(with: BundleI18n.LarkChat.Lark_Groups_OnlyGroupOwnerAdminCanVideoMeet, on: window)
                            return
                        }
                        UDToast.showTips(with: BundleI18n.LarkChat.Lark_Group_OnlyMembersWhoCanSendMessagesVC, on: window)
                    }
                    return
                }
                self.groupMeetingItemClicked()
            })
            .disposed(by: disposeBag)
        if let chat = self.metaModel?.chat {
            byteViewService?.getAssociatedMeeting(groupId: chat.id)
                .asObservable()
                .observeOn(MainScheduler.instance)
                .map({ meetingID -> Bool in
                    if meetingID?.isEmpty != false {
                        return false
                    } else {
                        return true
                    }
                })
                .subscribe(onNext: { [weak button] isInMeeting in
                    button?.isInMeeting = isInMeeting
                })
                .disposed(by: disposeBag)
        }
        return button
    }()

    private func groupMeetingItemClicked() {
        guard let metaModel = self.metaModel, let byteViewService else { return }
        let targetVC = self.context.chatVC()
        targetVC.view.endEditing(true)
        let chat = metaModel.chat
        ChatTrack.trackChatTitleBarVideoMeetingClick(chat: chat)
        let params = PushParam(from: targetVC)
        byteViewService.pushJoinMeetingVC(groupID: chat.id, isFromSecretChat: false, isE2Ee: false, isJoinMeeting: groupMeetingNavibarButton.isInMeeting, pushParam: params)
        IMTracker.Chat.Main.Click.Meeting(chat, context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))
    }

    private static func addPointerStyle(_ button: UIButton) {
        if #available(iOS 13.4, *) {
            button.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let view = interaction.view else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: view.bounds.width + 20, height: 36), 8)
                }))
        }
    }

    public override func barStyleDidChange() {
        if let image = phoneButton.imageView?.image {
            phoneButton.setImage(ChatNavigationBarItemTintColor.tintColorFor(image: image,
                                                                             style: self.context.navigationBarDisplayStyle()), for: .normal)
        }
        groupMeetingNavibarButton.meetingTintColor = self.context.navigationBarDisplayStyle().elementTintColor()
    }
}
