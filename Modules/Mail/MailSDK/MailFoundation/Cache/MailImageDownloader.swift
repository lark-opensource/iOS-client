//
//  MailImageDownloader.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/3/3.
//

import Foundation
import RxSwift
import LarkStorage

typealias MailImageDownloadCallback = (Data?, URLResponse?, Error?, MailImageDownloadType) -> Void

class MailImageDownloadRequestCallback {
    /// finish callback
    let callback: MailImageDownloadCallback
    /// associated URLRequest
    fileprivate weak var dataSession: MailSchemeDataSession?
    var logURLString: String? {
        return dataSession?.request.url?.mailSchemeLogURLString
    }
    var readMailThreadID: String? {
        return dataSession?.readMailThreadID
    }

    init(callback: @escaping MailImageDownloadCallback, dataSession: MailSchemeDataSession?) {
        self.callback = callback
        self.dataSession = dataSession
    }
}

enum MailImageDownloadState {
    case waiting
    case progress(progress: Double)
    case failed(errorCode: Int)
    case success(image: Data)
    case cancel
}

// TODO: 二期改造吧，改造哦成本较大
protocol MailImageDownloaderProtocol {
    typealias DownloadInfo = DriveImageDownloadInfo
    /// Reture result as callback
    func downloadWithDriveSDKCallback(info: DownloadInfo,
                                      priority: DriveDownloadRequestCtx.DriveDownloadPriority,
                                      session: MailSchemeDataSession?,
                                      progressHandler: @escaping (() -> Void),
                                      callback: @escaping MailImageDownloadCallback,
                                      cache: MailImageCacheProtocol)

    /// Reture result as observable
    /// - disableCdn: 使用cdn会现请求cdn info后下载，对于单个小文件比较好使，传true不走cdn，下载只发一个请求
    func downloadWithDriveSDKObservable(token: String,
                                        thumbnailSize: CGSize?,
                                        userID: String,
                                        priority: DriveDownloadRequestCtx.DriveDownloadPriority,
                                        disableCdn: Bool,
                                        cache: MailImageCacheProtocol) -> Observable<MailImageDownloadState>?

    func cancel(token: String, session: MailSchemeDataSession)
}

// TODO: 二期整体流程改造完后，将这个protocol删除，方法private掉。
protocol MailImageDownloadCallbackHelper {
    func addCallback(token: String, session: MailSchemeDataSession?, callback: @escaping MailImageDownloadCallback)
    func getAllCallbacks(token: String) -> [MailImageDownloadCallback]?
    func getCallback(token: String, session: MailSchemeDataSession) -> MailImageDownloadCallback?
    func clearAllCallbacks(token: String)
    func clearCallback(token: String, session: MailSchemeDataSession)
    func callAllCallback(token: String, data: Data?, response: URLResponse?, error: Error?, downloadType: MailImageDownloadType)
}

class MailImageDownloader {
    // 这里没加锁，注意多线程操作。
    private var callbackMap = ThreadSafeDictionary<String, [MailImageDownloadRequestCallback]>()
    // task pool 暂时不需要限制 [token: Requset]
    private var taskPool: [String: MailRequest<Any>] = [:]
    private let downloader: DriveDownloadProxy?
    private let featureManager: UserFeatureManager
    private let bag = DisposeBag()
    private let userID: String

    init(userID: String, driveProvider: DriveDownloadProxy?, featureManager: UserFeatureManager) {
        self.userID = userID
        self.downloader = driveProvider
        self.featureManager = featureManager
    }

    private func imageDownloadPath(token: String, thumbSize: CGSize?) -> IsoPath {
        let cacheDir = FileOperator.getReadMailIamgeCacheDir(userID: userID).path
        let lastPathComponent: String
        if let size = thumbSize {
            lastPathComponent = "\(token)-\(Int(size.width))*\(Int(size.height))"
        } else {
            lastPathComponent = token
        }
        return cacheDir + lastPathComponent
    }
}

extension MailImageDownloader: MailImageDownloaderProtocol {
    func downloadWithDriveSDKCallback(info: DownloadInfo,
                                      priority: DriveDownloadRequestCtx.DriveDownloadPriority,
                                      session: MailSchemeDataSession?,
                                      progressHandler: @escaping (() -> Void),
                                      callback: @escaping MailImageDownloadCallback,
                                      cache: MailImageCacheProtocol) {
        // add callbacks
        addCallback(token: info.token, session: session, callback: callback)
        let localPath = imageDownloadPath(token: info.token, thumbSize: info.thumbSize)
        var downloadTypeForStastic: MailImageDownloadType = .driveOrigin
        var downloadType: DriveDownloadRequestCtx.DriveDownloadType = .image
        var disableCDN = false
        // Download image as thumbnail instead of full size
        if let size = info.thumbSize {
            downloadType = .thumbnail(width: Int(size.width), height: Int(size.height))
            downloadTypeForStastic = .driveThumb
            disableCDN = true
        }
        let ctx = DriveDownloadRequestCtx(fileToken: info.token,
                                          mountNodePoint: session?.userID ?? userID,
                                          localPath: localPath.url.relativeString,
                                          downloadType: downloadType,
                                          priority: priority,
                                          disableCdn: disableCDN)
        MailLogger.info("mail image DriveSDK download start downloadType \(downloadType) token: \(info.token.md5()) priority: \(priority)")
        self.downloader?.download(with: ctx, messageID: nil).subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            MailLogger.info("mail image DriveSDK download key: \(result.key), status: \(result.downloadStatus)")
            switch result.downloadStatus {
            case .failed:
                MailLogger.info("mail image DriveSDK download failed: \(result.key), downloadType \(downloadType), token: \(info.token.md5())")
                let errorMsg = "mail image DriveSDK fail with errorCode \(result.errorCode)"
                MailLogger.error(errorMsg)
                self.callAllCallback(token: info.token, data: nil, response: nil,
                                     error: MailURLError.driveError(code: result.errorCode),
                                     downloadType: downloadTypeForStastic)
                /// 补充邮箱业务侧埋点
                InteractiveErrorRecorder.recordError(event: .download_attachment_fail, errorCode: .rust_error,
                                                     tipsType: .error_page, scene: .messagelist, errorMessage: errorMsg)
            case .success:
                guard let path = self.getDownloadPath(requestPath: localPath, responseContext: result) else {
                    MailLogger.info("mail image DriveSDK download invalid path: \(result.key), downloadType \(downloadType), token: \(info.token.md5())")

                    let errorMsg = "invalid path"
                    self.callAllCallback(token: info.token, data: nil,
                                         response: nil,
                                         error: MailURLError.unexpected(code: -1, msg: errorMsg),
                                         downloadType: downloadTypeForStastic)
                    return

                }
                // 由于同时存在预加载和正常预览加载的任务，两个任务优先级不同，当一个图片预加载任务在等待队列中，此时打开该图片正常的预览请求，为了避免正常预览任务等待过久，
                // 需要调用DriveSDK重新发起下载任务，DriveSDK会修改等待队列中相同任务的优先级，避免正常预览场景等待过久
                // 所以会出现两次成功回调, 两次回调分别调用不同的downloader实例，预加载downloader和MailSchemeDataSession downloader是两个实例。
                if let data = (try? Data.read(from: path)) ?? self.cachedData(from: cache, downloadInfo: info) {
                    self.saveData(data, to: cache, downloadInfo: info, completion: {
                        try? path.removeItem()
                    })
                    let downloadTypeForStastic = self.getDownloadType(data, downloadInfo: info)
                    MailLogger.info("mail image DriveSDK download success with bytes \(data.count), downloadKey: \(result.key), downloadType: \(downloadTypeForStastic), token: \(info.token.md5())")

                    self.callAllCallback(token: info.token,
                                         data: data,
                                         response: nil,
                                         error: nil,
                                         downloadType: downloadTypeForStastic)
                } else {
                    MailLogger.error("mail image DriveSDK success data not found, downloadKey: \(result.key), token: \(info.token.md5())")
                    let errorMsg = "drive success without data"
                    self.callAllCallback(token: info.token, data: nil,
                                         response: nil,
                                         error: MailURLError.unexpected(code: -1, msg: errorMsg),
                                         downloadType: downloadTypeForStastic)
                    /// fail case
                    InteractiveErrorRecorder.recordError(event: .download_attachment_fail, errorCode: .rust_error,
                                                         tipsType: .error_page, scene: .messagelist, errorMessage: errorMsg)
                }
            case .inflight:
                progressHandler()
            case .cancel:
                self.clearAllCallbacks(token: info.token)
            case .pending, .queue, .ready:
                break
            }
        }).disposed(by: bag)
    }

    func downloadWithDriveSDKObservable(token: String,
                                        thumbnailSize: CGSize?,
                                        userID: String,
                                        priority: DriveDownloadRequestCtx.DriveDownloadPriority,
                                        disableCdn: Bool = false,
                                        cache: MailImageCacheProtocol) -> Observable<MailImageDownloadState>? {
        guard let downloader = downloader else { return nil }

        let localPath = imageDownloadPath(token: token, thumbSize: thumbnailSize)
        var downloadType: DriveDownloadRequestCtx.DriveDownloadType = .image
        // Download image as thumbnail instead of full size
        if let size = thumbnailSize {
            downloadType = .thumbnail(width: Int(size.width), height: Int(size.height))
        }
        let ctx = DriveDownloadRequestCtx(fileToken: token,
                                          mountNodePoint: userID,
                                          localPath: localPath.url.relativeString,
                                          downloadType: downloadType,
                                          priority: priority,
                                          disableCdn: disableCdn)
        MailLogger.info("mail image DriveSDK start")

        return downloader.download(with: ctx).map { [weak self] result -> MailImageDownloadState in
            guard let self = self else { return .failed(errorCode: -1) }
            switch result.downloadStatus {
            case .failed:
                MailLogger.error("mail image DriveSDK fail with errorCode \(result.errorCode)")
                return .failed(errorCode: result.errorCode)
            case .success:
                guard let path = self.getDownloadPath(requestPath: localPath, responseContext: result) else {
                    MailLogger.error("mail image DriveSDK success invalid path")
                    return .failed(errorCode: -1)
                }
                if let data = try? Data.read(from: path) {
                    MailLogger.info("mail image DriveSDK success with bytes \(data.count)")
                    cache.set(key: cache.cacheKey(token: token, size: thumbnailSize), image: data, type: .transient, completion: {
                        try? localPath.removeItem()
                    })
                    return .success(image: data)
                } else {
                    MailLogger.error("mail image DriveSDK success data not found")
                    return .failed(errorCode: -1)
                }
            case .inflight:
                return .progress(progress: Double(result.downloadProgress.0 / result.downloadProgress.1))
            case .cancel:
                return .cancel
            case .pending, .queue, .ready:
                return .waiting
            }
        }
    }

    func cancel(token: String, session: MailSchemeDataSession) {
        // remove associated callbacks
        clearCallback(token: token, session: session)
    }
    
    // download path
    // drivesdk接口下载地址为请求地址
    // mail封装的下载接口，下载地址有两种情况：
    // 1. 不等于请求地址，mail rust会将文件下载到mail rust生成的目录， 需要使用IsoPath.parse(fromRust:)解析成IsoPath
    // 2. 下载缩略图类型，下载地址为请求的地址， 请求的地址通过IsoPath.parse(fromRust:)无法解析，只能使用请求时创建的IsoPath
    // 3. 异常情况， 下载缩略图的情况，如果后端缩略图生成失败，降级为原图，rust会推送错误的路径，这种情况需要使用请求路径（目前mail rustsdk改动较大，由客户端兼容）
    private func getDownloadPath(requestPath: IsoPath, responseContext: DriveDownloadResponseCtx) -> IsoPath? {
        if featureManager.open(.offlineCacheImageAttach, openInMailClient: false) {
            if case .thumbnail = responseContext.requestContext.downloadType {
                return requestPath
            } else if let path = responseContext.path, !path.isEmpty, let pathURL = try? IsoPath.parse(fromRust: path) {
                return pathURL
            } else {
                MailLogger.error("mail image DriveSDK invalid respone path \(responseContext.path ?? "")")
                return requestPath
            }
        } else {
            return requestPath
        }
    }

    // cache downloaded data
    private func saveData(_ data: Data, to cache: MailImageCacheProtocol, downloadInfo: DownloadInfo, completion: @escaping () -> Void) {
        if !downloadInfo.useThumb {
            MailLogger.info("MailImageDownloader save orign image data to cache key: \(downloadInfo.token.md5())")
            cache.set(key: downloadInfo.token, image: data, type: .transient, completion: completion)
        } else {
            if downloadInfo.originDataSize > data.count {
                // cache thumbnail
                let key = cache.cacheKey(token: downloadInfo.token, size: downloadInfo.thumbSize)
                MailLogger.info("MailImageDownloader save thumb image data to cache key: \(key.md5())")
                cache.set(key: key, image: data, type: .transient, completion: completion)
            } else {
                // if thumbnail generat failed, will downgrade to origin data download, cache origin data
                MailLogger.info("MailImageDownloader save orign image data to cache when downgrade to orign cache key: \(downloadInfo.token.md5())")
                cache.set(key: downloadInfo.token, image: data, type: .transient, completion: completion)
            }
        }
    }

    // get cached data
    private func cachedData(from cache: MailImageCacheProtocol, downloadInfo: DownloadInfo) -> Data? {
        if downloadInfo.useThumb {
            let key = cache.cacheKey(token: downloadInfo.token, size: downloadInfo.thumbSize)
            MailLogger.info("MailImageDownloader get thumb image from cache key: \(key.md5())")
            if let data = cache.get(key: key, type: .transient) {
                // 优先使用缩略图数据
                return data
            } else {
                // 缩略图不存在，判断是否有原图缓存（transient & persistent）
                MailLogger.info("MailImageDownloader get origin image from cache key: \(downloadInfo.token.md5())")
                return cache.get(key: downloadInfo.token)
            }
        } else {
            MailLogger.info("MailImageDownloader get orign image from cache key: \(downloadInfo.token.md5())")
            return cache.get(key: downloadInfo.token)
        }
    }


    // 由于后端支持降级（缩略图不存在的情况降级为下载原图，线上旧邮件的图片都会走降级），
    // 所以需要在下载成功后判断下载的是否是缩略图或者原图
    private func getDownloadType(_ data: Data, downloadInfo: DownloadInfo) -> MailImageDownloadType {
        if downloadInfo.originDataSize > data.count {
            return .driveThumb
        } else {
            return .driveOrigin
        }
    }
}

// callback helper
extension MailImageDownloader: MailImageDownloadCallbackHelper {
    func addCallback(token: String, session: MailSchemeDataSession?, callback: @escaping MailImageDownloadCallback) {
        let requestCallback = MailImageDownloadRequestCallback(callback: callback, dataSession: session)
        if var callbacks = callbackMap[token] {
            callbacks.append(requestCallback)
            callbackMap[token] = callbacks
        } else {
            callbackMap[token] = [requestCallback]
        }
    }

    func getAllCallbacks(token: String) -> [MailImageDownloadCallback]? {
        return callbackMap[token]?.map({ $0.callback })
    }

    func getCallback(token: String, session: MailSchemeDataSession) -> MailImageDownloadCallback? {
        return callbackMap[token]?.first(where: { $0.dataSession == session })?.callback
    }

    func clearCallback(token: String, session: MailSchemeDataSession) {
        guard var callbacks = callbackMap[token] else {
            return
        }
        let logUrl = callbacks.first?.logURLString ?? ""
        let tid = callbacks.first?.readMailThreadID ?? ""
        callbacks.removeAll(where: { $0.dataSession == session })
        callbackMap[token] = callbacks
        MailLogger.info("mail image clear one callback with url \(logUrl), tid:\(tid), remain count \(callbacks.count)")
    }

    func clearAllCallbacks(token: String) {
        let callbacks = callbackMap.removeValue(forKey: token)
        let logUrl = callbacks?.first?.logURLString ?? ""
        let tid = callbacks?.first?.readMailThreadID ?? ""
        MailLogger.info("mail image clear ALL callbacks with url \(logUrl), tid:\(tid)")
    }

    func callAllCallback(token: String, data: Data?, response: URLResponse?, error: Error?, downloadType: MailImageDownloadType) {
        guard let callbacks = getAllCallbacks(token: token) else {
            MailLogger.error("no callbacks found for token \(token.md5())")
            mailAssertionFailure("no callbacks found for token")
            return
        }

        /// call
        for callback in callbacks {
            callback(data, response, error, downloadType)
        }

        /// clear
        clearAllCallbacks(token: token)
    }
}
