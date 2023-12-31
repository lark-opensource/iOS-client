//
//  ImageUtils.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/8/19.
//

import Foundation
import Kingfisher
import LKCommonsLogging
import LarkSetting
import ByteWebImage
import LarkFeatureGating

@objcMembers
public final class EMAImageUtils: NSObject {
    static let logger = Logger.oplog(EMAImageUtils.self, category: "EMAImageUtils")
    
    // TODOZJX
    @FeatureGatingValue(key: "openplatform.api.previewimage.bytewebimage.enable")
    static public var byteWebImageEnable: Bool

    public static func isCached(key: String) -> Bool {
        if byteWebImageEnable {
            return LarkImageService.shared.isCached(resource: .default(key: key), options: .all)
        }else {
            return KingfisherManager.shared.cache.isCached(forKey: key)
        }
    }
    
    /// 查询图片是否已经缓存
    public static func diskImageExists(url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return KingfisherManager.shared.cache.isCached(forKey: url.absoluteString)
    }
}

extension UIImageView {
    
    private func shouldAddLastModifiedForImageCacheKey() -> Bool {
        // TODOZJX
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api.preview_image.cache_key_add_last_modified")
    }
    
    /// 加载网络图片
    @objc
    public func ema_setImage(url: URL?, placeHolder: UIImage?) {
        ema_setImage(url: url, placeHolder: placeHolder, headers: nil, progressBlock: nil)
    }
    
    /// 加载网络图片
    @objc
    public func ema_setImage(
        url: URL?,
        placeHolder: UIImage?,
        headers: [AnyHashable: Any]? = nil,
        progressBlock: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
        completionBlock: ((_ image: Image?, _ url: URL?, _ fromCache: Bool, _ error: OPError?) -> Void)? = nil
    ) {
        guard let url = url else {
            completionBlock?(nil, nil, false, OPError.error(monitorCode: GDAPIMonitorCode.image_load_failed, message: "loadImage: url is nil"))
            return
        }
        
        // 设置自定义 header
        let modifier = AnyModifier { request in
            var r = request
            headers?.forEach { (key, value) in
                if let key = key as? String, let value = value as? String {
                    r.setValue(value, forHTTPHeaderField: key)
                }
            }
            return r
        }
        
        let progressBlock: DownloadProgressBlock = { (receivedSize, totalSize) in
            progressBlock?(receivedSize, totalSize)
        }
        
        let completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { (result) in
            switch result {
            case .success(let value):
                completionBlock?(value.image, value.source.url, value.cacheType != CacheType.none, nil)
            case .failure(let error):
                completionBlock?(nil, url, false, error.newOPError(monitorCode: GDAPIMonitorCode.image_load_failed))
            }
        }
        
        if url.isFileURL {
            if shouldAddLastModifiedForImageCacheKey() {
                let cacheKey = customCacheKey(url: url)
                self.kf.setImage(with: LocalFileImageDataProvider(fileURL: url, cacheKey: cacheKey), placeholder: placeHolder, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
            } else {
                self.kf.setImage(with: LocalFileImageDataProvider(fileURL: url), placeholder: placeHolder, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
            }
        } else {
            self.kf.setImage(with: ImageResource(downloadURL: url), placeholder: placeHolder, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
    
    public func ema_setImage(
        request: URLRequest,
        progressBlock: ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)? = nil,
        completionBlock: ((_ image: Image?, _ url: URL?, _ fromCache: Bool, _ error: OPError?) -> Void)? = nil
    ) {
        guard let url = request.url else {
            completionBlock?(nil, nil, false, OPError.error(monitorCode: GDAPIMonitorCode.image_load_failed, message: "loadImage: url is nil"))
            return
        }
   

        // 设置自定义 request
        let modifier = AnyModifier { modifierRequest in
            var r = modifierRequest
            r.url = request.url
            r.allHTTPHeaderFields = request.allHTTPHeaderFields
            r.httpMethod = request.httpMethod
            r.httpBody = request.httpBody
            return r
        }
        
        let progressBlock: DownloadProgressBlock = { (receivedSize, totalSize) in
            progressBlock?(receivedSize, totalSize)
        }
        
        let completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { (result) in
            switch result {
            case .success(let value):
                completionBlock?(value.image, value.source.url, value.cacheType != CacheType.none, nil)
            case .failure(let error):
                if !error.isNotCurrentTask {
                    EMAImageUtils.logger.error("kingfisher load image fail error:\(error)")
                }
                completionBlock?(nil, url, false, error.newOPError(monitorCode: GDAPIMonitorCode.image_load_failed))
            }
        }
        
        if url.isFileURL {
            if shouldAddLastModifiedForImageCacheKey() {
                let cacheKey = customCacheKey(url: url)
                self.kf.setImage(with: LocalFileImageDataProvider(fileURL: url, cacheKey: cacheKey), placeholder: nil, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
            } else {
                self.kf.setImage(with: LocalFileImageDataProvider(fileURL: url), placeholder: nil, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
            }
        } else {
            self.kf.setImage(with: ImageResource(downloadURL: url), placeholder: nil, options: [.requestModifier(modifier)], progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
    
    public func ema_setImageV2(
        request: URLRequest,
        progressBlock: ByteWebImage.ImageRequestProgress? = nil,
        completionBlock: ((_ image: Image?, _ url: URL?, _ fromCache: Bool, _ error: OPError?) -> Void)? = nil
    ) {
        guard let url = request.url else {
            completionBlock?(nil, nil, false, OPError.error(monitorCode: GDAPIMonitorCode.image_load_failed, message: "loadImage: url is nil"))
            return
        }
   
        // 设置自定义 request
        let modifier: RequestModifier =  { modifierRequest in
            var r = modifierRequest
            r.url = request.url
            r.allHTTPHeaderFields = request.allHTTPHeaderFields
            r.httpMethod = request.httpMethod
            r.httpBody = request.httpBody
            return r
        }
   
        let completionHandler: ByteWebImage.ImageRequestCompletion = { (result) in
            switch result {
            case .success(let value):
                let fromCache = value.from == .memoryCache || value.from == .diskCache
                EMAImageUtils.logger.info("ByteWebImage load image value:\(value)")
                completionBlock?(value.image, value.request.currentRequestURL, fromCache , nil)
            case .failure(let error):
                EMAImageUtils.logger.error("ByteWebImage load image fail error:\(error)")
                completionBlock?(nil, url, false, error.newOPError(monitorCode: GDAPIMonitorCode.image_load_failed))
            }
        }
        let size = LarkImageService.shared.imageSetting.downsample.image.ptSize//1000*1000pt
        if url.isFileURL {
            self.bt.setLarkImage(.default(key: url.absoluteString), options: [.notCache(.all),.downsampleSize(size)], modifier: modifier, progress: progressBlock, completion: completionHandler)
        } else {
            self.bt.setLarkImage(.default(key: url.absoluteString), placeholder: nil, options: [.downsampleSize(size)], modifier: modifier, progress: progressBlock, completion: completionHandler)
        }
    }
    
    private func customCacheKey(url: URL) -> String {
        guard url.isFileURL else {
            return url.absoluteString
        }
        guard let timestamp = lastModifiedTimestamp(filePath: url.path) else {
            return url.absoluteString
        }
        return "\(url.absoluteString)-\(timestamp)"
    }

    private func lastModifiedTimestamp(filePath: String) -> Int64? {
        do {
            let attributes = try LSFileSystem.attributesOfItem(atPath: filePath) as NSDictionary
            guard let lastModified = attributes.fileModificationDate()?.timeIntervalSince1970 else { return nil }
            return Int64(lastModified * 1000)
        } catch let error {
            EMAImageUtils.logger.error("get local file attributesOfItem fail \(filePath)", error: error)
        }
        return nil
    }
}

extension UIImage {
    
    /// 获取图片的GIF data
    @objc
    public func ema_gifRepresentation() -> Data? {
        return self.kf.gifRepresentation()
    }
}
