//
//  SendMessageTracker.swift
//  LarkSendMessage
//
//  Created by 李勇 on 2022/11/22.
//

import UIKit
import Foundation
import RustPB // Basic_V1_Trace
import LarkPerf // ClientPerf
import LarkModel // Chat
import LarkTracing // LarkTracingUtil
import LarkContainer // InjectedLazy
import LKCommonsLogging // Logger

public protocol SendMessageTrackerProtocol {
    func beforeCreateQuasiMessage(context: APIContext?, processCost: TimeInterval?)

    func getQuasiMessage(msg: LarkModel.Message,
                         context: APIContext?,
                         contextId: String,
                         size: Int64?,
                         rustCreateForSend: Bool?,
                         rustCreateCost: TimeInterval?,
                         useNativeCreate: Bool)

    func cacheImageExtraInfo(cid: String,
                             imageInfo: ImageMessageInfo,
                             useOrigin: Bool)
    func cacheImageFallbackToFileExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool)

    func beforeSendMessage(context: APIContext?, msg: LarkModel.Message, processCost: TimeInterval?)

    // 调用发消息接口成功
    func finishSendMessageAPI(context: APIContext?, msg: LarkModel.Message, contextId: String, messageId: String?, netCost: UInt64, trace: Basic_V1_Trace?)

    // 发消息成功
    func sendMessageFinish(cid: String,
                           messageId: String,
                           success: Bool,
                           page: String,
                           isCheckExitChat: Bool,
                           renderCost: TimeInterval?)

    func errorQuasiMessage(context: APIContext?)

    func otherError(context: APIContext?)

    func transcodeFailed(context: APIContext?, code: Int, errorMsg: String, cid: String?, info: VideoTrackInfo?)

    func errorSendMessage(context: APIContext?, cid: String, error: Error)

    func showLoading(cid: String)

    func beforeTransCode()
    func afterTransCode(cid: String, info: VideoTrackInfo)

    func beforeGetResource()
    func afterGetResource()
}

public enum ActionPosition: String {
    case chat = "chat_window"
    case messageDetail = "thread_detail_page"
    public var pageNameForReciableTrack: String {
        switch self {
        case .chat:
            return "ChatMessagesViewController"
        case .messageDetail:
            return "MessageDetailViewController"
        }
    }
}

/// Chat相关信息：https://bytedance.feishu.cn/space/doc/doccnlXJv4xV4mTJSAFu4VjMqVb#BXt6R1
public final class ChatKeyPointTrackerInfo {
    public let id: String
    public let isCrypto: Bool
    public var inChatMessageDetail: Bool
    public var chat: Chat?

    // code_next_line tag CryptChat
    public init(id: String,
                isCrypto: Bool,
                inChatMessageDetail: Bool = false,
                chat: Chat?) {
        self.id = id
        // code_next_line tag CryptChat
        self.isCrypto = isCrypto
        self.inChatMessageDetail = inChatMessageDetail
        self.chat = chat
    }

    // 作为参数放到extra中，Slardar打点使用
    public var log: [String: String] {
        let chatTypeStr: String
        if self.chat?.isMeeting ?? false {
            chatTypeStr = "meeting"
        } else {
            switch self.chat?.type ?? .p2P {
            case .p2P:
                chatTypeStr = "single"
            case .group:
                chatTypeStr = "group"
            case .topicGroup:
                chatTypeStr = "topicGroup"
            @unknown default:
                assert(false, "new value")
                chatTypeStr = "unknown"
            }
        }
        return ["chat_id": self.id, "crypto": self.isCrypto ? "1" : "0", "chat_type": chatTypeStr]
    }

    public lazy var chatTypeForReciableTrace: Int = {
        if inChatMessageDetail {
            return 4
        }
        switch self.chat?.type ?? .p2P {
        case .p2P:
            return 1
        case .group:
            return 2
        @unknown default:
            return 0
        }
    }()
}

/// 发消息埋点由两部分组成：SendMessageTracker（发送耗时） + ChatKeyPointTracker（UI相关）
public final class SendMessageTracker: SendMessageTrackerProtocol, UserResolverWrapper {
    public let userResolver: UserResolver
    //消息发送相关信息记录
    @ScopedInjectedLazy private var sendRecorder: SendMessageKeyPointRecorderProtocol?
    private let actionPosition: ActionPosition
    static let logger = Logger.log(SendMessageTracker.self, category: "MessageSender")
    //发消息
    private let sendServiceKey = "send_message_time"
    //Chat相关信息记录
    private var chatInfo: ChatKeyPointTrackerInfo
    /// 埋点依赖LarkCore，重构为注入，解除对LarkCore的依赖
    public var trackMsgDetailClick: ((Message?, Chat?) -> Void)?

    // MARK: - init
    public init(userResolver: UserResolver, chatInfo: ChatKeyPointTrackerInfo, actionPosition: ActionPosition) {
        self.userResolver = userResolver
        self.chatInfo = chatInfo
        self.actionPosition = actionPosition
    }

    // MARK: - private
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

    // MARK: - public
    //indentify生成
    public func generateIndentify() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "_")
    }

    //开始发送消息，此时没有cid作为唯一标示，需要传入一个indentify作为唯一标示
    public func startSendMessage(context: APIContext, params: [String: Any]? = nil) {
        let identify = context.contextID
        sendRecorder?.startSendMessage(indentify: identify, chatInfo: chatInfo, params: params)
        ClientPerf.shared.startSlardarEvent(service: sendServiceKey, indentify: identify)
    }

    public func beforeCreateQuasiMessage(context: APIContext?, processCost: TimeInterval?) {
        if let context = context {
            sendRecorder?.startCallQuasiMessageAPI(indentify: context.contextID, processCost: processCost)
        }
    }

    public func cacheImageExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool) {
        let imageSourceRes = imageInfo.sendImageSource.originImage
        let sendImage = imageSourceRes.image
        let scale = sendImage?.scale ?? 1.0
        let imageHeight = (sendImage?.size.height ?? 0) * scale
        let imageWidth = (sendImage?.size.width ?? 0) * scale
        let pixelSize: CGSize = sendImage?.bt.pixelSize ?? .zero
        let uploadWidth = pixelSize == .zero ? imageWidth : pixelSize.width
        let uploadHeight = pixelSize == .zero ? imageHeight : pixelSize.height
        let extralInfo: [String: Any] = [
            "is_image_fallback_to_file": false,
            "is_image_origin": useOrigin,
            "resource_width": imageInfo.originalImageSize.width,
            "resource_height": imageInfo.originalImageSize.height,
            "resource_frames": 1,
            "image_type": imageInfo.sendImageSource.originImage.sourceType.description,
            "color_space": imageInfo.sendImageSource.originImage.colorSpaceName ?? "unknown",
            "is_preprocessed": imageInfo.isPreprocessed,
            "resource_content_length": imageInfo.imageSize ?? 0,
            "upload_content_length": imageInfo.sendImageSource.originImage.data?.count ?? 0,
            "upload_height": uploadHeight ?? 0,
            "upload_width": uploadWidth ?? 0,
            "image_process_cost": imageInfo.sendImageSource.originImage.compressCost ?? 0,
            "compress_algorithm": imageInfo.sendImageSource.originImage.compressAlgorithm ?? "",
            "compress_ratio": imageInfo.sendImageSource.originImage.compressRatio ?? 0
        ]
        sendRecorder?.cacheExtraInfo(cid: cid, extralInfo: extralInfo)
    }

    public func cacheImageFallbackToFileExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool) {
        let extraInfo: [String: Any] = [
            "is_image_fallback_to_file": true,
            "resource_content_length": imageInfo.imageSize ?? 0,
            "upload_content_length": imageInfo.imageSize ?? 0,
            "is_image_origin": useOrigin,
            "image_type": imageInfo.sourceImageType.description,
            "resource_width": imageInfo.originalImageSize.width,
            "resource_height": imageInfo.originalImageSize.height
        ]
        sendRecorder?.cacheExtraInfo(cid: cid, extralInfo: extraInfo)
    }

    public func getQuasiMessage(msg: Message, context: APIContext?, contextId: String, size: Int64?, rustCreateForSend: Bool?, rustCreateCost: TimeInterval?, useNativeCreate: Bool) {
        guard let context = context else { return }

        // 有端上创建假消息优化
        if useNativeCreate {
            // 并且此时Rust也创建完毕，需要更新pointCost[.callQuasiMessageAPI]为Rust创建耗时
            if rustCreateForSend == true, let rustCreateCost = rustCreateCost {
                sendRecorder?.finishCallQuasiMessageAPI(cid: msg.cid, rustCreateCost: rustCreateCost, message: msg)
                // 结束假消息Span
                LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.createQuasiMessage, cid: msg.cid)
                return
            }
            // 暂时记录pointCost[.callQuasiMessageAPI]为端上创建耗时，等Rust创建完毕再更新为Rust创建耗时
            sendRecorder?.finishCallQuasiMessageAPI(indentify: context.contextID, contextId: contextId, message: msg, extralInfo: [:])
            // 此时不结束假消息Span，等Rust创建完毕再结束
            return
        }

        // 没有端上创建假消息优化，记录pointCost[.callQuasiMessageAPI]为Rust创建耗时
        sendRecorder?.finishCallQuasiMessageAPI(indentify: context.contextID, contextId: contextId, message: msg, extralInfo: [:])
        // 直接结束假消息Span
        LarkTracingUtil.sendMessageEndSpanByName(spanName: LarkTracingUtil.createQuasiMessage, cid: msg.cid)
    }

    public func beforeSendMessage(context: APIContext?, msg: LarkModel.Message, processCost: TimeInterval?) {
        if let context = context {
            sendRecorder?.startCallSendMessageAPI(cid: msg.cid, processCost: processCost, extralInfo: [:])
        }
    }

    public func finishSendMessageAPI(context: APIContext?, msg: LarkModel.Message, contextId: String, messageId: String?, netCost: UInt64, trace: Basic_V1_Trace? = nil) {
        if let context = context {
            sendRecorder?.finishSendMessageAPI(cid: msg.cid, contextId: contextId, netCost: netCost, trace: trace)
            if self.actionPosition == .messageDetail { self.trackMsgDetailClick?(msg, self.chatInfo.chat) }
        }
    }

    public func sendMessageFinish(cid: String, messageId: String, success: Bool, page: String, isCheckExitChat: Bool, renderCost: TimeInterval? = 0) {
        guard let sendInfo = sendRecorder?.sendMessageFinish(cid: cid, messageId: messageId, success: success, page: page, isCheckExitChat: isCheckExitChat, renderCost: renderCost) else {
            return
        }
        self.log(sendInfo: sendInfo)
    }

    public func errorQuasiMessage(context: APIContext?) {
        Self.logger.info("finishWithError_errorQuasiMessage")
        if let context = context {
            sendRecorder?.finishWithError(indentify: context.contextID, cid: nil, error: .createQuasiError(), page: actionPosition.pageNameForReciableTrack)
        }
    }

    public func otherError(context: APIContext?) {
        Self.logger.info("finishWithError_otherError")
        if let context = context {
            sendRecorder?.finishWithError(indentify: context.contextID, cid: nil, error: .otherError(), page: actionPosition.pageNameForReciableTrack)
        }
    }

    // TODO @lichen 这里应该被重构掉
    public func transcodeFailed(context: APIContext?, code: Int, errorMsg: String, cid: String?, info: VideoTrackInfo?) {
        /// code 为 0 代表用户正常操作
        if code == 0 { return }
        Self.logger.info("finishWithError_transcodeFailed code \(code) errorMsg \(errorMsg) cid \(cid)")
        if let context = context {
            if let cid = cid, let info = info {
                sendRecorder?.saveTrackVideoInfo(cid: cid, info: info)
            }
            sendRecorder?.saveTrackVideoError(indentify: context.contextID, cid: cid, code: code, errorMsg: errorMsg)
            sendRecorder?.finishWithError(indentify: context.contextID, cid: cid, error: .otherError(), page: actionPosition.pageNameForReciableTrack)

            /// cid 为空代表这个错误为视频获取阶段错误，还没有上屏，正常流程埋点会由于获取不到相关info而中断
            /// 这里针对这种场景进行特化
            if cid == nil {
                let tempTrackInfo = SendMessageTrackerInfo(indentify: UUID().uuidString)
                let error = NSError(
                    domain: "video.pick.error",
                    code: code,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg]
                )
                self.sendRecorder?.sendVideoInfo(info: tempTrackInfo, success: false, error: error, finishTime: CACurrentMediaTime())
            }
        }
    }

    public func errorSendMessage(context: APIContext?, cid: String, error: Error) {
        Self.logger.info("finishWithError_errorSendMessage")
        if let context = context {
            sendRecorder?.finishWithError(indentify: context.contextID, cid: cid, error: .sendMessageError(error), page: actionPosition.pageNameForReciableTrack)
        }
    }

    public func showLoading(cid: String) {
        sendRecorder?.messageSendShowLoading(cid: cid)
    }

    public func beforeTransCode() {}
    public func afterTransCode(cid: String, info: VideoTrackInfo) {
        sendRecorder?.saveTrackVideoInfo(cid: cid, info: info)
    }

    public func beforeGetResource() {}
    public func afterGetResource() {}
}
