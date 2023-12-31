//
//  ChooseImagePlugin.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/3/4.
//

import OPFoundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting
import OPSDK
import OPPluginManagerAdapter
import UIKit
import OPPluginBiz
import LarkContainer

private let chooseImageDefaultCount: Int = 9
private let chooseImageDefaultMaxCount: Int = 20

/// choose image 错误消息统一管理，主要用作 log
private enum ChooseImageErrorMessage: String {
    case gadgetContext = "can not find gadgetContext to chooseImage"
    case imagePlugin = "Client NOT Impl the API."
    case auth = "auth failed"
    case userCancel = "User Cancel"
    case saveFile = "save failed"
    case unknown = "unknown error"
}

private func genError(_ code: OpenAPIErrorCodeProtocol, _ message:  String) -> OpenAPIError {
    OpenAPIError(code: code)
        .setOuterMessage(message)
}

private func genError(errno: OpenAPIErrnoProtocol) -> OpenAPIError {
    OpenAPIError(errno: errno)
}

// MARK: chooseImage
extension OpenPluginImage {

    private func remoteCompressRate() -> CGFloat {
        CGFloat((try? userResolver.settings.setting(with: Int.self, key: .make(userKeyLiteral: "api_compressImage_rate"))) ?? 80) / 100.0
    }
   
    /// 获取 uniqueId
    /// API Code internalError
    private func apiUniqueId(forContext context: OpenAPIContext) throws -> OPAppUniqueID {
        guard let uniqueId = context.uniqueID else {
            throw genError(OpenAPICommonErrorCode.unknown, "")
                .setErrno(OpenAPICommonErrno.internalError)
        }
        return uniqueId
    }
    
    /// 获取 BDPChooseImagePluginModel
    /// API Code unknown
    private func imageModel(forParams params: OpenPluginChooseImageRequest, uniqueId: OPAppUniqueID) throws -> BDPChooseImagePluginModel {
        // 这两个逻辑很成熟了就不改了
        let imageSourceType = genImageSourceType(params: params)
        let imageSizeType = genImageSizeType(params: params)
        var dict = [String : Any]()
        if params.count < 1 {
            params.count = chooseImageDefaultCount
        }
        let maxCount = chooseImageMaxCount(uniqueId: uniqueId)
        params.count = min(params.count, maxCount)
        dict["count"] = params.count
        dict["cameraDevice"] = params.cameraDevice
        dict["bdpSourceType"] = imageSourceType.rawValue
        dict["bdpSizeType"] = imageSizeType.rawValue
        dict["isSaveToAlbum"] = params.isSaveToAlbum.rawValue
        dict["confirmBtnText"] = params.confirmBtnText
        return try BDPChooseImagePluginModel(dictionary: dict)
    }
    
    /// chooseImage maxCount字段 settings 配置
    /// https://cloud.bytedance.net/appSettings-v2/detail/config/170504/detail/basic
     func chooseImageMaxCount(uniqueId: OPAppUniqueID) -> Int {
        do {
            let config: [String: Any] = try userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "choose_image_max_count"))
            guard let appConfig = config["appConfig"] as? [String:Int] else{
                return chooseImageDefaultMaxCount
            }
            let appID = uniqueId.appID
            if let maxCount = appConfig[appID], maxCount > 0 {
                return maxCount
            }
            if let defaultMaxCount = config["default"] as? Int, defaultMaxCount > 0 {
                return defaultMaxCount
            }
            return chooseImageDefaultMaxCount
        } catch {
            return chooseImageDefaultMaxCount
        }
        
    }
    /// 通过鉴权将可选 images 转化为非空
    /// 过程中的全部异常全抛出处理
    /// - Parameters:
    ///   - images: 可空 image 数组
    ///   - authType: 如果不是 deny，images 为空，则视为用户取消
    /// - Returns: 非空数组
    private func checkImagesResult(images: [UIImage]?, authType: BDPImageAuthResult) throws -> [UIImage] {
        if authType == .deny {
            throw genError(errno: OpenAPICommonErrno.systemAuthDeny)
        }
        guard let images = images else {
            throw genError(OpenAPICommonErrorCode.internalError, "User Cancel")
                .setErrno(OpenAPIImageErrno.useCanceled)
        }
        return images
    }
    
    private func saveImage(images: [UIImage], isOriginal: Bool, fsContext: FileSystem.Context) -> OpenPluginChooseImageResponse {
        Self.saveImage(images: images, compressionQuality: isOriginal ? 1.0 : remoteCompressRate(), fsContext: fsContext)
    }
    
    private func saveImageV2(images: [UIImage], isOriginal: Bool, fsContext: FileSystem.Context, callback: @escaping (OpenPluginChooseImageResponse) -> Void) {
        Self.saveImageV2(images: images, compressionQuality: isOriginal ? 1.0 : remoteCompressRate(), fsContext: fsContext, callback: callback)
    }
    
    static func saveImage(image: UIImage, compressionQuality: CGFloat, fsContext: FileSystem.Context) throws -> OpenPluginChooseImageResponse.TempFilesItem {
        let result = try FileUtils.saveImage(image: image, compressionQuality: compressionQuality, fsContext: fsContext)
        return OpenPluginChooseImageResponse.TempFilesItem(path: result.path, size: result.size)
    }
    
    static func saveImageV2(image: UIImage, compressionQuality: CGFloat, fsContext: FileSystem.Context) -> OpenPluginChooseImageResponse.TempFilesItem? {
        fsContext.trace.info("saveImageV2 start call")
        let result: OpenPluginChooseImageResponse.TempFilesItem?
        do {
            result = try Self.saveImage(image: image, compressionQuality: compressionQuality, fsContext: fsContext)
        } catch {
            result = nil
            fsContext.trace.error("saveImageV2 save fail", error: error)
        }
        return result
    }
    
    static func saveImage(images: [UIImage], compressionQuality: CGFloat, fsContext: FileSystem.Context) -> OpenPluginChooseImageResponse {
        images.reduce(OpenPluginChooseImageResponse(tempFilePaths: [], tempFiles: [])) { partialResult, image in
            do {
                let file = try saveImage(image: image, compressionQuality: compressionQuality, fsContext: fsContext)
                var paths = partialResult.tempFilePaths
                var files = partialResult.tempFiles
                paths.append(file.path)
                files.append(file)
                return .init(tempFilePaths: paths, tempFiles: files)
            } catch {
                return partialResult
            }
        }
    }
    
    static func saveImageV2(images: [UIImage], compressionQuality: CGFloat, fsContext: FileSystem.Context, callback: @escaping (OpenPluginChooseImageResponse) -> Void)  {
        let serialQueue = DispatchQueue(label: "com.bytedance.chooseimage.saveimage.queue", qos: .utility, autoreleaseFrequency: .workItem)
        let group = DispatchGroup()
        var tempFilePaths: [String] = []
        var tempFiles: [OpenPluginChooseImageResponse.TempFilesItem] = []
        for image in images {
            serialQueue.async(group: group) {
                if let filesItem = saveImageV2(image: image, compressionQuality: compressionQuality, fsContext: fsContext) {
                    tempFilePaths.append(filesItem.path)
                    tempFiles.append(filesItem)
                }
            }
        }
        group.notify(queue: .main) {
            callback(OpenPluginChooseImageResponse(tempFilePaths: tempFilePaths, tempFiles: tempFiles))
        }
    }
    
    private func isNewSaveImageDisable() -> Bool {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.chooseimage.new.saveimage.disable")
    }
    
    /// chooseImage https://open.feishu.cn/document/uYjL24iN/uMTMx4yMxEjLzETM
    /// 一致性 checklist https://bytedance.feishu.cn/wiki/wikcn05BFWavlIOq1KIobWE9yFd
    func chooseImageV2(with params: OpenPluginChooseImageRequest,
                       context: OpenAPIContext,
                       gadgetContext: GadgetAPIContext,
                       callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseImageResponse>) -> Void) {
        do {
            context.apiTrace.info("chooseImageV2 begin, \(params.count)")
            let uniqueID = try apiUniqueId(forContext: context)
            let model = try imageModel(forParams: params, uniqueId: uniqueID)
            context.apiTrace.info("chooseImageV2 imageModel generate done")
            BDPPluginImageCustomImpl
                .sharedPlugin()
                .bdp_chooseImage(with: model,
                                 from: gadgetContext.controller) { [weak self] imgs, isOriginal, authResult in
                do {
                    guard let self = self else {
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setMonitorMessage("chooseImageV2 nil self")
                            .setErrno(OpenAPICommonErrno.internalError)
                        callback(.failure(error: error))
                        return
                    }
                    context.apiTrace.info("chooseImageV2 do chooseImage result, authResult: \(authResult == .pass ? "pass" : "deny")")
                    let images = try self.checkImagesResult(images: imgs, authType: authResult)
                    context.apiTrace.info("chooseImageV2 do chooseImage result, image count: \(images.count)")
                    let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID,
                                                       trace: context.apiTrace,
                                                       tag: "chooseImage")
                    
                    if !self.isNewSaveImageDisable() {
                        context.apiTrace.info("chooseImageV2 start saveImageV2,images.cout:\(images.count),isOriginal:\(isOriginal)")
                        self.saveImageV2(images: images, isOriginal: isOriginal, fsContext: fsContext) { result in
                            callback(.success(data: result))
                        }
                    }else {
                        context.apiTrace.info("chooseImageV2 start saveImageV1,images.cout:\(images.count),isOriginal:\(isOriginal)")
                        let result = self.saveImage(images: images, isOriginal: isOriginal, fsContext: fsContext)
                        callback(.success(data: result))
                        context.apiTrace.info("chooseImageV2 do chooseImage success")
                    }
                    
                } catch let e as OpenAPIError {
                    callback(.failure(error: e))
                    context.apiTrace.error(e.outerMessage ?? ChooseImageErrorMessage.unknown.rawValue)
                } catch {
                    // 正常不应该调用到这里的
                    assertionFailure()
                    callback(.failure(error: genError(OpenAPICommonErrorCode.unknown, "unknown exec")
                        .setErrno(OpenAPICommonErrno.unknown)))
                    context.apiTrace.error(ChooseImageErrorMessage.unknown.rawValue)
                }
            }
        } catch let e as OpenAPIError {
            callback(.failure(error: e))
            context.apiTrace.error(e.outerMessage ?? ChooseImageErrorMessage.unknown.rawValue)
        } catch {
            // 正常不应该调用到这里的
            assertionFailure()
            callback(.failure(error: genError(OpenAPICommonErrorCode.unknown, "unknown exec")
                .setErrno(OpenAPICommonErrno.unknown)))
            context.apiTrace.error(ChooseImageErrorMessage.unknown.rawValue)
        }
    }
    
    func chooseImageV3(with params: OpenPluginChooseImageRequest,
                       context: OpenAPIContext,
                       gadgetContext: GadgetAPIContext,
                       callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseImageResponse>) -> Void) {
        do {
            context.apiTrace.info("cameraKit chooseImage begin, \(params.count)")
            let uniqueID = try apiUniqueId(forContext: context)
            let model = try imageModel(forParams: params, uniqueId: uniqueID)
            context.apiTrace.info("cameraKit imageModel generate done")
            guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
                return
            }
            let allowAlbumMode = model.bdpSourceType.contains(.album)
            let allowCameraMode = model.bdpSourceType.contains(.camera)
            let original = model.bdpSizeType.contains(.original)
            let compressed = model.bdpSizeType.contains(.compressed)
            let isSaveToAlbum = model.isSaveToAlbum == "1"
            let confirmBtnText = model.confirmBtnText
            EMAImagePicker.pickImageNew(withMaxCount: model.count,
                                        allowAlbumMode: allowAlbumMode,
                                        allowCameraMode: allowCameraMode,
                                        isOriginalHidden: !(original && compressed),
                                        isOriginal: (original && !compressed),
                                        isSaveToAlbum: isSaveToAlbum,
                                        cameraDevice: model.cameraDevice,
                                        confirmBtnText: confirmBtnText,
                                        in: controller) {[weak self] imgs, isOriginal, authResult, cameraError in
                do {
                    guard let self = self else {
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setMonitorMessage("cameraKit nil self")
                            .setErrno(OpenAPICommonErrno.internalError)
                        callback(.failure(error: error))
                        return
                    }
                    if let cameraError {
                        let error = Self.handleCameraError(cameraError: cameraError, trace: context.apiTrace)
                        callback(.failure(error: error))
                        return
                    }
                    context.apiTrace.info("cameraKit do chooseImage result, authResult: \(authResult == .pass ? "pass" : "deny")")
                    let images = try self.checkImagesResult(images: imgs, authType: authResult)
                    context.apiTrace.info("cameraKit do chooseImage result, image count: \(images.count)")
                    let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID,
                                                       trace: context.apiTrace,
                                                       tag: "chooseImage")
                    
                    if !self.isNewSaveImageDisable() {
                        context.apiTrace.info("cameraKit start saveImageV2,images.cout:\(images.count),isOriginal:\(isOriginal)")
                        self.saveImageV2(images: images, isOriginal: isOriginal, fsContext: fsContext) { result in
                            callback(.success(data: result))
                        }
                    }else {
                        context.apiTrace.info("cameraKit start saveImageV1,images.cout:\(images.count),isOriginal:\(isOriginal)")
                        let result = self.saveImage(images: images, isOriginal: isOriginal, fsContext: fsContext)
                        callback(.success(data: result))
                        context.apiTrace.info("cameraKit do chooseImage success")
                    }
                    
                } catch let e as OpenAPIError {
                    callback(.failure(error: e))
                    context.apiTrace.error(e.outerMessage ?? ChooseImageErrorMessage.unknown.rawValue)
                } catch {
                    // 正常不应该调用到这里的
                    assertionFailure()
                    callback(.failure(error: genError(OpenAPICommonErrorCode.unknown, "unknown exec")
                        .setErrno(OpenAPICommonErrno.unknown)))
                    context.apiTrace.error(ChooseImageErrorMessage.unknown.rawValue)
                }
            }
            
        } catch let e as OpenAPIError {
            callback(.failure(error: e))
            context.apiTrace.error(e.outerMessage ?? ChooseImageErrorMessage.unknown.rawValue)
        } catch {
            // 正常不应该调用到这里的
            assertionFailure()
            callback(.failure(error: genError(OpenAPICommonErrorCode.unknown, "unknown exec")
                .setErrno(OpenAPICommonErrno.unknown)))
            context.apiTrace.error(ChooseImageErrorMessage.unknown.rawValue)
        }
                
    }
    
    static func handleCameraError(cameraError: CameraError, trace: OPTrace) -> OpenAPIError{
        switch cameraError {
        case .createCamera(let createError):
            switch createError {
            case .notSupportSimulator:
                trace.error("notSupportSimulator")
                return genError(errno: OpenAPICommonErrno.internalError)
            case.noVideoPermission:
                BDPAuthorization.showAlertNoPermission(.camera)
                trace.error("no camera permission")
                return genError(errno: OpenAPICommonErrno.systemAuthDeny)
            case .noAudioPermission:
                //图片不会走到这里
                trace.error("no audio permission")
                return genError(errno: OpenAPICommonErrno.internalError)
            case .mediaOccupiedByOthers(let scene, let msg):
                trace.error("media occupied by ohthers:\(scene),msg:\(String(describing: msg))")
                return genError(errno: OpenAPIImageErrno.startShootHigherPriorityFailed)
            @unknown default:
                trace.error("should not in hear")
                return genError(errno: OpenAPICommonErrno.internalError)
            }
        case .saveToAlbumFail:
            trace.error("pickImageNew saveToAlbumFail")
            return genError(errno: OpenAPICommonErrno.internalError)
        case .userCancel:
            return genError(OpenAPICommonErrorCode.internalError, "User Cancel")
                .setErrno(OpenAPIImageErrno.useCanceled)
        @unknown default:
            trace.error("should not in hear2")
            return genError(errno: OpenAPICommonErrno.internalError)
        }
    }

}
