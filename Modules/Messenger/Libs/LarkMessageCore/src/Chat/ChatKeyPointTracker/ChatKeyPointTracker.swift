//
//  ChatKeyPointTracker.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/8/16.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkPerf
import LarkFoundation
import LarkSDKInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LKCommonsTracker
import AppReciableSDK
import RustPB
import LarkContainer
import LarkSendMessage
import LarkPreload

//进入会话相关耗时统计
public final class ChatLoadTrakInfo {
    public var chatInfo: ChatKeyPointTrackerInfo?
    public var enterBackground: Bool = false
    public let fromWhere: ChatFromWhere
    public let extraInfo: [String: Any]

    //https://bytedance.feishu.cn/docs/doccnqILybP0jHLlFcQ7GGVOAnd#
    // 开始时间,初始化时默认赋值
    private let start = CACurrentMediaTime()
    //页面init构造函数耗时
    public var chatVCInitCost: Int64 = 0
    //Chat中各Module执行onLoad耗时
    public var loadModuleCost: Int64 = 0
    //路由中预加载延迟回调耗时
    public var preLoadDataBufferCost: Int64 = 0
    //首屏接口相关信息
    public var getChatMessagesTrakInfo: GetChatMessagesTrackInfo?
    //页面首屏消息数据处理开始时间点
    public var renderStart: CFTimeInterval?
    //页面中间态或正式视图构造完成时间点
    public var initViewEndTime: CFTimeInterval?
    //页面vm数据处理完成发射首屏渲染信号时间点
    public var pulishToMainThreadStart: CFTimeInterval?
    //页面收到首屏渲染信号时间点
    public var swithToMainThreadEnd: CFTimeInterval?
    //页面cellvm转换耗时
    public var transCellVMCost: Int64 = 0
    //是否显示了中间态
    public var showInstentView: Bool = false
    //获取chat模型接口耗时
    public var fetchChatCost: Int64 = 0
    //获取chat.chatter模型接口耗时
    public var fetchChatterCost: Int64 = 0
    //页面相关组件构造耗时
    public var generateComponentsCost: Int64 = 0
    //页面视图构造前逻辑耗时
    public var beforeGenerateNormalViewsCost: Int64 = 0
    //页面相关视图构造耗时
    public var generateNormalViewsCost: Int64 = 0
    //页面视图构造后逻辑耗时
    public var afterGenerateNormalViewsCost: Int64 = 0
    //如果进入会话是指定消息，首屏数据中是否包含目标消息
    public var hitTargetMessage: Bool = false
    //整个流程的最后一步，页面收到首屏消息刷新信号并处理完成时间点
    public var renderEnd: CFTimeInterval?
    //首屏消息cellForRow开始执行时间点
    public var tableRenderStart: CFTimeInterval?
    //首屏消息cellForRow执行完成时间点
    public var tableRenderEnd: CFTimeInterval?
    //页面首屏消息数据处理开始，到收到首屏消息刷新信号并处理完成
    private(set) lazy var renderDuration: Int64 = {
        guard let renderStart = self.renderStart, let renderEnd = self.renderEnd else {
            return 0
        }
        return Int64((renderEnd - renderStart) * 1000)
    }()
    //页面vm数据处理完成发射信号，到页面收到信号耗时
    private lazy var swithToMainThreadCost: Int64 = {
        guard let start = self.pulishToMainThreadStart, let end = self.swithToMainThreadEnd else {
            return 0
        }
        return Int64((end - start) * 1000)
    }()
    //首字耗时，中间态视图或正式视图展示耗时
    private(set) lazy var firstRender: Int64 = {
        if let initViewEndTime = self.initViewEndTime {
            return Int64((initViewEndTime - start) * 1000)
        }
        return 0
    }()
    //首屏消息tableView cellForRow耗时
    private lazy var cellForRowCost: Int64 = {
        if let renderEnd = self.tableRenderStart, let tableRenderEnd = self.tableRenderEnd {
            return Int64((tableRenderEnd - renderEnd) * 1000)
        }
        return 0
    }()

    //总耗时
    private(set) lazy var duration: Int64 = {
        guard let renderEnd = self.renderEnd else { return 0 }
        return Int64((renderEnd - start) * 1000)
    }()

    public lazy var metric: [String: String] = {
        guard self.duration != 0 else { return [:] }
        return [
            "preLoadDataBufferCost": "\(self.preLoadDataBufferCost)",
            "chatVCInitCost": "\(self.chatVCInitCost)",
            "loadModuleCost": "\(self.loadModuleCost)",
            "fetchChatCost": "\(self.fetchChatCost)",
            "fetchChatterCost": "\(self.fetchChatterCost)",
            "sdk_cost": "\(self.getChatMessagesTrakInfo?.sdkCost ?? 0)",
            "client_data_cost": "\(self.getChatMessagesTrakInfo?.parseCost ?? 0)",
            "showInstentView": "\(self.showInstentView)",
            "generateComponentsCost": "\(self.generateComponentsCost)",
            "beforeGenerateNormalViewsCost": "\(self.beforeGenerateNormalViewsCost)",
            "generateNormalViewsCost": "\(self.generateNormalViewsCost)",
            "afterGenerateNormalViewsCost": "\(self.afterGenerateNormalViewsCost)",
            "first_render": "\(self.firstRender)",
            "transCellVMCost": "\(self.transCellVMCost)",
            "main_thread_switch_cost": "\(self.swithToMainThreadCost)",
            "client_render_cost": "\(self.renderDuration)",
            "latency": "\(duration - max(self.preLoadDataBufferCost, self.fetchChatCost + self.fetchChatterCost))",
            "newLatency": "\(self.duration)",
            "cellForRowCost": "\(self.cellForRowCost)"
        ]
    }()

    public init(fromWhere: ChatFromWhere, extraInfo: [String: Any]) {
        self.fromWhere = fromWhere
        self.extraInfo = extraInfo
    }

    public lazy var reciableExtraMetric: [String: Any] = {
        guard let chat = chatInfo?.chat else { return ["feed_id": self.extraInfo["feedId"] ?? ""] }
        return ["chatter_count": chat.userCount,
                "feed_id": self.extraInfo["feedId"] ?? "", "net_costs": self.getChatMessagesTrakInfo?.netCosts ?? []]
    }()

    public lazy var reciableExtraCategory: [String: Any] = {
        guard let chatInfo = chatInfo, let chat = chatInfo.chat else {
            return ["source_type": fromWhere.sourceTypeForReciableTrace,
                    "is_background": self.enterBackground]
        }
        return ["source_type": fromWhere.sourceTypeForReciableTrace,
                "chat_type": chatInfo.chatTypeForReciableTrace,
                "is_background": self.enterBackground,
                "is_external": chat.isCrossTenant,
                "is_metting": chat.isMeeting]

    }()
}

public protocol KeyboardSendMessageKeyPointTrackerService: AnyObject {

    func generateIndentify() -> String

    func startImageProcess(indentify: String, imageFrom: ImageFrom)

    func startThumbImageProcess(indentify: String)

    func endThumbImageProcess(indentify: String)

    func startImageRequest(indentify: String)

    func endImageRequest(indentify: String)

    func startOriginImageProcess(indentify: String)

    func endOriginImageProcess(indentify: String)

    func endImageProcess(indentify: String)
}

/// 会话页面相关关键业务打点
/// 打点文档：https://bytedance.feishu.cn/space/doc/doccnlXJv4xV4mTJSAFu4VjMqVb#
public final class ChatKeyPointTracker: UserResolverWrapper, KeyboardSendMessageKeyPointTrackerService {
    public let userResolver: UserResolver
    //Chat相关信息记录
    public var chatInfo: ChatKeyPointTrackerInfo
    //获取ntp time
    @ScopedInjectedLazy var ntpAPI: NTPAPI?
    //获取当前用户id
    @ScopedInjectedLazy var passportUserService: PassportUserService?
    //消息发送相关信息记录
    @ScopedInjectedLazy private var sendRecorder: SendMessageKeyPointRecorderProtocol?
    // 标记共选择了几个图片、视频
    public static let selectAssetsCount = "multiNumber"
    // 选择图片、视频的来源
    public static let chooseAssetSource = "ChooseAssetSource"

    public enum ChooseAssetSource: String {
        case album
        case camera
        case other
    }

    //发消息
    private let sendServiceKey = "send_message_time"

    //点击电梯跳转 click_message_elevator_time
    private let unReadTipJumpServiceKey = "chat_read_all_unread_messages_time"
    private let unReadTipJumpLogId = "eesa_chat_read_all_unread_messages_cost"

    /// load more loading耗时
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#2FgzyU
    private let loadMoreMessageTimeService = "load_more_message_time"
    private let loadMoreMessageTimeLogID = "eesa_load_more_message_time"

    //会话内跳转
    private let jumpInChatServiceKey = "jump_in_chat_time"
    private let jumpInChatLogId = "jump_in_chat_time"

    //图片发送流程中图片处理相关打点
    private let imageProcessRecord: SendImageProcessKeyPointTracker
    private let sendImageProcess = "send_image_process"

    //首屏加载相关
    private let chatLoadTimeKey = "chat_load_time"
    //push进会话相关数据
//    private let pushMessageLoadTimeKey = "view_push_message_times"
    /// 点击push进会话耗时打点，3.28上。之前key错了
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#BExakK
    private let pushMessageLoadTimeKeyV2 = "view_push_message_time"
    //建群进会话相关数据
    private let createGroupLoadTimeKey = "create_group_time"

    private lazy var chatLoadTimeTrackIndentify: String = {
        let indentify = self.generateIndentify()
        return "\(self.chatInfo.id)" + indentify
    }()

    //首屏加载相关打点信息
    public var loadTrackInfo: ChatLoadTrakInfo?

    public init(resolver: UserResolver, chatInfo: ChatKeyPointTrackerInfo) {
        self.chatInfo = chatInfo
        self.imageProcessRecord = SendImageProcessKeyPointTracker()
        self.userResolver = resolver
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
        self.loadTrackInfo?.enterBackground = true
    }

    //indentify生成
    public func generateIndentify() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "_")
    }

    // MARK: - 收消息
    /// 新增接收消息埋点，PRD：https://bytedance.feishu.cn/docx/doxcnupKpu2CdBem3rdDObzI8nh
    private lazy var messageReceiveMonitor: Bool = {
        return self.userResolver.fg.staticFeatureGatingValue(with: "lark.client.chat.message_receive_monitor")
    }()
    private var currentGroupMessageReceiveCount: Int = 0
    public func receiveNewMessage(message: Message, pageName: String) {
        // 排除超大群、自己发的消息
        guard self.messageReceiveMonitor, let chat = chatInfo.chat, !chat.isSuper,
              !message.isMeSend(userId: passportUserService?.user.userID ?? ""), let ntpServiceTime = ntpAPI?.getNTPTime() else { return }
        // 群聊每50条上报一条
        if chat.type == .group, self.currentGroupMessageReceiveCount < 50 {
            self.currentGroupMessageReceiveCount += 1
            return
        }
        self.currentGroupMessageReceiveCount = 0

        // 上报可感知埋点
        let extraCategory: [String: Any] = [
            "message_type": message.type.rawValue,
            "chat_type": chat.type == .p2P ? 1 : 2,
            "is_external": chat.isCrossTenant,
            "is_metting": chat.isMeeting,
            "is_bot": chat.isSingleBot
        ]
        let extraMetric: [String: Any] = [
            "chatter_count": chat.chatterCount,
            "message_id": message.id,
            "create_time": message.createTimeMs,
            "update_time": message.updateTime * 1000,
            "receive_time": ntpServiceTime
        ]
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger,
            scene: .Chat,
            event: .receiveMessage,
            cost: Int(ntpServiceTime - message.createTimeMs),
            page: pageName,
            extra: Extra(isNeedNet: true, metric: extraMetric, category: extraCategory)
        ))
    }

    // MARK: - 发消息
    public func messageOnScreen(cid: String, messageid: String, page: String, renderCost: TimeInterval) {
        _ = sendRecorder?.messageOnScreen(cid: cid, messageid: messageid, page: page, renderCost: renderCost)
    }

    public func sendMessageFinish(cid: String,
                                  messageId: String,
                                  success: Bool,
                                  page: String,
                                  isCheckExitChat: Bool,
                                  renderCost: TimeInterval? = 0) {
        guard let sendInfo = sendRecorder?.sendMessageFinish(cid: cid,
                                                            messageId: messageId,
                                                            success: success,
                                                            page: page,
                                                            isCheckExitChat: isCheckExitChat,
                                                            renderCost: renderCost) else {
            return
        }
        self.log(sendInfo: sendInfo)
    }

    public func beforePublishOnScreenSignal(cid: String, messageId: String) {
        sendRecorder?.beforePublishOnScreenSignal(cid: cid, messageId: messageId)
    }

    public func afterPublishOnScreenSignal(cid: String, messageId: String) {
        sendRecorder?.afterPublishOnScreenSignal(cid: cid, messageId: messageId)
    }

    public func beforePublishFinishSignal(cid: String, messageId: String) {
        sendRecorder?.beforePublishFinishSignal(cid: cid, messageId: messageId)
    }

    public func afterPublishFinishSignal(cid: String, messageId: String) {
        sendRecorder?.afterPublishFinishSignal(cid: cid, messageId: messageId)
    }

    //离开页面，把目前发送中没Finish的点上报
    public func leaveChat() {
        sendRecorder?.leaveChat { (info) in
            self.log(sendInfo: info)
        }
    }

    // MARK: - 点击电梯跳转
    public enum JumpScene: String {
        case unReadTipToBottom
        case unReadTipToTopUnreadMessage
        case unReadTipToBottomUnreadMessage
        case unReadTipToPosition
        case routerLocate
        case keyboardShow
    }

    public struct CostTrackInfo {
        let bySDK: Bool
        let clientCost: Int64
        let sdkCost: Int64
        public init(bySDK: Bool, clientCost: Int64 = 0, sdkCost: Int64 = 0) {
            self.bySDK = bySDK
            self.clientCost = clientCost
            self.sdkCost = sdkCost
        }
    }

    public func unReadTipStartJump(indentify: String) {
        ClientPerf.shared.startSlardarEvent(service: unReadTipJumpServiceKey, indentify: indentify)
        ClientPerf.shared.startEvent(unReadTipJumpServiceKey, logid: unReadTipJumpLogId)
    }

    public func unReadTipFinishJump(indentify: String, scene: ChatKeyPointTracker.JumpScene, trackInfo: ChatKeyPointTracker.CostTrackInfo?) {
        guard let trackInfo = trackInfo, trackInfo.bySDK else { return }
        var params = chatInfo.log
        params["scene"] = scene.rawValue
        self.insert(costTrackInfo: trackInfo, params: &params)
        ClientPerf.shared.endSlardarEvent(service: unReadTipJumpServiceKey, indentify: indentify, params: params)
        ClientPerf.shared.endEvent(unReadTipJumpServiceKey, logid: unReadTipJumpLogId, params: params)
    }

    // MARK: - 会话内跳转
    public func inChatStartJump(indentify: String) {
        ClientPerf.shared.startSlardarEvent(service: jumpInChatServiceKey, indentify: indentify)
        ClientPerf.shared.startEvent(jumpInChatServiceKey, logid: jumpInChatLogId)
    }

    public func inChatFinishJump(indentify: String, scene: ChatKeyPointTracker.JumpScene, trackInfo: ChatKeyPointTracker.CostTrackInfo?) {
        guard let trackInfo = trackInfo, trackInfo.bySDK else { return }
        var params = chatInfo.log
        params["scene"] = scene.rawValue
        self.insert(costTrackInfo: trackInfo, params: &params)
        ClientPerf.shared.endSlardarEvent(service: jumpInChatServiceKey, indentify: indentify, params: params)
        ClientPerf.shared.endEvent(jumpInChatServiceKey, logid: jumpInChatLogId, params: params)
    }

    // MARK: - load more message time
    /// LoadMoreType
    public enum LoadMoreType: String {
        case older
        case newer
    }

    private var loadOlderStartTime: CFTimeInterval?
    private var loadNewerStartTime: CFTimeInterval?
    public func startLoadMoreMessageTime(loadType: LoadMoreType) {
        switch loadType {
        case .newer:
            if loadNewerStartTime == nil {
                loadNewerStartTime = CACurrentMediaTime()
            }
        case .older:
            if loadOlderStartTime == nil {
                loadOlderStartTime = CACurrentMediaTime()
            }
        }
    }

    public func endLoadMoreMessageTime(loadType: LoadMoreType) {
        let endTime = CACurrentMediaTime()
        var latency: CFTimeInterval = 0
        switch loadType {
        case .newer:
            if let startTime = loadNewerStartTime {
                latency = endTime - startTime
            }
            loadNewerStartTime = nil
        case .older:
            if let startTime = loadOlderStartTime {
                latency = endTime - startTime
            }
            loadOlderStartTime = nil
        }
        if latency <= 0 {
            return
        }
        ClientPerf.shared.singleSlardarEvent(
            service: loadMoreMessageTimeService,
            cost: latency * 1000,
            logid: loadMoreMessageTimeLogID,
            params: chatInfo.log,
            category: ["load_type": loadType.rawValue]
        )
    }

    // MARK: - 图片发送
    public func startImageProcess(indentify: String, imageFrom: ImageFrom) {
        self.imageProcessRecord.startImageProcess(indentify: indentify, imageFrom: imageFrom)
        ClientPerf.shared.startSlardarEvent(service: sendImageProcess, indentify: indentify)
    }

    public func startThumbImageProcess(indentify: String) {
        self.imageProcessRecord.startThumbImageProcess(indentify: indentify)
    }

    public func endThumbImageProcess(indentify: String) {
        self.imageProcessRecord.endThumbImageProcess(indentify: indentify)
    }

    public func startImageRequest(indentify: String) {
        self.imageProcessRecord.startImageRequest(indentify: indentify)
    }

    public func endImageRequest(indentify: String) {
        self.imageProcessRecord.endImageRequest(indentify: indentify)
    }

    public func startOriginImageProcess(indentify: String) {
        self.imageProcessRecord.startOriginImageProcess(indentify: indentify)
    }

    public func endOriginImageProcess(indentify: String) {
        self.imageProcessRecord.endOriginImageProcess(indentify: indentify)
    }

    public func endImageProcess(indentify: String) {
        guard let info = imageProcessRecord.endImageProcess(indentify: indentify) else {
            return
        }
        ClientPerf.shared.endSlardarEvent(
            service: sendImageProcess,
            indentify: info.indentify,
            metric: info.metricLog,
            params: nil,
            category: info.category)
    }

    // MARK: - 首屏相关
    public func trackChatLoadTimeStart(trackInfo: ChatLoadTrakInfo?, pageName: String) {
        guard let trackInfo = trackInfo else { return }
        self.loadTrackInfo = trackInfo
        self.loadTrackInfo?.chatInfo = self.chatInfo
        #if DEBUG
        return
        #endif
        let chatLoadTimeKey = self.chatLoadTimeKey
        let pushMessageLoadTimeKey = self.pushMessageLoadTimeKeyV2
        let createGroupLoadTimeKey = self.createGroupLoadTimeKey
        let chatInfo = self.chatInfo
        let fromWhere = trackInfo.fromWhere
        let extraInfo = trackInfo.extraInfo
        //监听正在进会话
        CoreSceneMointor.chatIsEnterIng = true
        TimeMonitorHelper.shared.startTrack(
            task: chatLoadTimeTrackIndentify,
            bind: nil,
            callback: { _ in
                //监听进会话完成
                CoreSceneMointor.chatIsEnterIng = false
                guard fromWhere != .ignored,
                    fromWhere != .singleChatGroup,
                    !trackInfo.metric.isEmpty else {
                        return
                }
                let chatLog = chatInfo.log
                if fromWhere == .push {
                    ClientPerf.shared.singleSlardarEvent(
                        service: pushMessageLoadTimeKey,
                        cost: CFTimeInterval(trackInfo.duration),
                        logid: "eesa_\(pushMessageLoadTimeKey)",
                        metric: nil,
                        params: chatLog,
                        category: ["locate_target_message_status": trackInfo.hitTargetMessage ? 1 : 0]
                    )
                }
                if let createGroupToChatInfo = extraInfo[CreateGroupToChatInfo.key] as? CreateGroupToChatInfo {
                    var extra = chatLog
                    extra["way"] = createGroupToChatInfo.way.rawValue
                    extra["sync_message"] = createGroupToChatInfo.syncMessage ? "y" : "n"
                    extra["message_count"] = "\(createGroupToChatInfo.messageCount)"
                    extra["count"] = "\(createGroupToChatInfo.memberCount)"
                    let event = SlardarEvent(name: createGroupLoadTimeKey,
                                             metric: ["time": trackInfo.duration + createGroupToChatInfo.cost],
                                             category: [:],
                                             extra: extra)
                    Tracker.post(event)
                }
                var metric = trackInfo.metric
                metric["source_type"] = "\(fromWhere.rawValue)"
                Tracker.post(SlardarEvent(
                    name: chatLoadTimeKey,
                    metric: metric,
                    category: [:],
                    extra: chatLog)
                )
                let latencyDetail: [String: Any] = ["sdk_cost": trackInfo.getChatMessagesTrakInfo?.sdkCost ?? 0,
                                                    "client_data_cost": trackInfo.getChatMessagesTrakInfo?.parseCost ?? 0,
                                                    "client_render_cost": trackInfo.renderDuration,
                                                    "first_render": trackInfo.firstRender]
                AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                      scene: .Chat,
                                                                      event: .enterChat,
                                                                      cost: Int(trackInfo.duration),
                                                                      page: pageName,
                                                                      extra: Extra(isNeedNet: false,
                                                                                   latencyDetail: latencyDetail,
                                                                                   metric: trackInfo.reciableExtraMetric,
                                                                                   category: trackInfo.reciableExtraCategory)))
            }
        )
    }

    public func trackChatLoadTimeEnd() {
        #if !DEBUG
        TimeMonitorHelper.shared.endTrack(task: chatLoadTimeTrackIndentify, bind: nil, params: [:])
        #endif
    }

    // MARK: - 工具类
    public static func cost(startTime: CFTimeInterval) -> Int64 {
        return Int64((CACurrentMediaTime() - startTime) * 1000)
    }

    private func insert(costTrackInfo: ChatKeyPointTracker.CostTrackInfo, params: inout [String: String]) {
        params["bySDK"] = costTrackInfo.bySDK ? "true" : "false"
        guard costTrackInfo.bySDK else { return }

        params["clientCost"] = "\(costTrackInfo.clientCost)"
        params["sdkCost"] = "\(costTrackInfo.sdkCost)"
    }

    /// 往Slardar打点
    private func log(sendInfo: SendMessageTrackerInfo) {
        var params = chatInfo.log
        sendInfo.extraLog.forEach({ params[$0.0] = $0.1 })
        ClientPerf.shared.endSlardarEvent(
            service: sendServiceKey,
            indentify: sendInfo.indentify,
            metric: sendInfo.metricLog,
            params: params,
            category: sendInfo.category)
    }
}
