//
//  VideoMessageSend.swift
//  Pods
//
//  Created by K3 on 2018/9/28.
//

import UIKit
import Foundation
import Photos // PHAsset
import RxSwift // DisposeBag
import LarkModel // Message
import EENavigator // NavigatorFrom
import UniverseDesignToast // UDToast
import LKCommonsLogging // Logger
import LarkAlertController // LarkAlertController
import RustPB // Basic_V1_DynamicNetStatusResponse
import LarkSDKInterface // SDKRustService
import ThreadSafeDataStructure // SafeSet
import LarkFoundation // FileUtils
import LarkContainer // InjectedLazy
import TTVideoEditor // VEConfigCenter
import LarkFoundation // Utils
import LKCommonsTracker // Tracker
import LarkCache // LarkCache
import Reachability // Reachability
import LarkVideoDirector // VideoEditorManager
import LarkStorage // @KVConfig
import LarkSetting
import LarkSensitivityControl

private typealias Path = LarkSDKInterface.PathWrapper

@frozen
public enum SendVideoContent {
    case asset(PHAsset)
    case fileURL(URL)
}

public struct SendVideoParams {
    public var content: SendVideoContent
    public var isCrypto: Bool
    public var isOriginal: Bool
    /// 以附件形式发送
    public var forceFile: Bool
    public var chatId: String
    public var threadId: String?
    public var parentMessage: LarkModel.Message?
    public var from: NavigatorFrom

    public init(content: SendVideoContent,
                isCrypto: Bool,
                isOriginal: Bool,
                forceFile: Bool,
                chatId: String,
                threadId: String?,
                parentMessage: LarkModel.Message?,
                from: NavigatorFrom) {
        self.content = content
        self.isCrypto = isCrypto
        self.isOriginal = isOriginal
        self.forceFile = forceFile
        self.chatId = chatId
        self.threadId = threadId
        self.parentMessage = parentMessage
        self.from = from
    }
}

public protocol VideoMessageSendService {
    /// 视频转码进度
    var compressProgessObservable: Observable<(String, Double)> { get }
    func compressProgessObservable(key: String) -> Observable<Double>

    /// 发送视频
    func sendVideo(with params: SendVideoParams,
                   extraParam: [String: Any]?,
                   context: APIContext?,
                   createScene: Basic_V1_CreateScene?,
                   sendMessageTracker: SendMessageTrackerProtocol?,
                   resourceManager: ResourcePreProcessManager?,
                   stateHandler: ((SendMessageState) -> Void)?)

    /// 视频预处理
    func preprocessVideo(with content: SendVideoContent, isOriginal: Bool, scene: VideoPreprocessScene, preProcessManager: ResourcePreProcessManager?)

    /// 视频预测处理
    func checkPreprocessVideoIfNeeded(result: PHFetchResult<PHAsset>, preProcessManager: ResourcePreProcessManager?)

    /// 获取视频信息
    func getVideoInfo(
        with content: SendVideoContent,
        isOriginal: Bool,
        setting: VideoSendSetting,
        extraParam: [String: Any]?,
        resultHandler: @escaping (VideoParseInfo?, Error?) -> Void
    )
    func getVideoInfo(
        with content: SendVideoContent,
        isOriginal: Bool,
        extraParam: [String: Any]?,
        resultHandler: @escaping (VideoParseInfo?, Error?) -> Void
    )

    func resendVideoMessage(_ message: Message, from: NavigatorFrom)
    /// remove compress task by `messageID` 通过`messageid`移除压缩任务

    func cancel(messageCID: String, isDelete: Bool)

    /// 视频转码
    func transcode(
        key: String,
        form: String,
        to: String,
        isOriginal: Bool,
        videoSize: CGSize,
        extraInfo: [String: Any],
        progressBlock: ProgressHandler?,
        dataBlock: VideoDataCBHandler?,
        retryBlock: (() -> Void)?
    ) -> Observable<TranscodeInfo>

    /// 取消视频转码
    func cancelVideoTranscode(key: String)

    // 单测工程中使用，CI中单测包是DEBUG环境
    #if ALPHA
    func setCompressProgress(key: String, progress: Double)
    func cleanCompressProgress(key: String)
    #endif
}

/// 兼容接口
public extension VideoMessageSendService {
    /// 发送视频
    func sendVideo(with params: SendVideoParams,
                   extraParam: [String: Any]?,
                   context: APIContext?,
                   createScene: Basic_V1_CreateScene? = nil,
                   sendMessageTracker: SendMessageTrackerProtocol?,
                   stateHandler: ((SendMessageState) -> Void)?) {
        sendVideo(with: params, extraParam: extraParam, context: context,
                  createScene: createScene, sendMessageTracker: sendMessageTracker, resourceManager: nil, stateHandler: stateHandler)
    }
}

final class TranscodeTask {

    enum TaskType {
        case normal
        case preprocess
    }

    /// 唯一 ID
    var id: String

    /// 任务类型
    var type: TaskType

    /// 是否是"原图"模式
    var isOriginal: Bool

    /// 视频转码Key
    var key: String

    /// 视频时长(s)
    var duration: Int32

    /// 视频压缩前大小
    var size: UInt64

    /// 视频导出路径
    var exportPath: String

    /// 视频压缩路径
    var compressPath: String

    /// 视频宽高尺寸
    var videoSize: CGSize

    /// 是否 PHAsset 视频
    var isPHAssetVideo: Bool

    /// 视频首帧图大小
    var compressCoverFileSize: Float

    /// UI 上线文
    weak var from: NavigatorFrom?

    // 分片上传组件
    var chunkuploader: VideoChunkUploader

    /// 发送闭包
    /// compressCost: 压缩处理时长
    var sender: (_ compressCost: TimeInterval?) -> Void

    // TODO: 似乎没有用这个属性
    /// 转码状态回调
    var stateHandler: ((SendMessageState) -> Void)?

    /// 打点类
    var sendMessageTracker: SendMessageTrackerProtocol?

    var preProcessManager: ResourcePreProcessManager?

    /// 打包参数
    var context: APIContext?

    /// 任务是否已经结束（完成/被取消）
    var finished: Bool = false

    /// 是否是合并任务
    var isMerge: Bool = false

    /// 用户自定义额外参数
    var extraInfo: [String: Any] = [:]

    /// 开始转码时间
    var startTime: TimeInterval = 0

    /// 预转码持续时间
    var preDuration: TimeInterval = 0

    /// 上屏后的创建时间
    var createTime: TimeInterval

    /// 视频上次修改时间
    public var modificationDate: TimeInterval

    /// 视频任务创建时间
    public var taskCreateDate: TimeInterval

    /// 是否可以透传视频
    public var canPassthrough: Bool

    public init(
        userResolver: UserResolver,
        id: String,
        context: APIContext? = nil,
        type: TaskType,
        isOriginal: Bool,
        key: String,
        duration: Int32,
        size: UInt64,
        exportPath: String,
        compressPath: String,
        videoSize: CGSize,
        isPHAssetVideo: Bool,
        canPassthrough: Bool,
        compressCoverFileSize: Float,
        modificationDate: TimeInterval,
        from: NavigatorFrom?,
        sender: @escaping (_ compressCost: TimeInterval?) -> Void,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        preProcessManager: ResourcePreProcessManager? = nil,
        stateHandler: ((SendMessageState) -> Void)?
    ) throws {
        self.id = id
        self.context = context
        self.type = type
        self.isOriginal = isOriginal
        self.key = key
        self.duration = duration
        self.size = size
        self.exportPath = exportPath
        self.compressPath = compressPath
        self.videoSize = videoSize
        self.isPHAssetVideo = isPHAssetVideo
        self.compressCoverFileSize = compressCoverFileSize
        self.modificationDate = modificationDate
        self.from = from
        self.sender = sender
        self.stateHandler = stateHandler
        self.sendMessageTracker = sendMessageTracker
        self.preProcessManager = preProcessManager
        self.createTime = CACurrentMediaTime()
        self.taskCreateDate = Date().timeIntervalSince1970
        self.canPassthrough = canPassthrough
        self.chunkuploader = try VideoChunkUploader(userResolver: userResolver)
        VideoMessageSend.logger.info("video task init \(self)")
    }

    deinit {
        VideoMessageSend.logger.info("video task deinit \(self)")
    }

}

/// 视频预压缩场景
public enum VideoPreprocessScene: String {
    /// 勾选视频时
    case selectVideo = "select_video"
    /// 点开视频预览时
    case previewVideo = "preview_video"
    /// 打开相册时（压缩最近的视频）
    case openAlbum = "open_album"
    /// 系统分享
    case shareFromSystem = "share_from_system"
}

final class VideoMessageSend: VideoMessageSendService, UserResolverWrapper {
    let userResolver: UserResolver

    static let logger = Logger.log(VideoMessageSend.self, category: "Module.IM.VideoMessageSend")
    private let disposeBag = DisposeBag()

    private let sendQueue = DispatchQueue(label: "video_send_queue", qos: .userInteractive)
    private let chunkQueue = DispatchQueue(label: "video_chunk_queue", qos: .userInteractive)
    private lazy var sendScheduler = SerialDispatchQueueScheduler(queue: sendQueue, internalSerialQueueName: sendQueue.label)

    private let sendMessageAPI: SendMessageAPI
    private let transcodeService: VideoTranscodeService
    private var userGeneralSettings: UserGeneralSettings
    private var sendingManager: SendingMessageManager
    private let client: SDKRustService

    private var deleteOriginVideoAfterSuccess: Bool { userResolver.fg.staticFeatureGatingValue(with: "messenger.send.video.delete_origin_video") }

    /// 存放所有获取视频信息的任务
    private var tasks: SafeSet<VideoParseTask> = SafeSet<VideoParseTask>([], synchronization: .semaphore)
    /// 预处理解析任务
    private var preprocessSet: SafeSet<VideoParseTask> = SafeSet<VideoParseTask>([], synchronization: .semaphore)

    /// 记录将要转码的所有消息cid，假消息创建成功后插入
    private var items: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)
    /// 记录将要转码的任务，每次转码时取第一个，串行转码
    private var transcodeTasks: SafeArray<TranscodeTask> = [] + .semaphore

    private var chunkUploadTasks: SafeArray<TranscodeTask> = [] + .semaphore

    /// 当前转码任务
    private var inTranscodingTask: TranscodeTask?

    private lazy var localVideoCache: LarkCache.Cache = sendVideoCache(userID: userResolver.userID)

    /// 进度缓存
    private var progressCacheDic: SafeDictionary<String, Double> = [:] + .semaphore

    private var _compressProgessPublish = PublishSubject<(String, Double)>()
    var compressProgessObservable: Observable<(String, Double)> { return _compressProgessPublish.asObservable() }

    /// 文件导出 hud
    private var exportFileHUD: UDToast?

    /// rust 网络状态
    private var netStatus: Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent
    private let reachability = Reachability()

    /// 当前是否是弱网
    private var isWeakNetwork: Bool {
        let weakNetStatus: [Basic_V1_DynamicNetStatusResponse.NetStatus] = [
            .weak, .netUnavailable, .serviceUnavailable
        ]
        VideoMessageSend.logger.info("current currentNetStatus is \(self.netStatus)")
        if weakNetStatus.contains(self.netStatus),
           reachability?.connection != .none {
            VideoMessageSend.logger.info("isWeakNetwork check is true")
            return true
        }
        return false
    }

    private static let store = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("SendMessage"))

    //上次检测预压缩的视频时间
    @KVConfig(key: "lastCheckPreprocessTime", store: store)
    private var lastCheckPreprocessTime: TimeInterval?

    /// 视频透传检测器，只在视频预处理、预测处理时使用
    private let passChecker: VideoPassChecker

    /// 视频解析器
    private let parseManager = VideoParseTaskManager()

    init(userResolver: UserResolver, sendMessageAPI: SendMessageAPI, transcodeService: VideoTranscodeService, client: SDKRustService, pushDynamicNetStatus: Observable<PushDynamicNetStatus>) throws {
        self.userResolver = userResolver
        self.sendMessageAPI = sendMessageAPI
        self.transcodeService = transcodeService
        self.client = client
        self.userGeneralSettings = try userResolver.resolve(assert: UserGeneralSettings.self)
        self.sendingManager = try userResolver.resolve(assert: SendingMessageManager.self)
        self.passChecker = try VideoPassChecker(userResolver: userResolver)

        // 监听Rust网络状态
        pushDynamicNetStatus.subscribe(onNext: { [weak self] (push) in
            self?.netStatus = push.dynamicNetStatus
        }).disposed(by: self.disposeBag)

        /// 初始化 vesdk log
        VideoEditorManager.shared.setupVideoEditorIfNeeded()

        try? self.reachability?.startNotifier()
        SendVideoLogger.debug("VideoMessageSend init", .lifeCycle, pid: "", cid: "")
    }

    /// 获取视频转码进度
    func compressProgessObservable(key: String) -> Observable<Double> {
        var valueSignal = self.compressProgessObservable
            .filter({ (taskKey, _) -> Bool in
                return taskKey == key
            })
            .map({ (_, progress) -> Double in
                return progress
            })
        if let progress = self.progressCacheDic[key] {
            valueSignal = valueSignal.startWith(progress)
        }
        return valueSignal
    }

    /// 更新视频转码进度
    func setCompressProgress(key: String, progress: Double) {
        VideoMessageSend.logger.info("set video key \(key) compress progress \(progress)")
        self.progressCacheDic[key] = progress
        self._compressProgessPublish.onNext((key, progress))
    }

    /// 清除视频转码进度
    func cleanCompressProgress(key: String) {
        VideoMessageSend.logger.info("clean video key \(key) compress progress")
        self.progressCacheDic[key] = nil
    }

    private func videoParseTask(with content: SendVideoContent,
                                isOriginal: Bool,
                                pid: String,
                                cid: String,
                                videoSendSetting: VideoSendSetting? = nil,
                                type: VideoParseType = .normal) throws -> VideoParseTask {
        let videoSendSetting = videoSendSetting ?? userGeneralSettings.videoSynthesisSetting.value.sendSetting
        let data: SendVideoContent
        if case .asset(let asset) = content, let url = asset.editVideo {
            // 视频编辑过，则发送编辑后的视频
            data = .fileURL(url)
        } else {
            data = content
        }
        return try VideoParseTask(
            userResolver: userResolver,
            data: data,
            isOriginal: isOriginal,
            type: type,
            transcodeService: self.transcodeService,
            videoSendSetting: videoSendSetting,
            taskID: pid,
            contentID: cid
        )
    }

    /// 以附件模式发送消息
    private func sendFile(
        with info: VideoParseTask.VideoInfo,
        context: APIContext?,
        chatId: String,
        threadId: String?,
        replyInThread: Bool,
        parentMessage: LarkModel.Message?,
        createScene: Basic_V1_CreateScene?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        let context = APIContext(contextID: "")
        context.set(key: APIContext.replyInThreadKey, value: replyInThread)
        self.sendQueue.async { [weak self] in
            self?.sendMessageAPI.sendFile(
                context: context,
                path: info.exportPath,
                name: info.name,
                parentMessage: parentMessage,
                removeOriginalFileAfterFinish: false,
                chatId: chatId,
                threadId: threadId,
                createScene: createScene,
                sendMessageTracker: sendMessageTracker,
                stateHandler: stateHandler)
        }
    }

    /// 按照文件形式发送视频
    private func sendFile(
        asset: PHAsset,
        isOriginal: Bool,
        context: APIContext?,
        chatId: String,
        threadId: String?,
        parentMessage: LarkModel.Message?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        guard let cachePath = VideoParser.createVideoSaveURL(userID: userResolver.userID, asset: asset, isOriginal: isOriginal),
          let resouce = VideoParser.videoAssetResources(for: asset) else {
              return
        }
        let exportPath = cachePath.path + ".mov"
        let sendFile = { [weak self] in
            self?.sendQueue.async { [weak self] in
                self?.sendMessageAPI.sendFile(
                    context: context,
                    path: exportPath,
                    name: resouce.originalFilename,
                    parentMessage: parentMessage,
                    removeOriginalFileAfterFinish: false,
                    chatId: chatId,
                    threadId: threadId,
                    sendMessageTracker: sendMessageTracker,
                    stateHandler: stateHandler)
            }
        }
        // 如果文件已经存在则直接发送
        if Path(exportPath).exists {
            VideoMessageSend.logger.info("send file block")
            sendFile()
        } else if let outputURL = URL(string: exportPath) {
            VideoMessageSend.logger.info("export file data")
            DispatchQueue.main.async {
                // 无UI上下文，只能暂时取MainScene
                if let window = self.userResolver.navigator.mainSceneWindow {
                    self.exportFileHUD = UDToast.showLoading(
                        with: BundleI18n.LarkSendMessage.Lark_Legacy_VideoMessagePrepareToSend,
                        on: window,
                        disableUserInteraction: false)
                }
            }
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            _ = try? AlbumEntry.requestExportSession(forToken: Token("LARK-PSDA-VideoMessageSend_requestExportSession"),
                                                     manager: PHImageManager.default(),
                                                     forVideoAsset: asset,
                                                     options: options,
                                                     exportPreset: AVAssetExportPresetPassthrough,
                                                     resultHandler: { (exportSession, _) in
                guard let exportSession = exportSession else {
                    return
                }
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.mov
                exportSession.exportAsynchronously(completionHandler: {
                    switch exportSession.status {
                    case .completed:
                        VideoMessageSend.logger.info("export file data finish")
                        DispatchQueue.main.async {
                            self.exportFileHUD?.remove()
                            self.exportFileHUD = nil
                        }
                        sendFile()
                    default:
                            VideoMessageSend.logger.error("export file data failed \(exportSession.status.rawValue) \(exportSession.error)")
                        DispatchQueue.main.async {
                            self.exportFileHUD?.remove()
                            self.exportFileHUD = nil
                            if let window = self.userResolver.navigator.mainSceneWindow {
                                UDToast.showFailure(
                                    with: BundleI18n.LarkSendMessage.Lark_Legacy_ComposePostVideoReadDataError,
                                    on: window
                                )
                            }
                        }
                    }
                })
            })
        }
    }

    /// 以视频模式发送消息，过程分为
    /// - 创建假消息
    /// - 透传检测
    /// - 转码
    /// - 发送
    // swiftlint:disable function_parameter_count
    private func sendVideo(
        with info: VideoParseTask.VideoInfo,
        context: APIContext?,
        isOriginal: Bool,
        chatId: String,
        threadId: String?,
        parentMessage: LarkModel.Message?,
        from: NavigatorFrom?,
        extraParam: [String: Any]? = nil,
        createScene: Basic_V1_CreateScene? = nil,
        sendMessageTracker: SendMessageTrackerProtocol?,
        preProcessManager: ResourcePreProcessManager?,
        stateHandler: ((SendMessageState) -> Void)?
    ) {
        Tracker.post(TeaEvent("send_video_start_dev", params: [:]))
        let pid = extraParam?["processId"] as? String ?? SendVideoLogger.IDGenerator.uniqueID
        let cid = extraParam?["contentId"] as? String ?? ""
        let deleteOriginVideoAfterSuccess = self.deleteOriginVideoAfterSuccess
        let wrappedStateHandler: ((SendMessageState) -> Void) = { state in
            // 发送成功后删除原视频文件，减少空间占用
            if case .finishSendMessage(let message, _, _, _, _) = state {
                guard deleteOriginVideoAfterSuccess else { return }
                if let mediaContent = message.content as? MediaContent {
                    let originPath = mediaContent.originPath
                    do {
                        try Path(originPath).deleteFile()
                        SendVideoLogger.info("delete origin video at \(originPath)", .send, pid: pid, cid: cid)
                    } catch {
                        SendVideoLogger.warn("delete origin video failed: \(error), \(originPath)", .send, pid: pid, cid: cid)
                    }
                }
            }
            stateHandler?(state)
        }
        self.sendQueue.async { [weak self] in
            guard let self = self else { return }
            SendVideoLogger.info("start create media quasi message", .send, pid: pid, cid: cid)
            let context = context ?? APIContext(contextID: "")
            if let extraParam = extraParam,
                let lastMessagePosition = extraParam["lastMessagePosition"],
                let quasiMsgCreateByNative = extraParam["quasiMsgCreateByNative"],
                let chatDisplayMode = extraParam[APIContext.chatDisplayModeKey] {
                context.lastMessagePosition = lastMessagePosition as? Int32
                context.quasiMsgCreateByNative = quasiMsgCreateByNative as? Bool
                context.chatDisplayMode = chatDisplayMode as? RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum
            }
            if let replyInThreadValue = extraParam?[APIContext.replyInThreadKey] as? Bool {
                context.set(key: APIContext.replyInThreadKey, value: replyInThreadValue)
            }
            // 取出 video 的秒传 key
            context.preprocessResourceKey = preProcessManager?.getSwiftKey(type: .media(info.compressPath))
            // 调用发送接口创建假消息
            self.sendMessageAPI.sendMedia(
                context: context,
                params: SendMediaParams(
                    exportPath: info.exportPath,
                    compressPath: info.compressPath,
                    name: info.name,
                    image: info.preview,
                    imageData: info.firstFrameData,
                    mediaSize: info.naturalSize,
                    duration: Int32(info.duration * 1000),
                    chatID: chatId,
                    threadID: threadId,
                    parentMessage: parentMessage,
                    createScene: createScene
                ),
                handler: { [weak self, weak from] (message, sender) in
                    guard let self = self, let message = message else { return }
                    SendVideoLogger.info("end create media quasi message", .send, pid: pid + "-" + message.cid, cid: cid,
                                         params: ["processId": pid, "message_cid": message.cid, "contentId": cid])

                    // 是否可以透传
                    let passthroughResult = self.passChecker.videoCanPassthrough(videoInfo: info, isOriginal: isOriginal)
                    // 创建转码任务
                    guard let task = try? TranscodeTask(
                        userResolver: self.userResolver,
                        id: pid,
                        context: context,
                        type: .normal,
                        isOriginal: isOriginal,
                        key: message.cid,
                        duration: Int32(info.duration),
                        size: info.filesize,
                        exportPath: info.exportPath,
                        compressPath: info.compressPath,
                        videoSize: info.naturalSize,
                        isPHAssetVideo: info.isPHAssetVideo,
                        canPassthrough: passthroughResult,
                        compressCoverFileSize: Float(info.firstFrameData?.count ?? 0) / 1024 / 1024,
                        modificationDate: info.modificationDate,
                        from: from,
                        sender: sender,
                        sendMessageTracker: sendMessageTracker,
                        stateHandler: wrappedStateHandler
                    ) else { return }
                    task.extraInfo[VideoChunkUploader.messageKey] = message

                    self.items.insert(message.cid)
                    self.sendingManager.add(task: message.cid)

                    // 调用异步发送
                    self.asyncSendVideoMessage(task: task)
                },
                sendMessageTracker: sendMessageTracker,
                stateHandler: wrappedStateHandler)
        }
    }
    // swiftlint:enable function_parameter_count

    //获取视频相关信息
    func getVideoInfo(
        with content: SendVideoContent,
        isOriginal: Bool,
        extraParam: [String: Any]?,
        resultHandler: @escaping (VideoParseInfo?, Error?) -> Void
    ) {
        self.getVideoInfo(
            with: content,
            isOriginal: isOriginal,
            setting: self.userGeneralSettings.videoSynthesisSetting.value.sendSetting,
            extraParam: extraParam,
            resultHandler: resultHandler)
    }

    func getVideoInfo(
        with content: SendVideoContent,
        isOriginal: Bool,
        setting: VideoSendSetting,
        extraParam: [String: Any]?,
        resultHandler: @escaping (VideoParseInfo?, Error?) -> Void
    ) {
        let pid = SendVideoLogger.IDGenerator.uniqueID
        let cid = SendVideoLogger.IDGenerator.contentID(for: content, origin: isOriginal)
        SendVideoLogger.info("getVideoInfo start parse", .parseInfo, pid: pid, cid: cid)
        guard let task = try? self.videoParseTask(with: content, isOriginal: isOriginal, pid: pid, cid: cid,
                                             videoSendSetting: setting, type: .normal)
        else { return }
        self.tasks.insert(task)
        self.getParseInfo(task: task).subscribe(onNext: { (info) in
            SendVideoLogger.info("parse video success", .parseInfo, pid: pid, cid: cid)
            VideoMessageSend.logger.info("parse video success \(info.status)")
            resultHandler(info, nil)
        }, onError: { (error) in
            VideoMessageSend.logger.error("parse video failed \(error)")
            resultHandler(nil, error)
        }, onDisposed: { [weak self, weak task] in
            guard let `self` = self, let task = task else { return }
            _ = self.tasks.remove(task)
        }).disposed(by: disposeBag)
    }

    /// 视频预测处理
    func checkPreprocessVideoIfNeeded(result: PHFetchResult<PHAsset>, preProcessManager: ResourcePreProcessManager?) {
        VideoMessageSend.logger.info("checkPreprocessVideoIfNeeded")
        let currentTime = Date()
        let filterConfig = self.userGeneralSettings.videoPreprocessConfig.value.filter
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            return
        }
        let filterMediaCount = filterConfig.mediaCount
        let filterVideoCount = filterConfig.videoCount
        let assetsCount = result.count
        let indexSet = IndexSet(integersIn: max(0, assetsCount - filterMediaCount)..<assetsCount)
        result.objects(at: indexSet)
            .reversed()
            .filter({ $0.mediaType == .video })
            .prefix(filterVideoCount)
            .forEach { asset in
                let pid = SendVideoLogger.IDGenerator.preprocessID
                guard let creationDate = asset.creationDate else {
                    SendVideoLogger.warn("cannot find creationDate for asset, ignore \(asset)", .preprocess, pid: pid, cid: "")
                    return
                }
                guard let lastCheckPreprocessTime = self.lastCheckPreprocessTime,
                   lastCheckPreprocessTime < creationDate.timeIntervalSince1970 else {
                    SendVideoLogger.info("later than lastCheckPreprocessTime, ignore \(asset)", .preprocess, pid: pid, cid: "")
                    return
                }
                self.lastCheckPreprocessTime = creationDate.timeIntervalSince1970

                // 最近添加的视频才压缩，老视频不压缩
                guard creationDate.timeIntervalSince1970 + filterConfig.interval > currentTime.timeIntervalSince1970 else {
                    self.postPredictResult(type: "none", cpu: -1, scene: .openAlbum, failReason: "not new video")
                    SendVideoLogger.info("old video, ignore \(asset)", .preprocess, pid: pid, cid: "")
                    return
                }
                self.preprocessVideo(with: .asset(asset), isOriginal: false, scene: .openAlbum, pid: pid, preProcessManager: preProcessManager)
            }
    }

    func preprocessVideo(with content: SendVideoContent, isOriginal: Bool, scene: VideoPreprocessScene, preProcessManager: ResourcePreProcessManager?) {
        self.preprocessVideo(with: content, isOriginal: isOriginal, scene: scene, pid: nil, preProcessManager: preProcessManager)
    }

    private func preprocessVideo(with content: SendVideoContent, isOriginal: Bool,
                                 scene: VideoPreprocessScene, pid: String?, preProcessManager: ResourcePreProcessManager?) {
        if VideoDebugKVStore.videoDebugEnable, !VideoDebugKVStore.preprocessVideo {
            SendVideoLogger.warn("preprocess is disabled by debug", .preprocess, pid: "", cid: "")
            return
        }
        let preCompressConfig = self.userGeneralSettings.videoPreprocessConfig.value.compress
        let switcher = preCompressConfig.compressSwitch // TODO: compress 流程单独拆开
        switch scene {
        case .selectVideo:
            guard switcher.selectVideoEnable else { return }
        case .previewVideo:
            guard switcher.previewVideoEnable else { return }
        case .openAlbum:
            guard switcher.openAlbumEnable else { return }
        case .shareFromSystem:
            guard switcher.shareFromSystemEnable else { return }
        }
        let mediaDiskUtil = MediaDiskUtil(userResolver: userResolver)

        let pid = pid ?? SendVideoLogger.IDGenerator.preprocessID
        let cid = SendVideoLogger.IDGenerator.contentID(for: content, origin: isOriginal)

        // CPU 过高不压缩
        let cpuUsageLimit = preCompressConfig.limit.cpuUsage
        let averageCPUUsage = (try? Utils.averageCPUUsage) ?? 100
        guard cpuUsageLimit > averageCPUUsage else {
            self.postPredictResult(type: "none", cpu: averageCPUUsage, scene: scene, failReason: "cpu too high")
            SendVideoLogger.info("CPU too high: \(averageCPUUsage), ignore \(content)", .preprocess, pid: pid, cid: cid)
            return
        }

        // 检查是否有空间预处理
        guard mediaDiskUtil.checkVideoPreprocessEnable(content: content) else {
            self.postPredictResult(type: "none", cpu: -1, scene: scene, failReason: "disk not enough")
            SendVideoLogger.info("Disk not enough, ignore \(content)", .preprocess, pid: pid, cid: cid)
            return
        }
        self.postPredictResult(type: "compress", cpu: averageCPUUsage, scene: scene)

        SendVideoLogger.debug("start scene: \(scene)", .preprocess, pid: pid, cid: cid)
        SendVideoLogger.info("parse video start \(content)", .preprocess, pid: pid, cid: cid)
        guard let task = try? self.videoParseTask(
            with: content,
            isOriginal: isOriginal,
            pid: pid,
            cid: cid,
            type: .preprocess
        ) else { return }
        self.preprocessSet.insert(task)
        self.getParseInfoWithPassCheck(task: task).subscribe(onNext: { [weak self] (info) in
            guard let `self` = self else { return }
            SendVideoLogger.info("parse video success \(info.status)", .preprocess, pid: pid, cid: cid)
            if info.status == .fillBaseInfo,
               // 如果视频能直接透传，则不需要转码直接发送
                !self.passChecker.videoCanPassthrough(videoInfo: info, isOriginal: isOriginal) {
                guard let task = try? TranscodeTask(
                    userResolver: self.userResolver,
                    id: pid,
                    type: .preprocess,
                    isOriginal: isOriginal,
                    key: cid,
                    duration: Int32(info.duration),
                    size: info.filesize,
                    exportPath: info.exportPath,
                    compressPath: info.compressPath,
                    videoSize: info.naturalSize,
                    isPHAssetVideo: info.isPHAssetVideo,
                    canPassthrough: false,
                    compressCoverFileSize: Float(info.firstFrameData?.count ?? 0) / 1024 / 1024,
                    modificationDate: info.modificationDate,
                    from: nil,
                    // sender设置为空：1.预转码完成用户没点发送则不做任何事情，2.预处理完成前用户点击发送sender会被重新赋值后走正常发送流程
                    sender: { _ in },
                    preProcessManager: preProcessManager,
                    stateHandler: nil
                ) else { return }
                self.asyncSendVideoMessage(task: task)
            }
            // 这里添加 (info.status == .fillBaseInfo && 透传通过) 增加秒传处理
            if info.status == .fillBaseInfo, self.passChecker.videoCanPassthrough(videoInfo: info, isOriginal: isOriginal), let preProcessManager {
                preProcessManager.onResourcesChanged([(.media(info.compressPath), .none, [.preSwiftTransmission])])
            }
        }, onError: { (error) in
            SendVideoLogger.error("parse video failed: \(error)", .preprocess, pid: pid, cid: cid)
        }, onDisposed: { [weak self, weak task] in
            guard let `self` = self, let task = task else { return }
            _ = self.preprocessSet.remove(task)
        }).disposed(by: disposeBag)
    }

    private func postPredictResult(type: String, cpu: Float, scene: VideoPreprocessScene, failReason: String? = nil) {
        Tracker.post(TeaEvent("video_predicte_compress_dev",
                              params: ["result": type,
                                       "cpuUsage": cpu,
                                       "scene": scene.rawValue,
                                       "fail_reason": failReason as Any]))
    }

    /// 发送视频
    func sendVideo(with params: SendVideoParams,
                   extraParam: [String: Any]? = nil,
                   context: APIContext?,
                   createScene: Basic_V1_CreateScene?,
                   sendMessageTracker: SendMessageTrackerProtocol?,
                   resourceManager: ResourcePreProcessManager?,
                   stateHandler: ((SendMessageState) -> Void)?) {
        let content = params.content
        /// 密聊，将改为附件发送
        let transformFile = params.isCrypto || params.forceFile
        let isOriginal = params.isOriginal
        let chatId = params.chatId
        let threadId = params.threadId
        let parentMessage = params.parentMessage
        let from = params.from
        let pid = SendVideoLogger.IDGenerator.uniqueID
        let cid = SendVideoLogger.IDGenerator.contentID(for: params.content, origin: isOriginal)
        var extraParam = extraParam ?? [:]
        extraParam["processId"] = pid
        extraParam["contentId"] = cid
        // 获取VideoParseTask对象，获取获取视频基本信息、判断是否能发送、是否以附件形式发送
        guard let task = try? videoParseTask(with: content, isOriginal: isOriginal, pid: pid, cid: cid) else { return }
        // 插入一个获取视频信息的任务
        self.tasks.insert(task)

        SendVideoLogger.info("start parsing", .send, pid: pid, cid: cid)
        sendMessageTracker?.beforeGetResource()
        // 取消所有透传检测任务
        self.passChecker.cancelAllTasks()
        self.getParseInfo(task: task, immediately: true).subscribe(onNext: { [weak self, weak from] (info) in
            sendMessageTracker?.afterGetResource()
            // (是不是直接文件发送, 获取成功的信息)
            switch (transformFile, info.status) {
            case (true, _):
                SendVideoLogger.info("force to send file", .send, pid: pid, cid: cid,
                                     params: ["isCrypto": "\(params.isCrypto)", "forceFile": "\(params.forceFile)"])
                self?.sendFile(
                    with: info,
                    context: context,
                    chatId: chatId,
                    threadId: threadId,
                    replyInThread: (extraParam[APIContext.replyInThreadKey] as? Bool) ?? false,
                    parentMessage: parentMessage,
                    createScene: createScene,
                    sendMessageTracker: sendMessageTracker,
                    stateHandler: stateHandler
                )
            // 正常发送
            case (false, .fillBaseInfo):
                SendVideoLogger.info("end parsing, normal send", .send, pid: pid, cid: cid)
                self?.sendVideo(
                    with: info,
                    context: context,
                    isOriginal: isOriginal,
                    chatId: chatId,
                    threadId: threadId,
                    parentMessage: parentMessage,
                    from: from,
                    extraParam: extraParam,
                    createScene: createScene,
                    sendMessageTracker: sendMessageTracker,
                    preProcessManager: resourceManager,
                    stateHandler: stateHandler
                )
            // 发送视频超出限制，将改为附件发送
            case (false, let status):
                SendVideoLogger.info("transform to send file", .send, pid: pid, cid: cid,
                                     params: ["parseStatus": "\(status)"])
                guard let self = self, let from = from else { return }

                self.showAlert(task.parser.sendWithFileI18n(status: info.status), from: from) { [weak self] in
                    self?.sendFile(
                        with: info,
                        context: context,
                        chatId: chatId,
                        threadId: threadId,
                        replyInThread: (extraParam[APIContext.replyInThreadKey] as? Bool) ?? false,
                        parentMessage: parentMessage,
                        createScene: createScene,
                        sendMessageTracker: sendMessageTracker,
                        stateHandler: stateHandler
                    )
                }
            }
        }, onError: { [weak self, weak from] (error) in
            SendVideoLogger.error("parse failed", .send, pid: pid, cid: cid, error: error)
            DispatchQueue.main.async {
                guard let self = self, let from = from else { return }
                let errorInfo = self.videoTranscodeErrorCodeWithMsg(error)
                sendMessageTracker?.transcodeFailed(context: context, code: errorInfo.0, errorMsg: errorInfo.1, cid: nil, info: nil)

                if let sendVideoError = error as? VideoParseTask.ParseError {
                    /// 视频解析失败, 降级为文件发送
                    if self.userGeneralSettings.videoSynthesisSetting.value.sendSetting.sendFileEnable,
                       case .asset(let asset) = params.content {
                        switch sendVideoError {
                        case .fileReachMax, .userCancel:
                            break
                        default:
                            SendVideoLogger.debug("show send video file alert", .send, pid: pid, cid: cid)
                            self.showAlert(
                                BundleI18n.LarkSendMessage.Lark_Legacy_ComposePostVideoReadDataError,
                                showCancel: true,
                                from: from,
                                onSure: { [weak self] in
                                    SendVideoLogger.debug("send video file on sure", .send, pid: pid, cid: cid)
                                    self?.sendFile(
                                        asset: asset,
                                        isOriginal: params.isOriginal,
                                        context: context,
                                        chatId: params.chatId,
                                        threadId: params.threadId,
                                        parentMessage: params.parentMessage,
                                        sendMessageTracker: sendMessageTracker,
                                        stateHandler: stateHandler)
                                })
                            return
                        }
                    }
                }
                /// 弹出错误提示
                self.sendVideoOnError(error, from: from)
            }
        }, onDisposed: { [weak self, weak task] in
            // 以下两个时机会被调用：
            // 1、self.disposeBag被释放；
            // 2、序列发射完所有元素（onError也算）。
            guard let `self` = self, let task = task else { return }
            // 清理当前任务，主要处理上面情况2，即时清理内存缓存数据
            _ = self.tasks.remove(task)
        }).disposed(by: disposeBag)
    }

    /// 重发视频消息
    ///
    /// - Parameter message: 假消息
    func resendVideoMessage(_ message: LarkModel.Message, from: NavigatorFrom) {
        guard let content = message.content as? LarkModel.MediaContent, !items.contains(message.cid) else {
            assert(false, "message type error or video is transcoding: \(message.cid)")

            VideoMessageSend.logger.error(
                "resend video: get 'MediaContent' error or video is transcoding",
                additionalData: ["messageId": message.cid]
            )

            return
        }

        guard let task = try? TranscodeTask(
            userResolver: userResolver,
            id: message.cid,
            type: .normal,
            isOriginal: content.originPath.contains(VideoParser.originPathSuffix),
            key: message.cid,
            duration: content.duration / 1000,
            size: UInt64(content.size),
            exportPath: content.originPath,
            compressPath: content.compressPath,
            // 重发消息没有分辨率信息，传zero让VideoTranscodeService内部重新获取一次
            videoSize: .zero,
            isPHAssetVideo: true,
            canPassthrough: false,
            compressCoverFileSize: 0,
            modificationDate: Date().timeIntervalSince1970,
            from: from,
            sender: { [weak self] _ in
                self?.sendMessageAPI.resendMessage(message: message)
            },
            sendMessageTracker: nil, // TODO: 重发消息不会有错误上报
            stateHandler: nil) else { return }

        task.extraInfo[VideoChunkUploader.messageKey] = message
        self.items.insert(message.cid)
        self.sendingManager.add(task: message.cid)
        self.sendMessageAPI.updateQuasiMessage(context: nil, cid: message.cid, status: .pending)
        self.asyncSendVideoMessage(task: task)
    }

    /// 取消某一个消息的发送，这个时候一定是假消息上屏后了，也就是说这时候肯定是在转码/上传阶段，不是在获取视频信息阶段
    func cancel(messageCID: String, isDelete: Bool) {
        Self.logger.info("click cancel video \(messageCID) isDelete \(isDelete)")
        // 队列中执行，保证transcodeTasks、items等属性线程安全
        self.sendQueue.async { [weak self] in
            guard let `self` = self else { return }
            if !isDelete {
                // 取消正在发送中的消息，目前在外部还会调用 cancel UploadFile 的 API， UploadFile 不适用与边压边传场景
                self.sendMessageAPI.cancelSendMessage(context: nil, cid: messageCID)
                // 更新假消息
                self.sendMessageAPI.updateQuasiMessage(context: nil, cid: messageCID, status: .failed)
            }
            // 如果当前视频正在转码，则取消转码
            if let transcodingTask = self.inTranscodingTask, transcodingTask.key == messageCID {
                self.transcodeService.cancelVideoTranscode(key: messageCID)
            }
            // 取消正在分片上传的 task
            let uploadingTasks = self.chunkUploadTasks.getImmutableCopy()
            uploadingTasks.forEach { task in
                if task.chunkuploader.uploading &&
                    task.key == messageCID {
                    task.chunkuploader.cancel(in: self.chunkQueue)
                }
            }
            // 删除转码任务，无需删除获取视频信息任务，因为此时肯定是获取完毕了的，因为消息上屏后才能点击取消
            _ = self.items.remove(messageCID)
            self.cleanCompressProgress(key: messageCID)
            self.sendingManager.remove(task: messageCID)
            self.transcodeTasks = self.transcodeTasks.filter({ $0.key != messageCID })
        }
    }

    fileprivate func cancelPreprocessTasksIfNeeded(for task: TranscodeTask) -> Bool {
        // 新的预处理任务不需要 cancel 之前的预处理任务
        if task.type == .preprocess {
            return false
        }
        // 清除之前的预处理任务
        self.preprocessSet.removeAll()
        self.transcodeTasks = self.transcodeTasks.filter({ task in
            return task.type == .normal
        })
        // 当前存在未完成的预转码任务
        if let currentTask = self.inTranscodingTask, currentTask.type == .preprocess, !currentTask.finished {
            // 当前预转码视频就是用户要发送的视频，此时直接复用
            if currentTask.compressPath == task.compressPath {
                let originKey = currentTask.key
                let finalKey = task.key
                SendVideoLogger.info("merge pre task", .send, pid: "\(currentTask.id)->\(task.id)", cid: currentTask.key,
                                     params: ["old_id": currentTask.id, "new_id": task.id, "contentId": currentTask.key])
                self.inTranscodingTask?.id = task.id
                self.inTranscodingTask?.key = task.key
                self.inTranscodingTask?.type = .normal
                self.inTranscodingTask?.sender = task.sender
                self.inTranscodingTask?.stateHandler = task.stateHandler
                self.inTranscodingTask?.sendMessageTracker = task.sendMessageTracker
                self.inTranscodingTask?.context = task.context
                self.inTranscodingTask?.extraInfo = task.extraInfo
                self.inTranscodingTask?.isMerge = true
                self.inTranscodingTask?.createTime = task.createTime
                self.inTranscodingTask?.from = task.from
                if let startTime = self.inTranscodingTask?.startTime, startTime != 0 {
                    self.inTranscodingTask?.preDuration = CACurrentMediaTime() - startTime
                }
                self.transcodeService.updateVideoTranscodeKey(from: originKey, to: finalKey)
                return true
            } else {
                // 取消当前预转码视频，为当前要发送的视频节省资源
                SendVideoLogger.info("cancel pre task due to \(task.key) start sending", .preprocess,
                                     pid: currentTask.id, cid: currentTask.key)
                currentTask.finished = true
                self.transcodeService.cancelVideoTranscode(key: currentTask.key)
            }
        }
        return false
    }

    func transcode(
        key: String,
        form: String,
        to: String,
        isOriginal: Bool,
        videoSize: CGSize,
        extraInfo: [String: Any],
        progressBlock: ProgressHandler?,
        dataBlock: VideoDataCBHandler?,
        retryBlock: (() -> Void)?
    ) -> Observable<TranscodeInfo> {
        var strategy = VideoTranscodeStrategy()
        strategy.isOriginal = isOriginal
        strategy.isWeakNetwork = self.isWeakNetwork
        return self.transcodeService.transcode(
            key: key,
            form: form,
            to: to,
            strategy: strategy,
            videoSize: videoSize,
            extraInfo: extraInfo,
            progressBlock: progressBlock,
            dataBlock: dataBlock,
            retryBlock: retryBlock
        )
    }

    /// 取消视频转码
    func cancelVideoTranscode(key: String) {
        self.transcodeService.cancelVideoTranscode(key: key)
    }

    /// 当前类被销毁，需要取消所有转码任务
    deinit {
        // 取消获取视频信息任务
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        // 取消转码
        VECompileTaskManagerSession.sharedInstance().cancelTranscode()
        // 取消转码任务
        items.removeAll()
        transcodeTasks.removeAll()

        self.reachability?.stopNotifier()
        SendVideoLogger.debug("VideoMessageSend deinit", .lifeCycle, pid: "", cid: "")
    }

    // 获取视频信息后，判断是否可以透传，只在视频预处理时调用
    private func getParseInfoWithPassCheck(task: VideoParseTask) -> Observable<VideoParseTask.VideoInfo> {
        self.getParseInfo(task: task).flatMap { [weak self] (info) -> Observable<VideoParseTask.VideoInfo> in
            // 如果正在进行一个正常转码任务，则不判断视频透传
            if let inTranscodingTask = self?.inTranscodingTask,
               inTranscodingTask.type == .normal {
                return .just(info)
            }
            // 只有正确获取信息的视频才需要判断是否需要需要透传
            guard info.status == .fillBaseInfo else {
                return .just(info)
            }
            return Observable.create { [weak self] observer in
                if let self = self {
                    self.passChecker.checkVideoCanPassthrough(videoInfo: info, callback: {
                        observer.onNext(info)
                        observer.onCompleted()
                    })
                }
                return Disposables.create()
            }
        }
    }

    private func getParseInfo(task: VideoParseTask, immediately: Bool = false) -> Observable<VideoParseTask.VideoInfo> {
        return parseManager.add(task: task, immediately: immediately)
    }
}

// MAKR: - 转码
private extension VideoMessageSend {
    /// 埋点请求
    func sendMetricsToSDK(map: [String: Float]) {
        var request = Basic_V1_SendMetricsRequest()
        request.key2Value = map
        _ = client.sendAsyncRequest(request)
    }

    /// 打点 @杨京
    func trace(startTime: TimeInterval, task: TranscodeTask) throws {
        let result = Path(task.compressPath).fileSize
        let map: [String: Float] = [
            "ee.lark.ios.video.compress": 0.0,
            "compress_cost": Float(CACurrentMediaTime() - startTime),
            "duration": Float(task.duration),
            "input_size_bytes": Float(task.size),
            "output_size_bytes": Float(Int(truncatingIfNeeded: result ?? 0))
        ]
        self.sendMetricsToSDK(map: map)
    }

    /// 检查是否还有排队中的任务
    func checkNext() {
        guard self.inTranscodingTask == nil, !self.transcodeTasks.isEmpty else { return }
        self.transcoding(task: self.transcodeTasks.remove(at: 0))
    }

    /// 异步发送视频
    func asyncSendVideoMessage(task: TranscodeTask) {

        self.sendQueue.async { [weak self] in
            guard let self = self else { return }
            /// 这里返回 true 代表当前任务命中预处理任务
            if self.cancelPreprocessTasksIfNeeded(for: task) {
                return
            }
            /// push 发送进度
            self.setCompressProgress(key: task.key, progress: 0)
            /// 任务进队列
            self.transcodeTasks.append(task)
            SendVideoLogger.info("[\(task.type)] enter sendQueue", .transcode,
                                 pid: task.id, cid: task.key, params: ["key": task.key])
            self.checkNext()
        }
    }

    func transcoding(task: TranscodeTask) {
        self.inTranscodingTask = task
        SendVideoLogger.info("start", .transcode, pid: task.id, cid: task.key)
        let isPHAssetVideo = task.isPHAssetVideo
        let modificationDate = task.modificationDate
        let taskCreateDate = task.taskCreateDate
        let compressCoverFileSize = task.compressCoverFileSize

        let chunkQueue = self.chunkQueue
        let time = CACurrentMediaTime()
        task.startTime = time
        task.sendMessageTracker?.beforeTransCode()

        // 分片上传缓存逻辑
        var cacheSize: Int32 = 0
        var cacheOffset: Int64 = 0
        var cacheBuffer: Data = Data()
        let sendSetting = self.userGeneralSettings.videoSynthesisSetting.value.sendSetting
        let bufferSize: Int64 = sendSetting.chunkBufferSize

        var strategy = VideoTranscodeStrategy()
        strategy.isOriginal = task.isOriginal
        strategy.isWeakNetwork = self.isWeakNetwork
        strategy.isPassthrough = task.canPassthrough

        self.transcodeService.transcode(
            key: task.key,
            form: task.exportPath,
            to: task.compressPath,
            strategy: strategy,
            videoSize: task.videoSize,
            extraInfo: ["cid": task.id], // TODO: 没有地方用，删除这个参数
            progressBlock: { [weak self, weak task] (progress) in
                guard let self = self, let task = task else {
                    return
                }
                SendVideoLogger.debug("progress: \(progress)", .transcode, pid: task.id, cid: task.key)
                self.setCompressProgress(key: task.key, progress: progress)
            },
            dataBlock: { [weak task] (data, offset, size, isFinish) in
                guard let task = task else {
                    return
                }
                if bufferSize == 0 {
                    // 不使用缓存
                    task.chunkuploader.upload(task: task, data: data, offset: offset, size: size, isFinish: isFinish, in: chunkQueue)
                    return
                }
                if cacheOffset + Int64(cacheSize) == offset {
                    // 数据连续
                    cacheBuffer += data
                    cacheSize += size
                } else {
                    // 数据不连续先把之前的数据上传
                    if cacheSize > 0 {
                        task.chunkuploader.upload(task: task, data: cacheBuffer, offset: cacheOffset, size: cacheSize, isFinish: false, in: chunkQueue)
                    }

                    // 存储新的数据
                    cacheBuffer = data
                    cacheOffset = offset
                    cacheSize = size
                }

                if cacheSize > bufferSize || isFinish {
                    task.chunkuploader.upload(task: task, data: cacheBuffer, offset: cacheOffset, size: cacheSize, isFinish: isFinish, in: chunkQueue)
                    // 清理数据
                    cacheBuffer = Data()
                    cacheOffset = 0
                    cacheSize = 0
                }
            },
            retryBlock: { [weak task] in
                guard let task = task else {
                    return
                }
                if task.chunkuploader.uploading {
                    task.chunkuploader.cancel(in: chunkQueue)
                }
            }
        )
        .observeOn(sendScheduler)
        .subscribe(onNext: { [weak self] arg in
            // 只处理转码成功的状态
            guard case .finish(let info) = arg.status else { return }
            task.finished = true
            info.isPHAssetVideo = isPHAssetVideo
            info.modificationDate = modificationDate
            info.videoSendDate = taskCreateDate
            info.compressCoverFileSize = compressCoverFileSize
            info.isMergePreCompress = task.isMerge
            info.preDuration = task.preDuration
            info.createTime = task.createTime
            info.startTime = task.startTime
            info.isCompressUpload = task.chunkuploader.uploading
            task.sendMessageTracker?.afterTransCode(cid: task.key, info: info)
            SendVideoLogger.info("success", .transcode, pid: task.id, cid: task.key)
            let compressPath = task.compressPath
            let fileName = String(URL(string: compressPath)?.path.split(separator: "/").last ?? "")
            let fileSize = try? FileUtils.fileSize(compressPath)
            self?.localVideoCache.saveFileName(fileName, size: Int(fileSize ?? 0))
            // 如果转码结束了type还是preprocess，说明用户在预转码结束前没有点击发送：此时停止分片上传，后续用户点击发送时复用转码后的文件直接进入上传流程
            if task.type == .preprocess, task.chunkuploader.uploading {
                task.chunkuploader.cancel(in: chunkQueue)
            }
            // 压缩完之后秒传
            if let preProcessManager = task.preProcessManager {
                preProcessManager.onResourcesChanged([(.media(task.compressPath), .none, [.preSwiftTransmission])])
            }

            // 边转边传逻辑：转码已完成，等待上传完成
            if task.chunkuploader.uploading {
                SendVideoLogger.info("uploading, wait for chunk callback", .upload, pid: task.id, cid: task.key)
                self?.chunkUploadTasks.append(task)
                task.chunkuploader.finishCallback = { [weak self, weak task] (cancel, error) in
                    guard let self = self, let task = task else {
                        return
                    }
                    SendVideoLogger.info("chunk uploader finish callback", .upload, pid: task.id, cid: task.key,
                                         params: ["cancel": "\(cancel)"], error: error)
                    if !cancel {
                        if let err = error {
                            info.isCompressUploadSuccess = false
                            info.compressUploadFailedMsg = "\(err)"
                        } else {
                            info.isCompressUploadSuccess = true
                        }
                         // 转码&上传完成，执行后续逻辑
                        task.sender(CACurrentMediaTime() - time)
                    }
                    if let index = self.chunkUploadTasks.firstIndex(where: { $0.key == task.key }) {
                        self.chunkUploadTasks.remove(at: index)
                        SendVideoLogger.info("remove index \(index) from chunkUploadTasks", .upload,
                                             pid: task.id, cid: task.key)
                    }
                    self.sendingManager.remove(task: task.key)
                }
            } else {
                SendVideoLogger.info("not uploading, just call sender", .transcode, pid: task.id, cid: task.key)
                // 没有边转边传，只是转码完成，执行后续逻辑
                task.sender(CACurrentMediaTime() - time)
                self?.sendingManager.remove(task: task.key)
            }
        }, onError: { [weak self] (error) in
            SendVideoLogger.error("failed", .transcode, pid: task.id, cid: task.key, error: error)
            guard let self = self else {
                return
            }
            task.finished = true
            if task.chunkuploader.uploading {
                task.chunkuploader.cancel(in: chunkQueue)
            }
            self.cleanCompressProgress(key: task.key)
            self.sendingManager.remove(task: task.key)
            var info: VideoTrackInfo?
            var realError: Error = error
            if let e = error as? VideoTranscodeWrapError {
                realError = e.error
                info = e.trackInfo
                info?.isPHAssetVideo = isPHAssetVideo
                info?.modificationDate = modificationDate
                info?.videoSendDate = taskCreateDate
                info?.compressCoverFileSize = compressCoverFileSize
                info?.isMergePreCompress = task.isMerge
                info?.preDuration = task.preDuration
                info?.createTime = task.createTime
                info?.startTime = task.startTime
                info?.isCompressUpload = task.chunkuploader.uploading
                info?.netStatus = self.netStatus
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    task.type == .normal else {
                    return
                }
                let errorInfo = self.videoTranscodeErrorCodeWithMsg(realError)
                task.sendMessageTracker?.transcodeFailed(context: task.context, code: errorInfo.0, errorMsg: errorInfo.1, cid: task.key, info: info)
                self.sendMessageAPI.updateQuasiMessage(context: nil, cid: task.key, status: .failed)
                self.sendVideoOnError(realError, from: task.from)
            }
        }, onDisposed: { [weak self] in
            guard let self = self else { return }
            SendVideoLogger.info("disposed task \(self.inTranscodingTask?.id ?? "")", .transcode,
                                 pid: task.id, cid: task.key)
            // 修改正在转码标记
            self.inTranscodingTask = nil
            do {
                try self.trace(startTime: time, task: task)
            } catch {
                SendVideoLogger.error("trace video error: \(error)", .others, pid: task.id, cid: task.key)
            }
            // 移除转码任务
            _ = self.items.remove(task.key)
            // 开始下一个转码任务
            self.checkNext()
        }).disposed(by: disposeBag)
    }
}

// MARK: - 错误处理
private extension VideoMessageSend {

    func videoTranscodeErrorCodeWithMsg(_ error: Error) -> (Int, String) {
        let appIsActive = UIApplication.shared.applicationState == .active
        var error = error
        if let wrap = error as? VideoTranscodeWrapError {
            error = wrap.error
        }
        if let sendvideoError = error as? VideoParseTask.ParseError {
            switch sendvideoError {
            case .userCancel:
                return (0, "user cancel")
            case .fileReachMax(let fileSize, let fileSizeLimit):
                return (-101, "fileReachMax fileSize \(fileSize) fileSizeLimit \(fileSizeLimit)")
            case .videoTrackUnavailable:
                return (-102, "videoTrackUnavailable")
            case .loadAVAssetIsInCloudError(let error):
                return (-103, "\(error)")
            case .assetTypeError(let error):
                return (-104, "\(error)")
            case .getVideoSizeError(let error):
                return (-105, "\(error)")
            case .loadAVAssetError(let error):
                return (-106, "\(error)")
            case .loadVideoSourceURLError(let error):
                return (-107, "\(error)")
            case .createSandboxPathError(let error):
                return (-108, "\(error)")
            case .copyVideoSourceDataError(let error):
                return (-109, "\(error)")
            case .exportVideoDataError(let error):
                return (-110, "\(error)")
            case .getFirstFrameError(let error):
                return (-111, "\(error)")
            case .canelProcessTask:
                return (-112, "canelProcessTask")
            case .getAVCompositionUrlError:
                return (-113, "getAVCompositionUrlError")
            }
        } else if let error = error as? NSError {
            if error.code == HTS_CANCELED, appIsActive {
                return (0, "\(error)")
            }
            if error.code != 0 {
                return (error.code, "\(error)")
            } else {
                // 链路上部分不规范的 NSError 没有指定 errorCode, 这种情况返回一个特定错误码
                return (-100, "\(error)")
            }
        }
        return (-99, "unkonow error")
    }

    func sendVideoOnError(_ error: Error?, from: NavigatorFrom?) {
        guard let from = from else { return }
        DispatchQueue.main.async { [weak self] in
            let appIsActive = UIApplication.shared.applicationState == .active
            if let sendvideoError = error as? VideoParseTask.ParseError {
                switch sendvideoError {
                case .fileReachMax(_, let fileSizeLimit):
                    self?.showFileSizeLimitFailure(fileSizeLimit, from: from)
                case .videoTrackUnavailable:
                    if let window = from.fromViewController?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkSendMessage.Lark_Legacy_VideoMessageVideoUnavailable, on: window)
                    }
                case .loadAVAssetIsInCloudError:
                    self?.showAlert(BundleI18n.LarkSendMessage.Lark_Chat_iCloudMediaUploadError, showCancel: false, from: from)
                case .userCancel: break
                default:
                    // 提示数据读取错误
                    self?.showAlert(
                        BundleI18n.LarkSendMessage.Lark_Legacy_ComposePostVideoReadDataError,
                        showCancel: false,
                        from: from
                    )
                }
            } else if let error = error as? NSError, error.code == HTS_CANCELED, appIsActive {
                // 这里判断 appIsActive 是因为我们引入了一个退到后台会自动 cancel 当前转码的 VESDK 版本
                // 判断 appIsActive 临时兼容, 如果 appIsActive 为 false 则按照普通 error 报错处理
                // 取消转码，则不处理
            } else {
                // 提示数据读取错误
                self?.showAlert(BundleI18n.LarkSendMessage.Lark_Legacy_ComposePostVideoReadDataError, showCancel: false, from: from)
            }
        }
    }

    /// 显示弹窗，请在主线程调用
    ///
    /// - Parameters:
    ///   - message: 信息
    ///   - showCancel: 是否显示“取消”
    ///   - onSure: 确定事件
    func showAlert(_ message: String, showCancel: Bool = true, from: NavigatorFrom, onSure: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkSendMessage.Lark_Legacy_Hint)
            alertController.setContent(text: message)
            if showCancel {
                alertController.addCancelButton()
            }
            alertController.addPrimaryButton(text: BundleI18n.LarkSendMessage.Lark_Legacy_LarkConfirm, dismissCompletion: {
                onSure?()
            })
            self.userResolver.navigator.present(alertController, from: from)
        }
    }

    /// 将文件大小限制转换为字符串
    /// 当限制小于1GB时，以MB为单位表示，否则以GB为单位表示
    private func fileSizeToString(_ fileSize: UInt64) -> String {
        let megaByte: UInt64 = 1024 * 1024
        let gigaByte = 1024 * megaByte
        if fileSize < gigaByte {
            let fileSizeInMB = Double(fileSize) / Double(megaByte)
            return String(format: "%.2fMB", fileSizeInMB)
        } else {
            let fileSizeInGB = Double(fileSize) / Double(gigaByte)
            return String(format: "%.2fGB", fileSizeInGB)
        }
    }

    private func showFileSizeLimitFailure(_ fileSizeLimit: UInt64, from: NavigatorFrom) {
        guard let window = from.fromViewController?.view.window else { return }
        UDToast.showFailure(with: BundleI18n
                                .LarkSendMessage
                                .Lark_File_ToastSingleFileSizeLimit(fileSizeToString(fileSizeLimit)),
                               on: window)
    }
}
