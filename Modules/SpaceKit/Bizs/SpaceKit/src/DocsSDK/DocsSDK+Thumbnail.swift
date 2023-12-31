//
//  SpaceKit+Thumbnail.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/11.
//  
import RxSwift
import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

extension DocsSDK {

//    @available(*, deprecated, message: "use getThumbnail(url:, fileType:, thumbnailInfo:) instead")
//    public func downloadEncryptImg(use url: String,
//                                   fileType: Int,
//                                   thumbnailInfo: [String: Any],
//                                   imageView: UIImageView,
//                                   completion: ((UIImage?, Error?) -> Void)?) {
//        let extraInfo = SpaceThumbnailInfo.ExtraInfo(thumbnailInfo)
//        guard let info = SpaceThumbnailInfo(unencryptURL: URL(string: url), extraInfo: extraInfo) else {
//            completion?(nil, SpaceThumbnailDownloader.DownloadError.parseDataFailed)
//            return
//        }
//        let docsType: DocsType
//        if let realDocsType = DocsType(pbDocsTypeRawValue: fileType) {
//            docsType = realDocsType
//        } else {
//            docsType = .unknownDefaultType
//        }
//
//        var processer = SpaceDefaultProcesser()
//        let insets = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
//        processer.resizeInfo = SpaceThumbnailProcesserResizeInfo(targetSize: imageView.bounds.size,
//                                                                 imageInsets: insets)
//        let request = SpaceThumbnailManager.Request(token: "chat-thumbnail-token",
//                                                    info: info,
//                                                    source: .chat,
//                                                    fileType: docsType,
//                                                    placeholderImage: nil,
//                                                    failureImage: nil,
//                                                    forceCheckForUpdate: true,
//                                                    processer: processer)
//        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
//        manager.getThumbnail(request: request)
//            .observeOn(MainScheduler.instance)
//            .subscribe { [weak imageView] event in
//                switch event {
//                case let .next(image):
//                    imageView?.image = image
//                case let .error(error):
//                    DocsLogger.error("DocsSDK --- download encrypt img failed with error", error: error)
//                    completion?(nil, error)
//                case .completed:
//                    completion?(imageView?.image, nil)
//                }
//            }
//            // TODO: 交由调用方dispose
//            .disposed(by: manager.tmpDisposeBag)
//    }

    public func notifyEnterChatPage() {
        let config = DocsContainer.shared.resolve(SpaceThumbnailManager.self)?.config
        config?.notifyEnterChatPage()
    }

    public func notifyLeaveChatPage() {
        let config = DocsContainer.shared.resolve(SpaceThumbnailManager.self)?.config
        config?.notifyLeaveChatPage()
    }

    public func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageSize: CGSize) -> Observable<UIImage> {
        getThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageSize: imageSize, forceUpdate: false)
    }

    public func getThumbnail(url: String,
                fileType: Int,
                thumbnailInfo: [String: Any],
                imageSize: CGSize,
                forceUpdate: Bool) -> Observable<UIImage> {
        let extraInfo = SpaceThumbnailInfo.ExtraInfo(thumbnailInfo)
        guard let info = SpaceThumbnailInfo(unencryptURL: URL(string: url), extraInfo: extraInfo) else {
            return .error(SpaceThumbnailDownloader.DownloadError.parseDataFailed)
        }
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
        let docsType: DocsType
        if let realDocsType = DocsType(pbDocsTypeRawValue: fileType) {
            docsType = realDocsType
        } else {
            docsType = .unknownDefaultType
        }
        let needCheckForUpdate = forceUpdate ? true : manager.config.checkNeedRefresh(key: info.url)
        var processer = SpaceCropWhenReadProcesser(cropSize: imageSize)
        processer.resizeInfo = SpaceThumbnailProcesserResizeInfo(targetSize: imageSize,
                                                                 imageInsets: UIEdgeInsets(top: 16, left: 12, bottom: 18, right: 12))
        let cacheTag = "\(Int(imageSize.width))-\(Int(imageSize.height))"
        let request = SpaceThumbnailManager.Request(token: "chat-thumbnail-token",
                                                    info: info,
                                                    source: .chat,
                                                    fileType: docsType,
                                                    placeholderImage: nil,
                                                    failureImage: nil,
                                                    forceCheckForUpdate: needCheckForUpdate,
                                                    processer: processer,
                                                    cacheTag: cacheTag)
        let result = manager.getThumbnail(request: request).share(replay: 1, scope: .whileConnected)
        result.subscribe().disposed(by: manager.tmpDisposeBag)
        return result
    }

    public func syncThumbnail(token: String, fileType: Int, completion: @escaping (Error?) -> Void) {
        DocThumbnailSyncer.syncDocThumbnail(objToken: token, objType: DocsType(pbDocsTypeRawValue: fileType)?.rawValue, completion: completion)
    }

    public func didFinishDownloadImgInLarkChat(for url: String, fileType: Int, error: Error?) {
        let type = DocsType(rawValue: fileType)
        let errorMsg = error.debugDescription
        let result = ThumbDownloadStatistics.Result(source: .chat,
                                                    isSucceed: error == nil,
                                                    fileType: type,
                                                    url: url,
                                                    isUpdate: false,
                                                    isNew: false,
                                                    errorMsg: errorMsg,
                                                    code: nil)
        ThumbDownloadStatistics.reportResult(result)
    }
}
