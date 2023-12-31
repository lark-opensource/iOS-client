//
//  RustSendMessageAPI.swift
//  Lark
//
//  Created by linlin on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import RxSwift // DisposeBag
import RxCocoa // Driver
import LarkModel // Message
import LarkContainer // InjectedLazy
import LarkSDKInterface // SDKRustService
import LKCommonsLogging // Logger
import ByteWebImage // LarkImageService
import LarkRustClient // RequestPacket
import ServerPB // ServerPB_Appshare_ShareApp
import FlowChart // FlowChartSerialProcess
import EEAtomic // SafeLazy
import LarkFoundation // FuncContext
import LarkStorage // IsoPath/AbsPath
import LarkFeatureGating

private typealias Path = LarkSDKInterface.PathWrapper

/// 用做发消息传参数使用，里面存放发消息所需的额外信息
public class APIContext {
    public static let contextIDKey = "ContextID"
    /// 目前使用：匿名发帖/回帖，功能已下线，不用关心相关逻辑
    public static let anonymousKey = "AnonymousKey"
    /// 消息以话题形式进行回复
    public static let replyInThreadKey = "replyInThreadKey"
    public static let chatDisplayModeKey = "chatDisplayMode"
    public static let chatFromWhere = "chatFromWhere"
    /// 如果是MyAI的分会场，则存储一些业务方信息
    public static let myAIChatModeConfig = "MyAIChatModeConfig"
    /// 如果是MyAI的主会场，则存储一些业务方信息
    public static let myAIMainChatConfig = "MyAIMainChatConfig"
    /// AI “快捷指令” 作为普通消息发送、上屏，信息携带在 context 参数中
    public static let myAIQuickActionInfo = "myAIQuickActionInfo"
    /// AI “快捷指令” 作为普通消息发送、上屏，附上原始信息，以便后续流程访问 QuickAction 属性
    public static let myAIQuickActionBody = "myAIQuickActionBody"

    /// 如果回复了消息的局部内容，则会存储一些局部回复的信息 LarkModel.PartialReplyInfo
    public static let partialReplyInfo = "messagePartialReplyInfo"

    private let context: FuncContext

    public var lastMessagePosition: Int32?
    public var quasiMsgCreateByNative: Bool?
    public var preprocessResourceKey: String?
    public var chatDisplayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?

    public init(contextID: String) {
        self.context = FuncContext()
        self.context.set(key: APIContext.contextIDKey, value: contextID)
    }

    public var contextID: String {
        return context.get(key: APIContext.contextIDKey) ?? ""
    }

    public func set<V>(key: String, value: V) {
        context.set(key: key, value: value)
    }

    public func get<V>(key: String) -> V? {
        return context.get(key: key)
    }

    public func getContext() -> FuncContext {
        return context
    }
}

public enum SendMessageState {
    case getQuasiMessage(LarkModel.Message, contextId: String, processCost: Int64? = nil, rustCreateForSend: Bool? = false, rustCreateCost: TimeInterval? = 0)
    //processCost耗时：图片、视频等发消息前，端上会做一些压缩、转码等处理
    case beforeSendMessage(LarkModel.Message, processCost: TimeInterval?)
    case finishSendMessage(LarkModel.Message, contextId: String, messageId: String?, netCost: UInt64, trace: Basic_V1_Trace? = nil)
    case errorQuasiMessage
    case errorSendMessage(cid: String, error: Error)
    case otherError
}

public protocol SendMessageAPI {
    typealias PreprocessingHandler = (_ message: Message?, _ sender: @escaping (_ preprocessCost: TimeInterval?) -> Void) -> Void
    var statusDriver: Driver<(LarkModel.Message, Error?)> { get }
    var pushCenter: PushNotificationCenter { get }

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        scheduleTime: Int64?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendText(
        context: APIContext?,
        sendTextParams: SendTextParams,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    )

    func sendCard(
        context: APIContext?,
        content: CardContent,
        chatId: String,
        threadId: String?,
        parentMessage: Message?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendSticker(
        context: APIContext?,
        sticker: RustPB.Im_V1_Sticker,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendAudio(
        context: APIContext?,
        audio: AudioDataInfo,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendAudio(
        context: APIContext?,
        audio: AudioDataInfo,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendAudio(
        context: APIContext?,
        audioInfo: StreamAudioInfo,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: Message?,
        removeOriginalFileAfterFinish: Bool,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: Message?,
        removeOriginalFileAfterFinish: Bool,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)
    // swiftlint:disable all
    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: Message?,
        removeOriginalFileAfterFinish: Bool,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    // swiftlint:disable function_parameter_count
    // 帖子分带视频和不带视频两种，带视频的需要先创建假消息，然后再发送
    func sendPost(
        context: APIContext?,
        title: String,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?,
        stateHandler: ((SendMessageState) -> Void)?)
    // swiftlint:enable function_parameter_count

    // swiftlint:disable all
    // 帖子分带视频和不带视频两种，带视频的需要先创建假消息，然后再发送
    func sendPost(
        context: APIContext?,
        title: String,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        scheduleTime: Int64?,
        preprocessingHandler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)
    // swiftlint:enable all

    func sendPost(
        context: APIContext?,
        sendPostParams: SendPostParams,
        preprocessingHandler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendImage(
        context: APIContext?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendImage(
        context: APIContext?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendImage(
        context: APIContext?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((Int, SendMessageState) -> Void)?)

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        stateHandler: ((Int, SendMessageState) -> Void)?)

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((Int, SendMessageState) -> Void)?)

    func sendLocation(
        context: APIContext?,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        screenShot: UIImage,
        location: LocationContent,
        sendMessageTracker: SendMessageTrackerProtocol,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendMedia(
        context: APIContext?,
        params: SendMediaParams,
        handler: PreprocessingHandler?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendMedia(
        context: APIContext?,
        params: SendMediaParams,
        handler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)

    func sendShareUserCardMessage(context: APIContext?,
                                  shareChatterId: String,
                                  sendChannelType: SendChannelType,
                                  sendMessageTracker: SendMessageTrackerProtocol?,
                                  stateHandler: ((SendMessageState) -> Void)?)

    func sendShareUserCardMessage(context: APIContext?,
                                  shareChatterId: String,
                                  sendChannelType: SendChannelType,
                                  createScene: Basic_V1_CreateScene?,
                                  sendMessageTracker: SendMessageTrackerProtocol?,
                                  stateHandler: ((SendMessageState) -> Void)?)

    func sendShareAppCardMessage(context: APIContext?, type: ShareAppCardType, chatId: String) -> Observable<Void>

    func sendShareAppCard(context: APIContext?, type: ShareAppCardType, chatId: String) -> Observable<String?>

    func updateQuasiMessage(context: APIContext?, cid: String, status: RustPB.Basic_V1_QuasiMessage.Status)

    func sendGroupShare(context: APIContext?,
                        sharChatId: String,
                        chatId: String,
                        threadId: String?,
                        stateHandler: ((SendMessageState) -> Void)?)
    func sendGroupShare(context: APIContext?,
                        sharChatId: String,
                        chatId: String,
                        threadId: String?,
                        createScene: Basic_V1_CreateScene?,
                        stateHandler: ((SendMessageState) -> Void)?)

    // 重发消息
    func resendMessage(message: Message)

    // NOTE: 为push设计的，防止多次重复发送消息
    func dealPushMessage(message: Message) -> Bool

    // 取消发送消息
    func cancelSendMessage(context: APIContext?, cid: String)
    // 单测工程中使用，CI中单测包是DEBUG环境
#if ALPHA
    func preSendMessage(cid: String)
    func resendMessage(context: APIContext?, message: LarkModel.Message)
    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?)
    func quasiMsgCreateByNative(context: APIContext?) -> Bool
    func addPendingMessages(id: String, value: (message: Message, filePath: String, deleteFileWhenFinish: Bool))
    func sendError(value: (LarkModel.Message, Error?))
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
    func getImageMessageInfoCost(info: ImageMessageInfo) -> TimeInterval
#endif
}

final class RustSendMessageAPI: SendMessageAPI, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(RustSendMessageAPI.self, category: "RustSDK.SendMessage")
    /// 伪造一个key来标识原图，目的：在发送成功后取出，再用content中的key进行缓存，可以看replaceImageMessageCacheKey等方法
    static let originImageCachePre: String = "originPreKey"
    /// 仅用于测试工程中进行逻辑的校验
#if ALPHA
    static public var beforeCreateQuasiMsgHandler: (() -> Void)?
#endif

    let queue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)
    let client: SDKRustService
    let scheduler: ImmediateSchedulerType
    private var disposeBag = DisposeBag()

    /// 记录发送、重发的消息，处理发送loading的展示时机，比如0.5s之后才展示loading
    private var sendingCids = Set<String>()
    private var resendingCids = Set<String>()

    private var sendingLock = NSLock()

    /// 文件消息使用，发送成功后移除原文件等额外处理，逻辑看uploadFileFinish、handleFileMessageOnSuceess
    private var pendingMessages: [String: (message: LarkModel.Message, filePath: String, deleteFileWhenFinish: Bool)] = [:]

    // 状态变更通知
    private var statusPubSub = PublishSubject<(LarkModel.Message, Error?)>()

    private var userGeneralSettings: UserGeneralSettings
    private var sendingManager: SendingMessageManager

    /// 发送消息状态监听
    var statusDriver: Driver<(LarkModel.Message, Error?)> {
        return self.statusPubSub.asDriver { _ in
            return Driver<(LarkModel.Message, Error?)>.empty()
        }
    }
    private let chatAPI: ChatAPI
    /// 监听图片、视频、文件上传进度，本质是监听Rust的PushUploadFileResponse；本类中只用来处理文件
    private let progressService: ProgressService
    public let pushCenter: PushNotificationCenter
    private let dependency: RustSendMessageAPIDependency
    private  var chatterManager: ChatterManagerProtocol
    var currentChatter: Chatter {
        chatterManager.currentChatter
    }
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus {
        self.dependency.currentNetStatus
    }

    // 发文本流程
    @SafeLazy var sendTextProcess: SerialProcess<SendMessageProcessInput<SendTextModel>, RustSendMessageAPI>!
    // 发文件流程
    @SafeLazy var sendFileProcess: SerialProcess<SendMessageProcessInput<SendFileModel>, RustSendMessageAPI>!
    // 发图片总流程: 走图片or文件
    @SafeLazy var sendImageProcess: SerialProcess<SendMessageProcessInput<SendImageModel>, RustSendMessageAPI>!
    // 发语音流程
    @SafeLazy var sendAudioProcess: SerialProcess<SendMessageProcessInput<SendAudioModel>, RustSendMessageAPI>!
    // 发视频流程
    @SafeLazy var sendMediaProcess: SerialProcess<SendMessageProcessInput<SendMediaModel>, RustSendMessageAPI>!
    // 发位置流程
    @SafeLazy var sendLocationProcess: SerialProcess<SendMessageProcessInput<SendLocationModel>, RustSendMessageAPI>!
    // 发表情包流程
    @SafeLazy var sendStickerProcess: SerialProcess<SendMessageProcessInput<SendStickerModel>, RustSendMessageAPI>!
    // 发卡片流程
    @SafeLazy var sendCardProcess: SerialProcess<SendMessageProcessInput<SendCardModel>, RustSendMessageAPI>!
    // 发用户卡片流程
    @SafeLazy var sendShareUserCardProcess: SerialProcess<SendMessageProcessInput<SendShareUserCardModel>, RustSendMessageAPI>!
    // 发富文本流程
    @SafeLazy var sendPostProcess: SerialProcess<SendMessageProcessInput<SendPostModel>, RustSendMessageAPI>!
    // 发群分享流程
    @SafeLazy var sendGroupShareProcess: SerialProcess<SendMessageProcessInput<SendGroupShareModel>, RustSendMessageAPI>!

    init(
        userResolver: UserResolver,
        chatAPI: ChatAPI,
        progressService: ProgressService,
        pushCenter: PushNotificationCenter,
        client: SDKRustService,
        onScheduler: ImmediateSchedulerType,
        dependency: RustSendMessageAPIDependency
    ) throws {
        self.userResolver = userResolver
        self.chatAPI = chatAPI
        self.progressService = progressService
        self.pushCenter = pushCenter
        self.dependency = dependency
        self.client = client
        self.scheduler = onScheduler
        self.userGeneralSettings = try userResolver.resolve(assert: UserGeneralSettings.self)
        self.sendingManager = try userResolver.resolve(assert: SendingMessageManager.self)
        self.chatterManager = try userResolver.resolve(assert: ChatterManagerProtocol.self)

        self.statusPubSub
            .subscribe(onNext: { [weak self] (message, _) in
                guard let `self` = self else { return }
                self.pushCenter.post(PushChannelMessage(message: message))
                self.pushCenter.post(PushChannelMessages(messages: [message]))
                // track send message
                LarkSendMessageTracker.trackEndSendMessage(message: message)
            }).disposed(by: disposeBag)

        self.progressService.finish.subscribe(onNext: { [weak self] (pushUploadFile) in
            guard let `self` = self else { return }
            if pushUploadFile.state == .uploadSuccess {
                self.uploadFileFinish(cid: pushUploadFile.localKey, success: true)
            } else {
                self.uploadFileFinish(cid: pushUploadFile.localKey, success: false)
            }
        }).disposed(by: disposeBag)

        initSendMessagProcess()
    }

    private func initSendMessagProcess() {
        _sendTextProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendTextProcess()
        }
        _sendMediaProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendMediaProcess()
        }
        _sendAudioProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendAudioProcess()
        }
        _sendFileProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendFileProcess()
        }
        _sendImageProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendImageProcess()
        }
        _sendLocationProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendLocationProcess()
        }
        _sendStickerProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendStickerProcess()
        }
        _sendCardProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendCardProcess()
        }
        _sendShareUserCardProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendShareUserCardProcess()
        }
        _sendPostProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendPostProcess()
        }
        _sendGroupShareProcess = SafeLazy { [weak self] in
            guard let self = self else { return nil }
            return self.getSendGroupShareProcess()
        }
    }

    func resendMessage(context: APIContext?, message: LarkModel.Message) {
        let cid = message.cid
        RustSendMessageAPI.logger.info("sendTrace in resendMessage \(cid)")
        sendingLock.lock()
        RustSendMessageAPI.logger.info("sendTrace resendMessage get lock \(cid)")
        resendingCids.insert(cid)
        sendingManager.add(task: cid)
        sendingLock.unlock()
        self.adjustLocalStatus(message: message, stateHandler: nil)
        statusPubSub.onNext((message, nil))

        if let fileContent = message.content as? FileContent,
           pendingMessages[cid] == nil {
            pendingMessages[cid] = (message: message, filePath: fileContent.filePath, deleteFileWhenFinish: false)
        }
        RustSendMessageModule
            .resendMessage(cid: cid, client: client, context: context)
            .subscribe(onError: { [weak self] (error) in
                message.localStatus = .fail
                self?.statusPubSub.onNext((message, error))
                RustSendMessageAPI.logger.error("消息重发失败", additionalData: ["Cid": cid], error: error)
            })
            .disposed(by: disposeBag)
    }

    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    //是否端上创建上屏消息
    func quasiMsgCreateByNative(context: APIContext?) -> Bool {
        if let context = context, context.lastMessagePosition != nil,
           context.chatDisplayMode != nil, context.quasiMsgCreateByNative == true,
           userGeneralSettings.createQuasiMessageConfig.isNativeQuasiMessage {
            return true
        }
        return false
    }

    private func uploadFileFinish(cid: String, success: Bool) {
        guard let (message, path, deleteWhenFinish) = pendingMessages[cid] else {
            return
        }
        if success {
            if deleteWhenFinish, message.content is FileContent {
                try? Path(path).deleteFile()
            }
            // 这里不清楚为啥不调用pendingMessages.removeValue(forKey: cid)，历史逻辑无法考究，也不敢动
            // pendingMessages.removeValue(forKey: cid)
        } else {
            message.localStatus = .fail
            pendingMessages.removeValue(forKey: cid)
        }
    }

    func addPendingMessages(id: String, value: (message: Message, filePath: String, deleteFileWhenFinish: Bool)) {
        pendingMessages[id] = value
    }

    func preSendMessage(cid: String) {
        sendingLock.lock()
        sendingCids.insert(cid)
        sendingManager.add(task: cid)
        sendingLock.unlock()
    }

    func dealPushMessage(message: LarkModel.Message) -> Bool {
        Self.logger.info("sendTrace in dealPushMessage \(message.cid)")
        guard let key = calculateKey(for: message) else {
            return false
        }
        sendingLock.lock()
        defer {
            sendingLock.unlock()
        }
        Self.logger.info("sendTrace in dealPushMessage get key \(key) \(message.cid)")
        let cid = message.cid
        if resendingCids.contains(key) {
            Self.logger.info("sendTrace dealPushMessage handle resendingCids \(cid) \(key)")
            handleFileMessageOnSuceess(message)
            replaceImageMessageCacheKey(message: message)
            replaceMediaMessageCacheKey(message: message)
            replaceLocationMessageCacheKey(message: message)
            statusPubSub.onNext((message, nil))
            resendingCids.remove(key)
            sendingManager.remove(task: key)
            return true
        }

        if sendingCids.contains(key) {
            Self.logger.info("sendTrace dealPushMessage handle sendingCids \(cid) \(key)")
            handleFileMessageOnSuceess(message)
            replaceImageMessageCacheKey(message: message)
            replaceMediaMessageCacheKey(message: message)
            replaceLocationMessageCacheKey(message: message)
            statusPubSub.onNext((message, nil))
            sendingCids.remove(key)
            sendingManager.remove(task: key)
            return true
        }

        return false
    }

    /// 替换图片消息key所对应的图片资源
    private func replaceImageMessageCacheKey(message: LarkModel.Message) {
        guard message.type == .image,
              message.localStatus == .success,
              let content = message.content as? LarkModel.ImageContent else {
            return
        }
        //缩略图
        var thumbnailImage = LarkImageService.shared.image(with: .default(key: message.cid), cacheOptions: .memory)
        //原图
        let originImageCacheKey = "\(Self.originImageCachePre)_\(message.cid)"
        let originalImage = LarkImageService.shared.image(with: .default(key: originImageCacheKey), cacheOptions: .memory)

        LarkImageService.shared.removeCache(resource: .default(key: message.cid))
        LarkImageService.shared.removeCache(resource: .default(key: originImageCacheKey))
        //设置缩略图key,如果没有缩略图或者是gif（gif缩略图不播放）用原图代替缩略图
        let isGif = originalImage?.bt.imageFileFormat == .gif
        if thumbnailImage == nil || isGif {
            thumbnailImage = originalImage
        }
        if let image = thumbnailImage {
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.middle.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.thumbnail.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.middleWebp.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.thumbnailWebp.key), cacheOptions: .memory)
        }
        //设置原图的key
        if let image = originalImage {
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.origin.key), cacheOptions: .memory)
        }

    }

    /// 替换视频消息key所对应的图片资源
    private func replaceMediaMessageCacheKey(message: LarkModel.Message) {
        guard message.type == .media,
              message.localStatus == .success,
              let content = message.content as? LarkModel.MediaContent else {
            return
        }
        let image = LarkImageService.shared.image(with: .default(key: message.cid), cacheOptions: .memory)
        LarkImageService.shared.removeCache(resource: .default(key: message.cid))
        if let image = image {
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.middle.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.thumbnail.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.middleWebp.key), cacheOptions: .memory)
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: content.image.thumbnailWebp.key), cacheOptions: .memory)
        }
    }

    /// 替换位置消息key所对应的图片资源
    private func replaceLocationMessageCacheKey(message: LarkModel.Message) {
        guard message.type == .location,
              message.localStatus == .success,
              let content = message.content as? LarkModel.LocationContent else {
            return
        }
        let image = LarkImageService.shared.image(with: .default(key: message.cid), cacheOptions: .memory)
        LarkImageService.shared.removeCache(resource: .default(key: message.cid))
        if let image = image {
            LarkImageService.shared.cacheImage(image: image, data: nil, resource: .default(key: content.image.origin.key), cacheOptions: .memory)
        }
    }

    /// 发送文件消息成功处理
    private func handleFileMessageOnSuceess(_ message: LarkModel.Message) {
        guard
            message.type == .file,
            let content = message.content as? LarkModel.FileContent,
            !content.isInMyNutStore,
            pendingMessages[message.cid] != nil else {
            return
        }

        let pathExtension = (content.name as NSString).pathExtension
        switch message.localStatus {
        case .success:
            LarkSendMessageTracker.trackAttachedFileSendFinish(isSuccess: true, fileType: pathExtension, fileSize: Int(content.size))
            if Path.useLarkStorage {
                // 对于本地普通文件，发送成功之后，为了下次不再下载，需要把文件路径替换成 downloads/content.key.md5/content.name这种格式
                let originFilePath = content.filePath.asAbsPath()
                // 密聊文件不需要端上缓存，后续浏览时也没有使用，使用的始终是sdk缓存，即便是自己发的，第一次打开时也会去下载
                if originFilePath.exists, message.burnLife <= 0 {
                    let cache = fileDownloadCache(userResolver.userID)
                    let newFileDir = cache.iso.rootPath + content.key.kf.md5
                    let newFilePath = newFileDir + content.name
                    do {
                        try newFileDir.createDirectoryIfNeeded()
                        try newFilePath.notStrictly.moveItem(from: originFilePath)
                        _ = cache.saveFileName(content.key.kf.md5 + "/" + content.name)
                    } catch {
                        RustSendMessageAPI.logger.error("create dir failed", additionalData: ["url": newFilePath.absoluteString], error: error)
                    }
                }
            } else {
                // 对于本地普通文件，发送成功之后，为了下次不再下载，需要把文件路径替换成 downloads/content.key.md5/content.name这种格式
                let originFilePath = Path.Old(content.filePath)

                // 密聊文件不需要端上缓存，后续浏览时也没有使用，使用的始终是sdk缓存，即便是自己发的，第一次打开时也会去下载
                if originFilePath.exists, message.burnLife <= 0 {
                    let cache = fileDownloadCache(userResolver.userID)
                    let newFileDir = Path.Old(cache.rootPath) + content.key.kf.md5
                    let newFilePath = newFileDir + content.name
                    do {
                        try newFileDir.createDirectoryIfNeeded()
                        try originFilePath.moveFile(to: newFilePath)
                        _ = cache.saveFileName(content.key.kf.md5 + "/" + content.name)
                    } catch {
                        RustSendMessageAPI.logger.error("create dir failed", additionalData: ["url": newFilePath.rawValue], error: error)
                    }
                }
            }
            pendingMessages.removeValue(forKey: message.cid)
        case .fail:
            LarkSendMessageTracker.trackAttachedFileSendFinish(isSuccess: false, fileType: pathExtension, fileSize: Int(content.size))
            pendingMessages.removeValue(forKey: message.cid)
        default:
            break
        }
    }

    private func calculateKey(for message: LarkModel.Message) -> String? {
        if message.isRecalled || message.isDeleted {
            return nil
        }
        return message.cid
    }

    /// 状态先变为fakeSuccess，过一段时间如果还没发送成功（收到Rust的PushMessageResponse，执行dealPushMessage方法），则变为process展示loading
    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?) {
        guard message.threadId.isEmpty || message.position == replyInThreadMessagePosition  else {
            //thread回复消息不实现该策略
            RustSendMessageAPI.logger.info("sendTrace adjustLocalStatus return for thread \(message.cid)")
            message.localStatus = .process
            return
        }

        var delayProcess: Double?
        let networkStatus = self.dependency.currentNetStatus
        switch networkStatus {
        case .excellent:
            message.localStatus = .fakeSuccess
            delayProcess = 0.5
        case .evaluating:
            message.localStatus = .fakeSuccess
            delayProcess = 0.1
        case .netUnavailable, .serviceUnavailable, .weak, .offline:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        let cid = message.cid
        RustSendMessageAPI.logger.info("sendTrace dynamicNetStatus \(networkStatus.rawValue) \(cid)")
        if let delayProcess = delayProcess {
            // 使用global，避免死锁卡主线程
            DispatchQueue.global().asyncAfter(deadline: .now() + delayProcess) {
                RustSendMessageAPI.logger.info("sendTrace adjustLocalStatus in globalAsync \(cid)")
                self.sendingLock.lock()
                defer {
                    self.sendingLock.unlock()
                }
                RustSendMessageAPI.logger.info("sendTrace adjustLocalStatus get lock \(cid)")
                if self.sendingCids.contains(message.cid) ||
                    self.resendingCids.contains(message.cid) ||
                    // 这里其实不用判断pendingMessages，因为pendingMessages一定也在sendingCids/resendingCids中
                    self.pendingMessages[message.cid] != nil {
                    RustSendMessageAPI.logger.info("sendTrace in adjustLocalStatus \(cid)")
                    message.localStatus = .process
                    self.statusPubSub.onNext((message, nil))
                }
            }
        }
    }
}

extension RustSendMessageAPI {

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let params = SendTextParams(content: content,
                                    lingoInfo: nil,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: threadId,
                                    createScene: nil,
                                    scheduleTime: nil)
        self.sendText(context: context,
                      sendTextParams: params,
                      sendMessageTracker: nil,
                      stateHandler: stateHandler)
    }

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene? = nil,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let params = SendTextParams(content: content,
                                    lingoInfo: nil,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: threadId,
                                    createScene: createScene,
                                    scheduleTime: nil)
        self.sendText(context: context,
                      sendTextParams: params,
                      sendMessageTracker: sendMessageTracker,
                      stateHandler: stateHandler)
    }

    func sendText(
        context: APIContext?,
        content: RustPB.Basic_V1_RichText,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene? = nil,
        scheduleTime: Int64? = nil,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let params = SendTextParams(content: content,
                                    lingoInfo: nil,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: threadId,
                                    createScene: createScene,
                                    scheduleTime: scheduleTime)
        self.sendText(context: context,
                      sendTextParams: params,
                      sendMessageTracker: sendMessageTracker,
                      stateHandler: stateHandler)
    }

    func sendText(context: APIContext?,
                  sendTextParams: SendTextParams,
                  sendMessageTracker: SendMessageTrackerProtocol? = nil,
                  stateHandler: ((SendMessageState) -> Void)? = nil) {
        let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
        let model = SendTextModel(content: sendTextParams.content,
                                  lingoInfo: sendTextParams.lingoInfo ?? RustPB.Basic_V1_LingoOption(),
                                  chatId: sendTextParams.chatId,
                                  threadId: sendTextParams.threadId,
                                  createScene: sendTextParams.createScene,
                                  transmitToChat: sendTextParams.transmitToChat)
        self.queue.async {
            self.sendTextProcess.run(input: SendMessageProcessInput(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: sendTextParams.parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread,
                scheduleTime: sendTextParams.scheduleTime)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendCard(
        context: APIContext?,
        content: LarkModel.CardContent,
        chatId: String,
        threadId: String?,
        parentMessage: LarkModel.Message? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            let model = SendCardModel(chatId: chatId, threadId: threadId, card: content)
            self.sendCardProcess.run(input: SendMessageProcessInput<SendCardModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendAudio(
        context: APIContext?,
        audio: AudioDataInfo,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        self.sendAudio(context: context,
                       audio: audio,
                       parentMessage: parentMessage,
                       chatId: chatId,
                       threadId: threadId,
                       sendMessageTracker: nil,
                       stateHandler: stateHandler)
    }

    func sendAudio(
        context: APIContext?,
        audio: AudioDataInfo,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let type: NewAudioDataInfo.AudioType
        switch audio.type {
        case .opus:
            type = .opus
        case .pcm:
            type = .pcm
        }
        let audioDataInfo = NewAudioDataInfo(dateType: .data(audio.data, audio.uploadID),
                                             length: audio.length,
                                             type: type,
                                             text: audio.text)
        self.queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            self.sendAudioProcess.run(input: SendMessageProcessInput(
                context: context,
                model: SendAudioModel(info: audioDataInfo, chatId: chatId, threadId: threadId),
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendAudio(
        context: APIContext?,
        audioInfo: StreamAudioInfo,
        parentMessage: LarkModel.Message?,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
        let audioDataInfo = NewAudioDataInfo(dateType: .uploadID(audioInfo.uploadID),
                                             length: audioInfo.length,
                                             type: .default,
                                             text: audioInfo.text)
        self.queue.async {
            self.sendAudioProcess.run(input: SendMessageProcessInput(
                context: context,
                model: SendAudioModel(info: audioDataInfo, chatId: chatId, threadId: threadId),
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: LarkModel.Message? = nil,
        removeOriginalFileAfterFinish: Bool = false,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        self.sendFile(context: context,
                      path: path,
                      name: name,
                      parentMessage: parentMessage,
                      removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                      chatId: chatId,
                      threadId: threadId,
                      sendMessageTracker: nil,
                      stateHandler: stateHandler)
    }

    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: LarkModel.Message? = nil,
        removeOriginalFileAfterFinish: Bool = false,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        self.sendFile(context: context,
                      path: path,
                      name: name,
                      parentMessage: parentMessage,
                      removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                      chatId: chatId,
                      threadId: threadId,
                      createScene: nil,
                      sendMessageTracker: sendMessageTracker,
                      stateHandler: stateHandler)
    }

    // swiftlint:disable function_parameter_count
    func sendFile(
        context: APIContext?,
        path: String,
        name: String,
        parentMessage: Message?,
        removeOriginalFileAfterFinish: Bool,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        let model = SendFileModel(path: path,
                                  name: name,
                                  chatId: chatId,
                                  threadId: threadId,
                                  size: nil,
                                  removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                                  createScene: createScene)
        self.queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            self.sendFileProcess.run(input: SendMessageProcessInput(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }
    // swiftlint:enable function_parameter_count

    func sendError(value: (LarkModel.Message, Error?)) {
        // TODO: 修改消息发送失败的逻辑,下掉这里的特化
        // DLP对于发消息失败时的临时特化逻辑, 防止quasiMessage的字段被端上创建的假消息覆盖
        if let error = value.1?.underlyingError as? APIError {
            if error.code == 311_120 {
                Self.logger.info("ErrorCode:<\(error.code)>, Messageid:<\(value.0.id)>, send no message with error.")
                return
            }
        }
        self.statusPubSub.onNext(value)
    }

    private func processSendResponse(_ res: FlowChartResponse) {
        switch res {
        case .success(let identify, let info):
            Self.logger.info("SendMessage<\(identify)> executed success: extraInfo = \(info)")
        case .failure(let identify, let error):
            Self.logger.error("SendMessage<\(identify)> executed failure!!!, desc = \(error.getDescription()), extraInfo = \(error.getExtraInfo())")
        }
    }

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        stateHandler: ((Int, SendMessageState) -> Void)?
    ) {
        self.sendImages(contexts: contexts,
                        parentMessage: parentMessage,
                        useOriginal: useOriginal,
                        imageMessageInfos: imageMessageInfos,
                        chatId: chatId,
                        threadId: threadId,
                        sendMessageTracker: nil,
                        stateHandler: stateHandler)
    }

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((Int, SendMessageState) -> Void)?
    ) {
        // 一次多选发图片的任务都放在一个串型队列里来保证时序性，用serialToken来标记
        self.sendImages(contexts: contexts,
                        parentMessage: parentMessage,
                        useOriginal: useOriginal,
                        imageMessageInfos: imageMessageInfos,
                        chatId: chatId,
                        threadId: threadId,
                        createScene: nil,
                        sendMessageTracker: sendMessageTracker,
                        stateHandler: stateHandler)
    }

    func sendImage(
        context: APIContext?,
        parentMessage: LarkModel.Message? = nil,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        self.sendImage(context: context,
                       parentMessage: parentMessage,
                       useOriginal: useOriginal,
                       imageMessageInfo: imageMessageInfo,
                       chatId: chatId,
                       threadId: threadId,
                       sendMessageTracker: nil,
                       stateHandler: stateHandler)
    }

    func sendImage(
        context: APIContext?,
        parentMessage: LarkModel.Message? = nil,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        sendImage(context: context,
                  parentMessage: parentMessage,
                  useOriginal: useOriginal,
                  imageMessageInfo: imageMessageInfo,
                  chatId: chatId,
                  threadId: threadId,
                  createScene: nil,
                  sendMessageTracker: sendMessageTracker,
                  stateHandler: stateHandler)
    }

    func sendImage(
        context: APIContext?,
        parentMessage: LarkModel.Message? = nil,
        useOriginal: Bool,
        imageMessageInfo: ImageMessageInfo,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene? = nil,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
        let model = SendImageModel(useOriginal: useOriginal,
                                   imageMessageInfo: imageMessageInfo,
                                   chatId: chatId,
                                   threadId: threadId,
                                   createScene: createScene)
        queue.async {
            self.sendImageProcess.run(input: SendMessageProcessInput<SendImageModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendImages(
        contexts: [APIContext]?,
        parentMessage: LarkModel.Message?,
        useOriginal: Bool,
        imageMessageInfos: [ImageMessageInfo],
        chatId: String,
        threadId: String?,
        createScene: RustPB.Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((Int, SendMessageState) -> Void)?
    ) {
        // 一次多选发图片的任务都放在一个串型队列里来保证时序性，用serialToken来标记
        let multiSendSerialToken = imageMessageInfos.count > 1 ? RequestPacket.nextSerialToken() : nil
        // 目前发图速度太快, 临时通过 delay 限制频率 > 10ms 避免图片乱序
        let multiSendSerialDelay = imageMessageInfos.count > 1 ? 0.01 : nil
        for (index, info) in imageMessageInfos.enumerated() {
            let context = contexts?[index]
            queue.async {
                let model = SendImageModel(useOriginal: useOriginal,
                                           imageMessageInfo: info,
                                           chatId: chatId,
                                           threadId: threadId,
                                           createScene: createScene)
                let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
                self.sendImageProcess.run(input: SendMessageProcessInput<SendImageModel>(
                    context: context,
                    model: model,
                    stateHandler: { stateHandler?(index, $0) },
                    parentMessage: parentMessage,
                    multiSendSerialToken: multiSendSerialToken,
                    multiSendSerialDelay: multiSendSerialDelay,
                    sendMessageTracker: sendMessageTracker,
                    replyInThread: replyInThread)) { [weak self] res in
                        self?.processSendResponse(res)
                }
            }
        }
    }

    func getImageMessageInfoCost(info: ImageMessageInfo) -> TimeInterval {
        if let image = info.sendImageSource.coverForOnScreen {
            return image.compressCost ?? 0
        } else {
            return info.sendImageSource.originImage.compressCost ?? 0
        }
    }

    func sendLocation(
        context: APIContext?,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        screenShot: UIImage,
        location: LarkModel.LocationContent,
        sendMessageTracker: SendMessageTrackerProtocol,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            let model = SendLocationModel(chatId: chatId, threadId: threadId, screenShot: screenShot, location: location)
            self.sendLocationProcess.run(input: SendMessageProcessInput<SendLocationModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendMedia(
        context: APIContext?,
        params: SendMediaParams,
        handler: PreprocessingHandler?,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        self.sendMedia(context: context,
                       params: params,
                       handler: handler,
                       sendMessageTracker: nil,
                       stateHandler: stateHandler)
    }

    func sendMedia(
        context: APIContext?,
        params: SendMediaParams,
        handler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        self.queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            self.sendMediaProcess.run(input: SendMessageProcessInput<SendMediaModel>(
                context: context,
                model: SendMediaModel(params: params, handler: handler, createScene: params.createScene),
                stateHandler: stateHandler,
                parentMessage: params.parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func updateQuasiMessage(context: APIContext?, cid: String, status: RustPB.Basic_V1_QuasiMessage.Status) {
        RustSendMessageModule.updateQuasiMessage(
            cid: cid,
            status: status,
            client: client,
            context: context
        )
    }

    func cancelSendMessage(context: APIContext?, cid: String) {
        RustSendMessageModule.cancelSendMessage(
            cid: cid,
            client: client,
            context: context
        )
    }
    // swiftlint:disable all
    func sendPost(
        context: APIContext?,
        title: String,
        content: RustPB.Basic_V1_RichText,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        let params = SendPostParams(
            title: title,
            content: content,
            lingoInfo: nil,
            parentMessage: parentMessage,
            chatId: chatId,
            threadId: threadId,
            isGroupAnnouncement: isGroupAnnouncement,
            scheduleTime: nil
        )
        self.sendPost(
            context: context,
            sendPostParams: params,
            preprocessingHandler: preprocessingHandler,
            sendMessageTracker: nil,
            stateHandler: stateHandler
        )
    }

    func sendPost(
        context: APIContext?,
        title: String,
        content: RustPB.Basic_V1_RichText,
        parentMessage: LarkModel.Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        scheduleTime: Int64?,
        preprocessingHandler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        let params = SendPostParams(
            title: title,
            content: content,
            lingoInfo: nil,
            parentMessage: parentMessage,
            chatId: chatId,
            threadId: threadId,
            isGroupAnnouncement: isGroupAnnouncement,
            scheduleTime: scheduleTime
        )
        self.sendPost(
            context: context,
            sendPostParams: params,
            preprocessingHandler: preprocessingHandler,
            sendMessageTracker: sendMessageTracker,
            stateHandler: stateHandler
        )
    }
    // swiftlint:enable all

    func sendPost(
        context: APIContext?,
        sendPostParams: SendPostParams,
        preprocessingHandler: PreprocessingHandler?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            let model = SendPostModel(chatId: sendPostParams.chatId,
                                      threadId: sendPostParams.threadId,
                                      title: sendPostParams.title,
                                      content: sendPostParams.content,
                                      lingoInfo: sendPostParams.lingoInfo ?? RustPB.Basic_V1_LingoOption(),
                                      isGroupAnnouncement: sendPostParams.isGroupAnnouncement,
                                      preprocessingHandler: preprocessingHandler,
                                      transmitToChat: sendPostParams.transmitToChat)
            self.sendPostProcess.run(input: SendMessageProcessInput<SendPostModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: sendPostParams.parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread,
                scheduleTime: sendPostParams.scheduleTime)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func sendSticker(
        context: APIContext?,
        sticker: RustPB.Im_V1_Sticker,
        parentMessage: LarkModel.Message? = nil,
        chatId: String,
        threadId: String?,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)? = nil
    ) {
        queue.async {
            let replyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
            let model = SendStickerModel(chatId: chatId, threadId: threadId, sticker: sticker)
            self.sendStickerProcess.run(input: SendMessageProcessInput<SendStickerModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                parentMessage: parentMessage,
                sendMessageTracker: sendMessageTracker,
                replyInThread: replyInThread)) { [weak self] res in
                    self?.processSendResponse(res)
            }

        }
    }

    func sendShareUserCardMessage(
        context: APIContext?,
        shareChatterId: String,
        sendChannelType: SendChannelType,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        self.sendShareUserCardMessage(context: context,
                                      shareChatterId: shareChatterId,
                                      sendChannelType: sendChannelType,
                                      createScene: nil,
                                      sendMessageTracker: sendMessageTracker,
                                      stateHandler: stateHandler)
    }

    func sendShareUserCardMessage(
        context: APIContext?,
        shareChatterId: String,
        sendChannelType: SendChannelType,
        createScene: Basic_V1_CreateScene? = nil,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        queue.async {
            let model = SendShareUserCardModel(shareChatterId: shareChatterId, sendChannelType: sendChannelType, createScene: createScene)
            self.sendShareUserCardProcess.run(input: SendMessageProcessInput<SendShareUserCardModel>(
                context: context,
                model: model,
                stateHandler: stateHandler,
                sendMessageTracker: sendMessageTracker)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    enum CustomError: Error {
        case selfIsNil
    }

    func sendShareAppCardMessage(
        context: APIContext?,
        type: ShareAppCardType,
        chatId: String
    ) -> Observable<Void> {
        var req = ServerPB_Appshare_ShareAppCardV2Request()
        var typeStr = "unknown"
        switch type {
        case .unknown:
            assertionFailure()
        case let .app(appID, url):
            typeStr = "app"
            var shareApp = ServerPB_Appshare_ShareApp()
            shareApp.appID = appID
            shareApp.cardLink = ServerPB_Appshare_CardLink()
            shareApp.cardLink.href = url
            shareApp.chatIdsStr = [chatId]
            req.app = shareApp
            req.type = .shareApp
        case let .appPage(appID, title, iconToken, url, appLinkHref, options):
            typeStr = "appPage"
            var shareAppPage = ServerPB_Appshare_ShareAppPage()
            shareAppPage.appID = appID
            if let imgKey = iconToken {
                shareAppPage.imgKey = imgKey
            }
            shareAppPage.title = title
            shareAppPage.cardLink = ServerPB_Appshare_CardLink()
            shareAppPage.cardLink.href = url
            if let appLinkHref = appLinkHref {
                if options.contains(.IOS) {
                    shareAppPage.cardLink.iosHref = appLinkHref
                }
                if options.contains(.Android) {
                    shareAppPage.cardLink.androidHref = appLinkHref
                }
                if options.contains(.PC) {
                    shareAppPage.cardLink.pcHref = appLinkHref
                }
            }
            shareAppPage.chatIdsStr = [chatId]
            req.appPage = shareAppPage
            req.type = .shareAppPage
        case let .h5(appId, title, iconToken, desc, url):
            typeStr = "h5"
            var shareH5 = ServerPB_Appshare_ShareH5()
            if let appId = appId {
                shareH5.appID = appId
            }
            shareH5.title = title
            if let imgKey = iconToken {
                shareH5.imgKey = imgKey
            }
            shareH5.description_p = desc
            shareH5.cardLink = ServerPB_Appshare_CardLink()
            shareH5.cardLink.href = url
            shareH5.chatIdsStr = [chatId]
            req.h5 = shareH5
            req.type = .shareAppH5
        @unknown default:
            assertionFailure()
        }
        Self.logger.info("send shareAppCard", additionalData: [
            "type": "\(typeStr)"
        ])
        return client.sendPassThroughAsyncRequest(req, serCommand: .appShareV2)
    }

    func sendShareAppCard(
        context: APIContext?,
        type: ShareAppCardType,
        chatId: String
    ) -> Observable<String?> {
        var req = ShareAppCardRequest()
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chatId
        channel.type = .chat
        req.channel = channel
        req.type = .card
        req.content = QuasiContent()

        switch type {
        case .unknown:
            assertionFailure()
        case .app(let appID, let url):
            var shareApp = RustPB.Im_V1_ShareApp()
            shareApp.appID = appID
            shareApp.cardLink = RustPB.Im_V1_CardLink()
            shareApp.cardLink.href = url
            req.app = shareApp
            req.shareType = .app
        case .appPage(let appID, let title, let iconToken, let url, let appLinkHref, let options):
            var shareApp = RustPB.Im_V1_ShareAppPage()
            shareApp.appID = appID
            shareApp.imgKey = iconToken ?? ""
            shareApp.title = title
            shareApp.cardLink = RustPB.Im_V1_CardLink()
            shareApp.cardLink.href = url
            if let appLinkHref = appLinkHref {
                if options.contains(.IOS) {
                    shareApp.cardLink.iosHref = appLinkHref
                }
                if options.contains(.Android) {
                    shareApp.cardLink.androidHref = appLinkHref
                }
                if options.contains(.PC) {
                    shareApp.cardLink.pcHref = appLinkHref
                }
            }
            req.appPage = shareApp
            req.shareType = .appPage
        case .h5(_, let title, let iconToken, let desc, let url):
            var shareH5 = RustPB.Im_V1_ShareH5()
            shareH5.title = title
            shareH5.imgKey = iconToken ?? ""
            shareH5.description_p = desc
            shareH5.cardLink = RustPB.Im_V1_CardLink()
            shareH5.cardLink.href = url
            req.h5 = shareH5
            req.shareType = .h5
        @unknown default:
            assertionFailure()
        }
        var pack = RequestPacket(message: req)
        pack.parentID = context?.contextID

        let ob = client.async(pack).flatMap { [weak self] (response: ShareAppCardResponse) -> Observable<SendResult> in
            guard let self = self else {
                return .error(CustomError.selfIsNil)
            }
            return RustSendMessageModule.sendMessage(cid: response.cid, client: self.client, context: context)
        }.map { $0.messageId }
        return ob
    }

    func sendGroupShare(
        context: APIContext?,
        sharChatId: String,
        chatId: String,
        threadId: String?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        self.sendGroupShare(context: context,
                            sharChatId: sharChatId,
                            chatId: chatId,
                            threadId: threadId,
                            createScene: nil,
                            stateHandler: stateHandler)
    }

    func sendGroupShare(
        context: APIContext?,
        sharChatId: String,
        chatId: String,
        threadId: String?,
        createScene: Basic_V1_CreateScene? = nil,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        queue.async {
            let model = SendGroupShareModel(chatId: chatId, threadId: threadId, shareChatId: sharChatId, createScene: createScene)
            self.sendGroupShareProcess.run(input: SendMessageProcessInput<SendGroupShareModel>(
                context: context,
                model: model,
                rootId: threadId,
                parentId: threadId,
                stateHandler: stateHandler)) { [weak self] res in
                    self?.processSendResponse(res)
            }
        }
    }

    func resendMessage(message: LarkModel.Message) {
        queue.async {
            self.resendMessage(context: nil, message: message)
        }
    }

    func dealSendingMessage(
        message: LarkModel.Message,
        replyInThread: Bool,
        parentMessage: LarkModel.Message? = nil,
        chatFromWhere: String?
    ) {
        RustSendMessageAPI.logger.info("sendTrace dealSendingMessage \(message.cid)")
        if let parentMessage = parentMessage {
            message.parentMessage = parentMessage
            if replyInThread {
                message.rootMessage = parentMessage
            } else {
                if parentMessage.rootId.isEmpty {
                    message.rootMessage = parentMessage
                } else {
                    message.rootMessage = parentMessage.rootMessage
                }
            }
        }
        self.pushCenter.post(PushChannelMessage(message: message))
        self.pushCenter.post(PushChannelMessages(messages: [message]))
        DispatchQueue.global().async {
            if let chat = (try? self.chatAPI.getLocalChats([message.channel.id]))?.first?.value {
                LarkSendMessageTracker.trackSendMessage(
                    message,
                    chat: chat,
                    messageSummerize: self.dependency.messageSummerize,
                    isSupportURLType: self.dependency.isSupportURLType,
                    chatFromWhere: chatFromWhere)
                self.dependency.trackClickMsgSend(chat, message, chatFromWhere: chatFromWhere)
            }
        }
    }
}

public typealias SerialProcess = FlowChartSerialProcess
public typealias ConditionProcess = FlowChartConditionProcess

extension RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum {
    func transform() -> Message.DisplayMode {
        switch self {
        case .default:
            return .default
        case .thread:
            return .thread
        case .unknown:
            return .unknownDisplayMode
        }
    }
}
