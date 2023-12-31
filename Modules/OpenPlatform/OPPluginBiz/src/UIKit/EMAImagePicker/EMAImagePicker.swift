//
//  LarkUIKitImagePickerImpl.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/3.
//

import Kingfisher
import LKCommonsLogging
import LarkCamera
import Photos
import LarkAssetsBrowser
import LarkImageEditor
import ByteWebImage
import LarkActionSheet
import CoreServices
import OPPluginManagerAdapter
import UIKit
import LarkUIKit
import LarkFoundation
import OPFoundation
import LarkFeatureGating
import LarkSetting
import LarkVideoDirector
import LarkContainer

public enum CameraError: Error {
    case saveToAlbumFail
    case userCancel
    case createCamera(LarkCameraKit.Error.Creating)
}

@objcMembers
public final class EMAImagePicker: NSObject {
    private static let logger = Logger.oplog(EMAImagePicker.self, category: "EMAImagePicker")
    
    // TODOZJX
    //相册选图&视频，右上角"拍照"按钮去除兜底fg，默认不打开
    @FeatureGatingValue(key: "openplatform.api.choose_image_remove_button.disable")
    public static var takePhotoEnable: Bool
    
    // TODOZJX
    @FeatureGatingValue(key: "openplatform.api.choose_image_callback_opt.disable")
    public static var callbackOptDisable: Bool

// MARK: - Image
    public static func pickImage(
        withMaxCount maxCount: Int,
        allowAlbumMode: Bool,
        allowCameraMode: Bool,
        isOriginalHidden: Bool,
        isOriginal: Bool,
        singleSelect: Bool = false,
        cameraDevice: String = "back",
        in controller: UIViewController,
        resultCallback: (([UIImage]?, Bool, BDPImageAuthResult) -> Void)?
        ) {

        if controller == nil {
            return
        }

        func showAlbumImagePicker() {
            BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                if isSuccess {
                    let imagePicker = ImagePickerViewController(assetType: .imageOnly(maxCount: maxCount), selectedAssets: [], isOriginal: isOriginal, isOriginButtonHidden: isOriginalHidden, sendButtonTitle: BDPI18n.done, editImageCache: nil)
                    if singleSelect {
                        imagePicker.showSingleSelectAssetGridViewController()
                    } else {
                        imagePicker.showMultiSelectAssetGridViewController()
                    }
                    imagePicker.imagePickerFinishSelect = { (picker, result) in
                        let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                        hud.showAfterDelay(0.5)
                        DispatchQueue.global(qos: .background).async {
                            var imageArray: [UIImage] = []

                            for asset in result.selectedAssets {
                                let options = PHImageRequestOptions()
                                options.isSynchronous = true
                                options.deliveryMode = .fastFormat
                                options.resizeMode = .fast
                                options.isNetworkAccessAllowed = true
                                let sema = DispatchSemaphore(value: 0)
                                PHImageManager.default().requestImageData(for: asset, options: options) { (data, _, _, _) in
                                    if let data = data, let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                                        if asset.isGIF, let img = UIImage.bdp_animatedImage(withGIFData: data) {
                                            imageArray.append(img)
                                        } else {
                                            imageArray.append(image)
                                        }
                                    }
                                    /// iOS13 isSynchronous 为true，但requestImageData依然为异步，通过signal解决
                                    if #available(iOS 13.0, *) {
                                        sema.signal()
                                    }
                                }
                                if #available(iOS 13.0, *) {
                                    sema.wait()
                                }
                            }
                            DispatchQueue.main.async {
                                hud.remove()
                                picker.dismiss(animated: true, completion: nil)
                                resultCallback?(imageArray, result.isOriginal, .pass)
                            }
                        }
                    }
                    imagePicker.imagePikcerCancelSelect = { (picker, _) in
                        picker.dismiss(animated: true, completion: nil)
                        resultCallback?(nil, isOriginal, .pass)
                    }

                    if #available(iOS 13.0, *) {
                        imagePicker.modalPresentationStyle = .fullScreen
                    }
                    controller.present(imagePicker, animated: true)
                } else {
                    resultCallback?(nil, isOriginal, .deny)
                }
            }

        }

        func showCameraImagePicker() {
            BDPAuthorization.checkSystemPermission(withTips: .camera) { (isSuccess) in
                if isSuccess {
                    let camera = UIImagePickerCallbackController()
                    camera.sourceType = .camera
                    if cameraDevice == "front" {
                        camera.cameraDevice = .front
                    } else if cameraDevice == "back" {
                        camera.cameraDevice = .rear
                    } else {
                        camera.cameraDevice = .rear
                    }
                    camera.delegateImageCallback(callback: { (image, picker) in
                        picker.dismiss(animated: true, completion: nil)
                        if let image = image {
                            resultCallback?([image], isOriginal, .pass)
                        } else {
                            resultCallback?(nil, isOriginal, .pass)
                        }
                    })
                    if #available(iOS 13.0, *) {
                        camera.modalPresentationStyle = .fullScreen
                    }
                    controller.present(camera, animated: true)
                } else {
                    resultCallback?(nil, isOriginal, .deny)
                }
            }
        }
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let canUseCamera = allowCameraMode && isCameraAvailable
        if canUseCamera, !allowAlbumMode {
            // 只有相机可用
            showCameraImagePicker()
        } else if !canUseCamera, allowAlbumMode {
            // 只用相册可用
            showAlbumImagePicker()
        } else if canUseCamera, allowAlbumMode {
            // 相机 & 相册 都可用
            let sheetActions = [
                EMAActionSheetAction(title: BDPI18n.take_photo, style: .default) {
                    showCameraImagePicker()
                },
                EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                    showAlbumImagePicker()
                },
                EMAActionSheetAction(title: BDPI18n.cancel, style: .cancel) {
                    resultCallback?(nil, isOriginal, .pass)
                },
            ]
            
            
            let actionSheet = OPActionSheet.createActionSheet(with: sheetActions, isAutorotatable: UDRotation.isAutorotate(from: controller))
            controller.present(actionSheet, animated: true, completion: nil)
        } else {
            resultCallback?(nil, isOriginal, .deny)
        }
    }
    
    static func _showAlbumImagePicker(
        withMaxCount maxCount: Int,
        allowAlbumMode: Bool,
        allowCameraMode: Bool,
        isOriginalHidden: Bool,
        isOriginal: Bool,
        singleSelect: Bool = false,
        isSaveToAlbum: Bool = false,
        cameraDevice: String = "back",
        confirmBtnText: String?,
        in controller: UIViewController,
        resultCallback: (([UIImage]?, Bool, BDPImageAuthResult) -> Void)?
        ) {
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            if isSuccess {
                var sendButtonTitle = BDPI18n.done
                if let confirmBtnText = confirmBtnText, !confirmBtnText.isEmpty {
                    sendButtonTitle = confirmBtnText
                }
                let imagePicker = ImagePickerViewController(assetType: .imageOnly(maxCount: maxCount),
                                                            selectedAssets: [],
                                                            isOriginal: isOriginal,
                                                            isOriginButtonHidden: isOriginalHidden,
                                                            sendButtonTitle: sendButtonTitle,
                                                            takePhotoEnable: Self.takePhotoEnable,
                                                            editImageCache: nil)
                if singleSelect {
                    imagePicker.showSingleSelectAssetGridViewController()
                } else {
                    imagePicker.showMultiSelectAssetGridViewController()
                }
                imagePicker.imagePickerFinishSelect = { (picker, result) in
                    let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                    hud.showAfterDelay(0.5)
                    DispatchQueue.global(qos: .background).async {
                        var imageArray: [UIImage] = []

                        for asset in result.selectedAssets {
                            let options = PHImageRequestOptions()
                            options.isSynchronous = true
                            options.deliveryMode = .fastFormat
                            options.resizeMode = .fast
                            options.isNetworkAccessAllowed = true
                            let sema = DispatchSemaphore(value: 0)
                            PHImageManager.default().requestImageData(for: asset, options: options) { (data, _, _, _) in
                                if let data = data, let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                                    if asset.isGIF, let img = UIImage.bdp_animatedImage(withGIFData: data) {
                                        imageArray.append(img)
                                    } else {
                                        imageArray.append(image)
                                    }
                                }
                                /// iOS13 isSynchronous 为true，但requestImageData依然为异步，通过signal解决
                                if #available(iOS 13.0, *) {
                                    sema.signal()
                                }
                            }
                            if #available(iOS 13.0, *) {
                                sema.wait()
                            }
                        }
                        DispatchQueue.main.async {
                            hud.remove()
                            if (Self.callbackOptDisable) {
                                picker.dismiss(animated: true, completion: nil)
                                resultCallback?(imageArray, result.isOriginal, .pass)
                            } else {
                                picker.dismiss(animated: true) {
                                    resultCallback?(imageArray, result.isOriginal, .pass)
                                }
                            }
                        }
                    }
                }
                imagePicker.imagePikcerCancelSelect = { (picker, _) in
                    if (Self.callbackOptDisable) {
                        picker.dismiss(animated: true, completion: nil)
                        resultCallback?(nil, isOriginal, .pass)
                    } else {
                        picker.dismiss(animated: true) {
                            resultCallback?(nil, isOriginal, .pass)
                        }
                    }
                }

                if #available(iOS 13.0, *) {
                    imagePicker.modalPresentationStyle = .fullScreen
                }
                controller.present(imagePicker, animated: true)
            } else {
                resultCallback?(nil, isOriginal, .deny)
            }
        }

    }
    ///pickImage的V2版本，接入了主端camera，对album无影响，后续没问题，将会把V1删除
    public static func pickImageV2(
        withMaxCount maxCount: Int,
        allowAlbumMode: Bool,
        allowCameraMode: Bool,
        isOriginalHidden: Bool,
        isOriginal: Bool,
        singleSelect: Bool = false,
        isSaveToAlbum: Bool = false,
        cameraDevice: String = "back",
        confirmBtnText: String?,
        in controller: UIViewController?,
        resultCallback: (([UIImage]?, Bool, BDPImageAuthResult) -> Void)?
        ) {

        guard let controller = controller else {
            logger.error("pickImageV2 error: topController nil")
            resultCallback?(nil, isOriginal, .pass)
            return
        }
        
        func showAlbumImagePicker() {
            _showAlbumImagePicker(withMaxCount: maxCount, allowAlbumMode: allowAlbumMode, allowCameraMode: allowCameraMode, isOriginalHidden: isOriginalHidden, isOriginal: isOriginal, confirmBtnText: confirmBtnText, in: controller, resultCallback: resultCallback)
        }
            
        func showCameraImagePickerV2(){
            BDPAuthorization.checkSystemPermission(withTips: .camera) { (isSuccess) in
                guard isSuccess else {
                    resultCallback?(nil, isOriginal, .deny)
                    return
                }
                if isSaveToAlbum {//保存图片判断相册权限
                    BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                        guard isSuccess else {
                            resultCallback?(nil, isOriginal, .deny)
                            return
                        }
                        showCameraVC()
                    }
                }else {
                    showCameraVC()
                }
                ///camera 拍摄照片
                func showCameraVC(){
                    let cameraWrapper = AssetCameraWrapper()
                    cameraWrapper.camera.mediaType = .photo
                    cameraWrapper.camera.defaultCameraPosition = cameraDevice == "front" ? .front : .back

                    cameraWrapper.didTakePhoto = { [weak cameraWrapper] (image) in
                        let callback: () -> Void = {
                            if isSaveToAlbum {
                                Utils.savePhoto(image: image) { (success, granted) in
                                    logger.info("pickImageV2 savePhoto success：\(success),granted:\(granted)")
                                    if success && granted {
                                        resultCallback?([image], isOriginal, .pass)
                                    }else {
                                        resultCallback?(nil, isOriginal, granted ? .pass : .deny)
                                    }
                                }
                            } else {
                                resultCallback?([image], isOriginal, .pass)
                            }
                        }
                        if (Self.callbackOptDisable) {
                            callback()
                            cameraWrapper?.dismissCamera(animated: true)
                        } else {
                            cameraWrapper?.dismissCamera(animated: true, completion: callback)
                        }
                    }
                    cameraWrapper.didDismiss = {[weak cameraWrapper] in
                        if (Self.callbackOptDisable) {
                            resultCallback?(nil, isOriginal, .pass)
                            cameraWrapper?.dismissCamera(animated: true)
                        } else {
                            cameraWrapper?.dismissCamera(animated: true, completion: {
                                resultCallback?(nil, isOriginal, .pass)
                            })
                        }
                    }
                    if #available(iOS 13.0, *) {
                        cameraWrapper.camera.modalPresentationStyle = .fullScreen
                    }
                    cameraWrapper.present(vc: controller, animated: true)
                }
            }
        }
            
            
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let canUseCamera = allowCameraMode && isCameraAvailable
        if canUseCamera, !allowAlbumMode {
            // 只有相机可用
            showCameraImagePickerV2()
        } else if !canUseCamera, allowAlbumMode {
            // 只用相册可用
            showAlbumImagePicker()
        } else if canUseCamera, allowAlbumMode {
            // 相机 & 相册 都可用
            let sheetActions = [
                EMAActionSheetAction(title: BDPI18n.take_photo, style: .default) {
                    showCameraImagePickerV2()
                },
                EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                    showAlbumImagePicker()
                },
                EMAActionSheetAction(title: BDPI18n.cancel, style: .cancel) {
                    resultCallback?(nil, isOriginal, .pass)
                },
            ]
            
            let actionSheet = OPActionSheet.createActionSheet(with: sheetActions, isAutorotatable: UDRotation.isAutorotate(from: controller))
            controller.present(actionSheet, animated: true, completion: nil)
        } else {
            resultCallback?(nil, isOriginal, .deny)
        }
    }
    
    public static func pickImageNew(
        withMaxCount maxCount: Int,
        allowAlbumMode: Bool,
        allowCameraMode: Bool,
        isOriginalHidden: Bool,
        isOriginal: Bool,
        singleSelect: Bool = false,
        isSaveToAlbum: Bool = false,
        cameraDevice: String = "back",
        confirmBtnText: String?,
        in controller: UIViewController?,
        resultCallback: (([UIImage]?, Bool, BDPImageAuthResult, CameraError?) -> Void)?
        ) {

        guard let controller = controller else {
            logger.error("pickImageV2 error: topController nil")
            resultCallback?(nil, isOriginal, .pass, nil)
            return
        }
        
        func showAlbumImagePicker() {
            _showAlbumImagePicker(withMaxCount: maxCount, allowAlbumMode: allowAlbumMode, allowCameraMode: allowCameraMode, isOriginalHidden: isOriginalHidden, isOriginal: isOriginal, confirmBtnText: confirmBtnText, in: controller) { images, isOriginal, authResult in
                resultCallback?(images, isOriginal, authResult, nil)
            }
        }
            
        func showCameraImagePicker(){
            if isSaveToAlbum {//保存图片判断相册权限
                BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
                    guard isSuccess else {
                        resultCallback?(nil, isOriginal, .deny, nil)
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
                config.mediaType = .photoOnly
                config.autoSave = isSaveToAlbum
                config.afterTakePhotoAction = .enterImageEditor
                config.didTakePhoto = {(image, vc, saveToAlbumSuccess, granted) in
                    logger.info("cameraKit didTakePhoto image:\(image), vc:\(vc), success:\(saveToAlbumSuccess), granted:\(granted)")
                    if isSaveToAlbum, !saveToAlbumSuccess {
                        vc.dismiss(animated: true) {
                            resultCallback?(nil, isOriginal, .pass, .saveToAlbumFail)
                        }
                        return
                    }
                    vc.dismiss(animated: true) {
                        resultCallback?([image], isOriginal, .pass, nil)
                    }
                }
                config.didCancel = {(error) in
                    logger.error("LarkCameraKit didCancel:\(String(describing: error))")
                    resultCallback?(nil, isOriginal, .pass, .userCancel)
                }
                EMAImagePicker.showCameraVC(config: config, from: controller) { result in
                    switch result {
                    case .failure(let error):
                        resultCallback?(nil, isOriginal, .pass, .createCamera(error))
                    case .success():
                        logger.info("EMAImagePicker showCameraVC success")
                    }
                }

            }
        }
            
            
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let canUseCamera = allowCameraMode && isCameraAvailable
        if canUseCamera, !allowAlbumMode {
            // 只有相机可用
            showCameraImagePicker()
        } else if !canUseCamera, allowAlbumMode {
            // 只用相册可用
            showAlbumImagePicker()
        } else if canUseCamera, allowAlbumMode {
            // 相机 & 相册 都可用
            let sheetActions = [
                EMAActionSheetAction(title: BDPI18n.take_photo, style: .default) {
                    showCameraImagePicker()
                },
                EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                    showAlbumImagePicker()
                },
                EMAActionSheetAction(title: BDPI18n.cancel, style: .cancel) {
                    resultCallback?(nil, isOriginal, .pass, nil)
                },
            ]
            
            let actionSheet = OPActionSheet.createActionSheet(with: sheetActions, isAutorotatable: UDRotation.isAutorotate(from: controller))
            controller.present(actionSheet, animated: true, completion: nil)
        } else {
            resultCallback?(nil, isOriginal, .deny, nil)
        }
    }
    
    public static func showCameraVC(config: LarkCameraKit.CameraConfig,
                                    from: UIViewController,
                                    completion: @escaping ((Result<Void, LarkCameraKit.Error.Creating>) -> Void)){
        let userResolver = Container.shared.getCurrentUserResolver()
        LarkCameraKit.createCamera(with: config, from: from, userResolver: userResolver) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let cameraVC):
                if #available(iOS 13.0, *) {
                    cameraVC.modalPresentationStyle = .fullScreen
                }
                from.present(cameraVC, animated: true)
                completion(.success(()))
            }
        }
    }
    
// MARK: - Video
    /// 根据参数选择视频（拍摄或相册选择）
    public static func pickVideo(param: BDPChooseVideoParam, controller: UIViewController, callback: @escaping (BDPChooseVideoResult) -> Void) {
        let allowAlbumMode = param.sourceType.contains(.album);
        let allowCameraMode = param.sourceType.contains(.camera);
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let canUseCamera = isCameraAvailable && allowCameraMode
        if canUseCamera, !allowAlbumMode {
            // 只用相机
            showCameraVideoPicker(param: param, controller: controller, callback: callback)
        } else if !canUseCamera, allowAlbumMode {
            // 只用相册
            showAlbumVideoPicker(param: param, controller: controller, callback: callback)
        } else if canUseCamera, allowAlbumMode {
            // 相机 & 相册
            let sheetActions = [
                EMAActionSheetAction(title: BDPI18n.use_camera, style: .default) {
                    showCameraVideoPicker(param: param, controller: controller, callback: callback)
                },
                EMAActionSheetAction(title: BDPI18n.choose_from_album, style: .default) {
                    showAlbumVideoPicker(param: param, controller: controller, callback: callback)
                },
                EMAActionSheetAction(title: BDPI18n.cancel, style: .cancel) {
                    callback(BDPChooseVideoResult(code: .cancel))
                },
            ]
            
            let actionSheet = OPActionSheet.createActionSheet(with: sheetActions, isAutorotatable: UDRotation.isAutorotate(from: param.fromController))
            param.fromController.present(actionSheet, animated: true, completion: nil)
        } else {
            callback(BDPChooseVideoResult(code: .systemError))
        }
    }

    /// 相册方式选择视频
    private static func showAlbumVideoPicker(param: BDPChooseVideoParam, controller: UIViewController, callback: @escaping (BDPChooseVideoResult) -> Void) {
        BDPAuthorization.checkSystemPermission(withTips: .album) { (isSuccess) in
            guard isSuccess else {
                callback(BDPChooseVideoResult(code: .permissionDeny))
                return
            }

            let imagePicker = ImagePickerViewController(assetType: .videoOnly(maxCount: 1),
                                                        selectedAssets: [],
                                                        isOriginal: false,
                                                        isOriginButtonHidden: true,
                                                        sendButtonTitle: BDPI18n.done,
                                                        takePhotoEnable: Self.takePhotoEnable,
                                                        editImageCache: nil)
            imagePicker.showMultiSelectAssetGridViewController()
            imagePicker.imagePickerFinishSelect = { (picker, result) in
                guard let asset = result.selectedAssets.first else {
                    logger.error("internal error: asset is nil!")
                    picker.dismiss(animated: true, completion: nil)
                    callback(BDPChooseVideoResult(code: .systemError))
                    return
                }
                let hud = EMAHUD.showLoading(nil, on: picker.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                DispatchQueue.global(qos: .background).async {

                    let options = PHVideoRequestOptions()
                    options.deliveryMode = .fastFormat

                    PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (avAsset, _, _) in
                        guard let videoAsset = avAsset as? AVURLAsset else {
                            DispatchQueue.main.async {
                                logger.error("internal error: asset is not AVURLAsset!")
                                hud.remove()
                                picker.dismiss(animated: true, completion: nil)
                                callback(BDPChooseVideoResult(code: .systemError))
                            }
                            return;
                        }
                        exportVideo(videoAsset, maxDuration: param.maxDuration, compressed: param.compressed, outputFilePathWithoutExtention: param.outputFilePathWithoutExtention) { (result) in
                            DispatchQueue.main.async {
                                hud.remove()
                                picker.dismiss(animated: true, completion: nil)
                                callback(result)
                            }
                        }
                    })
                }
            }
            imagePicker.imagePikcerCancelSelect = { (picker, _) in
                picker.dismiss(animated: true, completion: nil)
                callback(BDPChooseVideoResult(code: .cancel))
            }
            if #available(iOS 13.0, *) {
                imagePicker.modalPresentationStyle = .fullScreen
            }
            param.fromController.present(imagePicker, animated: true)
        }
    }

    /// 拍摄方式选择视频
    private static func showCameraVideoPicker(param: BDPChooseVideoParam, controller: UIViewController, callback: @escaping (BDPChooseVideoResult) -> Void) {
        BDPAuthorization.checkSystemPermission(withTips: .camera) { (isSuccess) in
            guard isSuccess else {
                callback(BDPChooseVideoResult(code: .permissionDeny))
                return
            }
            let camera = UIImagePickerCallbackController()
            camera.sourceType = .camera
            camera.mediaTypes = [kUTTypeMovie as String]
            camera.cameraCaptureMode = .video
            camera.videoMaximumDuration = param.maxDuration
            camera.videoQuality = .typeMedium
            camera.delegateVideoCallback(callback: { (avAsset, picker) in
                guard let avAsset = avAsset else {
                    picker.dismiss(animated: true, completion: nil)
                    callback(BDPChooseVideoResult(code: .cancel))
                    return
                }
                let hud = EMAHUD.showLoading(nil, on: camera.view, window: controller.view.window, delay: 0, disableUserInteraction: true)
                exportVideo(avAsset, maxDuration: param.maxDuration, compressed: param.compressed, outputFilePathWithoutExtention: param.outputFilePathWithoutExtention) { (result) in
                    DispatchQueue.main.async {
                        hud.remove()
                        picker.dismiss(animated: true, completion: nil)
                        callback(result)
                    }
                }
            })
            camera.sourceType = .camera
            if #available(iOS 13.0, *) {
                camera.modalPresentationStyle = .fullScreen
            }
            param.fromController.present(camera, animated: true)
        }
    }
    
    /// 从 AVURLAsset 导出 .mp4 或 .mov 文件
    public static func exportVideo(_ asset: AVURLAsset, maxDuration: TimeInterval, compressed: Bool, outputFilePathWithoutExtention: String, callback: @escaping (BDPChooseVideoResult) -> Void) {
        exportVideo(with: asset, pathExtension: asset.url.pathExtension, maxDuration: maxDuration, compressed: compressed, outputFilePathWithoutExtention: outputFilePathWithoutExtention, callback: callback)
    }
    
    /// 从 AVAsset 导出 .mp4 或 .mov 文件
    public static func exportVideo(with asset: AVAsset, pathExtension: String, maxDuration: TimeInterval, compressed: Bool, outputFilePathWithoutExtention: String, callback: @escaping (BDPChooseVideoResult) -> Void) {
        if (CMTimeGetSeconds(asset.duration) > maxDuration) {
            logger.error("time limit exceed, dur: \(asset.duration), limit: \(maxDuration)")
            callback(BDPChooseVideoResult(code: .timeLimitExceed))
            return
        }

        let preset = compressed ? AVAssetExportPresetMediumQuality : AVAssetExportPresetPassthrough
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            logger.error("internal error: AVAssetExportSession init failed, asset: \(asset), preset: \(preset)")
            callback(BDPChooseVideoResult(code: .systemError))
            return
        }

        var filePath = outputFilePathWithoutExtention

        let ext = pathExtension
        if !filePath.hasSuffix(ext) {
            if filePath.hasSuffix(".") {
                filePath += ext
            } else {
                filePath += ".\(ext)"
            }
        }
        guard let fileURL = URL(string: filePath) else {
            logger.error("invalid param: file url init failed, path: \(filePath)")
            callback(BDPChooseVideoResult(code: .invalidParam))
            return
        }
        // 原有逻辑是后缀和 asset 保持一致，封装类型固定为 mp4
        // 这里修改为优先使用 iPhone 上兼容性更好的 mov 封装格式，同时尽量避免转封装
        if ext == "mp4" || ext == "MP4" {
            session.outputFileType = .mp4
        } else {
            session.outputFileType = .mov
        }
        session.outputURL = fileURL
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously {
            if session.status != .completed {
                logger.error("export video error: \(session.error), session status: \(session.status)")
                callback(BDPChooseVideoResult(code: .systemError))
                return
            }
            let result = BDPChooseVideoResult(code: .success)
            result.duration = CMTimeGetSeconds(asset.duration)
            result.filePath = fileURL.path
            do {
                result.size = CGFloat(try LSFileSystem.attributesOfItem(atPath: fileURL.path)[.size] as? Double ?? 0)
            } catch {
                logger.error("get file size err: \(error)")
            }

            if let track = asset.tracks(withMediaType: .video).first {
                // 修复拍摄视频，返回视频宽高值可能不正确的问题
                let size = __CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform)
                result.width = abs(size.width)
                result.height = abs(size.height)
            }
            callback(result)
        }
    }
}

/// 该组件解耦EEMicroAppSDK时，同时也会解耦对`Module LarkSuspendable`中`extension UINavigationController: UINavigationControllerDelegate`的依赖, 这时候需要新增加`UINavigationControllerDelegate`
private class UIImagePickerCallbackController: UIImagePickerController, UIImagePickerControllerDelegate {

    public typealias ChooseImageCallback = ((UIImage?, UIImagePickerController) -> Void)
    fileprivate var chooseImageCallback: ChooseImageCallback?

    public typealias ChooseVideoCallback = ((AVURLAsset?, UIImagePickerController) -> Void)
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
        self.chooseImageCallback?(nil, picker)
        self.chooseVideoCallback?(nil, picker)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // 统一在 callback 里面进行 dismiss
        if let chooseImageCallback = self.chooseImageCallback {
            var targetImage: UIImage?
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                targetImage = image
            } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                targetImage = image
            }
            if (!EMAFeatureGating.boolValue(forKey: "lark.open_platform.api.choose_image.get_original_photo")) {
                // 开启后，chooseImage API 不再进行默认压缩
                targetImage = targetImage?.ema_redraw()
            }
            chooseImageCallback(targetImage, picker)
        } else if let chooseVideoCallback = self.chooseVideoCallback {
            if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                let asset = AVURLAsset(url: url)
                chooseVideoCallback(asset, picker)
            } else {
                chooseVideoCallback(nil, picker)
            }

        }
    }
}

private class LarkCameraControllerDelegateImpl: LarkCameraControllerDelegate {
    static let logger = Logger.oplog(LarkCameraControllerDelegateImpl.self, category: "Module.EEMicroAppSDK.LarkCameraControllerDelegateImpl")
    fileprivate var chooseImageCallback: ((UIImage?) -> Void)?

    public func camera(_ camera: LarkCameraController, log message: String, error: Error?) {
        LarkCameraControllerDelegateImpl.logger.info(message, additionalData: nil, error: error)
    }

    public func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.chooseImageCallback?(photo)
            camera.dismiss(animated: true, completion: nil)
        }
    }
}

extension LarkCameraController {
    private static var cameraDelegateKey: UInt8 = 0

    fileprivate var cameraDelegate: LarkCameraControllerDelegateImpl? {
        set {
            objc_setAssociatedObject(self, &LarkCameraController.cameraDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &LarkCameraController.cameraDelegateKey) as? LarkCameraControllerDelegateImpl
        }
    }
}
