//
//  OpenPluginImage.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/22.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting
import ECOProbe
import OPSDK
import OPPluginManagerAdapter
import UniverseDesignToast
import Photos
import LarkAssetsBrowser
import OPPluginBiz
import LarkContainer

/// 从gadgetContext参数提取storageModule
private func storageModule(gadgetContext: OPAPIContextProtocol) -> BDPStorageModuleProtocol? {
    let moudleManager = BDPModuleManager(of: gadgetContext.uniqueID.appType)
    if let storage = moudleManager.resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol {
        return storage
    }
    return nil
}

final class OpenPluginImage: OpenBasePlugin {
    @InjectedSafeLazy var mediaProvider: OpenPluginMediaProxy

    func genImageSourceType(params: OpenPluginChooseImageRequest) -> BDPImageSourceType {
        var imageSourceType: BDPImageSourceType = .init(rawValue: 0)
        if params.sourceType.contains("album") {
            imageSourceType.formUnion(.album)
        }
        if params.sourceType.contains("camera") {
            imageSourceType.formUnion(.camera)
        }
        if imageSourceType == .init(rawValue: 0) {
            imageSourceType.formUnion(.album)
            imageSourceType.formUnion(.camera)
        }
        return imageSourceType
    }
    func genImageSizeType(params: OpenPluginChooseImageRequest) -> BDPImageSizeType {
        var imageSizeType: BDPImageSizeType = .init(rawValue: 0)
        if params.sizeType.contains("original") {
            imageSizeType.formUnion(.original)
        }
        if params.sizeType.contains("compressed") {
            imageSizeType.formUnion(.compressed)
        }
        if imageSizeType == .init(rawValue: 0) {
            imageSizeType.formUnion(.original)
            imageSizeType.formUnion(.compressed)
        }
        return imageSizeType
    }

    public func getImageInfo(
        with params: OpenAPIGetImageInfoParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIGetImageInfoResult>) -> Void)
    {
        standardGetImageInfo(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
    }

    private func standardGetImageInfo(
        with params: OpenAPIGetImageInfoParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIGetImageInfoResult>) -> Void
    ) {
       
        do {
            let file = try FileObject(rawValue: params.src) // 业务同学同步，JSSDK 已经处理了 http 的下载，到 API 的都是沙箱文件了
            let fsContext = FileSystem.Context(
                uniqueId: gadgetContext.uniqueID,
                trace: context.apiTrace,
                tag: "getImageInfo",
                isAuxiliary: true
            )
            //  读取文件，内部进行了读权限检查、存在性判断、是否文件
            let data = try FileSystem.readFile(file, context: fsContext)
            guard let image = UIImage(data: data) else {
                let apiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.formatImageDataFail)
                    .setMonitorMessage("invalid imageData")
                    .setErrno(OpenAPIImageErrno.InvalidImageData)
                callback(.failure(error: apiError))
                return
            }
            context.apiTrace.info("getImageInfo data.count:\(data.count), imageSize:\(image.size)")
            let imgWidth = Int(image.size.width)
            let imgHeight = Int(image.size.height)
            /// 补充图片大小相关逻辑
            guard imgHeight > 0, imgWidth > 0 else {
                let apiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.imageSizeIllegal).setErrno(OpenAPIImageErrno.InvalidImageSize)
                callback(.failure(error: apiError))
                return
            }
            let mimeType = BDPImageHelper.mimeType(forImageData: data)
            let type = (OPUnsafeObject(mimeType) as? NSString)?.components(separatedBy: "/").last
            let result = OpenAPIGetImageInfoResult(
                path: params.src,
                width: imgWidth,
                height: imgHeight,
                type: type ?? ""
            )
            callback(.success(data: result))
        }catch let fileError as FileSystemError {
            let fileCommonErrno = fileError.fileCommonErrno
            var openApiError: OpenAPIError
            switch fileError {
            case FileSystemError.invalidFilePath(_):
                openApiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.invalidFilePath)
                    .setErrno(fileCommonErrno)
            case FileSystemError.biz(.resolveStorageModuleFailed(_)),
                FileSystemError.biz(.resolveFilePathFailed(_, _)),
                FileSystemError.biz(.resolveLocalFileInfoFailed(_, _)),
                FileSystemError.fileNotExists(_, _):
                openApiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("no such file or directory")
                    .setErrno(fileCommonErrno)
            case FileSystemError.isNotFile(_, _):
                // 是否文件
                openApiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.notFile)
                    .setErrno(fileCommonErrno)
            case FileSystemError.fileNotExists(_, _):
                // 文件存在性
                openApiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.fileNotExist)
                    .setErrno(fileCommonErrno)
            case FileSystemError.readPermissionDenied(let file, _):
                // 读权限问题
                openApiError = OpenAPIError(code: OpenAPIGetImageInfoErrorCode.readPermissionDenied)
                    .setMonitorMessage("permission denied, open \"\(file.rawValue)\"")
                    .setErrno(fileCommonErrno)
            default:
                openApiError = fileError.fileSystemUnknownError
            }
            callback(.failure(error: openApiError))
        } catch {
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("get image info unknown error \(error)")
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: apiError))
        }
    }

    
    public func saveImageToPhotosAlbum(
        with params: OpenAPISaveImageParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        /// 权限判断：
        /// 1. 小程序飞书相册权限，框架已经校验 - 状态可见小程序 “关于” 页面；
        /// 2. 判断系统相册权限；
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            guard isSuccess else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            self.standardSaveImageToPhotosAlbum(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
    private func standardSaveImageToPhotosAlbum(
        with params: OpenAPISaveImageParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        /// 开启加解密后，不允许保存
        if FSCrypto.isCryptoInterceptEnable(type: .apiSaveImageToPhotosAlbum) {
            DispatchQueue.main.async {
                if let view = context.controller?.view {
                    UDToast.showTips(
                        with: BundleI18n.OPPlugin.OpenPlatform_Workplace_SafetyWarning_SaveFailed,
                        on: view
                    )
                } else {
                    context.apiTrace.error("cannot find controller view to show crypto tips")
                }
            }
            let apiError = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.securityPermissionDenied)
                .setErrno(OpenAPIImageErrno.SecurityPermissionDenied)
            callback(.failure(error: apiError))
            return
        }
        do {
            let file = try FileObject(rawValue: params.filePath)
            let fsContext = FileSystem.Context(
                uniqueId: gadgetContext.uniqueID,
                trace: context.apiTrace,
                tag: "saveImageToPhototsAlbum"
            )
            // 读取文件数据
            let imageData = try FileSystem.readFile(file, context: fsContext)
            mediaProvider.saveImageToPhotosAlbum(tokenIdentifier: OPSensitivityEntryToken.OpenPluginImage_saveImageToPhotosAlbum_creationRequestForAsset.stringValue, imageData: imageData) { success, error in
                context.apiTrace.info("saveImageToPhotosAlbum result success = \(success), error = \(error?.localizedDescription ?? "")")
                guard success else {
                    if #available(iOS 15.0, *) {
                        /// 'PHPhotosErrorDomain' is only available in iOS 13 or newer
                        if let err = error  as NSError?,
                           err.domain == PHPhotosErrorDomain,
                           err.code == PHPhotosError.invalidResource.rawValue {
                            /// 'PHPhotosError.invalidResource' is only available in iOS 15 or newer
                            let error = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.notImage).setErrno(OpenAPIImageErrno.ImageFormatNotSupported)
                            callback(.failure(error: error))
                            return
                        }
                    }
                    let apierror = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.saveToSystemAlbumFailed)
                        .setMonitorMessage("BDPSaveImageToPhotosAlbum fail \(error?.localizedDescription ?? "")")
                        .setErrno(OpenAPIImageErrno.UnableToSaveImage)
                    callback(.failure(error: apierror))
                    return
                }
                callback(.success(data: nil))
            }
        } catch let fileError as FileSystemError {
            let fileCommonErrno = fileError.fileCommonErrno
            var openApiError: OpenAPIError
            switch fileError {
            case FileSystemError.invalidFilePath(let path):
                openApiError = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.invilidFilePath)
                    .setErrno(fileCommonErrno)
            case FileSystemError.biz(.resolveStorageModuleFailed(_)):
                openApiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("get BDPStorageModuleProtocol falied")
                    .setErrno(fileCommonErrno)
            case FileSystemError.biz(.resolveFilePathFailed(_, _)),
                FileSystemError.biz(.resolveLocalFileInfoFailed(_, _)):
                openApiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("resolve filePath/localFileInfo failed")
                    .setErrno(fileCommonErrno)
            case FileSystemError.isNotFile(_, _):
                // 是否文件
                openApiError = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.notFile)
                    .setErrno(fileCommonErrno)
            case FileSystemError.fileNotExists(_, _):
                // 文件是否存在
                openApiError = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.fileNotExist)
                    .setMonitorMessage("no such file or directory, \"\(params.filePath)\"")
                    .setErrno(fileCommonErrno)
            case FileSystemError.readPermissionDenied(_, _):
                // 检查读权限
                openApiError = OpenAPIError(code: OpenAPISaveImageToPhotosAlbumErrorCode.readPermissionDenied)
                    .setMonitorMessage("permission denied, \(params.filePath)")
                    .setErrno(fileCommonErrno)
            default:
                openApiError = fileError.fileSystemUnknownError
            }
            callback(.failure(error: openApiError))
        } catch {
            callback(.failure(error: error.fileSystemUnknownError))
        }
    }
    
    public func previewImage(
        with params: OpenAPIPreviewImageParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        /// 通用错误回调方法
        let errorCallBack: ((String, OpenAPICommonErrorCode) -> Void) = { (errorMsg, code) in
            let error = OpenAPIError(code: code)
                .setOuterMessage(errorMsg)
            callback(.failure(error: error))
            context.apiTrace.error("previewImage fail \(errorMsg) \(code)")
        }
        guard let controller = gadgetContext.controller else {
            context.apiTrace.error("can not find controller to previewImage")
            errorCallBack("", .unknown)
            return
        }
        context.apiTrace.info("start call previewImageV1")
        let callIndex = "\(Date().timeIntervalSince1970)"
        let handler = EMAPluginImagePreviewHandler(uniqueID: gadgetContext.uniqueID, controller: controller)
        previewImageHolder[callIndex] = handler
        context.apiTrace.info("preview image start \(callIndex)")
        
        handler.previewImage(withParam: params.toJSONDict()) { [weak self](callbackType, result) in
            context.apiTrace.info("preview image start \(callIndex) finish \(callbackType.rawValue)")
            defer {
                self?.previewImageHolder.removeValue(forKey: callIndex)
            }
            guard callbackType == .success else {
                guard let resultDic = result as? [String: Any],
                   let errMsg = resultDic["errMsg"] as? String else {
                    errorCallBack("", .unknown)
                    return
                }
                switch callbackType {
                case .failed:
                    errorCallBack(errMsg, .unknown)
                case .userCancel:
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    errorCallBack(errMsg, .internalError)
                case .paramError:
                    errorCallBack(errMsg, .invalidParam)
                case .invalidScope, .noPlatformPermission, .noSystemPermission:
                    errorCallBack(errMsg, .authenFail)
                default:
                    errorCallBack(errMsg, .unknown)
                }
                return
            }
            callback(.success(data: nil))
        }
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "chooseImage", pluginType: Self.self,
                             paramsType: OpenPluginChooseImageRequest.self,
                             resultType: OpenPluginChooseImageResponse.self) { (this, params, context, gadgetContext, callback) in
            
            BDPMemoryManager.sharedInstance.triggerMemoryCleanByAPI(name: "chooseImage")
            let enable = this.isEnableCameraKit()
            if enable {
                this.chooseImageV3(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
            } else {
                this.chooseImageV2(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
        registerInstanceAsyncHandlerGadget(for: "compressImage", pluginType: Self.self,
                             paramsType: OpenPluginCompressImageRequest.self,
                             resultType: OpenPluginCompressImageResponse.self) { (this, params, context, gadgetContext, callback) in
            this.compressImageV2(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "getImageInfo",
                                           pluginType: Self.self,
                             paramsType: OpenAPIGetImageInfoParams.self,
                             resultType: OpenAPIGetImageInfoResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getImageInfo(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "saveImageToPhotosAlbum", pluginType: Self.self,
                             paramsType: OpenAPISaveImageParams.self,
                             resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.saveImageToPhotosAlbum(with: params, context: context, gadgetContext:gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "previewImage", pluginType: Self.self,
                             paramsType: OpenAPIPreviewImageParams.self,
                             resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            let isEnable = this.isEnableNewPreviewImage()
            if isEnable {
                this.previewImageV2(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
            } else {
                this.previewImage(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
    }
    /// preview Image Handler holder, release after callback
    var previewImageHolder: [String: EMAPluginImagePreviewHandler] = [:]
    
    private func chooseImageAPIRevert() -> Bool {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.media_api_change_revert")
    }

    private func compressImageAPIRevert() -> Bool {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.compress_image_change_revert")
    }
    
    private func isEnableCameraKit() -> Bool {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.camerakit.enable")
    }
    private func isEnableNewPreviewImage() -> Bool {
        PreviewImageConfig.settingsConfig().enableLarkPhotoPreview
    }
}
