//
//  MailPreloadServices.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation
import RxSwift
import RxCocoa
import Reachability

/// 邮件预加载触发来源
enum MailPreloadSource: String {
    case newMessage // 新邮件
    case list // 列表滚动
    case card // 邮件消息卡片
    case search // 搜索列表
    var preloadName: String {
        switch self {
        case .newMessage:
            return "mail_newmail_preloadImage"
        case .list:
            return "mail_stopScroll_preloadImage"
        case .card:
            return "mail_rendercard_preloadImage"
        case .search:
            return "mail_search_preloadImage"
        }
    }
}

protocol MailPreloadServicesProtocol {
    func preloadImagesImmediately(_ images: [MailClientDraftImage])
    func preloadImages(images: [MailClientDraftImage], source: MailPreloadSource)
    func preloadImages(threadIDs: [String], labelID: String, source: MailPreloadSource)
    func preloadFeedBack(_ requestInfo: DriveImageDownloadInfo, hitPreload: Bool)
    func cancelPreload(threadID: String, labelID: String, cardID: String?, ownerUserID: String?, source: MailPreloadSource)
    func updateDisplayWidth(_ width: CGFloat)
}

class MailPreloadServices: MailPreloadServicesProtocol {
    private var bag = DisposeBag()
    // 保存预加载图片唯一标识，避免重复触发预加载任务
    private var preloadingImagesKeys = ThreadSafeSet<String>()
    // 保存预加载邮件唯一标识，避免重复加载邮件
    private var preloadingMailOperations = ThreadSafeDictionary<String, PreloadMailItemOperation>()
    private let mailPreloadQueue = DispatchQueue(label: "com.mail.preloadQueue")
    private let preloadOperationQueue: OperationQueue
    private var netStatus = DynamicNetStatus.evaluating
    private var displayWidth: CGFloat = 0
    // dependencies
    private var manager: PreloadManagerProxy?
    private let imageDownloader: MailImageDownloaderProtocol
    private let imageCache: MailImageCacheProtocol
    private let featureManager: UserFeatureManager
    private let settings: MailSettingConfigProxy?

    init(manager: PreloadManagerProxy?,
         userID: String,
         driveProvider: DriveDownloadProxy?,
         imageCache: MailImageCacheProtocol,
         featureManager: UserFeatureManager,
         settings: MailSettingConfigProxy?) {
        self.manager = manager
        self.imageDownloader = MailImageDownloader(userID: userID, driveProvider: driveProvider, featureManager: featureManager)
        self.imageCache = imageCache
        self.featureManager = featureManager
        self.settings = settings
        preloadOperationQueue = OperationQueue()
        preloadOperationQueue.maxConcurrentOperationCount = 1
        setupNetStatus()
    }

    // 立即发起图片加载，优先级为userinteract, 用于用户点击打开邮件时提前发起图片请求
    func preloadImagesImmediately(_ images: [MailClientDraftImage]) {
        mailPreloadQueue.async {
            MailLogger.info("MailPreloadServices: start preload immediately when click")
            let requestInfos = self.parseRequestInfos(from: images)
            for info in requestInfos {
                guard !self.imageExist(for: info) else {
                    MailLogger.info("MailPreloadServices: image exist \(info.token.md5())")
                    return
                }
                self.imageDownloader.downloadWithDriveSDKCallback(info: info,
                                                                  priority: .userInteraction,
                                                                  session: nil,
                                                                  progressHandler: {},
                                                                  callback: { (_, _, _, _) in },
                                                                  cache: self.imageCache)
            }
        }
    }

    // 仅预加载图片，不预加载邮件内容
    // 使用场景: 邮件列表、收到新邮件,可以在列表数据中获取到MailClientDraftImage
    func preloadImages(images: [MailClientDraftImage], source: MailPreloadSource) {
        guard preloadEnable() else {
            MailLogger.info("MailPreloadServices: FG disable")
            return
        }
        mailPreloadQueue.async {
            let requestInfos = self.parseRequestInfos(from: images)
            MailLogger.info("MailPreloadServices: add images tasks \(requestInfos.count)")
            self.addPreloadImageTasks(requestInfos: Array(requestInfos), preloadName: source.preloadName, source: source)
        }
    }

    // 先加载邮件内容(本地/remote), 再预加载图片
    // 使用场景: 搜索结果，搜索结果没有images信息，需要通过邮件内容获取
    func preloadImages(threadIDs: [String], labelID: String, source: MailPreloadSource) {
        guard preloadEnable() else {
            MailLogger.info("MailPreloadServices: FG disable")
            return
        }
        for threadID in threadIDs {
            preloadImages(threadID: threadID,
                          labelID: labelID,
                          preloadName: source.preloadName,
                          source: source)
        }
    }

    // 跟踪预加载资源命中数据
    func preloadFeedBack(_ requestInfo: DriveImageDownloadInfo, hitPreload: Bool) {
        guard preloadEnable() else {
            MailLogger.info("MailPreloadServices: FG disable")
            return
        }
        guard let manager = manager else {
            MailLogger.error("MailPreloadServices: PreloadManagerProxy is nil")
            return
        }
        let diskCacheId = diskCacheID(for: requestInfo)
        manager.feedbackForDiskCache(diskCacheId: diskCacheId, hitPreload: hitPreload)
    }

    // cardID和ownerUserID, 在预加载邮件消息卡片的场景，需要使用这两个参数标记预加载任务，其他场景这两个字段传空。
    // 由于主端对IM场景性能考虑，本次没有接入邮件消息卡片预加载， 保留这两个参数，后续使用
    func cancelPreload(threadID: String, labelID: String, cardID: String?, ownerUserID: String?, source: MailPreloadSource) {
        guard preloadEnable() else {
            MailLogger.info("MailPreloadServices: FG disable")
            return
        }
        var forwardInfo: DataServiceForwardInfo?
        if let cardID = cardID, let ownerUserID = ownerUserID {
            forwardInfo = DataServiceForwardInfo(cardId: cardID, ownerUserId: ownerUserID)
        }

        let fakeOp = PreloadMailItemOperation(threadID: threadID, labelID: labelID, source: source, forwardInfo: forwardInfo)
        if let op = preloadingMailOperations[fakeOp.key], !op.isExecuting {
            MailLogger.info("MailPreloadServices: preload cancel threadID \(threadID)")
            op.cancel()
            _ = preloadingMailOperations.removeValue(forKey: fakeOp.key)
        }
    }

    func updateDisplayWidth(_ width: CGFloat) {
        guard preloadEnable() else {
            MailLogger.info("MailPreloadServices: FG disable")
            return
        }
        mailPreloadQueue.async {
            MailLogger.info("MailPreloadServices: update display width \(width)")
            self.displayWidth = width
        }
    }
    // forwardInfo: 预加载邮件消息卡片使用，其他场景传空
    private func preloadImages(threadID: String,
                               labelID: String,
                               preloadName: String,
                               source: MailPreloadSource,
                               forwardInfo: DataServiceForwardInfo? = nil) {
        mailPreloadQueue.async {
            guard self.netStatusAvalibleToPreload() else {
                MailLogger.info("MailPreloadServices: network not avalible to preload")
                return
            }
            let operation = PreloadMailItemOperation(threadID: threadID, labelID: labelID, source: source, forwardInfo: forwardInfo)
            guard self.preloadingMailOperations[operation.key] == nil else {
                MailLogger.info("MailPreloadServices: mail is preloading")
                return
            }
            operation.delegate = self
            self.preloadingMailOperations[operation.key] = operation
            self.preloadOperationQueue.addOperation(operation)
        }
    }

    private func addPreloadImageTasks(requestInfos: [DriveImageDownloadInfo], preloadName: String, source: MailPreloadSource) {
        guard let manager = manager else {
            MailLogger.error("MailPreloadServices: PreloadManagerProxy is nil")
            return
        }
        guard self.netStatusAvalibleToPreload() else {
            MailLogger.info("MailPreloadServices: network not avalible to preload")
            return
        }
        for requestInfo in requestInfos {
            if !imageExist(for: requestInfo) && !self.preloadingImagesKeys.contains(cacheKey(for: requestInfo)) {
                MailLogger.info("MailPreloadServices: add image preload task \(self.cacheKey(for: requestInfo).md5()) isThumb: \(requestInfo.useThumb)  source \(source)")
                self.preloadingImagesKeys.insert(cacheKey(for: requestInfo))
                // 1. 添加预加载任务
                let event = MailPreloadImageEvent(from: source.rawValue)
                let _ = manager.addTask(preloadName: preloadName, taskAction: { [weak self] in
                    self?.loadImage(requestInfo: requestInfo, event: event)
                }, stateCallBack: {[weak self] state in
                    guard let self = self else { return }
                    MailLogger.info("MailPreloadServices: preload taskID: \(self.cacheKey(for: requestInfo).md5()) state \(state)")
                    self.reportSchedule(event: event, status: state)
                    switch state {
                    case .disableByHitRate, .disableByLowDevice, .cancel:
                        self.preloadingImagesKeys.remove(self.cacheKey(for: requestInfo))
                    default:
                        break
                    }
                }, diskCacheId: self.diskCacheID(for: requestInfo))
            } else {
                MailLogger.info("MailPreloadServices: image exist \(cacheKey(for: requestInfo).md5()) ")
            }
        }
    }

    private func loadImage(requestInfo: DriveImageDownloadInfo, event: MailPreloadImageEvent) {
        mailPreloadQueue.async {
            MailLogger.info("MailPreloadServices: start image preload task token: \(requestInfo.token.md5())")
            guard !self.imageExist(for: requestInfo) else {
                MailLogger.info("MailPreloadServices: image exist")
                self.preloadingImagesKeys.remove(self.cacheKey(for: requestInfo))
                return
            }
            event.startDownload()
            self.imageDownloader.downloadWithDriveSDKCallback(info: requestInfo, priority: .default, session: nil, progressHandler: {}, callback: {[weak self] (data, _, _, _) in
                guard let self = self else { return }
                MailLogger.info("MailPreloadServices: preload image end \(self.cacheKey(for: requestInfo).md5())")
                MailLogger.info("MailPreloadServices: preload image result \(data != nil)")
                self.preloadingImagesKeys.remove(self.cacheKey(for: requestInfo))
                if let data = data {
                    event.downloadFinish(status: 0, dataLength: data.count)
                } else {
                    event.downloadFinish(status: 1, dataLength: nil)
                }
            }, cache: self.imageCache)
        }
    }

    private func setupNetStatus() {
        PushDispatcher
            .shared
            .larkEventChange
            .subscribe(onNext: {[weak self] push in
                switch push {
                case .dynamicNetStatusChange(let change):
                    MailLogger.info("MailPreloadServices: net status change \(change.netStatus)")
                    self?.netStatus = change.netStatus
                }
            }).disposed(by: bag)
    }

    private func preloadEnable() -> Bool {
        guard let manager = manager else { return false }
        return manager.preloadEnable() && featureManager.open(.preloadMailImageEnable, openInMailClient: false)
    }

    private func parseRequestInfos(from images: [MailClientDraftImage]) -> [DriveImageDownloadInfo] {
        let requestInfos = images.map({ image -> DriveImageDownloadInfo in
            return DriveImageDownloadInfo.tokenRequestInfo(token: image.fileToken,
                                                           image: image,
                                                           displayWidth: self.displayWidth)
        }).filter {[weak self] info in // 过滤正在执行的任务
            guard let self = self else { return false }
            guard info.token.count > 0 else { return false }
            return !self.preloadingImagesKeys.contains(self.cacheKey(for: info))
        }
        return requestInfos
    }

    private func cacheKey(for requestInfo: DriveImageDownloadInfo) -> String {
        return imageCache.cacheKey(token: requestInfo.token, size: requestInfo.thumbSize)
    }

    // diskCacheID 用于唯一标识一次预加载任务， 预加载框架会打印日志，md5一下
    private func diskCacheID(for requestInfo: DriveImageDownloadInfo) -> String {
        return cacheKey(for: requestInfo).md5()
    }

    private func imageExist(for requestInfo: DriveImageDownloadInfo) -> Bool {
        if requestInfo.useThumb {
            let key = cacheKey(for: requestInfo)
            // 缩略图不存在时，有可能是降级下载原图，所以需要同时判断是否原图是否存在
            return imageCache.get(key: key) != nil || imageCache.get(key: requestInfo.token) != nil
        } else {
            return imageCache.get(key: requestInfo.token) != nil
        }
    }
}

extension MailPreloadServices: PreloadMailItemDelegate {
    func operation(_ operation: PreloadMailItemOperation, result: Result<[MailClientDraftImage], Error>) {
        mailPreloadQueue.async {
            switch result {
            case .failure:
            _ = self.preloadingMailOperations.removeValue(forKey: operation.key)
            case .success(let images):
                let requestInfos = self.parseRequestInfos(from: images)
                MailLogger.info("MailPreloadServices: add images tasks \(requestInfos.count)")
                self.addPreloadImageTasks(requestInfos: Array(requestInfos), preloadName: operation.preloadName, source: operation.source)
                _ = self.preloadingMailOperations.removeValue(forKey: operation.key)
            }
        }
    }

    func netStatusAvalibleToPreload() -> Bool {
        switch self.netStatus {
        case .weak, .netUnavailable, .offline, .serviceUnavailable:
            MailLogger.info("MailPreloadServices: network status \(self.netStatus) will not preload")
            return false
        case .evaluating, .excellent:
            // if enable only wifi
            if settings?.preloadConfig?.enableOnlyWifi == true {
                MailLogger.info("MailPreloadServices: is wifi: \(isWifi())")
                return isWifi()
            } else {
                return true
            }
        @unknown default:
            MailLogger.error("MailPreloadServices: unknown netstatus")
            return false
        }
    }

    func isWifi() -> Bool {
        return Reachability()?.connection == .wifi
    }
}

// event stastics
extension MailPreloadServices {
    func reportSchedule(event: MailPreloadImageEvent, status: PreloadTaskState) {
        switch status {
        case .cancel:
            // 没有开始预加载
            event.downloadFinish(status: 2, dataLength: nil)
        case .disableByHitRate:
            // 没有开始预加载
            event.downloadFinish(status: 3, dataLength: nil)
        default:
            break
        }
    }
}
