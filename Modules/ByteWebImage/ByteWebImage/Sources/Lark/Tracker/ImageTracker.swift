//
//  ImageTracker.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/6/22.
//

import AppReciableSDK
import Foundation
import LKCommonsLogging
import LarkSetting
import RustPB
import LarkAccountInterface
import LarkContainer

// MARK: Basic Structures

public struct TrackInfo {
    public var biz: Biz
    public var scene: Scene
    public var fromType: FromType
    public var metric: [String: Any]?
    public var category: [String: Any]?
    public var latencyDetail: [String: Any]?
    public var extra: [String: Any]?
    public var chatType: ChatType = .unkonwn
    public var isOrigin: Bool = false // 是否是原图，默认false

    public enum ChatType: Int {
        case unkonwn = 0
        case single
        case group
        case topic
        case threadDetail
    }

    public enum FromType: Int {
        case unknown = 0
        case image
        case post
        case sticker
        case media
        case avatar
        case reaction
        case card
        case urlPreview
        case cover // 封面
        case chatHistory // 聊天历史
        case chatAlbum // 群相册

    }

    public init(biz: Biz = .Messenger,
                scene: Scene,
                isOrigin: Bool = false,
                fromType: FromType = .unknown,
                chatType: ChatType = .unkonwn,
                metric: [String: Any]? = nil,
                category: [String: Any]? = nil,
                latencyDetail: [String: Any]? = nil,
                extra: [String: Any]? = nil) {
        self.biz = biz
        self.scene = scene
        self.isOrigin = isOrigin
        self.fromType = fromType
        self.chatType = chatType
        self.metric = metric
        self.category = category
        self.latencyDetail = latencyDetail
        self.extra = extra
    }
}

// MARK: Image Appreciable Tracker

public final class ImageTracker {

    private static let logger = Logger.log(ImageTracker.self, category: "ByteWebImage.ImageTracker")
    private static let queue = DispatchSafeQueue(label: "com.lark.imageTracker", qos: .utility)
    public init() {}

    private var key: String = ""
    private var startTime: CFTimeInterval = 0
    private var trackInfo: TrackInfo = TrackInfo(biz: .Unknown, scene: .Unknown, fromType: .unknown)
    @Provider private var deviceService: DeviceService
    @Provider private var accountService: AccountService

    public func start(with resource: LarkImageResource, trackInfo: TrackInfo? = nil) {
        start(with: resource.getURLString() ?? "", trackInfo: trackInfo)
    }

    func start(with key: String, trackInfo: TrackInfo? = nil) {
        guard !key.isEmpty else { return }
        self.key = key
        if let trackInfo {
            self.trackInfo = trackInfo
        }
        startTime = CACurrentMediaTime()
    }

    /// 发送埋点
    /// - Parameters:
    ///   - type: 成功或失败，成功带上 load_type，失败带上 error
    ///   - imageSize: 图片加载尺寸
    ///   - originSize: 图片原图尺寸
    ///   - cacheSeekCost: 找缓存耗时
    ///   - queueCost: 请求排队耗时，单位 秒
    ///   - sdkCost: 请求耗时（SDK 总耗时），单位 秒
    ///   - decryptCost: 解密耗时，单位 秒
    ///   - decodeCost: 解码耗时，单位 秒
    ///   - cacheCost: 写缓存耗时，单位 秒
    ///   - rustCost: SDK 细分耗时
    ///   - dataLength: 图片文件大小
    ///   - imageCount: 图片数量（动图可能大于 1）
    ///   - imageType: 图片格式
    ///   - trackInfo: 失败时，是否要改埋点信息
    /// - Note: 耗时输入单位是秒，上报时会转成毫秒
    public func send(_ type: Result<ImageResultFrom, ByteWebImageError>,
                     request: ImageRequest? = nil,
                     imageSize: CGSize = .zero,
                     originSize: CGSize = .zero,
                     cacheSeekCost: TimeInterval = 0,
                     queueCost: TimeInterval = 0,
                     sdkCost: TimeInterval = 0,
                     decryptCost: TimeInterval = 0,
                     decodeCost: TimeInterval = 0,
                     cacheCost: TimeInterval = 0,
                     rustCost: [String: UInt64] = [:],
                     dataLength: Int = 0,
                     imageCount: Int = 1,
                     imageType: ImageFileFormat = .unknown,
                     sourceFileInfo: FileInfo? = nil,
                     trackInfo: TrackInfo? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        let timestamp = Date().timeIntervalSince1970 // 异步会造成时间戳不准确，这里记录准确时间
        Self.queue.async { [self] in // 不能 weak 否则会被释放掉
            let fileInfo = sourceFileInfo ?? FileInfo(file: file, function: function, line: line)
            updateTrackInfoIfNeeded(trackInfo, fileInfo: fileInfo)
            switch type {
            case let .success(from):
                guard var extra = generateEtra(imageSize: imageSize,
                                            originSize: originSize,
                                            dataLength: dataLength,
                                            imageCount: imageCount,
                                            cacheSeekCost: cacheSeekCost,
                                            queueCost: queueCost,
                                            sdkCost: sdkCost,
                                            decryptCost: decryptCost,
                                            decodeCost: decodeCost,
                                            cacheCost: cacheCost,
                                            rustCost: rustCost,
                                            contextID: request?.contextID,
                                            imageType: imageType,
                                            loadType: from,
                                            fileInfo: fileInfo)
                else { return }
                if [.image, .post, .media].contains(self.trackInfo.fromType) { // 目前只预加载这三种场景，仅此需要获取 Preload 信息
                    extra = getPreloadExtra(extra)
                }
                sendTracker(loadType: from, extra: extra, timestamp: timestamp, errorParams: nil)
            case let .failure(error):
                let imageFrom = error.userInfo[ImageError.UserInfoKey.cacheType] ?? "none"
                var errorStatus: Int = 0
                if let status = error.userInfo[ImageError.UserInfoKey.errorStatus] {
                    errorStatus = Int(status) ?? 0
                }
                var cacheType = ImageResultFrom.none
                switch imageFrom {
                case ImageCacheOptions.disk.description:
                    cacheType = .diskCache
                case ImageCacheOptions.memory.description:
                    cacheType = .memoryCache
                default:
                    cacheType = .downloading
                }
                guard error.code != ByteWebImageErrorUserCancelled,
                    let extra = generateEtra(imageSize: imageSize,
                                            originSize: originSize,
                                            dataLength: 0, // Error 的 dataLength 在 error.userInfo 里，最后会塞进去
                                            imageCount: imageCount,
                                            cacheSeekCost: 0,
                                            queueCost: 0,
                                            sdkCost: 0,
                                            decryptCost: 0,
                                            decodeCost: 0,
                                            cacheCost: 0,
                                            rustCost: rustCost,
                                            contextID: request?.contextID,
                                            imageType: imageType,
                                            loadType: cacheType,
                                            fileInfo: fileInfo,
                                            userInfo: error.userInfo)
                else { return }

                let errorType: ErrorType = (error.code == ByteWebImageErrorZeroByte || error.code == ByteWebImageErrorRequestFailed) ? .Network : .SDK
                let errorParams = ErrorParams(biz: self.trackInfo.biz,
                                            scene: self.trackInfo.scene,
                                            event: .imageLoad,
                                            errorType: errorType,
                                            errorLevel: .Fatal,
                                            errorCode: error.code,
                                            errorStatus: errorStatus,
                                            userAction: nil,
                                            page: nil,
                                            errorMessage: error.localizedDescription,
                                            extra: extra)
                sendTracker(loadType: cacheType, extra: extra, timestamp: timestamp, errorParams: errorParams)
            }
        }
    }

    private func updateTrackInfoIfNeeded(_ info: TrackInfo?,
                                         fileInfo: FileInfo) {
        if let info {
            trackInfo = info
        }
        #if DEBUG
        if trackInfo.biz == .Unknown || trackInfo.scene == .Unknown || trackInfo.fromType == .unknown {
            // trackInfo 不完整的情况，找业务方逐个加上
            Self.logger.warn("Incomplete trackInfo to be add: \(String(describing: trackInfo)); " +
                             "key: \(key); passed from \(fileInfo)")
        }
        #endif
    }

    /// - Parameters:
    ///   - cacheSeekCost: 读缓存时间
    ///   - queueCost: 真正发起请求前的排队时间
    ///   - decodeCost: 解码耗时
    ///   - cacheCost: 写缓存耗时
    ///   - rustCost: rust 细分耗时
    private func generateEtra(imageSize: CGSize,
                              originSize: CGSize,
                              dataLength: Int,
                              imageCount: Int,
                              cacheSeekCost: TimeInterval,
                              queueCost: TimeInterval,
                              sdkCost: TimeInterval,
                              decryptCost: TimeInterval,
                              decodeCost: TimeInterval,
                              cacheCost: TimeInterval,
                              rustCost: [String: UInt64],
                              contextID: String?,
                              imageType: ImageFileFormat,
                              loadType: ImageResultFrom,
                              fileInfo: FileInfo?,
                              userInfo: [String: String] = [:]) -> Extra? {
        var defaultCategory: [String: Any] = ["image_type": imageType.description,
                                              "from_type": trackInfo.fromType.rawValue,
                                              "chat_type": trackInfo.chatType.rawValue,
                                              "load_type": loadType.rawValue,
                                              "media_is_origin_type": trackInfo.isOrigin.stringValue
        ]
        var defaultLatencyDetail: [String: Any] = ["search_cache_cost": cacheSeekCost * 1000,
                                                   "send_req_waiting_cost": queueCost * 1000,
                                                   "sdk_cost": sdkCost * 1000,
                                                   "decrypt_cost": decryptCost * 1000,
                                                   "decode_cost": decodeCost * 1000,
                                                   "write_cache_cost": cacheCost * 1000]
        for item in rustCost {
            defaultLatencyDetail[item.key] = item.value
        }
        var defaultMetric: [String: Any] = [
            "resource_content_length": dataLength,
            "resource_width": Float(originSize.width),
            "resource_height": Float(originSize.height),
            "resource_frames": imageCount,
            "load_width": Float(imageSize.width),
            "load_height": Float(imageSize.height)
        ]
        userInfo.forEach { key, value in
            defaultMetric[key] = value
        }
        var defaultExtra: [String: Any] = [
            "image_key": key
        ]
        if let fileInfo {
            defaultExtra["source_file_info"] = fileInfo.description
        }
        if let contextID {
            defaultExtra["log_id"] = contextID
        }
        if let metric = trackInfo.metric {
            defaultMetric.merge(metric) { _, new in
                new
            }
        }
        if let category = trackInfo.category {
            defaultCategory.merge(category) { _, new in
                new
            }
        }
        if let latencyDetail = trackInfo.latencyDetail {
            defaultLatencyDetail.merge(latencyDetail) { _, new in
                new
            }
        }
        if let extra = trackInfo.extra {
            defaultExtra.merge(extra) { _, new in
                new
            }
        }
        return Extra(isNeedNet: true,
                     latencyDetail: defaultLatencyDetail,
                     metric: defaultMetric,
                     category: defaultCategory,
                     extra: defaultExtra)
    }

    private func getPreloadExtra(_ originExtra: Extra) -> Extra {
        let key = LarkImageResource.removeRustImagePrefixIfExisted(key: self.key)
        guard let record = ImagePreloadManager.shared.getResult(imageKey: key) else { return originExtra }
        var extra = originExtra
        extra.category?["preload_result"] = record.state.rawValue
        extra.category?["preload_scene"] = record.scene
        if record.state == .preloading {
            extra.metric?["preloading_duration"] = (CACurrentMediaTime() - record.startTime) * 1000
        }
        return extra
    }

    private func sendTracker(loadType: ImageResultFrom,
                             extra: Extra,
                             timestamp: TimeInterval,
                             errorParams: ErrorParams?) {
        if var errorParams = errorParams {
            // 传入精确的时间戳
            errorParams.timestamp = timestamp
            AppReciableSDK.shared.error(params: errorParams)
            self.sendSteamErrorLog(loadType: loadType, extra: extra, errorParams: errorParams)
        } else {
            var params = TimeCostParams(biz: trackInfo.biz,
                                        scene: trackInfo.scene,
                                        event: .imageLoad,
                                        cost: Int((CACurrentMediaTime() - startTime) * 1000),
                                        page: nil,
                                        extra: extra)
            // 传入精确的时间戳
            params.timestamp = timestamp
            // loadType 为 disk or memory 的量太大了，进行降采样再上报
            if loadType == .diskCache || loadType == .memoryCache,
               // fromType 在配置名单里再降采样
               let percentage = LarkImageService.shared
                .imageDisplaySetting
                .imageLoadDownsampleConfigs
                .percentage(for: trackInfo.fromType, loadType: loadType) {
                let shouldReport = Int.random(in: 0...100) < percentage
                guard shouldReport else {
                    if loadType == .diskCache { // memory 量太大了，减少日志输出
                        Self.logger.info("[Local]\(params.debugDescription)")
                    }
                    return
                }
            }
            AppReciableSDK.shared.timeCost(params: params)
        }
    }

    // 发送加载错误的日志到steam。过滤出会话内的网络图片，在渲染阶段的出错，上报到steam
    private func sendSteamErrorLog(loadType: ImageResultFrom, extra: Extra, errorParams: ErrorParams) {
        // 为了降低海量数据上报，目前只上报“会话内”的“网络图片”，并且是由于“端上渲染失败”才上报（RCError标记为errorType=="sdk"）
        if loadType == .downloading,
           [.Messenger, .Core].contains(self.trackInfo.biz),
           [.Chat, .Detail, .Pin, .Thread, .SecretChat].contains(self.trackInfo.scene),
           [.image, .post, .media, .sticker, .urlPreview].contains(self.trackInfo.fromType),
           let contextID = extra.extra?["log_id"] as? String,
           extra.metric?[ImageError.UserInfoKey.errorType] == nil  {
            sendSteamLog(contextID: contextID, errorCode: errorParams.errorCode, errorMsg: errorParams.errorMessage ?? "")
        }
    }

    // 组装request，发起steam的请求
    // https://bytedance.feishu.cn/wiki/Jn6jwAVWViFYgKkHZFccShT4nnd
    private func sendSteamLog(contextID: String, errorCode: Int, errorMsg: String) {
        guard FeatureGatingManager.shared.featureGatingValue(with: .sendSteamFG) else { return }
        var req = RustPB.Tool_V1_SendSteamLogsRequest()
        req.bizID = "file"
        typealias SteamGeneral = RustPB.Tool_V1_SendSteamLogsRequest.SteamGeneral
        typealias SteamSpecial = RustPB.Tool_V1_SendSteamLogsRequest.SteamSpecial
        typealias StringList = RustPB.Tool_V1_SendSteamLogsRequest.StringList

        var general = SteamGeneral()
        general.keys = ["errorCode": StringList(["\(errorCode)"]),
                        "WHICH_END": StringList(["iOS"]),
                        "error": StringList([errorMsg])]

        var special = SteamSpecial()
        special.eventID = UUID().uuidString
        special.keys = ["USER_ID": StringList([self.accountService.foregroundUser?.userID ?? ""]),
                        "createTime": StringList(["\(Int64(Date().timeIntervalSince1970 * 1000))"]),
                        "DEVICE_ID": StringList([self.deviceService.deviceId]),
                        "contextID": StringList([contextID]),
                        "subStage": StringList(["102001"]),
                        "isFailed": StringList(["true"]),
                        "fileKey": StringList([self.key]),
                        "action": StringList(["52"]),
                        "SUB_TAG": StringList(["52"])]

        req.special = [special]
        req.general = general
        _ = LarkImageService.shared.dependency.steamRequest(req: req).subscribe(onNext: { arg in
            Self.logger.info("send steam log req: \(req) res: \(arg)")
        }, onError: { err in
            Self.logger.error("send steam log req: \(req) err: \(err)")
        })
    }
}

extension RustPB.Tool_V1_SendSteamLogsRequest.StringList {
    fileprivate init(_ strArray: [String]) {
        self.init()
        self.value = strArray
    }
}

extension ImageTracker {

    func sendSuccess(_ result: ImageResult,
                     trackInfo: TrackInfo? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        let scale = result.image?.scale ?? 1.0
        let uiSize = result.image?.size ?? .zero
        let request = result.request

        send(.success(result.from),
             imageSize: CGSize(width: uiSize.width * scale, height: uiSize.height * scale),
             originSize: result.image?.bt.pixelSize ?? .zero,
             cacheSeekCost: request.cacheSeekCost,
             queueCost: request.queueCost,
             sdkCost: request.downloadCost,
             decryptCost: request.decryptCost,
             decodeCost: request.decodeCost,
             cacheCost: request.cacheCost,
             rustCost: request.rustCost ?? [:],
             dataLength: result.data?.count ?? 0,
             imageCount: Int((result.image as? ByteImage)?.frameCount ?? 1),
             imageType: result.image?.bt.imageFileFormat ?? .unknown,
             sourceFileInfo: request.sourceFileInfo,
             trackInfo: trackInfo,
             file: file,
             function: function,
             line: line)
    }
}
