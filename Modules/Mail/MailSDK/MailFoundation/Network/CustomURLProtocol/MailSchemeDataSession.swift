//
//  MailSchemeDataSession.swift
//  MailSDK
//
//  Created by majx on 2019.6.21 from DocSDK.CustomSchemeDataSession by huahuahu
//

import UIKit
import RxSwift

class MailURLError: NSError {
    private let _errorMessage: String
    
    var errorMessage: String {
        return "\(_errorMessage), \(localizedDescription)"
    }
    
    init(code: Int, errorMessage: String) {
        self._errorMessage = errorMessage
        super.init(domain: "MailURLError", code: code, userInfo: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// cid下载没有filetoken
    static var noFileToken: MailURLError {
        return MailURLError(code: -1, errorMessage: "no_filetoken")
    }
    /// Throw in all other cases
    static func unexpected(code: Int, msg: String?) -> MailURLError {
        return MailURLError(code: code, errorMessage: "MailUnexpected \(code), msg \(msg ?? "empty")")
    }
    /// DriveSDK下载错误
    static func driveError(code: Int) -> MailURLError {
        return MailURLError(code: code, errorMessage: "MailDriveError \(code)")
    }
}

typealias WebRequestInterceptCallBack = (Data?, URLResponse?, Error?) -> Void

protocol WebRequestInterceptHandleAble: AnyObject {
    func webRequestCanIntercept(urlString: String?) -> Bool
    func webRequestIntercept(urlString: String, completeHandle: WebRequestInterceptCallBack?)
}

extension WebRequestInterceptHandleAble {
    func webRequestCanIntercept(urlString: String?) -> Bool { return false }
}

protocol MailSchemeDataSessionDelegate: AnyObject {
    var provider: MailSharedServicesProvider? { get }
    func session(_ session: MailSchemeDataSession, didBeginWith newRequest: NSMutableURLRequest)
}

struct MailImageLoadInfo {
    let startTime: Int
    let isSendMail: Bool
}

// MARK: - MailSchemeDataSession 处理拦截到的网络请求
class MailSchemeDataSession: NSObject {
    private static var intercepterMap = NSHashTable<AnyObject>(options: NSPointerFunctions.Options.weakMemory)
    var urlInfoDic = [String: MailImageLoadInfo]()

    let request: URLRequest
    let disposeBag: DisposeBag = DisposeBag()
    typealias ImageLogInfo = (originURLString: String, fileTokenInfo: (fileToken: String, fileTokenResult: MailImageTokenRequsetResult)?)
    /// called before request fired
    var imageLogHandler: ((ImageLogInfo) -> Void)?

    var downloadProgressHandler: ((String) -> Void)?

    var inflightCallback: (() -> Void)?

    var userID: String? {
        sessionDelegate?.provider?.user.userID
    }

    var cacheService: MailCacheService? {
        sessionDelegate?.provider?.cacheService
    }

    lazy var coverDownloader = OfficialCoverPhotoDataProvider(configurationProvider: sessionDelegate?.provider?.provider.configurationProvider, imageService: sessionDelegate?.provider?.imageService)

    var webviewWidth: CGFloat = 0.0
    /// 读信threadID
    let readMailThreadID: String?

    private var sessionTask: MailRequest<Any>?
    private weak var sessionDelegate: MailSchemeDataSessionDelegate?
    var webviewUrl: URL?

    init(request: URLRequest, delegate: MailSchemeDataSessionDelegate?, readMailThreadID: String?) {
        self.request = request
        self.sessionDelegate = delegate
        self.readMailThreadID = readMailThreadID
        super.init()
    }

    class func composeDriveImageURL(fileToken: String, userID: String?, provider: ConfigurationProxy?) -> URL? {
        guard let userId = userID,
            let url = URL(string: MailDriveAPI.driveFileDownloadURL(fileToken: fileToken,
                                                                   mountPoint: "email",
                                                                    mountNodeToken: userId,
                                                                    provider: provider)) else {
            mailAssertionFailure("fail to create url")
            return nil
        }
        return url
    }

    /// 取得图片的下载 URL
    fileprivate func getImgDownloadUrl(from originUrl: URL) -> URL? {
        let cid = originUrl.absoluteString.replacingOccurrences(of: "cid:", with: "")
        if let imageInfo = cacheService?.object(forKey: cid) as? [String: String],
           let fileToken = imageInfo["fileToken"] {
            return MailSchemeDataSession.composeDriveImageURL(fileToken: fileToken, userID: userID,  provider: sessionDelegate?.provider?.provider.configurationProvider)
        } else {
            MailLogger.error("mail webview fail to get file token from cache cid:\(cid.md5())")
            /// mailAssertionFailure("fail to get file token from cache")
            return nil
        }
    }

    /// 发送请求
    fileprivate func requestStart(request: URLRequest, _ originUrl: URL, _ progressHandler: ProgressHandler?, _ completion: @escaping (Data?, URLResponse?, Error?, MailImageDownloadType) -> Void) {
        /// 这里先请求，若请求错误，再从缓存中查找数据
        sessionTask?.start(progressHandler: progressHandler, rawResult: { [weak self] (data, response, error) in
            /// 如果请求的shcme是token:yyy 的形式，有自己的处理逻辑
            if let provider = self?.sessionDelegate?.provider,
               provider.imageService.handleRequestCallback(originUrl: originUrl,
                                                           request: request,
                                                           response: (data, response, error)) {
                return
            }

            /// 以往的cid逻辑
            MailLogger.info("""
                MailSchemeDataSession image request response mime:
                \(response?.mimeType ?? "unknow")
                length: \(response?.expectedContentLength ?? 0)
                request url host:\(request.url?.host ?? "")
                """
                )
            /// 请求错误时，从缓存中查找数据，并返回
            guard let resultData = data, response?.expectedContentLength ?? 0 > 0 else {
                if error != nil {
                    MailLogger.info("""
                        MailSchemeDataSession image request error
                        url:\(request.url?.absoluteString ?? "")
                        | mime: \(response?.mimeType ?? "unknow")
                        | url host: \(originUrl.host)
                        | datasession error:\(String(describing: error?.desensitizedMessage))
                        """
                        )
                }
                completion(data, response, error, .http)
                return
            }
            /// 数据下载不完整，直接返回，不缓存不完整的数据
            guard let expectedContentLength = response?.expectedContentLength, resultData.count >= Int(expectedContentLength) else {
                MailLogger.info("MailSchemeDataSession image download not completed: \(originUrl.absoluteString)")
                completion(nil, response, error, .http)
                return
            }
            /// if mime type is not image, log error
            guard let mimeType = response?.mimeType, mimeType.hasPrefix("image") else {
                MailLogger.info("""
                    MailSchemeDataSession image request response mime:
 \(response?.mimeType ?? "unknow") error
| origin url: \(originUrl.absoluteString)
| request url:\(request.url?.absoluteString ?? "")
| response text: \(String(describing: String(data: resultData, encoding: .utf8)))
""")
                let user = self?.sessionDelegate?.provider?.user
                /// clean cache
                self?.cacheService?.set(object: nil, for: MailImageInfo.getImageUrlCacheKey(urlString: originUrl.absoluteString, userToken: user?.token, tenantID: user?.tenantID))
                completion(resultData, response, nil, .http)
                return
            }
            /// 完成请求并返回
            if let info = self?.urlInfoDic[originUrl.absoluteString] {
                let costTime = MailTracker.getCurrentTime() - info.startTime
                MailTracker.log(event: "mail_editor_image_load_time", params: ["is_cache": 0, "mail_cost_time": costTime, "is_send": info.isSendMail ? "1" : "2"])
            }
            completion(resultData, response, nil, .http)
            /// 更新本地缓存
            DispatchQueue.global().async { [weak self] in
                // It seems that only editor will use this session to fetch data, so it's ok for now to cache in MailEditorCacheService
                let user = self?.sessionDelegate?.provider?.user
                self?.cacheService?.set(object: resultData as NSCoding, for: MailImageInfo.getImageUrlCacheKey(urlString: originUrl.absoluteString, userToken: user?.token, tenantID: user?.tenantID))
            }
        })
    }

    /// 请求开始
    func start(isSendMail: Bool, image: MailClientDraftImage?, finishWithDrive: inout Bool, completionHandler: @escaping (Data?, URLResponse?, Error?, MailImageDownloadType) -> Void) {
        /// 判断是否有自定义的handle
        var hasCustomtHandle = false
        MailSchemeDataSession.intercepterMap.allObjects.forEach { (itemIntercepter) in
            guard hasCustomtHandle == false,
                let inter = itemIntercepter as? WebRequestInterceptHandleAble ,
                let urlString = request.url?.absoluteString,
                inter.webRequestCanIntercept(urlString: request.url?.absoluteString) else { return }
                inter.webRequestIntercept(urlString: urlString, completeHandle: { (data, response, error) in
                if data == nil, error == nil { /// 容错
                    completionHandler(nil, response, NSError(domain: "data is nil", code: -1, userInfo: nil), .unknown)
                } else {
                    completionHandler(data, response, error, .cache)
                }
            })
            hasCustomtHandle = true
        }
        guard hasCustomtHandle == false else { return }

        guard let provider = sessionDelegate?.provider else {
            mailAssertionFailure("[UserContainer] provider should not be nil in data session start")
            return
        }

        /// 请求的原始 URL
        guard let originUrl = self.request.url else {
            complteWith(error: .unexpected(code: -1, msg: "url empty"), completion: completionHandler)
            return
        }

        /// 将 request 转为 Mutable
        guard let request = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            complteWith(error: .unexpected(code: -1, msg: "request nil"), completion: completionHandler)
            return
        }

        var progressHandler: ProgressHandler?
        if let token = image?.fileToken, !token.isEmpty {
            let requestInfo = DriveImageDownloadInfo.tokenRequestInfo(token: token, image: image, displayWidth: webviewWidth)
            let result = provider.imageService.handleTokenRequest(requestInfo: requestInfo,
                                                                    requset: request,
                                                                    session: self,
                                                                    progressHandler: { [weak self] in
                                                                        self?.downloadProgressHandler?(originUrl.absoluteString)
                                                                        if let inflightCallback = self?.inflightCallback {
                                                                            inflightCallback()
                                                                            self?.inflightCallback = nil
                                                                        }
                                                                    },
                                                                    completion: {(data, response, error, downloadType) in
                // 预加载命中反馈上报
                if error == nil {
                    provider.preloadServices.preloadFeedBack(requestInfo, hitPreload: false)
                } else {
                    let hitCache = (downloadType == .cache)
                    provider.preloadServices.preloadFeedBack(requestInfo, hitPreload: hitCache)
                }
                completionHandler(data, response, error, downloadType)
            })
            // log filetoken download
            imageLogHandler?((originUrl.absoluteString, (token, result)))
            finishWithDrive = result == .driveDownload
            if result != .network {
                // if not network return.
                return
            }
            progressHandler  = { [weak self] progress in
                self?.downloadProgressHandler?(originUrl.absoluteString)
            }
        } else if originUrl.scheme == MailCustomScheme.cid.rawValue { /// cid: 协议，直接转发到真实的 URL
            let info = MailImageLoadInfo(startTime: MailTracker.getCurrentTime(), isSendMail: isSendMail)
            urlInfoDic[originUrl.absoluteString] = info
            // It seems that cache in MailCacheService is not guaranteed to exist, which may lead to failure in fetching the image data. by sheyu
            let user = sessionDelegate?.provider?.user
            if let cacheData = cacheService?.object(forKey: MailImageInfo.getImageUrlCacheKey(urlString: originUrl.absoluteString, userToken: user?.token, tenantID: user?.tenantID)) as? Data {
                MailLogger.info("complete request with cache data")
                if let info = urlInfoDic[originUrl.absoluteString] {
                    let costTime = MailTracker.getCurrentTime() - info.startTime
                    MailTracker.log(event: "mail_editor_image_load_time", params: ["is_cache": 1, "mail_cost_time": costTime, "is_send": info.isSendMail ? "1" : "2"])
                }
                completionHandler(cacheData, nil, nil, .cache)
                return
            }
            guard let downloadUrl = getImgDownloadUrl(from: originUrl) else {
                complteWith(error: .noFileToken, completion: completionHandler)
                return
            }
            imageLogHandler?((originUrl.absoluteString, nil))
            progressHandler  = { [weak self] progress in
                self?.downloadProgressHandler?(originUrl.absoluteString)
            }
            request.url = downloadUrl
        } else if originUrl.scheme == MailCustomScheme.mailAttachmentIcon.rawValue {
            /// mail-attachment-icon: 协议，用于附件的icon图片资源
            let fileName = originUrl.absoluteString
            let iconImage = MailSendAttachment.fileLadderIcon(with: fileName)
            let response = URLResponse()
            if let iconData = iconImage.pngData() {
                completionHandler(iconData, response, nil, .cache)
                return
            }
            completionHandler(nil, response, NSError(domain: "data is nil", code: -1, userInfo: nil), .unknown)
            return
        } else if originUrl.scheme == MailCustomScheme.coverTokenThumbnail.rawValue {
            let token = originUrl.absoluteString
                .substring(from: "\(MailCustomScheme.coverTokenThumbnail.rawValue):".count)
            let priority: Int32 = 50
            let thumb = OfficialCoverPhotoInfo(url: "",
                                               token: token,
                                               priority: priority,
                                               subjectColorHex: "")

            coverDownloader.fetchOfficialCoverPhotoDataWith(thumb,
                                                            coverSize: CGSize(width: 300, height: 300),
                                                            resumeBag: disposeBag) { image, error, downloadType in
                let response = URLResponse()
                if let error = error {
                    completionHandler(nil, response, error, downloadType)
                } else if let image = image, let imgData = image.data(quality: 1) {
                    completionHandler(imgData, response, nil, downloadType)
                } else {
                    // 兜底
                    completionHandler(nil, response, NSError(domain: "cover call all ni", code: -1, userInfo: nil), downloadType)
                }
            }

            return
        } else if originUrl.scheme == MailCustomScheme.coverTokenFull.rawValue {
            let token = originUrl.absoluteString
                .substring(from: "\(MailCustomScheme.coverTokenFull.rawValue):".count)

            let photoInfo = OfficialCoverPhotoInfo(url: "",
                                                   token: token,
                                                   priority: 10,
                                                   subjectColorHex: "")


            coverDownloader.fetchOfficialCoverPhotoDataWith(photoInfo,
                                                            coverSize: nil,
                                                            resumeBag: disposeBag) { image, error, downloadType in
                let response = URLResponse()
                if let error = error {
                    completionHandler(nil, response, error, downloadType)
                } else if let image = image, let imgData = image.data(quality: 1) {
                    completionHandler(imgData, response, nil, downloadType)
                } else {
                    // 兜底
                    completionHandler(nil, response, NSError(domain: "cover call all ni", code: -1, userInfo: nil), downloadType)
                }
            }

            return
        } else {
            request.url = originUrl
        }

        /// 系统下载没有出队回调，默认发起请求后就开始下载
        if inflightCallback != nil {
            inflightCallback?()
            inflightCallback = nil
        }

        /// 构造网络请求
        sessionDelegate?.session(self, didBeginWith: request)
        sessionTask = MailRequest(request: request as URLRequest, trafficType: .mailFetch)
        requestStart(request: request as URLRequest, originUrl, progressHandler, completionHandler)
    }

    /// 完成请求错误，如果是图片，表现为图片裂掉
    func complteWith(error: MailURLError, completion: @escaping (Data?, URLResponse?, MailURLError?, MailImageDownloadType) -> Void) {
        MailLogger.error("mail webview url error in webview custom scheme request")
        DispatchQueue.global().async {
            completion(nil, nil, error, .unknown)
        }
    }

    func stop() {
        guard let provider = sessionDelegate?.provider else {
            mailAssertionFailure("[UserContainer] provider should not be nil in data session stop")
            return
        }

        provider.imageService.handleRequestStop(session: self)
        let token = provider.imageService.htmlAdapter.getTokenFromUrl(request.url)
        if let callback = provider.imageService.imageDownloadCallbacks.getAllCallbacks(token: token), callback.count > 0 {
            // 还有callback，不需要停止request
            MailLogger.info("MailSchemeDataSession token, \(token), callbacks remain count: \(callback.count)")
        } else {
            // 没有callback依赖，停止request
            MailLogger.info("MailSchemeDataSession stop request \(token)")
            sessionTask?.cancel()
            sessionTask = nil
        }
    }
}
