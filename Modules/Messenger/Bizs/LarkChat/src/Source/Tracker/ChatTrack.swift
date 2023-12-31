//
//  ChatTrack.swift
//  LarkApp
//
//  Created by 李勇 on 2019/8/14.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import LarkModel
import AppReciableSDK
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import LKCommonsLogging
import LarkContainer
import LarkSearchCore

enum TranslateWay: String {
    case auto
    case manual
}

final class ChatTrack {
    //可感知新增字段
    static var CustomExtra = ["biz": Biz.Messenger.rawValue, "scene": Scene.Chat.rawValue]

    static func trackTapUnBlock(userID: String) {
        Tracker.post(TeaEvent(Homeric.CONTACT_UNBLOCK,
                              params: ["source": "im_unblock",
                                       "to_user_id": userID],
                              md5AllowList: ["to_user_id"]))
    }

    /// 翻译某条消息
    static func trackTranslate(chat: Chat, message: Message, way: TranslateWay) {
        var key: String = Homeric.MESSAGE_TRANSLATE
        if way == .auto {
            key = Homeric.MESSAGE_AUTOTRANSLATE
        }

        Tracker.post(TeaEvent(key, params: [
            "message_id": message.id,
            "message_type": messageType(message: message),
            "chat_type": chatType(chat: chat)
            ])
        )
    }

    /// 手动取消翻译某条消息
    static func trackTranslateToOrigin(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_UNTRANSLATE, params: [
            "is_autotranslate": chat.isAutoTranslate ? "y" : "n",
            "chat_type": chatType(chat: chat)
            ])
        )
    }

    /// 翻译了一张图片(对纯图片消息或者在查看器进行了翻译操作)
    static func trackTransalteImage(position: String, messageType: String) {
        Tracker.post(TeaEvent(Homeric.TRANSLATE_IMAGE, params: [
            "position": position,
            "message_type": messageType
            ])
        )
    }

    /// 操作了返回原图(对纯图片消息或者在查看器进行了还原操作)
    static func trackUntranslateImage() {
        Tracker.post(TeaEvent(Homeric.UNTRANSLATE_IMAGE, params: [:]))
    }

    static func trackChatTitleBarVideoMeetingClick(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_TITLE_BAR_VIDEO_CALL_CLICK, params: chat.chatInfoForTrack))
    }

    static func trackChatKeyBoardMoreClick(chat: Chat?) {
        guard let chat = chat else {
            return
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ADD_CLICK, params: chat.chatInfoForTrack))
    }

    static func messageType(message: Message) -> String {
        if message.type == .text { return "text" }
        if message.type == .post { return "post" }
        if message.type == .mergeForward { return "chat_history" }
        return ""
    }

    static func chatType(chat: Chat) -> String {
        if chat.isMeeting { return "meeting" }
        if chat.chatter?.type == .bot { return "single_bot" }
        if chat.type == .group { return "group" }
        return "single"
    }
    public static func trackForStableWatcher(domain: String, message: String, metricParams: [String: Any]?, categoryParams: [String: Any]?) {
        guard enablePostTrack() else { return }
        guard !domain.isEmpty, !message.isEmpty else { return }
        var realCategoryParams: [String: Any] = [
            "asl_monitor_domain": domain,
            "asl_monitor_message": message
        ]
        categoryParams?.forEach({(key, value) in
            realCategoryParams[key] = value
        })
        Tracker.post(SlardarEvent(name: "asl_watcher_event",
                                  metric: metricParams ?? [:],
                                  category: realCategoryParams,
                                  extra: [:]))
    }
    private static let logger = Logger.log(ChatTrack.self, category: "ChatTrack")
    public static func enablePostTrack() -> Bool {
        return SearchRemoteSettings.shared.enablePostStableTracker
    }
}

private func mainThreadExecuteTask(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async {
            task()
        }
    }
}

class ApprecibleTrackContext {
    // 开始时间
    var startTime: CFTimeInterval
    // FirstRender耗时
    var firstRenderViewCost: Int
    // sdk加载耗时
    var sdkCost: Int
    // 数据是否获取完成
    var dataIsRecieved: Bool
    // 是否依赖网络
    var isNeedNet: Bool

    init(startTime: CFTimeInterval = CACurrentMediaTime(),
         firstRenderViewCost: Int = 0,
         linkCost: Int = 0,
         sdkCost: Int = 0,
         dataIsRecieved: Bool = false,
         isNeedNet: Bool = false) {
        self.startTime = startTime
        self.firstRenderViewCost = firstRenderViewCost
        self.sdkCost = sdkCost
        self.dataIsRecieved = dataIsRecieved
        self.isNeedNet = isNeedNet
    }
}

enum ApprecibleTrackSourceType: Int {
    case messageDetail = 4
}

// 消息详情页列表打点
struct MessageDetailApprecibleTrack {
    final class MessageDetailContext: ApprecibleTrackContext {
        var category: [String: Any] = [:]
        var metric: [String: Any] = [:]
        var clientDataCostStart: CFTimeInterval = 0
        var clientDataCostEnd: CFTimeInterval = 0
        var clientRenderCostStart: CFTimeInterval = 0
        var clientRenderCostEnd: CFTimeInterval = 0

        init() {
            super.init()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(enterBackgroundHandle),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc
        private func enterBackgroundHandle() {
            self.category["enterBackground"] = true
        }
    }

    // 消息详情页列表打点相关配置
    private static let messageDetailPage = "MessageDetailViewController"
    private static var messageDetailPageKey: DisposedKey?
    private static var messageDetailPageTrackMap: [DisposedKey: MessageDetailContext] = [:]
    static func loadTimeStart(chat: Chat) {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Chat,
                                              event: .enterChat,
                                              page: messageDetailPage)
        messageDetailPageTrackMap.removeAll()
        let context = MessageDetailContext()
        context.startTime = CACurrentMediaTime()
        context.category["isCrypto"] = chat.isCrypto
        context.category["isExternal"] = chat.isCrossTenant
        context.category["chat_type"] = ApprecibleTrackSourceType.messageDetail.rawValue
        context.category["source_type"] = ChatFromWhere.default().rawValue
        context.metric["chatterCount"] = Int(chat.chatterCount)
        context.metric["feedId"] = chat.id
        messageDetailPageTrackMap[key] = context
        self.messageDetailPageKey = key
    }

    static func getMessageDetailPageKey() -> DisposedKey? {
        self.messageDetailPageKey
    }

    private static func getEventCost() -> Int {
        guard let disposedKey = messageDetailPageKey,
            let startTime = messageDetailPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateSDKCostTrack(key: DisposedKey?, cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = key else {
                return
            }
            messageDetailPageTrackMap[disposedKey]?.sdkCost = Int(cost * 1000)
        }
    }

    static func clientDataCostStartTrack(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = key else {
                return
            }
            messageDetailPageTrackMap[disposedKey]?.clientDataCostStart = CACurrentMediaTime()
        }
    }

    static func clientDataCostEndTrack(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = key else {
                return
            }
            messageDetailPageTrackMap[disposedKey]?.clientDataCostEnd = CACurrentMediaTime()
        }
    }

    static func clientRenderCostStartTrack(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = key else {
                return
            }
            messageDetailPageTrackMap[disposedKey]?.clientRenderCostStart = CACurrentMediaTime()
        }
    }

    static func clientRenderCostEndTrack(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = key else {
                return
            }
            messageDetailPageTrackMap[disposedKey]?.clientRenderCostEnd = CACurrentMediaTime()
        }
    }

    static func firstRenderCostTrack() {
        guard let disposedKey = messageDetailPageKey else {
            return
        }
        let cost = getEventCost()
        messageDetailPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        if messageDetailPageTrackMap[disposedKey]?.dataIsRecieved == true {
            loadingTimeEnd(key: disposedKey)
        }
    }

    static func loadingTimeEnd(key: DisposedKey?, isNeedNet: Bool? = nil) {
        mainThreadExecuteTask {
            guard let key = key else {
                return
            }
            messageDetailPageTrackMap[key]?.dataIsRecieved = true
            if let isNeedNet = isNeedNet {
                messageDetailPageTrackMap[key]?.isNeedNet = isNeedNet
            }
            // firstRenderViewCost完成后才能去打点
            guard messageDetailPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = messageDetailPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            let renderCost = max(0, (Int)((context.clientRenderCostEnd - context.clientRenderCostStart) * 1000))
            latencyDetail["client_render_cost"] = renderCost
            let dataCost = max(0, (Int)((context.clientDataCostEnd - context.clientDataCostStart) * 1000))
            latencyDetail["client_data_cost"] = dataCost
            latencyDetail["first_render"] = context.firstRenderViewCost

            let extra = Extra(isNeedNet: context.isNeedNet,
                              latencyDetail: latencyDetail,
                              metric: context.metric,
                              category: context.category)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func onError(key: DisposedKey?, error: Error) {
        guard let key = key,
              let context = messageDetailPageTrackMap.removeValue(forKey: key) else {
            return
        }
        let extra = Extra(isNeedNet: true,
                          metric: context.metric,
                          category: context.category)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Chat,
                                                        event: .enterChat,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: 2,
                                                        userAction: nil,
                                                        page: messageDetailPage,
                                                        errorMessage: nil,
                                                        extra: extra))
    }
}
