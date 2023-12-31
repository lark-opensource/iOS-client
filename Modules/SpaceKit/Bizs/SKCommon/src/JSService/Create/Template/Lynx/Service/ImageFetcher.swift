//
//  ImageFetcher.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/5.
//  


import Foundation
import Lynx
import Kingfisher
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import SKFoundation
#if USE_DYNAMIC_RESOURCE
import LarkResource
import SKInfra
#endif

class ImageFetcher: NSObject, LynxImageFetcher {
    private static let disposeBag = DisposeBag()
    func loadImage(with url: URL?, processors: [LynxImageProcessor], size: CGSize, contextInfo: [AnyHashable: Any]?, completion completionBlock: @escaping LynxImageLoadCompletionBlock) -> () -> Void {
        guard let url = url else {
            DocsLogger.error("ImageFetcher url is nil")
            let error = ImageFetcherError(msg: "url is null")
            completionBlock(nil, error, nil)
            return {}
        }
        let urlStr = url.absoluteString
        if urlStr.hasPrefix("http://") || urlStr.hasPrefix("https://") {
            let resource = ImageResource(downloadURL: url)
            KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { result in
                switch result {
                case .success(let value): completionBlock(value.image, nil, nil)
                case .failure(let error): completionBlock(nil, error, nil)
                }
            }
        } else if urlStr.hasPrefix("appImage://") {
            let key = urlStr.substring(from: "appImage://".endIndex)
            let image = Self.image(named: key)
            completionBlock(image, nil, nil)
        } else if urlStr.hasPrefix("thumbnail://") {
            let key = urlStr.substring(from: "thumbnail://".endIndex)
            Self.image(url: key) { image in
                completionBlock(image, nil, nil)
            }
        }
        return {}
    }
    
    private static func image(named: String) -> UIImage? {
        if named.starts(with: "ud_") {
            //获取UD icon
            let udString = named.substring(from: "ud_".endIndex)
            let splitString = udString.split(separator: "_")
            let udKey = String(splitString.first ?? "")
            let tinColor = String(splitString.last ?? "")
            guard let iconType = UDIcon.getIconTypeByName(udKey) else { return nil }

            let iconColor = UDColor.current.getValueByBizToken(token: tinColor)
            return UDIcon.getIconByKey(iconType, iconColor: iconColor)
        }

        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "SKResource.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.SKResourceBundle, compatibleWith: nil)
    }
    
    //处理加密的文档缩略图
    private static func image(url: String, compeletion: @escaping (UIImage?) -> Void) {
        let jsonString = url.removingPercentEncoding
        var dic = [String: Any]()
        if let data = jsonString?.data(using: .utf8) {
            do {
                dic = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            } catch {
                DocsLogger.error("wiki_recommend_thumbnail: convert json string error from lynx")
                return
            }
        } else {
            DocsLogger.error("wiki_recommend_thumbnail: convert json string to data error from lynx")
            return
        }
    
        guard let imageURL = dic["secret_url"] as? String,
              let typeString = dic["type"] as? String,
              let type = Int(typeString),
              let secret = dic["secret"] as? String else {
            DocsLogger.error("wiki_recimmend_thunmbnail: missing required parameters for unencrypt thumbnail")
            return
        }
        
        var thumbnailInfo: [String: Any] = ["type": type, "secret": secret]
        if let nonce = dic["nonce"] as? String, !nonce.isEmpty {
            thumbnailInfo["nonce"] = nonce
        }
        var unencryptURL: URL?
        if let unencryptURLString = dic["url"] as? String,
           !unencryptURLString.isEmpty,
           let temptURL = URL(string: unencryptURLString) {
            unencryptURL = temptURL
        }
        
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
        let extraInfo = SpaceThumbnailInfo.ExtraInfo(urlString: imageURL, encryptInfo: thumbnailInfo)
        guard let info = SpaceThumbnailInfo(unencryptURL: unencryptURL, extraInfo: extraInfo) else {
            DocsLogger.error("wiki_recommend_thumbnail: construct SpaceThumbnailInfo error")
            return
        }

        let request = SpaceThumbnailManager.Request(token: "wikiFeed-thumbnail-token",
                                                    info: info,
                                                    source: .unknown,
                                                    fileType: .unknownDefaultType,
                                                    placeholderImage: nil,
                                                    failureImage: nil,
                                                    forceCheckForUpdate: true)

        manager.getThumbnail(request: request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { result in
                compeletion(result)
            }, onError: { error in
                DocsLogger.error("wiki_recommend_thumbnail: get thumbnail error, error: \(error.localizedDescription)")
                compeletion(nil)
            })
            .disposed(by: disposeBag)
    }
    
    struct ImageFetcherError: Error, LocalizedError {
        let msg: String
        var errorDescription: String? {
            return NSLocalizedString(msg, comment: "")
        }
    }
}
