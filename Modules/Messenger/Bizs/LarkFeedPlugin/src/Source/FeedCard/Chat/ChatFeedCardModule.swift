//
//  ChatFeedCardModule.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/5/18.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkContainer
import LarkSwipeCellKit
import RustPB
import LarkModel
import RxSwift
import RxCocoa
import LarkFeed
import LarkBizTag
import LarkMessengerInterface
import LarkCore
import LarkAlertController
import LarkUIKit
import LarkNavigator
import LarkBizAvatar
import LarkEmotion
import LarkSceneManager
import LarkSDKInterface
import UniverseDesignDialog

struct ChatFeedErrorCode {
   static let outOfGroup: Int = 111_001
   static let disbandedGroup: Int = 4007
}

class ChatFeedCardModule: FeedCardBaseModule {
    @ScopedInjectedLazy private var dependency: ChatFeedCardDependency?

    let disposeBag = DisposeBag()

    // [必须实现]表明自己的业务类型
    override var type: FeedPreviewType {
        return .chat
    }

    // [必须实现] 关联业务的实体数据。feed框架内部使用，或者是使用feed框架的业务使用
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        let entityId: String
        if feedPreview.preview.chatData.chatType == .p2P {
            entityId = feedPreview.preview.chatData.chatterID
        } else {
            entityId = feedPreview.id
        }
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = feedPreview.id
        shortcutChannel.type = .chat
        let data = FeedPreviewBizData(entityId: entityId, shortcutChannel: shortcutChannel)
        return data
    }

    // [必须实现] 向feed card容器提供组装组件的配置信息。如果提供的默认的组装信息，已经满足业务方，则不需要重新配置，否则需要重写packInfo
    override var packInfo: FeedCardComponentPackInfo {
        let info = FeedCardComponentPackInfo(
            avatarArea: [.avatar],
            topArea: [.navigation],
            titleArea: [.title, .specialFocus, .customStatus, .tag],
            subTitleArea: [],
            statusArea: [.time, .flag],
            digestArea: [.reaction, .msgStatus, .digest, .mute, .mention],
            bottomArea: Feed.Feature(userResolver).feedButtonEnable ? [.cta] : [])
        return info
    }

    // [可选实现] 当对基础组件有异化数据诉求时，可实现这个方法
    override func customComponentVM(componentType: FeedCardComponentType,
                                    feedPreview: FeedPreview) -> FeedCardBaseComponentVM? {
        switch componentType {
        case .digest:
            let helper = FeedDigestInfoHelper(feedPreview: feedPreview, userResovler: feedCardContext.userResolver)
            return ChatFeedCardDigestVM(feedPreview: feedPreview, helper: helper)
        case .avatar:
            return ChatFeedCardAvatarVM(feedPreview: feedPreview)
        case .tag:
            return ChatFeedCardTagVM(feedPreview: feedPreview, userResovler: feedCardContext.userResolver, dependency: dependency)
        default:
            return nil
        }
    }

    // [必须实现] 控制 feed card 是否显示
    override func isShow(feedPreview: FeedPreview,
                         filterType: Feed_V1_FeedFilter.TypeEnum,
                         selectedStatus: Bool) -> Bool {
        /// 如果是密聊，没有消息可以直接显示
        if feedPreview.preview.chatData.isCrypto { return true }
        if filterType == .flag { return true }
        if feedPreview.preview.chatData.lastMessagePosition >= 0 { return true }
        let helper = FeedDigestInfoHelper(feedPreview: feedPreview, userResovler: feedCardContext.userResolver)
        if case .draft = helper.generateDigestMode(selectedStatus: selectedStatus) { return true }
        return false
    }

    // 返回从左往右滑动的 actions，返回 [] 可禁用从左往右滑动手势，返回过滤后的从左往右滑动的 actions
    override func rightActionTypes(feedPreview: FeedPreview, types: [FeedCardSwipeActionType]) -> [FeedCardSwipeActionType] {
        var rightActionTypes = types
        // 密盾聊暂不支持标记
        if feedPreview.preview.chatData.isPrivateMode {
            rightActionTypes.removeAll(where: { $0 == .flag })
        }
        return rightActionTypes
    }

    // mute操作，由各业务实现
    override func setMute(feedPreview: FeedPreview) -> Single<Void> {
        guard let dependency = dependency else { return .just(()) }
        return dependency.changeMute(chatId: feedPreview.id, to: !feedPreview.basicMeta.isRemind)
    }

    // 是否支持打标签操作
    override func isSupprtLabel(feedPreview: FeedPreview) -> Bool {
        return !feedPreview.preview.chatData.isCrypto
    }

    // 用于返回 cell 拖拽手势
    override func supportDragScene(feedPreview: FeedPreview) -> Scene? {
        switch feedPreview.preview.chatData.chatType {
        case .p2P:
            var userInfo: [String: String] = [:]
            userInfo["chatID"] = feedPreview.id
            let windowType = feedPreview.preview.chatData.chatterType == .bot ? "bot" : "single"
            let scene = LarkSceneManager.Scene(
                key: "P2pChat",
                id: feedPreview.preview.chatData.chatterID,
                title: feedPreview.uiMeta.name,
                userInfo: [:],
                windowType: windowType,
                createWay: "drag")
            return scene
        @unknown default:
            let chat = feedPreview
            var windowType: String = "group"
            if chat.preview.chatData.isMeeting {
                windowType = "event_group"
            } else if !chat.preview.chatData.oncallID.isEmpty {
                windowType = "help_desk"
            }
            let scene = LarkSceneManager.Scene(
                key: "Chat",
                id: feedPreview.id,
                title: chat.uiMeta.name,
                userInfo: [:],
                windowType: windowType,
                createWay: "drag")
            return scene
        }
    }

    // MARK: - FeedAction 能力
    override func getActionTypes(model: FeedActionModel, event: FeedActionEvent) -> [FeedActionType] {
        var types: [FeedActionType] = []
        switch event {
        case .leftSwipe:
            if !model.feedPreview.preview.chatData.isPrivateMode {
                types.append(.flag)
            }
            types.append(.shortcut)
        case .rightSwipe:
            types.append(.done)
        case .longPress:
            types += getActionTypes(model: model, event: .leftSwipe) +
                     getActionTypes(model: model, event: .rightSwipe)
            types.append(.mute)
            types.append(.clearBadge)
            if !model.feedPreview.preview.chatData.isCrypto {
                types.append(.label)
                types.append(.deleteLabel)
            }
            if model.feedPreview.preview.chatData.chatterType == .bot {
                types.append(.blockMsg)
            }
        @unknown default:
            break
        }
        return types
    }

    override func needHandleActionResult(type: FeedActionType, error: Error?) -> Bool {
        switch type {
        case .done, .shortcut, .mute, .flag:
           if let apiError = error?.underlyingError as? APIError,
              (Int(apiError.errorCode) == ChatFeedErrorCode.outOfGroup ||
               Int(apiError.errorCode) == ChatFeedErrorCode.disbandedGroup) {
               return true
           }
        default:
            break
        }
        return false
    }

    // 基于上方 needHandleActionResult 为前提判断条件
    override func handleActionResultByBiz(type: FeedActionType, model: FeedActionModel, error: Error?) {
        switch type {
        case .done, .shortcut, .mute, .flag:
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.LarkFeedPlugin.Lark_IM_YouAreNotInThisChat_Text, numberOfLines: 0)
            dialog.addPrimaryButton(text: BundleI18n.LarkFeedPlugin.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                FeedActionFactoryManager.performRemoveFeedAction(
                    feedPreview: model.feedPreview,
                    context: self.feedCardContext,
                    channel: model.channel)
            })
            model.fromVC?.present(dialog, animated: true, completion: nil)
        default:
            break
        }
    }
}
