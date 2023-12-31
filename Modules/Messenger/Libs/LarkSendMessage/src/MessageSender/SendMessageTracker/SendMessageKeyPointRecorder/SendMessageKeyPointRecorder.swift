//
//  SendMessageKeyPointRecorder.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/11/20.
//

import UIKit
import Foundation
import LarkModel // Message
import ThreadSafeDataStructure // SafeDictionary
import LarkContainer // InjectedLazy
import AppReciableSDK // AppReciableSDK
import LarkSDKInterface // APIError
import RustPB // Basic_V1_Trace
import LKCommonsTracker // Tracker
import Homeric // PERF_SEND_MSG_DEV
import LarkTracing // LarkTracingUtil
import LarkMonitor // BDPowerLogManager
import LKCommonsLogging // Logger
import LarkRichTextCore // summerize

// 发消息流程状态机错误类型
public enum SendMessageFlowStateError {
    // 创建假消息失败
    case createQuasiError(_ error: Error? = nil)
    // 发送消息接口失败
    case sendMessageError(_ error: Error? = nil)
    // 其他错误
    case otherError(_ error: Error? = nil)

    public func getSwiftError() -> Error? {
        switch self {
        case .createQuasiError(let error):
            return error
        case .sendMessageError(let error):
            return error
        case .otherError(let error):
            return error
        }
    }
}

// 发消息流程状态机
// 抽象通用的阶段, 业务方理论上不应该在此新加阶段
public enum SendMessageFlowState {
    // 创建假消息之前
    case beforeCreateQuasi(_ info: SendMessageTrackerInfo)
    // 消息上屏成功(端上创建假消息完成)
    case messageOnScreen(_ info: SendMessageTrackerInfo)
    // 创建假消息完成(SDK创建成功)
    case createQuasiSuccess(_ info: SendMessageTrackerInfo)
    // 发消息成功
    case sendMessageSuccess(_ info: SendMessageTrackerInfo)
    case error(_ info: SendMessageTrackerInfo, error: SendMessageFlowStateError)
}

// 发消息状态机监听者
open class SendMessageStateListener {
    public func stateChange(_ state: SendMessageFlowState) {
        assertionFailure("must be override")
    }
}

// weak持有SendMessageStateListener, 不影响其生命周期
public final class SendMessageStateListenerWrapper {
    public weak var listener: SendMessageStateListener?
    public init() {}
}

/// 记录多个消息发送相关信息
final class SendMessageKeyPointRecorder: SendMessageKeyPointRecorderProtocol, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(SendMessageKeyPointRecorder.self, category: "SendMessageKeyPointRecorder")
    // 发消息状态监听者，使用场景：发消息埋点进行到某些阶段时，对信息进行修改/新增/删除
    private var stateListeners: [SendMessageStateListenerWrapper] = []

    //key: cid
    private(set) var sendTrackInfoMap: SafeDictionary<String, SendMessageTrackerInfo> = [:] + .readWriteLock
    private var enterBackGroundStamp: TimeInterval?
    private let lock = NSLock()

    init(userResolver: UserResolver, stateListeners: [SendMessageStateListener]) {
        self.userResolver = userResolver
        stateListeners.forEach { stateListener in
            let wrapper = SendMessageStateListenerWrapper()
            wrapper.listener = stateListener
            self.stateListeners.append(wrapper)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func didEnterBackground() {
        self.enterBackGroundStamp = CACurrentMediaTime()
    }

    func registerStateListener(_ stateListener: SendMessageStateListener) {
        defer { lock.unlock() }
        lock.lock()
        let wrapper = SendMessageStateListenerWrapper()
        wrapper.listener = stateListener
        stateListeners.append(wrapper)
    }

    //开始发送消息，此时还没有cid,contextid这类唯一标示，需要传入一个indentify作为唯一标示,记录开始时间
    func startSendMessage(indentify: String,
                          chatInfo: ChatKeyPointTrackerInfo,
                          params: [String: Any]? = nil) {
        let info = SendMessageTrackerInfo(indentify: indentify)
        info.pointCost[.start] = CACurrentMediaTime()
        info.multiNumber = (params?["multiNumber"] as? Int) ?? 1
        info.chooseAssetSource = (params?["ChooseAssetSource"] as? String) ?? "unknown"
        info.chatInfo = chatInfo
        sendTrackInfoMap[indentify] = info
        // 执行注入的监听事件
        self.stateListeners.forEach { wrapper in
            wrapper.listener?.stateChange(.beforeCreateQuasi(info))
        }
        LarkTracingUtil.sendMessageStartRootSpan(spanName: LarkTracingUtil.sendMessage, cid: indentify)
        LarkTracingUtil.sendMessageStartChildSpanByPName(spanName: LarkTracingUtil.messageOnScreen, parentName: LarkTracingUtil.sendMessage, cid: indentify)
    }

    func startCallQuasiMessageAPI(indentify: String, processCost: TimeInterval?) {
        guard let info = sendTrackInfoMap[indentify] else {
            return
        }
        LarkTracingUtil.sendMessageStartChildSpanByPName(spanName: LarkTracingUtil.createQuasiMessage, parentName: LarkTracingUtil.sendMessage, cid: indentify)
        info.pointCost[.callQuasiMessageAPI] = CACurrentMediaTime()
        if let processCost = processCost {
            info.pointCost[.procssForQuasiMessage] = processCost
        }
    }

    //调用sdk后，得到cid,contextid等信息，此后以cid为key记录后续信息, extalInfo context携带的透传信息
    func finishCallQuasiMessageAPI(indentify: String,
                                   contextId: String,
                                   message: Message,
                                   extralInfo: [String: Any] = [:]) {
        guard let info = sendTrackInfoMap[indentify], let start = info.pointCost[.callQuasiMessageAPI] else {
            return
        }
        // 执行注入的监听事件
        self.stateListeners.forEach { wrapper in
            wrapper.listener?.stateChange(.createQuasiSuccess(info))
        }
        info.contextIds[.callQuasiMessageAPI] = contextId
        info.messageType = message.type
        info.cid = message.cid
        info.pointCost[.callQuasiMessageAPI] = CACurrentMediaTime() - start
        if let result = self.parseMessageContentLength(message: message) {
            switch result {
            case .text(let length):
                info.textContentLength = length
            case .resource(let length):
                info.resourceLength = length
            }
        }
        if message.type == .media {
            info.powerLogSession = BDPowerLogManager.beginSession("scene_video_send")
        } else if message.type == .image {
            info.powerLogSession = BDPowerLogManager.beginSession("scene_image_send")
        }
        sendTrackInfoMap[message.cid] = info
        sendTrackInfoMap.removeValue(forKey: indentify)
        LarkTracingUtil.sendMessageReplaceSpanNameWithCid(ondCid: indentify, newCid: message.cid)
    }

    //端上创建上屏消息的情况下，需要在rust创建完消息之后更新一下消息创建的时间。
    func finishCallQuasiMessageAPI(cid: String, rustCreateCost: TimeInterval?, message: Message) {
        guard let info = sendTrackInfoMap[cid], let rustCreateCost = rustCreateCost else {
            return
        }
        if let result = self.parseMessageContentLength(message: message) {
            switch result {
            case .text(let length):
                info.textContentLength = length
            case .resource(let length):
                info.resourceLength = length
            }
        }
        info.pointCost[.callQuasiMessageAPI] = rustCreateCost
    }

    public func cacheExtraInfo(cid: String,
                               extralInfo: [String: Any] = [:]) {
        guard let info = sendTrackInfoMap[cid] else {
            return
        }
        if extralInfo.isEmpty == false {
            for element in extralInfo {
                info.extralInfo[element.key] = element.value
            }
        }
    }

    func saveTrackVideoInfo(cid: String, info: VideoTrackInfo) {
        sendTrackInfoMap[cid]?.videoTrackInfo = info
    }

    func saveTrackVideoError(indentify: String, cid: String?, code: Int, errorMsg: String) {
        guard let info = sendTrackInfoMap[cid ?? indentify] else {
            return
        }
        info.videoTranscodeErrorCode = code
        info.videoTranscodeErrorMsg = errorMsg
    }

    func finishWithError(indentify: String, cid: String? = nil, error: SendMessageFlowStateError, page: String) {
        guard let info = sendTrackInfoMap[cid ?? indentify] else {
            return
        }
        // 执行注入的监听事件
        self.stateListeners.forEach { wrapper in
            wrapper.listener?.stateChange(.error(info, error: error))
        }
        LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.sendMessage, cid: indentify, tags: info.metricLog, error: true)
        let apiError = error.getSwiftError()?.underlyingError as? APIError
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Chat,
                                                        event: .messageSend,
                                                        errorType: apiError == nil ? .Unknown : .SDK,
                                                        errorLevel: .Fatal,
                                                        errorCode: Int(apiError?.code ?? -1),
                                                        errorStatus: Int(apiError?.status ?? 0),
                                                        userAction: nil,
                                                        page: page,
                                                        errorMessage: apiError?.debugMessage,
                                                        extra: Extra(isNeedNet: true,
                                                                     latencyDetail: nil,
                                                                     metric: self.reciableExtraMetric(info: info, id: cid ?? ""),
                                                                     category: self.reciableExtraCategory(info: info))))

        // 视频专项，视频埋点
        if info.messageType == .media {
            self.sendVideoInfo(info: info, success: false, error: error.getSwiftError(), finishTime: CACurrentMediaTime())
        }
        // 多媒体性能埋点
        if [.media, .image].contains(info.messageType), var session = info.powerLogSession {
            session.addCustomFilter(["success": 0,
                                     "multiNumber": info.multiNumber,
                                     "resourceLength": info.resourceLength,
                                     "chooseAssetSource": info.chooseAssetSource,
                                     "isExitChat": info.isExitChat])
            BDPowerLogManager.end(session)
        }

        sendTrackInfoMap.removeValue(forKey: indentify)
    }

    func startCallSendMessageAPI(cid: String, processCost: TimeInterval?, extralInfo: [String: Any] = [:]) {
        guard let info = sendTrackInfoMap[cid] else {
            return
        }
        LarkTracingUtil.sendMessageStartChildSpanByPName(spanName: LarkTracingUtil.callSendMessageAPI, parentName: LarkTracingUtil.sendMessage, cid: cid)
        info.pointCost[.callSendMessageAPI] = CACurrentMediaTime()
        if let processCost = processCost {
            info.pointCost[.procssForSendMessage] = processCost
        }
        for element in extralInfo {
            info.extralInfo[element.key] = element.value
        }
        if info.resourceLength == 0, let resourceLength = info.extralInfo["resource_content_length"] as? Int64 {
            info.resourceLength = resourceLength
        }
    }

    /// 发送消息成功
    func finishSendMessageAPI(cid: String, contextId: String, netCost: UInt64, trace: Basic_V1_Trace?) {
        guard let info = sendTrackInfoMap[cid], let start = info.pointCost[.callSendMessageAPI] else {
            return
        }
        LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.callSendMessageAPI, cid: cid)
        info.pointCost[.callSendMessageAPI] = CACurrentMediaTime() - start
        info.pointCost[.callSendMessageAPINetCost] = TimeInterval(netCost)
        info.contextIds[.callSendMessageAPI] = contextId
        if let spans = trace?.spans, !spans.isEmpty {
            for var span in spans {
                info.traceSpans[span.name] = span.durationMillis
                var attributes = span.attributes
                attributes.forEach { (key: String, value: String) in
                    info.traceSpans[key] = value
                }

            }
        }
    }

    public func beforePublishOnScreenSignal(cid: String, messageId: String) {
        guard let info = sendTrackInfoMap[cid] else {
            return
        }
        info.pointCost[.publishOnScreenSignal] = CACurrentMediaTime()
    }

    public func afterPublishOnScreenSignal(cid: String, messageId: String) {
        guard let info = sendTrackInfoMap[cid], let start = info.pointCost[.publishOnScreenSignal] else {
            return
        }
        info.pointCost[.publishOnScreenSignal] = CACurrentMediaTime() - start
    }

    public func beforePublishFinishSignal(cid: String, messageId: String) {
        guard let info = sendTrackInfoMap[cid] else {
            return
        }
        info.pointCost[.publishFinishSignal] = CACurrentMediaTime()
    }

    public func afterPublishFinishSignal(cid: String, messageId: String) {
        guard let info = sendTrackInfoMap[cid], let start = info.pointCost[.publishFinishSignal] else {
            return
        }
        info.pointCost[.publishFinishSignal] = CACurrentMediaTime() - start
    }

    func messageOnScreen(cid: String, messageid: String, page: String, renderCost: TimeInterval?) -> SendMessageTrackerInfo? {
        guard let info = sendTrackInfoMap[cid], let start = info.pointCost[.start] else {
            return nil
        }
        // 执行注入的监听事件
        self.stateListeners.forEach { wrapper in
            wrapper.listener?.stateChange(.messageOnScreen(info))
        }
        LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.messageOnScreen, cid: cid)
        // 假消息发送成功后的contextID
        let contextID = info.contextIds[.callQuasiMessageAPI] ?? ""
        let cost = CACurrentMediaTime() - start
        info.pointCost[.messageOnScreen] = cost
        let latencyDetail: [String: Any] = ["sdk_create_msg_cost": (info.pointCost[.callQuasiMessageAPI] ?? 0) * 1000,
                                            "ios_compress_cost": (info.pointCost[.procssForQuasiMessage] ?? 0) * 1000,
                                            "publish_onscreen_signal_cost": (info.pointCost[.publishOnScreenSignal] ?? 0) * 1000,
                                            "onscreen_render_cost": (renderCost ?? 0) * 1000]
        let extraMetric = self.reciableExtraMetric(info: info, id: messageid)
        let category = self.reciableExtraCategory(info: info)
        let extra = Extra(isNeedNet: false, latencyDetail: latencyDetail, metric: extraMetric, category: category, extra: ["context_id": contextID])
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Chat, event: .messageOnScreen, cost: Int(cost * 1000), page: page, extra: extra
        ))
        sendTrackInfoMap[cid] = info
        return info
    }

    public func messageSendShowLoading(cid: String) {
        guard let info = sendTrackInfoMap[cid] else {
            return
        }
        info.showLoading = true
    }

    func sendMessageFinish(cid: String,
                           messageId: String,
                           success: Bool,
                           page: String,
                           isCheckExitChat: Bool,
                           renderCost: TimeInterval? = 0) -> SendMessageTrackerInfo? {
        guard let info = sendTrackInfoMap[cid], let start = info.pointCost[.start] else {
            return nil
        }
        // 解决在Chat内重复上报的问题, 只有当离开chat时才上报
        if isCheckExitChat, info.isExitChat == false {
            return nil
        }
        sendTrackInfoMap.removeValue(forKey: cid)
        // 执行注入的监听事件
        self.stateListeners.forEach { wrapper in
            wrapper.listener?.stateChange(.sendMessageSuccess(info))
        }
        LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.sendMessage, cid: cid, tags: info.tracingTags)
        if success {
            // 提前标记结束时间
            let finishTime = CACurrentMediaTime()
            let cost = finishTime - start
            let latencyDetail: [String: Any] = ["sdk_create_msg_cost": (info.pointCost[.callQuasiMessageAPI] ?? 0) * 1000,
                                                "sdk_send_msg_cost": (info.pointCost[.callSendMessageAPI] ?? 0) * 1000,
                                                "net_cost": (info.pointCost[.callSendMessageAPINetCost] ?? 0),
                                                "compress_cost": (info.pointCost[.procssForSendMessage] ?? 0) * 1000, "publish_finish_signal_cost": (info.pointCost[.publishFinishSignal] ?? 0) * 1000,
                                                "success_render_cost": (renderCost ?? 0) * 1000]
            var extraMetric = self.reciableExtraMetric(info: info, id: cid)
            // 发送成功，需要带上视频转码埋点
            extraMetric.merge(self.reciableVideoMetric(info: info), uniquingKeysWith: { (first, _) in first })
            let category = self.reciableExtraCategory(info: info)
            // 消息发送成功后的contextID
            let contextID = info.contextIds[.callSendMessageAPI] ?? ""
            let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail, metric: extraMetric, category: category, extra: ["context_id": contextID])
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger, scene: .Chat, event: .messageSend, cost: Int(cost * 1000), page: page, extra: extra))
            info.pointCost[.success] = cost

            //弱网专项，往T平台埋点
            let preSendMsgInfo = self.preSendMsgInfo(info: info, cid: cid)
            Tracker.post(TeaEvent(Homeric.PERF_SEND_MSG_DEV,
                                  params: preSendMsgInfo))

            // 视频专项，视频埋点
            if info.messageType == .media {
                self.sendVideoInfo(info: info, success: true, error: nil, finishTime: finishTime)
            }
            // 多媒体性能埋点
            if [.media, .image].contains(info.messageType), var session = info.powerLogSession {
                session.addCustomFilter(["success": 1,
                                         "multiNumber": info.multiNumber,
                                         "resourceLength": info.resourceLength,
                                         "chooseAssetSource": info.chooseAssetSource,
                                         "isExitChat": info.isExitChat])
                BDPowerLogManager.end(session)
            }
        } else {
            info.pointCost[.fail] = CACurrentMediaTime() - start
        }
        return info
    }

    func leaveChat(callBack: (SendMessageTrackerInfo) -> Void) {
        sendTrackInfoMap.forEach { (arg) in
            if let start = arg.value.pointCost[.start] {
                let info = arg.value
                info.pointCost[.leave] = CACurrentMediaTime() - start
                info.isExitChat = true
                callBack(info)
            }
        }
    }

    private enum MessageContentLength {
        case text(Int)
        case resource(Int64)
    }

    private func parseMessageContentLength(message: Message) -> MessageContentLength? {
        switch message.type {
        case .text, .post:
            let richText = (message.content as? TextContent)?.richText ?? (message.content as? PostContent)?.richText
            return .text(richText?.lc.summerize().count ?? 0)
        case .file:
            return .resource((message.content as? FileContent)?.size ?? 0)
        case .folder:
            return .resource((message.content as? FolderContent)?.size ?? 0)
        case .audio:
            return .resource((message.content as? AudioContent)?.size ?? 0)
        case .media:
            return .resource((message.content as? MediaContent)?.size ?? 0)
        case .unknown, .email, .calendar, .shareCalendarEvent, .hongbao, .image,
             .generalCalendar, .videoChat, .commercializedHongbao, .shareUserCard,
             .system, .shareGroupChat, .mergeForward, .card, .location, .sticker, .todo,
             .diagnose, .vote:
            break
        @unknown default:
            break
        }
        return nil
    }

    /// 视频转码可感知埋点
    private func reciableVideoMetric(info: SendMessageTrackerInfo) -> [String: Any] {
        return ["media_type": info.videoTrackInfo?.origin.type ?? "",
                "media_duration": (info.videoTrackInfo?.duration ?? 0) * 1000,
                "media_rate": info.videoTrackInfo?.origin.rate ?? 0,
                "media_bitrate": (info.videoTrackInfo?.origin.bitrate ?? 0) / 1000,
                "media_width": info.videoTrackInfo?.origin.videoSize.width ?? 0,
                "media_height": info.videoTrackInfo?.origin.videoSize.height ?? 0,
                "media_compress_type": info.videoTrackInfo?.compressType ?? 0
        ]
    }

    private func reciableExtraMetric(info: SendMessageTrackerInfo, id: String) -> [String: Any] {
           return ["text_content_length": info.textContentLength,
                   "resource_content_length": info.resourceLength,
                   "chatter_count": info.chatInfo?.chat?.userCount ?? 0,
                   "message_id": id,
                   "resource_width": info.extralInfo["resource_width"] ?? 0,
                   "resource_height": info.extralInfo["resource_height"] ?? 0,
                   "resource_frames": info.extralInfo["resource_frames"] ?? 1,
                   "upload_content_length": info.extralInfo["upload_content_length"] ?? 0,
                   "upload_width": info.extralInfo["upload_width"] ?? 0,
                   "upload_height": info.extralInfo["upload_height"] ?? 0,
                   "image_process_cost": info.extralInfo["image_process_cost"] ?? 0,
                   "media_error_code": info.videoTranscodeErrorCode ?? 0,
                   "compress_algorithm": info.extralInfo["compress_algorithm"] ?? "",
                   "compress_ratio": info.extralInfo["compress_ratio"] ?? 0
           ]
    }

    private func reciableExtraCategory(info: SendMessageTrackerInfo) -> [String: Any] {
        let chatType: Int = info.chatInfo?.chatTypeForReciableTrace ?? 0
        if info.chatInfo == nil {
            assertionFailure("lose chatInfo")
        }
        var extra: [String: Any] = [
            "is_exit_chat": info.isExitChat ? "1" : "0",
            "message_type": info.messageType.rawValue,
            "chat_type": chatType,
            "is_in_background": info.enterBackGroud(self.enterBackGroundStamp),
            "is_metting": info.chatInfo?.chat?.isMeeting ?? false,
            "is_image_fallback_to_file": (info.extralInfo["is_image_fallback_to_file"] as? Bool ?? false).stringValue,
            // 视频是否被选了原图，图片是否被选了原图
            "media_is_origin_type": (info.videoTrackInfo?.isOriginal ?? (info.extralInfo["is_image_origin"] as? Bool ?? false)).stringValue,
            "color_space": info.extralInfo["color_space"] ?? "unkonwn",
            "image_type": info.extralInfo["image_type"] ?? "unkonwn",
            "is_preprocessed": info.extralInfo["is_preprocessed"] ?? false
        ]
        if [Message.TypeEnum.image, Message.TypeEnum.media].contains(info.messageType) {
            extra["resource_multiple_number"] = info.multiNumber
            extra["choose_image_source"] = info.chooseAssetSource
        }
        return extra
    }

    //发消息往T平台埋点信息，把往slardar上传的埋点数据拍平，加上sdk返回的trace数据。
    private func preSendMsgInfo(info: SendMessageTrackerInfo, cid: String) -> [AnyHashable: Any] {
        var traceSpans = info.traceSpans
        var preSendMsgInfo: [AnyHashable: Any] = [:]
        preSendMsgInfo["on_screen_cost"] = (info.pointCost[.messageOnScreen] ?? 0) * 1000
        preSendMsgInfo["total_cost"] = getMultiImageTotalCost(info: info, traceSpans: traceSpans)
        preSendMsgInfo["isNeedNet"] = true
        preSendMsgInfo["sdk_create_msg_cost"] = (info.pointCost[.callQuasiMessageAPI] ?? 0) * 1000
        preSendMsgInfo["sdk_send_msg_cost"] = (info.pointCost[.callSendMessageAPI] ?? 0) * 1000
        preSendMsgInfo["net_cost"] = (info.pointCost[.callSendMessageAPINetCost] ?? 0)
        preSendMsgInfo["compress_cost"] = (info.pointCost[.procssForSendMessage] ?? 0) * 1000
        preSendMsgInfo["context_id"] = info.contextIds[.callSendMessageAPI] ?? ""
        if [Message.TypeEnum.image, Message.TypeEnum.media].contains(info.messageType) {
            preSendMsgInfo["resource_multiple_number"] = info.multiNumber
        }

        preSendMsgInfo.merge(self.reciableExtraMetric(info: info, id: cid), uniquingKeysWith: { (first, _) in first })
        preSendMsgInfo.merge(self.reciableVideoMetric(info: info), uniquingKeysWith: { (first, _) in first })
        preSendMsgInfo.merge(self.reciableExtraCategory(info: info), uniquingKeysWith: { (first, _) in first })

        traceSpans.forEach { (key: String, value: Any) in
            preSendMsgInfo[key] = value
        }
        return preSendMsgInfo
    }

    private func getMultiImageTotalCost(info: SendMessageTrackerInfo, traceSpans: SafeDictionary<String, Any>) -> TimeInterval {
        // 发图需要减去排队等待时间
        let sendWaitTime = traceSpans["message_waiting_to_be_sent"] as? UInt64 ?? 0
        let uploadWaitTime = (traceSpans["content_prepare"] as? UInt64 ?? 0) - (traceSpans["content_prepare_minus_queue_waiting"] as? UInt64 ?? 0)
        if case .image = info.messageType, let totalCost = info.pointCost[.success] {
            return totalCost * 1000 - Double(sendWaitTime + uploadWaitTime)
        } else {
            return (info.pointCost[.success] ?? 0) * 1000
        }
    }
}

/// 专门用于视频的 tea 埋点
extension SendMessageKeyPointRecorder {

    func sendVideoInfo(info: SendMessageTrackerInfo, success: Bool, error: Error?, finishTime: CFTimeInterval = CACurrentMediaTime()) {
        var params: [String: Any] = [:]
        params = appendVideoInfo(info: info, params: params)
        params = appendSendVideoCost(info: info, params: params, finishTime: finishTime)
        params = appendSendVideoResult(
            info: info,
            params: params,
            success: success,
            error: error
        )
        params = appendPerformance(info: info, params: params)
        params = appendExtension(info: info, params: params)
        SendMessageKeyPointRecorder.logger.info("event send_video_info_dev parmas \(params)")
        Tracker.post(TeaEvent("send_video_info_dev",
                              params: params))
    }

    func appendVideoInfo(info: SendMessageTrackerInfo, params: [String: Any]) -> [String: Any] {
        var params = params
        if let videoTrackInfo = info.videoTrackInfo {
            params["origin_fps"] = videoTrackInfo.origin.rate
            params["origin_file_size"] = videoTrackInfo.origin.fileSize / 1024 / 1024
            params["origin_bitrate"] = videoTrackInfo.origin.bitrate / 1000
            params["origin_video_size"] = "\(Int(videoTrackInfo.origin.videoSize.width))x\(Int(videoTrackInfo.origin.videoSize.height))"

            params["result_fps"] = videoTrackInfo.result.rate
            params["result_file_size"] = videoTrackInfo.result.fileSize / 1024 / 1024
            params["result_bitrate"] = videoTrackInfo.result.bitrate / 1000
            params["result_video_size"] = "\(Int(videoTrackInfo.result.videoSize.width))x\(Int(videoTrackInfo.result.videoSize.height))"
            params["video_duration"] = videoTrackInfo.duration
            params["is_use_cache"] = videoTrackInfo.compressType == "reuse" ? 1 : 0
            params["is_original"] = videoTrackInfo.isOriginal ? 1 : 0
        }
        return params
    }

    func appendSendVideoCost(info: SendMessageTrackerInfo, params: [String: Any], finishTime: CFTimeInterval) -> [String: Any] {
        var params = params

        if let start = info.pointCost[.start] {
           if let videoTrackInfo = info.videoTrackInfo {
                let createTime = videoTrackInfo.createTime
                let startTime = videoTrackInfo.startTime
                if createTime != 0 {
                    params["pick_duration"] = (createTime - start) * 1000
                } else {
                    params["pick_duration"] = (info.pointCost[.procssForQuasiMessage] ?? 0) * 1000
                }

                if startTime != 0,
                   createTime != 0,
                   startTime >= createTime {
                    params["total_duration"] = (finishTime - start - (startTime - createTime)) * 1000
                } else {
                    params["total_duration"] = (finishTime - start) * 1000
                }
           } else {
               params["total_duration"] = (finishTime - start) * 1000
               params["pick_duration"] = (info.pointCost[.procssForQuasiMessage] ?? 0) * 1000
           }
        }

        if let videoTrackInfo = info.videoTrackInfo, videoTrackInfo.transcodeDuration != 0 {
            params["compress_duration"] = videoTrackInfo.transcodeDuration
        } else {
            params["compress_duration"] = (info.pointCost[.procssForSendMessage] ?? 0) * 1000
        }
        params["compress_upload_duration"] = (info.pointCost[.procssForSendMessage] ?? 0) * 1000
        // 对发视频来说，Rust的content_prepare span更接近上传耗时
        if let contentPrepare = info.traceSpans["content_prepare"] as? UInt64 {
            params["upload_duration"] = contentPrepare
        } else if info.pointCost[.callSendMessageAPINetCost] == nil {
            params["upload_duration"] = (finishTime - (info.pointCost[.callSendMessageAPI] ?? 0)) * 1000
        } else {
            params["upload_duration"] = (info.pointCost[.callSendMessageAPI] ?? 0) * 1000 - (info.pointCost[.callSendMessageAPINetCost] ?? 0)
        }
        // 记录SEND_MESSAGE的耗时
        params["sdk_send_msg_cost"] = (info.pointCost[.callSendMessageAPI] ?? 0) * 1000
        params["send_duration"] = (info.pointCost[.callSendMessageAPINetCost] ?? 0)
        if let videoTrackInfo = info.videoTrackInfo, videoTrackInfo.preDuration != 0 {
            params["pre_duration"] = videoTrackInfo.preDuration * 1000
        }
        return params
    }

    func appendSendVideoResult(info: SendMessageTrackerInfo, params: [String: Any], success: Bool, error: Error?) -> [String: Any] {
        var params = params
        if success {
            params["result"] = "success"
        } else {
            params["result"] = "failed"
            if let error = error?.underlyingError as? APIError {
                params["errorCode"] = error.errorCode
                params["errorMsg"] = "\(error.description)"
                params["errorType"] = "rust"
            } else if let error = error as? NSError {
                params["errorCode"] = error.code
                params["errorMsg"] = "\(error)"
                params["errorType"] = "native"
            } else if let videoTranscodeErrorCode = info.videoTranscodeErrorCode {
                params["errorCode"] = videoTranscodeErrorCode
                params["errorMsg"] = "videoTranscodeErrorCode \(videoTranscodeErrorCode) \(info.videoTranscodeErrorMsg)"
                params["errorType"] = "compress"
            } else {
                params["errorCode"] = -1
                if let error = error {
                    params["errorMsg"] = "\(error)"
                } else {
                    params["errorMsg"] = "unknown error"
                }
                params["errorType"] = "native"
            }
        }
        return params
    }

    func appendPerformance(info: SendMessageTrackerInfo, params: [String: Any]) -> [String: Any] {
        var params = params

        guard let videoTrackInfo = info.videoTrackInfo,
            let compressDuration = params["compress_duration"] as? TimeInterval,
            let uploadDuration = params["upload_duration"] as? TimeInterval,
            let originFileSize = params["origin_file_size"] as? TimeInterval,
            let resultFileSize = params["result_file_size"] as? TimeInterval,
            let resultBitrate = params["result_bitrate"] as? Int32,
            let originBitrate = params["origin_bitrate"] as? Int32 else {
                return params
        }

        if compressDuration > 0 {
            params["compress_speed"] = originFileSize * 1000 / compressDuration
        }

        if uploadDuration > 0 {
            params["upload_speed"] = resultFileSize * 1000 / uploadDuration
        }

        if resultFileSize > 0 {
            params["compress_ratio_file_size"] = originFileSize / resultFileSize
        }
        if resultBitrate > 0 {
            params["compress_ratio_bitrate"] = TimeInterval(originBitrate) / TimeInterval(resultBitrate)
        }
        return params
    }

    func appendExtension(info: SendMessageTrackerInfo, params: [String: Any]) -> [String: Any] {
        var params = params
        params["is_exit_chat"] = info.isExitChat ? "1" : "0"

        guard let videoTrackInfo = info.videoTrackInfo else {
            return params
        }
        params["decode_is_use_hw_264"] = 1
        params["decode_is_use_hw_265"] = 1
        params["encode_is_use_hw_264"] = 1
        params["compress_is_remux"] = videoTrackInfo.compressType == "muxer" ? 1 : 0
        params["compress_is_HDR"] = videoTrackInfo.isHDR ? 1 : 0
        params["video_source"] = videoTrackInfo.isPHAssetVideo ? "album" : "camera"
        params["origin_video_format"] = videoTrackInfo.origin.type
        params["origin_encode_format"] = videoTrackInfo.origin.encodeType
        params["result_encode_format"] = videoTrackInfo.result.encodeType
        params["unenabled_remux_code"] = videoTrackInfo.notRemuxErrorcode
        params["is_merge_pre_compress"] = videoTrackInfo.isMergePreCompress ? 1 : 0
        params["is_compress_upload"] = videoTrackInfo.isCompressUpload ? 1 : 0
        params["is_compress_upload_success"] = videoTrackInfo.isCompressUploadSuccess ? 1 : 0
        params["compress_upload_failed_msg"] = videoTrackInfo.compressUploadFailedMsg
        params["is_in_background"] = videoTrackInfo.isInBackground ? 1 : 0
        params["finish_is_in_background"] = videoTrackInfo.finishIsInBackground ? 1 : 0
        params["origin_last_modify_diff"] = videoTrackInfo.videoSendDate - videoTrackInfo.modificationDate
        params["compress_cover_file_size"] = videoTrackInfo.compressCoverFileSize
        params["use_weak_net_setting"] = videoTrackInfo.isWeakNetwork ? 1 : 0
        params["compile_scene"] = videoTrackInfo.compileScene
        params["compile_quality"] = videoTrackInfo.compileQuality
        params["send_net_status"] = videoTrackInfo.netStatus.rawValue
        params["is_raw"] = videoTrackInfo.isPassthrough ? 1 : 0
        params["prepare_aicodec_status"] = videoTrackInfo.param.aiCodecStatus
        params["use_aicodec"] = videoTrackInfo.result.useAICodec ? 1 : 0

        return params
    }
}

// 发消息埋点统一管理类协议
public protocol SendMessageKeyPointRecorderProtocol {
    // 注册状态监听者
    func registerStateListener(_ stateListener: SendMessageStateListener)

    func startSendMessage(indentify: String,
                          chatInfo: ChatKeyPointTrackerInfo,
                          params: [String: Any]?)

    func startCallQuasiMessageAPI(indentify: String, processCost: TimeInterval?)

    func finishCallQuasiMessageAPI(indentify: String,
                                   contextId: String,
                                   message: Message,
                                   extralInfo: [String: Any])

    func finishCallQuasiMessageAPI(cid: String, rustCreateCost: TimeInterval?, message: Message)

    func cacheExtraInfo(cid: String,
                        extralInfo: [String: Any])

    func saveTrackVideoInfo(cid: String, info: VideoTrackInfo)

    func saveTrackVideoError(indentify: String, cid: String?, code: Int, errorMsg: String)

    func finishWithError(indentify: String, cid: String?, error: SendMessageFlowStateError, page: String)

    func startCallSendMessageAPI(cid: String, processCost: TimeInterval?, extralInfo: [String: Any])

    func sendVideoInfo(info: SendMessageTrackerInfo, success: Bool, error: Error?, finishTime: CFTimeInterval)

    /// 发送消息成功
    func finishSendMessageAPI(cid: String, contextId: String, netCost: UInt64, trace: Basic_V1_Trace?)

    func messageOnScreen(cid: String, messageid: String, page: String, renderCost: TimeInterval?) -> SendMessageTrackerInfo?

    func messageSendShowLoading(cid: String)

    func sendMessageFinish(cid: String,
                           messageId: String,
                           success: Bool,
                           page: String,
                           isCheckExitChat: Bool,
                           renderCost: TimeInterval?) -> SendMessageTrackerInfo?

    func leaveChat(callBack: (SendMessageTrackerInfo) -> Void)

    func beforePublishOnScreenSignal(cid: String, messageId: String)

    func afterPublishOnScreenSignal(cid: String, messageId: String)

    func beforePublishFinishSignal(cid: String, messageId: String)

    func afterPublishFinishSignal(cid: String, messageId: String)
}
