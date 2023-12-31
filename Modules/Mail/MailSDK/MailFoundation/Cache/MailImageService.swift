//
//  MailImageService.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/3/4.
//

import Foundation
import RxSwift
import RxRelay
import LarkStorage

class MailImageService {
    let cache: MailImageCacheProtocol
    let htmlAdapter: MailHtmlImageAdapterProtocol
    let imageAdapter: MailHtmlImageAdapterProtocol
    //var rustTaskTable = BehaviorRelay(value: [String: RustSchemeTaskWrapper]())
    var _rustTaskTable = [String: RustSchemeTaskWrapper]()
    var downloadTask = BehaviorRelay<(String, RustSchemeTaskWrapper?)>(value: ("", nil))

    init(
        userID: String,
        cacheService: MailCacheService,
        driveProvider: DriveDownloadProxy?,
        imageCache: MailImageCacheProtocol,
        featureManager: UserFeatureManager
    ) {
        self.cache = imageCache
        self.htmlAdapter = MailHtmlImageAdapter(cacheService: cacheService)
        self.imageAdapter = MailThirdPartyImageAdapter(cacheService: cacheService)
        self._imageDownloader = MailImageDownloader(userID: userID, driveProvider: driveProvider, featureManager: featureManager)
        MailCommonDataMananger
            .shared
            .downloadPushChange
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] change in
                self?.mailDownloadPushChange(change)
            }).disposed(by: disposeBag)
    }

    func mailDownloadPushChange(_ change: MailDownloadPushChange) {
        MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange -- key: \(change.key) status: \(change.status) filePath: \(change.path?.fileName ?? "")")
        let key = change.key
        let rustTaskTable = _rustTaskTable//.value
        guard let rustTask = rustTaskTable[key] else {
            MailLogger.error("[mail_client_att] webview mail download mailDownloadPushChange ❌ push 在callback更新task队列之前达到")
            return
        }
        rustTask.downloadChange = change
        _rustTaskTable.updateValue(rustTask, forKey: key)
        downloadTask.accept((key, rustTask))
        switch change.status {
        case .success:
            guard var path = change.path else {
                MailLogger.error("[mail_client_att] webview mail download mailDownloadPushChange success-- key: \(change.key) but path is nil")
                return
            }
            guard let schemeTask = rustTask.task else {
                MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange 非内联图片 -- task为空")
                return
            }
            let originUrl = rustTask.webURL
            var data: Data?
            if AbsPath(path).exists {
                data = try? Data.read(from: AbsPath(path))
            } else {
                // 兜底
                path = path.correctPath
                data = try? Data.read(from: AbsPath(path))
            }
            let defaultResponse = URLResponse(url: originUrl ?? URL(fileURLWithPath: path), mimeType: path.extension,
                                              expectedContentLength: data?.count ?? 0, textEncodingName: nil)
            if let data = data, let url = originUrl {
                // 记录下载成功，读信界面通过loadImageMonitorDelegate上报tea和apm
                rustTask.loadImageMonitorDelegate?.onWebViewFinishImageDownloading(with: url.absoluteString, dataLength: data.count, finishWithDrive: false, downloadType: .rust)
            }

            schemeTask.didReceive(defaultResponse)
            schemeTask.didReceive(data ?? Data())
            schemeTask.didFinish()

            if let event = rustTask.apmEvent { // 写信场景上报
                let cost = MailTracker.getCurrentTime() - Int(1000 * event.recordDate.timeIntervalSince1970)
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.upload_ms(cost))
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.resource_content_length((data ?? Data()).count))
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_cache(0))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.download_type(MailImageDownloadType.rust.rawValue))
                event.postEnd()
            }

            removeRespKey(key)
        case .pending:
            MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange-- key: \(change.key) status: \(change.status)")
        case .inflight:
            MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange-- key: \(change.key) status: \(change.status)")
            if let url = rustTask.webURL {
                // Tea: 记录开始下载时间
                rustTask.loadImageMonitorDelegate?.onWebViewImageDownloading(with: url.absoluteString)
            }
        case .failed:
            MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange-- key: \(change.key) status: \(change.status) sandbox: \(AbsPath.home)")
            if let url = rustTask.webURL {
                // 记录下载失败, 读信场景通过loadImageMonitorDelegate上报tea和apm
                var errorInfo: APMErrorInfo?
                if let failedInfo = change.failedInfo {
                    errorInfo = (code: Int(failedInfo.errorCode), errMsg: failedInfo.errorMessage)
                }
                rustTask.loadImageMonitorDelegate?.onWebViewImageDownloadFailed(with: url.absoluteString,
                                                                                finishWithDrive: false,
                                                                                downloadType: .rust,
                                                                                errorInfo: errorInfo)
            }
            if let event = rustTask.apmEvent {
                if let failedInfo = change.failedInfo {
                    event.endParams.appendError(errorCode: Int(failedInfo.errorCode), errorMessage: "\(failedInfo.errorMessage)")
                }
                let cost = MailTracker.getCurrentTime() - Int(1000 * event.recordDate.timeIntervalSince1970)
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.upload_ms(cost))
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_cache(0))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.resource_content_length(0))
                event.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.download_type(MailImageDownloadType.rust.rawValue))
                event.postEnd()
            }
            let errorCode = Int(change.failedInfo?.errorCode ?? -1)
            let error = NSError(domain: "mail.rust.download", code: errorCode)
            rustTask.task?.didFailWithError(error)

            removeRespKey(key)
        case .cancel:
            fallthrough
        @unknown default:
            MailLogger.info("[mail_client_att] webview mail download mailDownloadPushChange-- key: \(change.key) status: \(change.status)")
        }
    }

    func startDownTask(_ task: (String, RustSchemeTaskWrapper)) {
        _rustTaskTable.updateValue(task.1, forKey: task.0)
        downloadTask.accept(task)
    }

    func cancelClientDownload() {
        for respKey in _rustTaskTable.keys {
            removeRespKey(respKey)
            MailDataSource.shared.fetcher?.mailCancelDownload(respKey: respKey)
                .subscribe(onNext: { _ in
                    MailLogger.info("[mail_client_att] msglist mailCancelDownload attachment success: \(respKey)")
                }, onError: { (error) in
                    MailLogger.error("[mail_client_att] msglist mailCancelDownload error: \(error)")
                }).disposed(by: self.disposeBag)
        }
        _rustTaskTable.removeAll()
    }

    func removeRespKey(_ key: String) {
        _rustTaskTable.removeValue(forKey: key)
    }

    var imageDownloader: MailImageDownloaderProtocol {
        return _imageDownloader
    }

    var imageDownloadCallbacks: MailImageDownloadCallbackHelper {
        return _imageDownloader
    }

    let disposeBag = DisposeBag()

    // MARK: PRIVATE
    private let _imageDownloader: MailImageDownloader
}

typealias MailImageSessionTaskResponse = (Data?, URLResponse?, Error?)

enum MailImageTokenRequsetResult {
    case errorToken
    case cache
    case repeatToken
    case driveDownload
    case network
}

// convenience interface
extension MailImageService {
    /// if return true. mean call back called immediately
    func handleTokenRequest(requestInfo: DriveImageDownloadInfo,
                            requset: NSMutableURLRequest,
                            session: MailSchemeDataSession,
                            progressHandler: @escaping (() -> Void),
                            completion: @escaping MailImageDownloadCallback) -> MailImageTokenRequsetResult {
        // check token.
        guard !requestInfo.token.isEmpty else {
            complteWith(error: .noFileToken, completion: completion)
            return .errorToken
        }

        let md5Token = requestInfo.token.md5()

        // if cache. return
        if let data = cacheData(info: requestInfo) {
            MailLogger.info("mail image token handler: cache(md5) \(md5Token)")
            completion(data, nil, nil, .cache)
            return .cache
        }
        // cache call back. if request already create
        if let callbacks = imageDownloadCallbacks.getAllCallbacks(token: requestInfo.token), !callbacks.isEmpty {
            MailLogger.info("mail image token handler: repeatToken(md5) \(md5Token)")
            imageDownloadCallbacks.addCallback(token: requestInfo.token, session: session, callback: completion)
            return .repeatToken
        }

        MailLogger.info("mail image token handler: network(md5) \(md5Token)")
        // 使用DriveSDK下载
        MailLogger.info("mail image token start download via DriveSDK")
        imageDownloader.downloadWithDriveSDKCallback(info: requestInfo,
                                                     priority: .userInteraction,
                                                     session: session,
                                                     progressHandler: progressHandler,
                                                     callback: completion,
                                                     cache: cache)
        return .driveDownload
    }

    /// handle session request call back.
    func handleRequestCallback(originUrl: URL,
                               request: URLRequest,
                               response res: MailImageSessionTaskResponse) -> Bool {
        let token = htmlAdapter.getTokenFromUrl(originUrl)
        guard token.count > 0 else {
            return false
        }

        let (data, response, error) = res
        MailLogger.info("""
            mail image request response mime: \(response?.mimeType ?? "unknow")
            length: \(response?.expectedContentLength ?? 0)
            """
        )
        /// 请求错误时，从缓存中查找数据，并返回
        guard let resultData = data, response?.expectedContentLength ?? 0 > 0 else {
            if let error = error {
                MailLogger.info("""
                    mail image request error:
                    | mime: \(response?.mimeType ?? "unknow")
                    | datasession error:\(error)
                    """
                    )
            }
            callAllCallback(token: token, data: data, response: response, error: error, downloadType: .http)
            return true
        }
        /// 数据下载不完整，直接返回，不缓存不完整的数据
        guard let expectedContentLength = response?.expectedContentLength, resultData.count >= Int(expectedContentLength) else {
            MailLogger.info("mail image download not completed")
            callAllCallback(token: token, data: nil, response: response, error: error, downloadType: .http)
            return true
        }
        /// if mime type is not image, log error
        guard let mimeType = response?.mimeType, mimeType.hasPrefix("image") else {
            MailLogger.info("""
                mail image request response mime:
\(response?.mimeType ?? "unknow")
error | response text: \(String(data: resultData, encoding: .utf8) ?? "nil")
""")
            /// clean cache
            cache.clear(key: token, type: .transient, completion: {})
            callAllCallback(token: token, data: resultData, response: response, error: nil, downloadType: .http)
            return true
        }
        /// 完成请求并返回
        callAllCallback(token: token, data: resultData, response: response, error: nil, downloadType: .http)
        /// 子线程将图片缓存起来
        DispatchQueue.global().async {
            self.cache.set(key: token, image: resultData, type: .transient, completion: {})
        }
        return true
    }

    func handleRequestStop(session: MailSchemeDataSession) {
        guard let originUrl = session.request.url else {
            return
        }
        let token = htmlAdapter.getTokenFromUrl(originUrl)
        imageDownloader.cancel(token: token, session: session)
    }

    private func cacheData(info: DriveImageDownloadInfo) -> Data? {
        if info.useThumb {
            let key = cache.cacheKey(token: info.token, size: info.thumbSize)
            if let data = cache.get(key: key) {
                // 优先使用缩略图数据
                return data
            } else {
                // 缩略图不存在，判断是否有原图缓存(transient & persistent)
                return cache.get(key: info.token)
            }
        } else {
            return cache.get(key: info.token)
        }
    }
}

// internal
extension MailImageService {
    /// 完成请求错误，如果是图片，表现为图片裂掉
    private func complteWith(error: MailURLError, completion: @escaping MailImageDownloadCallback) {
        MailLogger.error("mail webview url error in webview custom scheme request")
        DispatchQueue.global().async {
            // 还没启动下载流程就失败了，downloadType传unknown
            completion(nil, nil, error, .unknown)
        }
    }

    func callAllCallback(token: String, data: Data?, response: URLResponse?, error: Error?, downloadType: MailImageDownloadType) {
        imageDownloadCallbacks.callAllCallback(token: token, data: data, response: response, error: error, downloadType: downloadType)
    }
}

extension String {
    var `extension`: String {
        if let index = self.lastIndex(of: ".") {
            return String(self[index...]).replacingOccurrences(of: ".", with: "")
        } else {
            return ""
        }
    }

    var fileName: String {
        var name = self
        let pathMark = "mail_file/message/"
        let splitRange = name.range(of: pathMark)
        if let splitIndex = splitRange?.lowerBound {
            let count: Int = name.distance(from: name.startIndex, to: splitIndex)
            let index = name.index(name.startIndex, offsetBy: count)
            name = String(name.suffix(from: index)).replacingOccurrences(of: pathMark, with: "")
            if let range = name.range(of: "_", options: .literal) {
                let count = name.distance(from: name.startIndex, to: range.lowerBound)
                let index = name.index(name.startIndex, offsetBy: count)
                return String(name.suffix(from: index))
                    .replacingOccurrences(of: "_", with: "", options: .literal,
                                          range: name.rangeFromNSRange(nsRange: NSRange(location: 0, length: 1)))
            }
        }
        return ""
    }

    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        return Range(nsRange, in: self)
    }

    var correctPath: String {
        let splitRange = self.range(of: "/Documents/sdk_storage")
        if let splitIndex = splitRange?.lowerBound {
            let count: Int = self.distance(from: self.startIndex, to: splitIndex)
            let index = self.index(self.startIndex, offsetBy: count)
            return self.replacingOccurrences(of: String(self.prefix(upTo: index)), with: "\(AbsPath.home)")
        }
        MailLogger.error("vvImage webview mail download path is error, rust should fix it")
        return self
    }
}
