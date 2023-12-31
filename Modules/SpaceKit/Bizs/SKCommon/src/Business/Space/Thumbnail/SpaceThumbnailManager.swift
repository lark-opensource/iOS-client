//
//  SpaceThumbnailManager.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  
//swiftlint:disable file_length

import Foundation
import UIKit
import RxSwift
import SKFoundation
import SKResource
import UniverseDesignEmpty
import SpaceInterface

public protocol SpaceThumbnailManagerBase: AnyObject {
    var totalCacheSize: Observable<Float> { get }
    func cleanMemoryCache()
    func cleanAllCache(completion: (() -> Void)?)
}


extension SpaceThumbnailManager {

    public typealias Info = SpaceThumbnailInfo
    public typealias Downloader = SpaceThumbnailDownloader
    public typealias DownloadRequest = Downloader.Request
    public typealias DownloadResponse = Downloader.Response<UIImage>
    public typealias Cache = SpaceThumbnailCache
    public typealias Thumbnail = Cache.Thumbnail
    public typealias Statistic = SpaceThumbnailStatistic
    public typealias Source = Statistic.Source
    public typealias Config = SpaceThumbnailConfig

    public enum ThumbnailError: LocalizedError {
        case thumbnailExpired(etag: String?)
        case thumbnailUnavailable

        public var errorDescription: String? {
            switch self {
            case .thumbnailExpired:
                return "thumbnail exipred"
            case .thumbnailUnavailable:
                return "thumbnail unavailable and not placeholder image is provided"
            }
        }
    }

    public struct Request {

        let token: String
        let info: Info
        let source: Source
        let fileType: DocsType
        // 缓存不存在时会使用此图片
        let placeholderImage: UIImage?
        // 网络请求失败会使用此图片
        let failureImage: UIImage?
        // 是否强制向后台检查更新
        var forceCheckForUpdate: Bool
        // 操作缩略图
        var processer: SpaceThumbnailProcesser

        var cacheTag: String

        fileprivate var cacheKey: String {
            // 读写缓存时，去掉 URL 里的 timestamp 参数，避免 URL 刷新时缓存时效
            let urlKey = info.url.docs.deleteQuery(key: "timestamp")
            let encryptURLString = DocsTracker.encrypt(id: urlKey.absoluteString)
            return encryptURLString + source.rawValue + DocsSDK.currentLanguage.localeIdentifier + cacheTag
        }

        // URL 中的 timestamp 参数，用于辅助判断缓存是否过期
        fileprivate var urlTimestamp: TimeInterval? {
            guard let timestampString = info.url.docs.queryParams?["timestamp"],
                  let timestamp = Double(timestampString) else {
                return nil
            }
            return timestamp
        }

        public init(token: String, info: SpaceThumbnailManager.Info, source: SpaceThumbnailManager.Source,
                    fileType: DocsType, placeholderImage: UIImage?,
                    failureImage: UIImage?, forceCheckForUpdate: Bool = false,
                    processer: SpaceThumbnailProcesser = SpaceDefaultProcesser(), cacheTag: String = "") {
            self.token = token
            self.info = info
            self.source = source
            self.fileType = fileType
            self.placeholderImage = placeholderImage
            self.failureImage = failureImage
            self.forceCheckForUpdate = forceCheckForUpdate
            self.processer = processer
            self.cacheTag = cacheTag
        }
    }

    // 缩略图请求上下文，用于打点、记录缓存key
    private class Context {
        let token: String
        var url: String
        let cacheKey: String
        let source: Source
        let fileType: DocsType
        var isEncrypt = false
        var startTime = Date().timeIntervalSince1970
        let processer: SpaceThumbnailProcesser
        var fileSize: Int = 0
        let urlTimestamp: TimeInterval?

        init(token: String,
             url: String,
             cacheKey: String,
             source: Source,
             fileType: DocsType,
             urlTimestamp: TimeInterval?,
             processer: SpaceThumbnailProcesser) {
            self.token = token
            self.url = url
            self.cacheKey = cacheKey
            self.source = source
            self.fileType = fileType
            self.urlTimestamp = urlTimestamp
            self.processer = processer
        }
    }

    public enum ImageType {
        // 正常的缩略图
        case thumbnail
        // 后台返回的特殊图片（被删除、无权限、空文档等）
        case specialImage
        // 传入的占位图
        case placeholderImage
        // 传入的失败兜底图
        case failureImage
        // 从内存缓存读取时（有缓存时的首次回调），无法获取 imageType，后续会返回正确的类型
        case unknown
    }

    public struct Response {
        public let image: UIImage
        public let type: ImageType

        public init(image: UIImage, type: ImageType) {
            self.image = image
            self.type = type
        }

        public init?(image: UIImage?, type: ImageType) {
            guard let realImage = image else { return nil }
            self.image = realImage
            self.type = type
        }
    }
}

public final class SpaceThumbnailManager {

    public let config: Config
    let cache: Cache
    let downloader: Downloader
    // 临时提供给非 RX 接口 dispose 用，后续需要推动各接口改造
    public private(set) var tmpDisposeBag = DisposeBag()

    init() {
        self.config = Config()
        self.cache = Cache()
        self.downloader = Downloader()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidLogin),
                                               name: Notification.Name.Docs.userDidLogin,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userWillLogout),
                                               name: Notification.Name.Docs.userWillLogout,
                                               object: nil)
    }

    @objc
    private func userDidLogin() {
        DocsLogger.info("space.thumbnail.manager --- prepare to setup for user did login notification")
    }

    @objc
    private func userWillLogout() {
        DocsLogger.info("space.thumbnail.manager --- cleaning up for user will logout notification")
        cache.cleanAllCache()
        tmpDisposeBag = DisposeBag()
    }

    public func getThumbnail(url: URL, source: Source,
                             token: String? = nil,
                             docsType: DocsType = .unknownDefaultType,
                             placeHolderImage: UIImage? = nil,
                             failureImage: UIImage? = nil,
                             processer: SpaceThumbnailProcesser = SpaceDefaultProcesser(),
                             cacheTag: String = "") -> Observable<UIImage> {
        let info = Info.unencryptOnly(unencryptURL: url)
        let request = Request(token: token ?? source.rawValue,
                              info: info,
                              source: source,
                              fileType: docsType,
                              placeholderImage: placeHolderImage,
                              failureImage: failureImage,
                              processer: processer,
                              cacheTag: cacheTag)
        return getThumbnail(request: request)
    }

    public func getThumbnail(request: Request) -> Observable<UIImage> {
        getThumbnailWithType(request: request).map(\.image)
    }

    // swiftlint:disable cyclomatic_complexity
    public func getThumbnailWithType(request: Request) -> Observable<Response> {
        // KA 场景下: 如果禁用 Drive，使用默认的占位图
        if request.fileType == .file, !DriveFeatureGate.driveEnabled {
            let placeHolderImage = BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail.kf.image(withBlendMode: .normal, alpha: 1.0, backgroundColor: UIColor.ud.N00.nonDynamic)
            return .just(Response(image: placeHolderImage, type: .specialImage))
        }

        let context = Context(token: request.token,
                              url: request.info.url.absoluteString,
                              cacheKey: request.cacheKey,
                              source: request.source,
                              fileType: request.fileType,
                              urlTimestamp: request.urlTimestamp,
                              processer: request.processer)

        DocsLogger.info("space.thumbnail.manager --- getThumbnail source:\(request.source) cacheKey:\(DocsTracker.encrypt(id: request.cacheKey))")
        /// 先读取缓存
        let thumbnailImageObservable = cache.get(key: request.cacheKey)
            .asObservable()
            .flatMap { (thumbnail) -> Observable<Response> in
                DocsLogger.info("space.thumbnail.manager --- get response from cache cacheKey:\(DocsTracker.encrypt(id: request.cacheKey))")
                let thumbnail = context.processer.process(thumbnail: thumbnail)
                var response: Response?
                if let image = Self.image(for: thumbnail.type, context: context) {
                    if case .thumbnail = thumbnail.type {
                        response = Response(image: image, type: .thumbnail)
                    } else {
                        response = Response(image: image, type: .specialImage)
                    }
                } else if let image = request.placeholderImage {
                    response = Response(image: image, type: .placeholderImage)
                }
                let cacheOutdated = if let urlTimestamp = request.urlTimestamp, urlTimestamp > thumbnail.updatedTime {
                    true
                } else {
                    false
                }
                // 如果缓存过期，或者 request 中要求强制检查更新，就向后台请求新的缩略图
                if thumbnail.isExpired || request.forceCheckForUpdate || cacheOutdated {
                    DocsLogger.info("space.thumbnail.manager --- checking thumbnail need update")
                    return Observable.create { observer in
                        if let image = response {
                            observer.on(.next(image))
                        }
                        // 缓存过期时，抛出异常
                        observer.on(.error(ThumbnailError.thumbnailExpired(etag: thumbnail.etag)))
                        return Disposables.create()
                    }
                }
                guard let image = response else {
                    // 没封面图，且没有提供占位图
                    return .error(ThumbnailError.thumbnailUnavailable)
                }
                // 读取到缓存，且缓存没有过期
                let result = Statistic.Result(source: context.source,
                                              isSucceed: true,
                                              fileType: context.fileType,
                                              url: request.info.url.absoluteString,
                                              isUpdate: false,
                                              errorMsg: nil,
                                              code: nil)
                Statistic.report(result: result)
                return .just(image)
            }
            /// 缓存读取失败或者缓存过期，下载缩略图
            .catchError { [weak self] error in
                guard let self = self else { return .error(ThumbnailError.thumbnailUnavailable) }
                let thumbnaileTag: String?
                let downloadPlaceHolder: Observable<Response>
                if let thumbnailError = error as? ThumbnailError {
                    switch thumbnailError {
                    case let .thumbnailExpired(etag):
                        // 如果缓存过期，读取 etag
                        thumbnaileTag = etag
                        downloadPlaceHolder = .empty()
                    case .thumbnailUnavailable:
                        DocsLogger.error("space.thumbnail.manager --- thumbnail unavailable")
                        let result = Statistic.Result(source: context.source,
                                                      isSucceed: false,
                                                      fileType: context.fileType,
                                                      url: request.info.url.absoluteString,
                                                      isUpdate: false,
                                                      errorMsg: error.localizedDescription,
                                                      code: nil)
                        Statistic.report(result: result)
                        if let failureImage = request.failureImage {
                            return .just(Response(image: failureImage, type: .failureImage))
                        } else {
                            return .error(error)
                        }
                    }
                } else {
                    DocsLogger.error("space.thumbnail.manager --- get cache failed with error", error: error)
                    thumbnaileTag = nil
                    // 读取缓存失败时，需要先显示占位图（若有）
                    downloadPlaceHolder = .from(optional: Response(image: request.placeholderImage,
                                                                   type: .placeholderImage))
                }

                let downloadObservable = self.downloadThumbnail(request: request, etag: thumbnaileTag, context: context)
                    .catchError { error in
                        // 下载缩略图失败用错误图兜底
                        DocsLogger.error("space.thumbnail.manager --- download thumbnail failed with error", error: error)
                        var result = Statistic.Result(source: context.source,
                                                      isSucceed: false,
                                                      fileType: context.fileType,
                                                      url: request.info.url.absoluteString,
                                                      isUpdate: false,
                                                      errorMsg: error.localizedDescription,
                                                      code: nil)
                        if let downloadError = error as? Downloader.DownloadError {
                            if case let .unknownStatusCode(code) = downloadError {
                                result.code = code
                            } else if case let .unknownBusinessCode(code) = downloadError {
                                result.code = code
                            }
                        }
                        Statistic.report(result: result)
                        if let failureImage = request.failureImage {
                            return .just(Response(image: failureImage, type: .failureImage))
                        } else {
                            return .error(error)
                        }
                    }
                return downloadPlaceHolder.concat(downloadObservable)
            }

        /// 为了解决列表刷新时的闪烁问题，这里会尝试获取 memoryCache 中的图片，以保证在同一个 runloop 中读取到图片
        /// 注意，getMemoryCache 方法可能会阻塞当前线程
        var memoryImage = cache.getMemoryCache(key: request.cacheKey)
        if let originMemoryImage = memoryImage {
            memoryImage = context.processer.process(image: originMemoryImage)
        }
        let memoryImageObservable = Observable<Response>
            .from(optional: Response(image: memoryImage, type: .unknown))
            .do(onNext: { _ in
                DocsLogger.info("space.thumbnail.manager --- get thumbnail from memory cache cacheKey:\(DocsTracker.encrypt(id: request.cacheKey))")
            })
        return memoryImageObservable.concat(thumbnailImageObservable.observeOn(MainScheduler.instance))
    }
    // swiftlint:enable cyclomatic_complexity

    private static func reportInfo(with context: Context) {
        let endTime = Date().timeIntervalSince1970
        let pastTime = endTime - context.startTime
        let info = Statistic.Info(isEncrypt: context.isEncrypt,
                                  fileType: context.fileType,
                                  source: context.source,
                                  costTime: Int(pastTime * 1000),
                                  fileSize: context.fileSize)
        Statistic.report(info: info)
    }
}

extension SpaceThumbnailManager {
    public func markExpire(requests: [Request]) {
        let keys = requests.map(\.cacheKey)
        cache.markExpire(keys: keys)
    }
}

// MARK: - 下载的逻辑
extension SpaceThumbnailManager {

    /// 根据加密方式配置下载请求
    private func downloadThumbnail(request: Request, etag: String?, context: Context) -> Maybe<Response> {
        switch request.info {
        case let .unencryptOnly(unencryptURL):
            let downloadRequest = DownloadRequest(url: unencryptURL, encryptType: .noEncryption, etag: etag)
            return downloadThumbnail(request: downloadRequest, context: context)
        case let .encryptedOnly(encryptInfo):
            context.isEncrypt = true
            let downloadRequest = DownloadRequest(url: encryptInfo.url, encryptType: encryptInfo.encryptType, etag: etag)
            return downloadThumbnail(request: downloadRequest, context: context)
        case let .encryptedAndUnencrypt(encryptInfo, unencryptURL):
            guard encryptInfo.encryptType.isSupported else {
                // 加密方式不支持，降级为下载未加密的缩略图
                context.url = unencryptURL.absoluteString
                let downloadRequest = DownloadRequest(url: unencryptURL, encryptType: .noEncryption, etag: etag)
                return self.downloadThumbnail(request: downloadRequest, context: context)
            }
            context.url = encryptInfo.url.absoluteString
            context.isEncrypt = true
            let downloadRequest = DownloadRequest(url: encryptInfo.url, encryptType: encryptInfo.encryptType, etag: etag)
            return downloadThumbnail(request: downloadRequest, context: context)
                .catchError { [weak self] error -> Maybe<Response> in
                    guard let self = self else {
                        return .error(error)
                    }
                    if let decryptError = error as? Downloader.DownloadError,
                        case let .decryptionFailed(detailError) = decryptError {
                        DocsLogger.error("space.thumbnail.manager --- decrypt thumbnail failed, fallback to download unencrypt thumbnail", error: detailError)
                        // 解密错误下载未加密的缩略图进行兜底
                        // 更新埋点 URL 为未加密的缩略图 URL
                        context.url = unencryptURL.absoluteString
                        context.isEncrypt = false
                        let downloadRequest = DownloadRequest(url: unencryptURL, encryptType: .noEncryption, etag: etag)
                        return self.downloadThumbnail(request: downloadRequest, context: context)
                    }
                    return .error(error)
                }
        }
    }

    /// 下载缩略图并处理结果
    private func downloadThumbnail(request: DownloadRequest, context: Context) -> Maybe<Response> {
        return downloader.download(request: request)
            .flatMapMaybe { response -> Maybe<Response> in
                self.handle(response: response, context: context)
            }
    }

    /// 处理下载结果
    private func handle(response: DownloadResponse, context: Context) -> Maybe<Response> {
        DocsLogger.info("space.thumbnail.manager --- start handling thumbnail response")
        let cacheKey = context.cacheKey
        var result = Statistic.Result(source: context.source,
                                      isSucceed: true,
                                      fileType: context.fileType,
                                      url: context.url,
                                      isUpdate: true,
                                      errorMsg: nil,
                                      code: nil)
        defer {
            Statistic.report(result: result)
            Self.reportInfo(with: context)
        }
        var preProcessedImage: UIImage?
        // 若请求结果需要保存到缓存，存储到缓存中
        if let originThumbnail = Self.createThumbnail(from: response, context: context) {
            let thumbnail = context.processer.preProcess(thumbnail: originThumbnail)
            if case let .thumbnail(image, _) = thumbnail.type {
                preProcessedImage = image
            } else if case let .specialPlaceholder(image, _) = thumbnail.type {
                preProcessedImage = image
            }
            DocsLogger.info("space.thumbnail.manager --- saving thumbnail result")
            cache.save(key: cacheKey, token: context.token, thumbnail: thumbnail)
        }
        var responseImage: Response?
        switch response {
        case .resourceNotModified:
            DocsLogger.info("space.thumbnail.manager --- handle not modified thumbnail")
            // 复用缓存时，更新缓存记录的最后更新时间
            cache.update(key: cacheKey)
            // 缩略图没有改变时，更新埋点数据
            result.isUpdate = false
            context.isEncrypt = false
            return .empty()
        case .fileIsEmpty:
            DocsLogger.info("space.thumbnail.manager --- handle empty file thumbnail")
            let image = Self.specialImage(type: .emptyContent, context: context)
            responseImage = Response(image: image, type: .specialImage)
            // 缩略图为空白，更新埋点数据
            context.isEncrypt = false
        case .fileDeleted:
            DocsLogger.info("space.thumbnail.manager --- handle deleted file thumbnail")
            let image = Self.specialImage(type: .contentDeleted, context: context)
            responseImage = Response(image: image, type: .specialImage)
            // 文件不存在，更新埋点数据
            context.isEncrypt = false
        case .generating,
             .coverUnavailable,
             .coverNotExist:
            DocsLogger.info("space.thumbnail.manager --- handle unavailable thumbnail")
            responseImage = nil
            // 文件没有缩略图，更新埋点数据
            context.isEncrypt = false
        case let .specialPlaceHolder(image, _):  // 空白、无权限、后台生成失败、源文件已删除
            DocsLogger.info("space.thumbnail.manager --- handle special thumbnail")
            context.fileSize = (image.pngData()?.bytes.count ?? 0) / 1024
            if let previousProcessedImage = preProcessedImage {
                let image = context.processer.process(image: previousProcessedImage)
                responseImage = Response(image: image, type: .specialImage)
            } else {
                let tmpImage = context.processer.preProcess(image: image)
                let finalImage = context.processer.process(image: tmpImage)
                responseImage = Response(image: finalImage, type: .specialImage)
            }
        case let .success(image, _):
            DocsLogger.info("space.thumbnail.manager --- handle standard thumbnail")
            context.fileSize = (image.pngData()?.bytes.count ?? 0) / 1024
            if let previousProcessedImage = preProcessedImage {
                let image = context.processer.process(image: previousProcessedImage)
                responseImage = Response(image: image, type: .thumbnail)
            } else {
                let tmpImage = context.processer.preProcess(image: image)
                let finalImage = context.processer.process(image: tmpImage)
                responseImage = Response(image: finalImage, type: .thumbnail)
            }

        }
        guard let thumbnailImage = responseImage else {
            return .error(ThumbnailError.thumbnailUnavailable)
        }
        return .just(thumbnailImage)
    }
}

// MARK: - 特殊图片的相关逻辑
extension SpaceThumbnailManager {

    private enum SpecialImageType {
        case emptyContent
        case contentDeleted
    }

    private static func createThumbnail(from downloadResponse: DownloadResponse, context: Context) -> Thumbnail? {
        let type: Thumbnail.ThumbnailType
        switch downloadResponse {
        case .resourceNotModified:
            return nil
        case .fileIsEmpty:
            let image = Self.image(for: .emptyContent(image: nil), context: context)
            type = .emptyContent(image: image)
        case .fileDeleted:
            let image = Self.image(for: .contentDeleted(image: nil), context: context)
            type = .contentDeleted(image: image)
        case .generating:
            type = .generating
        case .coverUnavailable,
             .coverNotExist:
            type = .unavailable
        case let .specialPlaceHolder(image, etag):
            type = .specialPlaceholder(image: image, etag: etag)
        case let .success(image, etag):
            type = .thumbnail(image: image, etag: etag)
        }
        let updatedTime = Date().timeIntervalSince1970
        return Thumbnail(updatedTime: updatedTime, type: type)
    }

    private static func image(for type: Thumbnail.ThumbnailType, context: Context) -> UIImage? {
        switch type {
        case let .thumbnail(image, _),
             let .specialPlaceholder(image, _):
            return image
        case .emptyContent:
            return specialImage(type: .emptyContent, context: context)
        case .contentDeleted:
            return specialImage(type: .contentDeleted, context: context)
        case .generating:
            DocsLogger.error("space.thumbnail.manager --- unable to create thumbnail when thumbnail is generating")
            return nil
        case .unavailable:
            DocsLogger.error("space.thumbnail.manager --- unable to create thumbnail when thumbnail is unavailable")
            return nil
        }
    }

    private static func specialImage(type: SpecialImageType, context: Context) -> UIImage? {
        let source = context.source
        if case .template = source {
            // 模板中心v41，修改了请求失败的图片样式，所以这里改一下
            return UDEmptyType.loadingFailure.defaultImage()
        }

        return nil // 因为已经找不到"grid_cell_xxx"、"lark_chat_xxx"等图片了，这些特殊兜底图都放在后端了
    }
}

fileprivate extension SpaceThumbnailCache.Thumbnail {
    var isExpired: Bool {
        let pastTime = Date().timeIntervalSince1970 - updatedTime
        return pastTime >= ThumbnailUrlConfig.updateCheckTimeinterval
    }
}

extension SpaceThumbnailManager: SpaceThumbnailManagerBase {
    public var totalCacheSize: Observable<Float> {
        return cache.size
    }

    public func cleanMemoryCache() {
        cache.cleanMemoryCache()
    }

    public func cleanAllCache(completion: (() -> Void)?) {
        cache.cleanAllCache(completion: completion)
    }
}
