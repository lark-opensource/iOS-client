//
//  ByteViewCryptoChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zc09v on 2021/10/28.
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
import LarkFeatureGating
import LarkFeatureSwitch
import LarkModel
import LKCommonsTracker
import Homeric
import LarkSetting

final public class ByteViewCryptoChatNavigationBarSubModule: BaseNavigationBarItemSubModule {
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
        if chat.type == .p2P {
            items.append(self.phoneItem)
        } else if chat.type == .group && (byteViewService?.meetingEnable ?? false) && !chat.isSuper {
            items.append(self.groupMeetingNavibarItem)
        }
        return items
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        if self.metaModel?.chat.isAllowPost != model.chat.isAllowPost {
            let canJoin = model.chat.isAllowPost && self.hasMeetingPersmission
            groupMeetingNavibarButton.unableJoin = !canJoin
        }
        self.metaModel = model
    }

    private lazy var phoneItem: ChatNavigationExtendItem = {
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
        return ChatNavigationExtendItem(type: .phoneItem, view: button)
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
            inCryptoChannel: true,
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

    private func videoItemClicked() {
        guard let chat = self.metaModel?.chat, let chatter = chat.chatter else { return }
        let targetVC = self.context.chatVC()
        if chat.chatterHasResign {
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ChatterResignPermissionPhone, on: targetVC.view)
            return
        }
        targetVC.view.endEditing(true)
        let params = PushParam(from: targetVC)
        let meta = CollaborationUserMeta(chatId: chat.id,
                                         chatterId: chatter.id,
                                         chatterName: chatter.displayName,
                                         chatterAvatarKey: chatter.avatarKey)
        byteViewService?.pushStartSingleMeetingVC(
            navigator: context.nav,
            userMeta: meta,
            isVoiceCall: false,
            pushParam: params)
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
        guard let metaModel = self.metaModel else { return }
        let targetVC = self.context.chatVC()
        Tracker.post(TeaEvent(Homeric.VC_MEETING_LARK_ENTRY, params: ["action_name": "encryption_chat"]))
        targetVC.view.endEditing(true)
        let chat = metaModel.chat
        ChatTrack.trackChatTitleBarVideoMeetingClick(chat: chat)
        let params = PushParam(from: targetVC)
        byteViewService?.pushJoinMeetingVC(groupID: chat.id, isFromSecretChat: true, isE2Ee: isE2EeMeetingEnable, isJoinMeeting: groupMeetingNavibarButton.isInMeeting, pushParam: params)
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

    private var isE2EeMeetingEnable: Bool {
        userResolver.fg.staticFeatureGatingValue(with: "byteview.meeting.e2ee_meeting")
    }
}
