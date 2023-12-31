//
//  ChooseMedia.swift
//  OPPlugin
//
//  Created by bytedance on 2021/5/18.
//

import UIKit
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkAssetsBrowser
import OPPluginManagerAdapter
import Photos
import Kingfisher
import LarkActionSheet
import CoreServices
import ByteWebImage
import OPSDK
import LarkUIKit
import LarkFoundation
import OPFoundation
import LarkSetting
import OPPluginBiz
import LarkContainer
import LarkVideoDirector
/**
 PRD: https://bytedance.feishu.cn/docs/doccnSPV1jwRTB3k0D6vVQD9yae

 系统错误均对外暴露 system error，具体系统错误原因写入日志
 */
final class OpenPluginChooseMedia: OpenBasePlugin {
    /// 默认最大数量
    /// 选择图片或(和)视频
    /// - Parameters:
    ///   - param: 入参数据模型
    ///   - callback: 选择结果
    public func chooseMedia(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        //count逻辑和Android对齐
        if params.count < 1 {
            params.count = 9
        }else if params.count > 20 {
            params.count = 20
        }
        
        //新增参数三端对齐逻辑
        let changeRevert = userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.choose_media_change_revert")
        context.apiTrace.info("chooseMedia formatParams changeRevert:\(changeRevert)")
        if !changeRevert {
            //这里对参数做三端一致性对齐，mediaType，sourceType，sizeType字段如果过滤非法值后为空，则取默认值
            formatParams(params: params)
        }
            
        let allowChooseImage = params.mediaType.contains("image")
        let allowChooseVideo = params.mediaType.contains("video")
        let allowCameraMode = params.sourceType.contains("camera")
        let allowAlbumMode = params.sourceType.contains("album")
        context.apiTrace.info("Start chooseMedia")
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        //拍照片选项是否可用
        let canUseCameraPhoto = isCameraAvailable && allowCameraMode && allowChooseImage
        //拍视频选项是否可用
        let canUseCameraVideo = isCameraAvailable && allowCameraMode && allowChooseVideo
        if !canUseCameraPhoto, !canUseCameraVideo, !allowAlbumMode {
            // 相册不可用，拍图片不可用，拍视频也不可用
            context.apiTrace.error("camera is damaged or check the parameters, isCameraAvailable:\(isCameraAvailable), allowChooseImage:\(allowChooseImage), allowChooseVideo:\(allowChooseVideo), allowCameraMode:\(allowCameraMode), allowAlbumMode:\(allowAlbumMode)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("camera is damaged or check the parameters")
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: error))
            return
        }
        var sheetActions = [EMAActionSheetAction]()
        
        let useCameraKit = EMAFeatureGating.boolValue(forKey: "openplatform.api.camerakit.enable")
        context.apiTrace.info("chooseMedia useCameraKit:\(useCameraKit)")
        ///相机部分
        if canUseCameraPhoto {//相机->图片
            sheetActions.append(EMAActionSheetAction(title: BDPI18n.take_photo, style: .default) {
                if useCameraKit {
                    self.showMediaCameraImagePickerV3(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
                }else {
                    self.showMediaCameraImagePickerV2(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
                }
            })
        } else {
            context.apiTrace.info("canUseCameraPhoto is false")
        }
        if canUseCameraVideo {//相机->视频
            sheetActions.append(EMAActionSheetAction(title: BDPI18n.use_camera, style: .default) {
                params.maxDuration = max(3, min(params.maxDuration, 60))//跟Android对齐，maxDuration在3~60之间
                if useCameraKit{
                    self.showMediaCameraVideoPickerV3(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
                }else {
                    self.showMediaCameraVideoPickerV2(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
                }
            })
        } else {
            context.apiTrace.info("canUseCameraVideo is false")
        }
        ///相册部分
        if allowAlbumMode && allowChooseImage, allowAlbumMode && allowChooseVideo {//相册->图片&视频
            sheetActions.append(EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                self.showAlbumMediasPicker(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            })
        } else if allowAlbumMode && allowChooseImage, !allowChooseVideo {//相册->图片
            sheetActions.append(EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                self.showMediaAlbumImagePicker(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            })
        } else if !allowChooseImage, allowAlbumMode && allowChooseVideo {//相册->视频
            sheetActions.append(EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                self.showMediaAlbumVideosPicker(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            })
        } else {
            // 仅有拍摄选项，没有从相册选择的选项
            context.apiTrace.info("no album option")
        }
        sheetActions.append(EMAActionSheetAction(title: BDPI18n.cancel, style: .cancel) {
            context.apiTrace.info("cancel")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setOuterMessage("cancel")
                .setErrno(OpenAPIVideoErrno.UserCanceled)
            callback(.failure(error: error))
        })
        let actionSheet = OPActionSheet.createActionSheet(with: sheetActions, isAutorotatable: UDRotation.isAutorotate(from: controller))
        controller.present(actionSheet, animated: true, completion: nil)
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "chooseMedia", pluginType: Self.self, paramsType: OpenPluginChooseMediaParams.self, resultType: OpenPluginChooseMediaResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.chooseMedia(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
    
    private func formatParams(params: OpenPluginChooseMediaParams){
        let defaultMediaType = ["image","video"]
        let defaultSourceType = ["album","camera"]
        let defaultSizeType = ["original","compressed"]
        
        let resultMediaType = params.mediaType.filter {
            defaultMediaType.contains($0)
        }
        if resultMediaType.isEmpty {
            params.mediaType = defaultMediaType
        }
        
        let resultSourceType = params.sourceType.filter {
            defaultSourceType.contains($0)
        }
        if resultSourceType.isEmpty {
            params.sourceType = defaultSourceType
        }
        
        let resultSizeType = params.sizeType.filter {
            defaultSizeType.contains($0)
        }
        if resultSizeType.isEmpty {
            params.sizeType = defaultSizeType
        }
    }
    
    /// camerKit 图片
    private func showMediaCameraImagePickerV3(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("chooseMedia start cameraKit take photo")
        let uniqueID = gadgetContext.uniqueID
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        let original = params.sizeType.contains("original")
        let compressed = params.sizeType.contains("compressed")
        let isOriginal = (original && !compressed)
        let isSaveToAlbum = params.isSaveToAlbum == .one ? true:false
        let cameraDevice = params.cameraDevice
        context.apiTrace.info("cameraKit imagePicker isSaveToAlbum:\(isSaveToAlbum)")
        //保存到相册时，首先判断相册权限，通过再弹起camera
        if isSaveToAlbum {
            BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                guard isSuccess else {
                    context.apiTrace.error("no album permissionV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setOuterMessage("no album permission")
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                    callback(.failure(error: error))
                    return
                }
                showCameraVC()
            }
        }else {//不需要保存到相册
            showCameraVC()
        }
        
        func showCameraVC(){
            var config = LarkCameraKit.CameraConfig()
            config.cameraPosition = cameraDevice == "front" ? .front : .back
            config.mediaType = .photoOnly
            config.autoSave = isSaveToAlbum
            config.afterTakePhotoAction = .enterImageEditor
            config.didTakePhoto = {(image, vc, saveToAlbumSuccess, granted) in
                context.apiTrace.info("cameraKit didTakePhoto image:\(image), vc:\(vc), success:\(saveToAlbumSuccess), granted:\(granted)")
                if isSaveToAlbum, !saveToAlbumSuccess {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                        .setMonitorMessage("cameraKit save image to ablum fail")
                    vc.dismiss(animated: true) {
                        callback(.failure(error: error))
                    }
                    return
                }
                if let model = self.handleImage(img: image, isOriginal: isOriginal, uniqueID: uniqueID, context: context) {
                    vc.dismiss(animated: true) {
                        callback(.success(data: OpenPluginChooseMediaResult(files: [model])))
                    }
                } else {
                    context.apiTrace.error("system error parsing resourceV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setOuterMessage("system error")
                        .setErrno(OpenAPICommonErrno.unknown)
                    vc.dismiss(animated: true) {
                        callback(.failure(error: error))
                    }
                }
            }
            config.didCancel = {(error) in
                context.apiTrace.error("cameraKit takePhoto user cancel, error:\(String(describing: error))")
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("cancel")
                    .setErrno(OpenAPIVideoErrno.UserCanceled)
                callback(.failure(error: apiError))
            }
            Self.showCameraKitVC(config: config, from: controller, trace: context.apiTrace, callback: callback)
        }
      
    }
    
    /// cameraWrapper 图片
    private func showMediaCameraImagePickerV2(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("start take photoV2")
        let original = params.sizeType.contains("original")
        let compressed = params.sizeType.contains("compressed")
        let isOriginal = (original && !compressed)
        var isSaveToAlbum = false;
        if params.isSaveToAlbum == .one {
            isSaveToAlbum = true
        }
        context.apiTrace.info("imagePickerV2 isSaveToAlbum:\(isSaveToAlbum)")
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        BDPAuthorization.checkSystemPermission(withTips: .camera) { (isSuccess) in
            guard isSuccess else {
                context.apiTrace.error("no camera permissionV2")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setOuterMessage("no camera permission")
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            //保存到相册时，首先判断相册权限，通过再弹起camera
            if isSaveToAlbum {
                BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                    guard isSuccess else {
                        context.apiTrace.error("no album permissionV2")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                            .setOuterMessage("no album permission")
                            .setErrno(OpenAPICommonErrno.systemAuthDeny)
                        callback(.failure(error: error))
                        return
                    }
                    showCameraVC()
                }
            }else {//不需要保存到相册
                showCameraVC()
            }
            
            func showCameraVC(){
                let cameraWrapper = AssetCameraWrapper()
                cameraWrapper.camera.mediaType = .photo
                
                let cameraDevice = params.cameraDevice
                cameraWrapper.camera.defaultCameraPosition = cameraDevice == "front" ? .front : .back
            
                cameraWrapper.didTakePhoto = {[weak cameraWrapper] (image) in
                    if isSaveToAlbum {
                        context.apiTrace.info("chooseMediaImageV2 start savePhoto")
                        
                        let handler = { (success: Bool, granted: Bool) in
                            context.apiTrace.info("chooseMediaImageV2 savePhoto success:\(success),granted:\(granted)")
                            if success && granted {
                                if let model = self.handleImage(img: image, isOriginal: isOriginal, uniqueID: uniqueID, context: context) {
                                    callback(.success(data: OpenPluginChooseMediaResult(files: [model])))
                                } else {
                                    context.apiTrace.error("system error parsing resourceV2")
                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                        .setOuterMessage("system error")
                                        .setErrno(OpenAPICommonErrno.unknown)
                                    callback(.failure(error: error))
                                }
                            }else {
                                if !granted {
                                    context.apiTrace.error("no album permissionV2")
                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                                        .setOuterMessage("no album permission")
                                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                                    callback(.failure(error: error))
                                    return
                                }else {
                                    context.apiTrace.error("system error in save photoV2")
                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                        .setOuterMessage("system error")
                                        .setErrno(OpenAPICommonErrno.unknown)
                                    callback(.failure(error: error))
                                    return
                                }
                            }
                        }
                        if OPSensitivityEntry.sensitivityControlEnable() {
                            do {
                                try Utils.savePhoto(token: OPSensitivityEntryToken.OpenPluginChooseMedia_showCameraVC_Utils_savePhoto.psdaToken, image: image, handler: handler)
                            } catch {
                                context.apiTrace.error("savePhoto psda error \(error)")
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                                    .setErrno(OpenAPICommonErrno.internalError)
                                callback(.failure(error: error))
                            }
                            
                        } else {
                            Utils.savePhoto(image: image, handler: handler)
                        }

                    }else {
                        if let model = self.handleImage(img: image, isOriginal: isOriginal, uniqueID: uniqueID, context: context) {
                            callback(.success(data: OpenPluginChooseMediaResult(files: [model])))
                        } else {
                            context.apiTrace.error("system error parsing resourceV2")
                            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setOuterMessage("system error")
                                .setErrno(OpenAPICommonErrno.unknown)
                            callback(.failure(error: error))
                        }
                    }
                    cameraWrapper?.dismissCamera(animated: true)
                }
                
                cameraWrapper.didDismiss = {[weak cameraWrapper] in
                    // 进入相机拍摄后点的取消
                    context.apiTrace.error("cancel in take photoV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("cancel")
                        .setErrno(OpenAPIVideoErrno.UserCanceled)
                    callback(.failure(error: error))
                    cameraWrapper?.dismissCamera(animated: true)
                }
                
                if #available(iOS 13.0, *) {
                    cameraWrapper.camera.modalPresentationStyle = .fullScreen
                }
                cameraWrapper.present(vc: controller, animated: true)
            }

        }
    }
    /// cameraKit视频
    private func showMediaCameraVideoPickerV3(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("chooseMedia start cameraKit take video")
        let uniqueID = gadgetContext.uniqueID
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        let isSaveToAlbum = params.isSaveToAlbum == .one ? true:false
        let cameraDevice = params.cameraDevice
        context.apiTrace.info("cameraKit videoPicker isSaveToAlbum:\(isSaveToAlbum)")
        
        //在拍摄完成需要保存到相册时，首先判断相册权限，通过再弹起camera
        if isSaveToAlbum {
            BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                guard isSuccess else {
                    context.apiTrace.error("no album permissionV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setOuterMessage("no album permission")
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                    callback(.failure(error: error))
                    return
                }
                showCameraVC()
            }
        }else {
            showCameraVC()
        }
        
        func showCameraVC(){
            var config = LarkCameraKit.CameraConfig()
            config.cameraPosition = cameraDevice == "front" ? .front : .back
            config.mediaType = .videoOnly
            config.afterRecordVideoAction = .enterVideoEditor
            config.autoSave = isSaveToAlbum
            config.videoMaxDuration = params.maxDuration
            config.didRecordVideo = {(url, vc, saveToAlbumSuccess, granted) in
                context.apiTrace.info("cameraKit didRecordVideo url:\(url), vc:\(vc), success:\(saveToAlbumSuccess), granted:\(granted)")
                if isSaveToAlbum, !saveToAlbumSuccess {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                        .setMonitorMessage("cameraKit save video to ablum fail")
                    vc.dismiss(animated: true) {
                        callback(.failure(error: error))
                    }
                    return
                }
                let hud = EMAHUD.showLoading(nil, on: vc.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                let avAsset = AVURLAsset(url: url)
                self.chooseMediaExportVideo(avAsset, param: params, uniqueID: uniqueID, context: context, callback: { (result) in
                    DispatchQueue.main.async {
                        hud.remove()
                        vc.dismiss(animated: true) {
                            callback(.success(data: OpenPluginChooseMediaResult(files: [result])))
                        }
                    }
                })
            }
            config.didCancel = {(error) in
                context.apiTrace.error("cameraKit recordVideo user cancel, error:\(String(describing: error))")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("cancel")
                    .setErrno(OpenAPIVideoErrno.UserCanceled)
                callback(.failure(error: error))
            }
            Self.showCameraKitVC(config: config, from: controller, trace: context.apiTrace, callback: callback)
        }
        
    }
    
    private static func showCameraKitVC(config: LarkCameraKit.CameraConfig,
                                  from: UIViewController,
                                 trace: OPTrace,
                              callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void){
        trace.info("start showCameraKitVC mediaType:\(config.mediaType)")
        EMAImagePicker.showCameraVC(config: config, from: from) { result in
            switch result {
            case .failure(let error):
                trace.error("showCameraKitVC error:\(error)")
                switch error {
                case .notSupportSimulator:
                    let apiError = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    callback(.failure(error: apiError))
                case .noVideoPermission:
                    BDPAuthorization.showAlertNoPermission(.camera)
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setOuterMessage("no camera permission")
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                    callback(.failure(error: apiError))
                case .noAudioPermission:
                    BDPAuthorization.showAlertNoPermission(.microphone)
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setOuterMessage("no microphone permission")
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                    callback(.failure(error: apiError))
                case .mediaOccupiedByOthers(let scene, let msg):
                    trace.error("mediaOccupiedByOthers scene:\(scene), msg:\(String(describing: msg))")
                    var apiError = OpenAPIError(errno: OpenAPIVideoErrno.startShootHigherPriorityFailed)
                    if config.mediaType == .photoOnly {
                        apiError = OpenAPIError(errno: OpenAPIImageErrno.startShootHigherPriorityFailed)
                    }
                    callback(.failure(error: apiError))
                @unknown default:
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                    callback(.failure(error: error))
                }
            case .success():
                trace.info("chooseMedia showCameraKitVC success")
            @unknown default:
                let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
            }
        }

    }
    
    /// cameraWrapper视频
    private func showMediaCameraVideoPickerV2(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("start take videoV2")
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        var isSaveToAlbum = false;
        if params.isSaveToAlbum == .one {
            isSaveToAlbum = true
        }
        context.apiTrace.info("videoPickerV2 isSaveToAlbum:\(isSaveToAlbum)")
        BDPAuthorization.checkSystemPermission(withTips: .camera) { (isSuccess) in
            guard isSuccess else {
                context.apiTrace.info("no camera permissionV2")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setOuterMessage("no camera permission")
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            BDPAuthorization.checkSystemPermission(withTips: .microphone) { (isSuccess) in
                guard isSuccess else {
                    context.apiTrace.info("no microphone permissionV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setOuterMessage("no microphone permission")
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                    callback(.failure(error: error))
                    return
                }
                //在拍摄完成需要保存到相册时，首先判断相册权限，通过再弹起camera
                if isSaveToAlbum {
                    BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                        guard isSuccess else {
                            context.apiTrace.error("no album permissionV2")
                            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                                .setOuterMessage("no album permission")
                                .setErrno(OpenAPICommonErrno.systemAuthDeny)
                            callback(.failure(error: error))
                            return
                        }
                        showCameraVC()
                    }
                }else {
                    showCameraVC()
                }
            }
                       
            func showCameraVC(){
                let cameraWrapper = AssetCameraWrapper()
                cameraWrapper.camera.mediaType = .video
                cameraWrapper.camera.maxVideoDuration = params.maxDuration
                let cameraDevice = params.cameraDevice
                cameraWrapper.camera.defaultCameraPosition = cameraDevice == "front" ? .front : .back
                
                cameraWrapper.didFinishRecord = {[weak cameraWrapper] (url)in
                    executeOnMainQueueAsync {
                        if isSaveToAlbum {//保存视频到相册
                            context.apiTrace.info("chooseMediaVideoV2 start saveVideo")
                            let hud = EMAHUD.showLoading(nil, on: cameraWrapper?.camera.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                            let handler = { (success: Bool, granted: Bool) in
                                context.apiTrace.info("chooseMediaVideoV2 saveVideo success:\(success),granted:\(granted)")
                                if success && granted {
                                    let avAsset = AVURLAsset(url: url)
                                    self.chooseMediaExportVideo(avAsset, param: params, uniqueID: uniqueID, context: context, callback: { (result) in
                                        hud.remove()
                                        cameraWrapper?.dismissCamera(animated: true)
                                        callback(.success(data: OpenPluginChooseMediaResult(files: [result])))
                                    })
                                }else {//保存失败，无权限或者内部错误
                                    if !granted {
                                        context.apiTrace.error("no album permissionV2")
                                        let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                                            .setOuterMessage("no album permission")
                                            .setErrno(OpenAPICommonErrno.systemAuthDeny)
                                        callback(.failure(error: error))
                                        cameraWrapper?.dismissCamera(animated: true)
                                        return
                                    }else {
                                        // 拍摄后保存到相册系统错误
                                        context.apiTrace.error("system error in save videoV2")
                                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                            .setOuterMessage("system error")
                                            .setErrno(OpenAPICommonErrno.unknown)
                                        callback(.failure(error: error))
                                        cameraWrapper?.dismissCamera(animated: true)
                                        return
                                    }
                                }
                            }
                            if OPSensitivityEntry.sensitivityControlEnable() {
                                do {
                                    try Utils.saveVideo(token: OPSensitivityEntryToken.OpenPluginChooseMedia_showCameraVC_Utils_saveVideo.psdaToken,
                                                        url: url, handler: handler)
                                } catch {
                                    context.apiTrace.error("psda saveVideo error \(error)")
                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                                        .setErrno(OpenAPICommonErrno.internalError)
                                    callback(.failure(error: error))
                                    cameraWrapper?.dismissCamera(animated: true)
                                }
                                
                            } else {
                                Utils.saveVideo(url: url, handler: handler)
                            }
                            
                        }else {//不保存视频到相册
                            let avAsset = AVURLAsset(url: url)
                            let hud = EMAHUD.showLoading(nil, on: cameraWrapper?.camera.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                            self.chooseMediaExportVideo(avAsset, param: params, uniqueID: uniqueID, context: context, callback: { (result) in
                                hud.remove()
                                cameraWrapper?.dismissCamera(animated: true)
                                callback(.success(data: OpenPluginChooseMediaResult(files: [result])))
                            })
                        }
                    }
                    
                }
                
                cameraWrapper.didDismiss = {[weak cameraWrapper] in
                    // 进入相机拍摄后点的取消
                    context.apiTrace.error("cancel in take videoV2")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("cancel")
                        .setErrno(OpenAPIVideoErrno.UserCanceled)
                    callback(.failure(error: error))
                    cameraWrapper?.dismissCamera(animated: true)
                }
                if #available(iOS 13.0, *) {
                    cameraWrapper.camera.modalPresentationStyle = .fullScreen
                }
                cameraWrapper.present(vc: controller, animated: true)
            }
            
        }
    }
    
    /// 相册仅选图片
    private func showMediaAlbumImagePicker(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("start selecting photos from album")
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            guard isSuccess else {
                context.apiTrace.info("no album permission")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setOuterMessage("no album permission")
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            let original = params.sizeType.contains("original")
            let compressed = params.sizeType.contains("compressed")
            let isOriginal = (original && !compressed)
            let isOriginButtonHidden = !(original && compressed)
            let imagePicker = ImagePickerViewController(assetType: .imageOnly(maxCount: params.count),
                                                        selectedAssets: [],
                                                        isOriginal: isOriginal,
                                                        isOriginButtonHidden:isOriginButtonHidden,
                                                        sendButtonTitle: BDPI18n.done,
                                                        takePhotoEnable: EMAImagePicker.takePhotoEnable,
                                                        editImageCache: nil)
            if params.singleSelect {
                imagePicker.showSingleSelectAssetGridViewController()
            } else {
                imagePicker.showMultiSelectAssetGridViewController()
            }
            imagePicker.imagePikcerCancelSelect = { (picker, _) in
                picker.dismiss(animated: true, completion: nil)
                context.apiTrace.info("cancel in choose image")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("cancel")
                    .setErrno(OpenAPIVideoErrno.UserCanceled)
                callback(.failure(error: error))
            }
            imagePicker.imagePickerFinishSelect = { (picker, result) in
                context.apiTrace.info("number of photos selected from album:\(result.selectedAssets.count)")
                guard result.selectedAssets.count > 0 else {
                    context.apiTrace.info("cancel in choose image system page")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("cancel")
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return
                }
                let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                hud.showAfterDelay(0.5)
                let queue = DispatchQueue(label: "queue", attributes: .concurrent)
                let dispatchGroup: DispatchGroup = DispatchGroup()
                var errorCount = 0
                var results: [OpenPluginChooseMediaModel] = Array(repeating: .init(type: .error), count: result.selectedAssets.count)
                for (index, asset) in result.selectedAssets.enumerated() {
                    dispatchGroup.enter()
                    queue.async {
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.deliveryMode = .fastFormat
                        options.resizeMode = .fast
                        options.isNetworkAccessAllowed = true
                        self.handleImageAsset(asset: asset, options: options, isOriginal: result.isOriginal, uniqueID: uniqueID, context: context) { (model) in
                            DispatchQueue.main.async {
                                if let model = model {
                                    results[index] = model
                                } else {
                                    errorCount = errorCount + 1
                                    results[index] = OpenPluginChooseMediaModel(type: .image)
                                }
                                dispatchGroup.leave()
                            }
                        }
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    hud.remove()
                    picker.dismiss(animated: true, completion: nil)
                    if errorCount >= result.selectedAssets.count {
                        context.apiTrace.error("every choose image is nil, errorCount:\(errorCount), count:\(result.selectedAssets.count)")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setOuterMessage("system error")
                            .setErrno(OpenAPICommonErrno.unknown)
                        callback(.failure(error: error))
                    } else {
                        callback(.success(data: OpenPluginChooseMediaResult(files: results)))
                        context.apiTrace.info("select photo from album success, count:\(results.count)")
                    }
                }
            }
            if #available(iOS 13.0, *) {
                imagePicker.modalPresentationStyle = .fullScreen
            }
            controller.present(imagePicker, animated: true)
        }
    }
    /// 从相册仅选视频
    private func showMediaAlbumVideosPicker(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        context.apiTrace.info("start choose video from album")
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            guard isSuccess else {
                context.apiTrace.error("no album permission")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setOuterMessage("no album permission")
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            let compressed = params.sizeType.contains("compressed")
            let imagePicker = ImagePickerViewController(assetType: .videoOnly(maxCount:params.count),
                                                        selectedAssets: [],
                                                        isOriginal: !compressed,
                                                        isOriginButtonHidden: true,
                                                        sendButtonTitle: BDPI18n.done,
                                                        takePhotoEnable: EMAImagePicker.takePhotoEnable,
                                                        editImageCache: nil)
            imagePicker.showMultiSelectAssetGridViewController()
            imagePicker.imagePikcerCancelSelect = { (picker, _) in
                context.apiTrace.info("cancel in choose video")
                picker.dismiss(animated: true, completion: nil)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("cancel")
                    .setErrno(OpenAPIVideoErrno.UserCanceled)
                callback(.failure(error: error))
            }
            imagePicker.imagePickerFinishSelect = { (picker, result) in
                guard (result.selectedAssets.count != 0) else {
                    context.apiTrace.error("internal error: asset is nil!")
                    picker.dismiss(animated: true, completion: nil)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("cancel")
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return
                }
                var results: [OpenPluginChooseMediaModel] = Array(repeating: .init(type: .error), count: result.selectedAssets.count)
                let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                let queue = DispatchQueue(label: "queue", attributes: .concurrent)
                let dispatchGroup: DispatchGroup = DispatchGroup()
                var errorCount = 0
                for (index, asset) in result.selectedAssets.enumerated() {
                    dispatchGroup.enter()
                    queue.async(group: dispatchGroup) {
                        let options = PHVideoRequestOptions()
                        options.deliveryMode = .fastFormat
                        self.handleAVAsset(forToken: .PHImageManager_requestAVAsset_chooseMedia_showMediaAlbumVideosPicker, asset: asset, options: options, params: params, uniqueID: uniqueID, context: context) { (model) in
                            DispatchQueue.main.async {
                                if let model = model {
                                    results[index] = model
                                } else {
                                    errorCount = errorCount + 1
                                    results[index] = OpenPluginChooseMediaModel(type: .video)
                                }
                                dispatchGroup.leave()
                            }
                        }
                    }
                }
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    hud.remove()
                    picker.dismiss(animated: true, completion: nil)
                    if errorCount >= result.selectedAssets.count {
                        context.apiTrace.error("every choose video is nil, errorCount:\(errorCount), count:\(result.selectedAssets.count)")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setOuterMessage("system error")
                            .setErrno(OpenAPICommonErrno.unknown)
                        callback(.failure(error: error))
                    } else {
                        callback(.success(data: OpenPluginChooseMediaResult(files: results)))
                    }
                }
            }
            if #available(iOS 13.0, *) {
                imagePicker.modalPresentationStyle = .fullScreen
            }
            controller.present(imagePicker, animated: true)
        }
    }
    /// 相册选图片和视频
    private func showAlbumMediasPicker(params: OpenPluginChooseMediaParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseMediaResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        context.apiTrace.info("Start to select pictures/videos from the album")
        let original = params.sizeType.contains("original")
        let compressed = params.sizeType.contains("compressed")
        let isOriginal = (original && !compressed)
        let isOriginButtonHidden = !(original && compressed)
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            guard isSuccess else {
                context.apiTrace.error("No album permission")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setOuterMessage("no album permission")
                    .setErrno(OpenAPICommonErrno.systemAuthDeny)
                callback(.failure(error: error))
                return
            }
            ///TODO: 需主端支持不用分别设置图片/视频数量限制，等主端输入assetType改下类型，输出不变，调试下即可
            let imagePicker = ImagePickerViewController(assetType: .imageAndVideoWithTotalCount(totalCount: params.count),
                                                        selectedAssets: [],
                                                        isOriginal: isOriginal,
                                                        isOriginButtonHidden: isOriginButtonHidden,
                                                        sendButtonTitle: BDPI18n.done,
                                                        takePhotoEnable: EMAImagePicker.takePhotoEnable,
                                                        editImageCache: nil)
            imagePicker.showMultiSelectAssetGridViewController()
            imagePicker.imagePickerFinishSelect = { (picker, result) in
                context.apiTrace.info("After selecting pictures/videos in the album, start processing the selected results")
                guard (result.selectedAssets.count != 0) else {
                    context.apiTrace.error("system error when selecting image/video from album")
                    picker.dismiss(animated: true, completion: nil)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("cancel")
                        .setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                    return
                }
                var results: [OpenPluginChooseMediaModel] = Array(repeating: .init(type: .error), count: result.selectedAssets.count)
                let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                let queue = DispatchQueue(label: "queue", attributes: .concurrent)
                // 所有图片和视频处理完后线程组通知回调
                let dispatchGroup = DispatchGroup()
                var errorCount = 0
                for (index, asset) in result.selectedAssets.enumerated() {
                    dispatchGroup.enter()
                    if asset.mediaType == .image {
                        queue.async(group: dispatchGroup, execute:  {
                            let imageOptions = PHImageRequestOptions()
                            imageOptions.isSynchronous = true
                            imageOptions.deliveryMode = .fastFormat
                            imageOptions.resizeMode = .fast
                            imageOptions.isNetworkAccessAllowed = true
                            self.handleImageAsset(asset: asset, options: imageOptions, isOriginal: result.isOriginal, uniqueID: uniqueID, context: context) { (model) in
                                DispatchQueue.main.async {
                                    if let model = model {
                                        results[index] = model
                                    } else {
                                        errorCount = errorCount + 1
                                        results[index] = OpenPluginChooseMediaModel(type: .image)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        })
                    } else if (asset.mediaType == .video) {
                        queue.async(group: dispatchGroup, execute: {
                            let videoOptions = PHVideoRequestOptions()
                            videoOptions.deliveryMode = .fastFormat
                            self.handleAVAsset(forToken: .PHImageManager_requestAVAsset_chooseMedia_showMediaAlbumVideosPicker, asset: asset, options: videoOptions, params: params, uniqueID: uniqueID, context: context) { (model) in
                                DispatchQueue.main.async {
                                    if let model = model {
                                        results[index] = model
                                    } else {
                                        errorCount = errorCount + 1
                                        results[index] = OpenPluginChooseMediaModel(type: .image)
                                    }
                                    dispatchGroup.leave()
                                }
                            }
                        })
                    } else {
                        DispatchQueue.main.async {
                            context.apiTrace.error("asset is not image or video")
                            results[index] = OpenPluginChooseMediaModel(type: .error)
                            errorCount = errorCount + 1
                            dispatchGroup.leave()
                        }
                    }
                }

                dispatchGroup.notify(queue: DispatchQueue.main, execute:  {
                    context.apiTrace.info("End of selecting picture/video from album,count:\(results.count)")
                    hud.remove()
                    picker.dismiss(animated: true, completion: nil)
                    if errorCount >= result.selectedAssets.count {
                        context.apiTrace.error("every choose media is nil, errorCount:\(errorCount), count:\(result.selectedAssets.count)")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setOuterMessage("system error")
                            .setErrno(OpenAPICommonErrno.unknown)
                        callback(.failure(error: error))
                    } else {
                        callback(.success(data: OpenPluginChooseMediaResult(files: results)))
                    }
                })
            }
            imagePicker.imagePikcerCancelSelect = { (picker, _) in
                picker.dismiss(animated: true, completion: nil)
                context.apiTrace.info("cancel")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("cancel")
                    .setErrno(OpenAPIVideoErrno.UserCanceled)
                callback(.failure(error: error))
            }
            if #available(iOS 13.0, *) {
                imagePicker.modalPresentationStyle = .fullScreen
            }
            controller.present(imagePicker, animated: true)
        }
    }
    ///视频处理工具方法， 从 AVURLAsset 导出 .mp4 或 .mov 文件
    private func chooseMediaExportVideo(_ asset: AVURLAsset, param: OpenPluginChooseMediaParams, uniqueID:OPAppUniqueID, context:OpenAPIContext, callback: @escaping (OpenPluginChooseMediaModel) -> Void) {
        
        let compressed = param.sizeType.contains("compressed")
        let preset = compressed ? AVAssetExportPresetMediumQuality : AVAssetExportPresetPassthrough
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            context.apiTrace.error("AVAsset session is nil")
            callback(OpenPluginChooseMediaModel(type: .video))
            return
        }
        guard let storageModule = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
            context.apiTrace.error("internal error: File management initialization error")
            callback(OpenPluginChooseMediaModel(type: .video))
            return
        }
        let sandbox = storageModule.minimalSandbox(with: uniqueID)
        var filePath: String
        guard let randomPath = FileSystemUtils.generateRandomPrivateTmpPath(with: sandbox) else {
            context.apiTrace.error("internal error: generate random private tmp path failed")
            callback(OpenPluginChooseMediaModel(type: .video))
            return
        }
        filePath = URL(fileURLWithPath: randomPath).absoluteString
        let ext = asset.url.pathExtension
        if !filePath.hasSuffix(ext) {
            if filePath.hasSuffix(".") {
                filePath += ext
            } else {
                filePath += ".\(ext)"
            }
        }
        guard let fileURL = URL(string: filePath) else {
            context.apiTrace.error("invalid param: file url init failed, path: \(filePath)")
            callback(OpenPluginChooseMediaModel(type: .video))
            return
        }
        // 原有逻辑是后缀和 asset 保持一致，封装类型固定为 mp4
        // 这里修改为优先使用 iPhone 上兼容性更好的 mov 封装格式，同时尽量避免转封装
        if ext.lowercased() == "mp4" {
            session.outputFileType = .mp4
        } else {
            session.outputFileType = .mov
        }
        session.outputURL = fileURL
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously {
            if session.status != .completed {
                context.apiTrace.error("export video error: \(String(describing: session.error)), session status: \(session.status)")
                callback(OpenPluginChooseMediaModel(type: .video))
                return
            }
            var size:Int = 0
            do {
                size = Int(try LSFileSystem.attributesOfItem(atPath: fileURL.path)[.size] as? Double ?? 0)
            } catch {
                context.apiTrace.error("get file size err: \(error)")
            }
            var width:Float = 0
            var height:Float = 0

            if let track = asset.tracks(withMediaType: .video).first {
                // 修复拍摄视频，返回视频宽高值可能不正确的问题
                let size = __CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform)
                width = Float(abs(size.width))
                height = Float(abs(size.height))
            }
            var ttPath: String?
                do {
                    let randomPath = FileObject.generateRandomTTFile(type: .temp, fileExtension: fileURL.pathExtension)
                    let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: context.apiTrace, tag: "chooseMedia")
                    try FileSystemCompatible.moveSystemFile(fileURL.path, to: randomPath, context: fsContext)
                    ttPath = randomPath.rawValue
                } catch let error as FileSystemError {
                    context.apiTrace.error("copy system file failed", error: error)
                } catch {
                    context.apiTrace.error("copy system file unknown error", error: error)
                }
            guard let outPath = ttPath else {
                context.apiTrace.info("ttPath is nil")
                callback(OpenPluginChooseMediaModel(type: .video))
                return
            }
            let result = OpenPluginChooseMediaModel(type: .video, video: OpenPluginChooseVideoModel(path: outPath, duration: Float(floor(CMTimeGetSeconds(asset.duration))), size: size, width: abs(width), height: abs(height)))
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
    //处理照片工具方法
    private func handleImage(img:UIImage, isOriginal:Bool, uniqueID:OPAppUniqueID, context:OpenAPIContext) -> OpenPluginChooseMediaModel? {
        guard let fixImage = UIImage.bdp_fixOrientation(img) else {
            context.apiTrace.error("fixOrientation image is nil")
            return nil
        }
        var imageData:Data?
        if fixImage.images != nil {
            imageData = BDPImageAnimatedGIFRepresentation(fixImage, fixImage.duration, 0, nil)
        } else {
            /// 根据是否选择了原图决定是否进行压缩
            var newImage = fixImage
            if !isOriginal {
                context.apiTrace.info("handleImage downsampleImage start")
                newImage = ImageDownSampleUtils.downsampleImage(image: fixImage)
            }
            imageData = newImage.jpegData(compressionQuality: isOriginal ? 1.0 : 0.8)
        }
        guard let imgData = imageData else {
            context.apiTrace.error("imgData is nil")
            return nil
        }
        guard let fileExtension = TMACustomHelper.contentType(forImageData: imgData) else {
            context.apiTrace.error("fileExtension image is nil")
            return nil
        }
            let randomTempPath = FileObject.generateRandomTTFile(type: .temp, fileExtension: fileExtension)
            let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: context.apiTrace, tag: "chooseMedia")
            do {
                try FileSystemCompatible.writeSystemData(imgData, to: randomTempPath, context: fsContext)
                let imageModel = OpenPluginChooseImageModel(path: randomTempPath.rawValue, size: imgData.count)
                return OpenPluginChooseMediaModel(type: .image, image: imageModel)
            } catch let error as FileSystemError {
                context.apiTrace.error("write file error", error: error)
                return nil
            } catch {
                context.apiTrace.error("write file unknown error", error: error)
                return nil
            }
    }

    func handleAVAsset(forToken token: OPSensitivityEntryToken, asset: PHAsset, options: PHVideoRequestOptions, params: OpenPluginChooseMediaParams, uniqueID:BDPUniqueID, context:OpenAPIContext, callback:@escaping (OpenPluginChooseMediaModel?) -> Void) {
        do {
            try OPSensitivityEntry.photos_PHImageManager_requestAVAsset(forToken: token, manager: PHImageManager.default(), forVideoAsset: asset, options: options, resultHandler: { (avAsset, _, _) in
                guard let videoAsset = avAsset as? AVURLAsset else {
                    context.apiTrace.error("video parsing error: asset is not AVURLAsset!")
                    callback(OpenPluginChooseMediaModel(type: .video))
                    return
                }
                self.chooseMediaExportVideo(videoAsset, param: params, uniqueID: uniqueID, context: context) { (result) in
                    callback(result)
                }
            })
        } catch {
            context.apiTrace.error("handleAVAsset psda error \(error)")
            callback(nil)
        }
        
    }

    func handleImageAsset(asset: PHAsset, options: PHImageRequestOptions, isOriginal:Bool, uniqueID:BDPUniqueID, context:OpenAPIContext, callback:@escaping (OpenPluginChooseMediaModel?) -> Void) {
        
        do {
            try OPSensitivityEntry.PHImageManager_requestImageData(forToken: .PHImageManager_requestImageData_OpenPluginChooseMedia_handleImageAsset, manager: PHImageManager.default(), forAsset: asset, options: options) { (data, _, _, _) in
                guard let data = data else {
                    context.apiTrace.error("export image from asset error")
                    callback(OpenPluginChooseMediaModel(type: .image))
                    return
                }
                if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                    if asset.isGIF, let img = UIImage.bdp_animatedImage(withGIFData: data) {
                        if let model = self.handleImage(img: img, isOriginal: isOriginal, uniqueID: uniqueID, context: context) {
                            callback(model)
                        } else {
                            context.apiTrace.error("animate image parsing failed")
                            callback(OpenPluginChooseMediaModel(type: .image))
                        }
                    } else {
                        if let model = self.handleImage(img: image, isOriginal: isOriginal, uniqueID: uniqueID, context: context) {
                            callback(model)
                        } else {
                            context.apiTrace.error("image parsing failed")
                            callback(OpenPluginChooseMediaModel(type: .image))
                        }
                    }
                } else {
                    context.apiTrace.error("psda image data is nil")
                    callback(nil)
                }
            }
        } catch {
            context.apiTrace.error("psda error \(error)")
            callback(nil)
        }
        
    }
}

enum ChooseMediaCameraCallBackType: String {
    case sucess
    case cancel
    case systemError //!< 解析data时系统错误
}

/// 拍照片/视频工具类
private final class UIImageChooseMediaPickerCallbackController: UIImagePickerController, UIImagePickerControllerDelegate {
    public typealias ChooseImageCallback = ((UIImage?, UIImagePickerController, ChooseMediaCameraCallBackType) -> Void)
    fileprivate var chooseImageCallback: ChooseImageCallback?
    public typealias ChooseVideoCallback = ((AVURLAsset?, UIImagePickerController, ChooseMediaCameraCallBackType) -> Void)
    fileprivate var chooseVideoCallback: ChooseVideoCallback?
    public func delegateImageCallback(callback: @escaping ChooseImageCallback) {
        self.chooseImageCallback = callback
        self.delegate = self
    }
    public func delegateVideoCallback(callback: @escaping ChooseVideoCallback) {
        self.chooseVideoCallback = callback
        self.delegate = self
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        if let imageCallBack = self.chooseImageCallback {
            imageCallBack(nil, picker, .cancel)
        }
        if let videoCallBack = self.chooseVideoCallback {
            videoCallBack(nil, picker, .cancel)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 统一在 callback 里面进行 dismiss
        // 统一在 callback 里面进行 log
        if let chooseImageCallback = self.chooseImageCallback {
            var targetImage: UIImage?
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                targetImage = image
            } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                targetImage = image
            }
            if var target = targetImage {
                if (!EMAFeatureGating.boolValue(forKey: "lark.open_platform.api.choose_media.get_original_photo")) {
                    // 开启后，chooseMedia API 不再进行默认压缩
                    target = target.ema_redraw()
                }
                chooseImageCallback(target, picker, .sucess)
            } else {
                chooseImageCallback(nil, picker, .systemError)
            }
        }
        if let chooseVideoCallback = self.chooseVideoCallback {
            if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                let asset = AVURLAsset(url: url)
                chooseVideoCallback(asset, picker, .sucess)
            } else {
                chooseVideoCallback(nil, picker, .systemError)
            }
        }
    }
}
