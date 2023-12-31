//
//  UploadImageTracker.swift
//  LarkCore
//
//  Created by xiongmin on 2021/8/11.
//

import Foundation
import Photos
import AppReciableSDK
import ThreadSafeDataStructure
import LarkRustClient
import LarkFoundation

public let SdkErrorSerializeFailureError: ByteWebImageErrorCode = -44_900_014                    // RustSDK LarkError Protobuf 错误数据序列化失败

public final class UploadImageInfo {

    public enum FromType: Int {
        // 复刻过来
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

    public enum UploadScene: Int {
        case chat = 0
        case moment = 1
        case groupAvatar = 2
        case profileAvatar = 3
    }

    public var scene: Scene = .Chat
    public var fromType: FromType = .unknown
    public var compressCost: TimeInterval = 0
    public var imageType: String = "unknown"
    public var useOrigin: Bool = false
    public var resourceWidth: Float = 0
    public var resourceHeight: Float = 0
    public var resourceContentLength: Int = 0
    public var uploadWidth: Float = 0
    public var uploadHeight: Float = 0
    public var uploadContentLength: Int = 0
    public var colorSpaceName: String = "unknown"
    public var colorType: String = "unknown"
    public var fallToFile: Bool = false
    public var imageKey: String = ""
    public var resourceFrames: Int = 1
    public var resourceCount: Int = 1

    public init() { }

    public func addParams(compressResult: CompressResult) {
        // 补充图片的原始数据
        switch compressResult.input {
        case .phasset(let pHAsset):
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            if let editImage = pHAsset.editImage {
                self.resourceWidth = Float(editImage.size.width * editImage.scale)
                self.resourceHeight = Float(editImage.size.height * editImage.scale)
            } else {
                self.resourceContentLength = Int(pHAsset.size)
                self.resourceWidth = Float(pHAsset.originSize.width)
                self.resourceHeight = Float(pHAsset.originSize.height)
            }
        case .image(let image):
            self.resourceWidth = Float(image.size.width * image.scale)
            self.resourceHeight = Float(image.size.height * image.scale)
        case .data(let data):
            self.resourceContentLength = data.count
            // 此处只是通过data拿到image，因为不会展示image，所以不会有渲染等耗时操作
            let image = UIImage(data: data, scale: 1)
            self.resourceWidth = Float(image?.size.width ?? 0)
            self.resourceHeight = Float(image?.size.height ?? 0)
        }
        // 补充图片的上传数据
        switch compressResult.result {
        case .success(let imageSourceResult):
            self.imageType = imageSourceResult.sourceType.description
            self.colorSpaceName = imageSourceResult.colorSpaceName ?? "unknown"
            self.compressCost = imageSourceResult.compressCost ?? 0
            self.uploadContentLength = imageSourceResult.data?.count ?? 0
            let imageSize = (imageSourceResult.data?.bt.imageSize ?? .zero)
            self.uploadWidth = Float(imageSize.width)
            self.uploadHeight = Float(imageSize.height)
            // 如果是GIF，上报帧数
            // 会涉及到图片的基本信息解码(Info 段)，不会解码整张图片的数据(Data 段)，对 CPU 和内存无明显影响
            if imageSourceResult.sourceType == .gif, let framesCount = imageSourceResult.data?.bt.imageCount {
                self.resourceFrames = framesCount
            }
        case .failure:
            break
        }
    }
}

public final class UploadImageTracker {

    struct UploadTrackerParams {
        let biz: Biz
        let scene: Scene
        let startTime: TimeInterval
        let disposedKey: DisposedKey
    }

    static var infoMap: SafeDictionary<String, UploadTrackerParams> = [:] + .readWriteLock

    public static func start(key: String, scene: Scene, biz: Biz) {
        guard !key.isEmpty else { return }
        let disposedKey = AppReciableSDK.shared.start(biz: biz, scene: scene, event: .imageUpload, page: nil)
        infoMap[key] = UploadTrackerParams(biz: biz, scene: scene, startTime: CACurrentMediaTime(), disposedKey: disposedKey)
    }

    public static func end(key: String, info: UploadImageInfo) {
        guard !key.isEmpty, let par = infoMap[key] else { return }
        let detail: [String: Any] = [
            "compress_cost": info.compressCost,
            "upload_cost": CACurrentMediaTime() - par.startTime
        ]
        let category: [String: Any] = [
            "from_type": info.fromType.rawValue,
            "image_type": info.imageType,
            "color_space": info.colorSpaceName,
            "color_type": info.colorType,
            "media_is_origin_type": info.useOrigin
        ]
        let metric: [String: Any] = [
            "trigger_valid_check_downgradle_strategy": info.fallToFile,
            "image_key": info.imageKey,
            "media_is_origin_type": info.useOrigin,
            "resource_frames": info.resourceFrames,
            "resource_count": info.resourceCount,
            "resource_width": info.resourceWidth,
            "resource_height": info.resourceHeight,
            "resource_content_length": info.resourceContentLength,
            "upload_width": info.uploadWidth,
            "upload_height": info.uploadHeight,
            "upload_content_length": info.uploadContentLength
        ]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: detail,
                          metric: metric,
                          category: category,
                          extra: nil)
        AppReciableSDK.shared.end(key: par.disposedKey, extra: extra)
        infoMap[key] = nil
    }

    public static func error(key: String, error: Error?) {
        guard !key.isEmpty, let par = infoMap[key] else { return }
        let arg = UploadImageTracker.getErrorParams(error)
        let params = ErrorParams(biz: par.biz,
                                 scene: par.scene,
                                 event: .imageUpload,
                                 errorType: .Other,
                                 errorLevel: .Exception,
                                 errorCode: arg.code,
                                 errorStatus: arg.status,
                                 userAction: nil,
                                 page: nil,
                                 errorMessage: arg.msg)
        AppReciableSDK.shared.error(params: params)
        infoMap[key] = nil
    }

    private static func getErrorParams(_ error: Error?) -> (code: Int, status: Int, msg: String) {
        guard let error = error else { return (ByteWebImageErrorUnkown, 0, "") }
        func getRCErrorCode(_ rcError: RCError) -> (code: Int, status: Int, msg: String) {
            // 其中99%为业务错误
            if case let .businessFailure(errorInfo: errorInfo) = rcError {
                if errorInfo.errorCode == 0 {
                    // disable-lint: magic number
                    return (600_000, Int(errorInfo.errorStatus), errorInfo.debugMessage)
                    // enable-lint: magic number
                } else {
                    return (Int(errorInfo.errorCode), Int(errorInfo.errorStatus), errorInfo.debugMessage)
                }
            } else if case .sdkErrorSerializeFailure = rcError {
                // 1%为RustSDK Request Protobuf 请求序列化失败
                return (SdkErrorSerializeFailureError, 0, rcError.localizedDescription)
            }
            return (0, 0, rcError.localizedDescription)
        }
        // error.underlyingError 取的是最顶层的error，一般是APIError
        // RCError: 大部分的上传错误都是RCError
        // 这里只对比RCError，所以取最底层error
        let errorStack = error.metaErrorStack
        if let rcError: RCError = errorStack.isEmpty ? (error as? RCError) : (errorStack.last as? RCError) {
            return getRCErrorCode(rcError)
        }
        // 判断压缩阶段的错误
        if let compressError = error as? ByteWebImage.CompressError {
            return (compressError.code(), 0, error.localizedDescription)
        }
        // 拿一下业务方自定义的error code
        if let customUploadError = error as? CustomUploadError {
            return (customUploadError.code, 0, error.localizedDescription)
        }
        return (ByteWebImageErrorUnkown, 0, error.localizedDescription)
    }
}
