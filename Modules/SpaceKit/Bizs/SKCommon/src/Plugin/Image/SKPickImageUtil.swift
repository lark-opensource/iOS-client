//
//  SKPickImageInfoTransform.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/10/12.
// swiftlint:disable line_length


import SKFoundation
import Kingfisher
import AVFoundation
import Photos
import LarkSensitivityControl

public struct SkPickImagePreInfo {
    let image: UIImage?
    let oriData: Data?
    let picFormat: ImageFormat
    public init(image: UIImage?, oriData: Data?, picFormat: ImageFormat) {
        self.image = image
        self.oriData = oriData
        self.picFormat = picFormat
    }
}

public final class SkPickImageTransformInfo {
    public let resultData: NSCoding
    public let picFormat: ImageFormat
    public let contentType: String?
    public let cacheKey: String
    public let uuid: String
    public let srcUrl: String
    public let dataSize: Int
    public let width: CGFloat
    public let height: CGFloat

    public init(resultData: NSCoding, picFormat: ImageFormat, contentType: String?, cacheKey: String, uuid: String, srcUrl: String, dataSize: Int, width: CGFloat, height: CGFloat) {
        self.resultData = resultData
        self.picFormat = picFormat
        self.contentType = contentType
        self.cacheKey = cacheKey
        self.uuid = uuid
        self.srcUrl = srcUrl
        self.dataSize = dataSize
        self.width = width
        self.height = height
    }

}

public final class SKPickImageUtil {
    
    public static let picMaxSize: Int = 20 * 1024 * 1024
    
    public class func handleImageAsset(assets: [PHAsset], original: Bool, token: String, completion: ((_ info: [SkPickImagePreInfo]?) -> Void)) {
        var reachMaxSize: Bool = false
        var imagePreInfos: [SkPickImagePreInfo] = []
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        for asset in assets {
            do {
                if #available(iOS 13.0, *) {
                    _ = try AlbumEntry.requestImageDataAndOrientation(forToken: Token(token), manager: PHImageManager.default(), forAsset: asset, options: options) {(data, _ ,_, _) in
                        autoreleasepool {
                            guard let data = data else {
                                return
                            }
                            if data.count > Self.picMaxSize {
                                reachMaxSize = true
                            } else {
                                let picFormat = data.kf.imageFormat
                                if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                                    imagePreInfos.append(SkPickImagePreInfo(image: image, oriData: picFormat == .GIF ? data : nil, picFormat: picFormat))
                                }
                            }
                        }
                    }
                } else {
                    _ = try AlbumEntry.requestImageData(forToken: Token(token), manager: PHImageManager.default(), forAsset: asset, options: options) {(data, _ ,_, _) in
                        autoreleasepool {
                            guard let data = data else {
                                return
                            }
                            if data.count > Self.picMaxSize {
                                reachMaxSize = true
                            } else {
                                let picFormat = data.kf.imageFormat
                                if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                                    imagePreInfos.append(SkPickImagePreInfo(image: image, oriData: picFormat == .GIF ? data : nil, picFormat: picFormat))
                                }
                            }
                        }
                    }
                }
            } catch {
                DocsLogger.error("AlbumEntry requestImageDataAndOrientation error")
                completion(nil)
            }
        }

        if reachMaxSize {
            completion(nil)
        } else {
            completion(imagePreInfos)
        }
    }

    public class func getTransformImageInfo(_ images: [SkPickImagePreInfo], isOriginal: Bool) -> [SkPickImageTransformInfo] {
        var imageInfos: [SkPickImageTransformInfo] = []
        images.forEach { (imageInfo) in
            autoreleasepool {
                if var image = imageInfo.image {
                    let uuid = self.makeUniqueId()
                    let imageKey = self.makeImageCacheKey(with: uuid)
                    // 即使是原图也要限制在20M以内
                    let limitSize: UInt = isOriginal ? 20 * 1024 * 1024 : 2 * 1024 * 1024
                    var resultData: Data?
                    var picSizeBeginCompress: Int = 0
                    if imageInfo.picFormat == .GIF {
                        resultData = imageInfo.oriData
                    } else {
                        let beginTime = Date.timeIntervalSinceReferenceDate
                        // UIImage.compress可能会失败， https://stackoverflow.com/questions/29732886/uiimagejpegrepresentation-returns-nil
                        if image.cgImage == nil,
                           let ciImage = image.ciImage,
                            let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) {
                            DocsLogger.error("SkBasePickImagePlugin, cgImage is nil, picFormat=\(imageInfo.picFormat)", component: LogComponents.pickImage)
                            image = UIImage(cgImage: cgImage)
                        }
                        (resultData, picSizeBeginCompress) = image.compress(quality: 1, limitSize: limitSize)
                        let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                        self.report(picSize: picSizeBeginCompress, costTime: Int(costTime * 1000))
                    }
                    if let data = resultData as NSCoding? {
                        let src = self.makeImageCacheUrl(with: uuid)
                        let contentType = self.getContentType(imageInfo.picFormat)
                        let width: CGFloat = image.size.width * image.scale
                        let height: CGFloat = image.size.height * image.scale
                        let imgTransformInfo = SkPickImageTransformInfo(resultData: data, picFormat: imageInfo.picFormat, contentType: contentType, cacheKey: imageKey, uuid: uuid, srcUrl: src, dataSize: picSizeBeginCompress, width: width, height: height)
                        imageInfos.append(imgTransformInfo)
                        
                    } else {
                        DocsLogger.error("SkBasePickImagePlugin, resultData = nil, picFormat=\(imageInfo.picFormat)", component: LogComponents.pickImage)
                    }
                    
                } else {
                    DocsLogger.info("SkBasePickImagePlugin, 上传图片信息缺失", component: LogComponents.pickImage)
                    
                }
            }
        }
        return imageInfos
    }

    private class func report(picSize: Int, costTime: Int) {
        let param: [String: Any] = ["code": 0,
                                    "pic_size": picSize,
                                    "cost_time": costTime
        ]
        DocsTracker.log(enumEvent: .devPerformancePicCompress, parameters: param)
    }

    public class func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    public class func getContentType(_ imageType: ImageFormat) -> String {
        var contentType: String = ""
        switch imageType {
        case .GIF:
            contentType = "image/gif"
        case .PNG:
            contentType = "image/png"
        case .JPEG:
            contentType = "image/jpeg"
        default:
            contentType = ""
        }
        return contentType
    }

    public class func makeImageCacheKey(with uuid: String) -> String {
        return "/file/f/" + uuid
    }

    public class func uuidAndTokenMapKey(_ token: String) -> String {
        return "mapUUID" + token
    }

    public class func makeImageCacheUrl(with uuid: String) -> String {
        let cacheKey = self.makeImageCacheKey(with: uuid)
        return DocSourceURLProtocolService.scheme + "://com.bytedance.net" + cacheKey
    }
    
    public class func resolutionSizeForLocalVideo(url: URL) -> CGSize {
        guard let track = AVAsset(url: url as URL).tracks(withMediaType: AVMediaType.video).first else {
            DocsLogger.error("no AVAsset video info")
            return CGSize(width: 0.0, height: 0.0)
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: fabs(size.width), height: fabs(size.height))
    }

}
