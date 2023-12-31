//
//  CommonPickMediaManager.swift
//  SKCommon
//
//  Created by tanyunpeng on 2022/9/13.
//

import LarkUIKit
import Photos
import SKResource
import LarkAssetsBrowser
import EENavigator
import UIKit
import ByteWebImage
import SKUIKit
import SKFoundation
import LarkFoundation
import SpaceInterface
import SKInfra
import LarkSensitivityControl

public protocol PickMediaDelegate: AnyObject {
    func didFinishPickingMedia(results: [MediaResult])
}

public final class CommonPickMediaManager {

    weak var delegate: PickMediaDelegate?
    
    let mediaWriter: MediaWriter = MediaWriterImpl()
    
    private static let assetsQueue = DispatchQueue(label: "commom.compressAsset")
    
    public typealias ImagePickerCallback = ((UIViewController, [MediaResult]?) -> Void)
    
    public var imagePickerCallback: ImagePickerCallback?
    
    public var skSuiteView: SKAssuiteView?
    
    public var skImagePickerVC: SKImagePickerViewController?
    
    var mediaCompressService: MediaCompressService?
    
    private var progressView: ProgressAlertView?
    
    private var commonConfig: CommonPickMediaConfig
    
    private var imageViewConfig: ImageViewConfig?

    private var suiteViewConfig: SuiteViewConfig?
    
    private var startTime = 0.0
    
    public init(_ config: CommonPickMediaConfig,
                _ imageViewConfig: ImageViewConfig,
                imagePickerCallback: ImagePickerCallback? = nil) { //imagePickerViewController使用
        self.commonConfig = config
        self.imageViewConfig = imageViewConfig
        self.imagePickerCallback = imagePickerCallback
        initImageViewController(imageViewConfig)
        initCompressService(config.path)
    }
    
    public init(delegate: PickMediaDelegate? = nil, //assuitView使用
                _ config: CommonPickMediaConfig,
                suiteViewConfig: SuiteViewConfig) { //imagePickerViewController使用
        self.commonConfig = config
        self.delegate = delegate
        self.suiteViewConfig = suiteViewConfig
        initSKAssuiteView(assetType: suiteViewConfig.assetType, cameraType: suiteViewConfig.cameraType)
        initCompressService(config.path)
    }
    public func initSKAssuiteView(assetType: PhotoPickerAssetType, cameraType: CameraType) {
        let suiteView = AssetPickerSuiteView(assetType: assetType, originVideo: true, cameraType: cameraType, sendButtonTitle: commonConfig.sendButtonTitle, presentVC: commonConfig.rootVC)
        suiteView.delegate = self
        skSuiteView = suiteView
    }
    // swiftlint:disable cyclomatic_complexity
    func initImageViewController(_ imageViewConfig: ImageViewConfig) {
        skImagePickerVC = ImagePickerViewController(assetType: imageViewConfig.assetType,
                                                    isOriginal: imageViewConfig.isOriginal,
                                                    isOriginButtonHidden: commonConfig.isOriginButtonHidden,
                                                    sendButtonTitle: commonConfig.sendButtonTitle,
                                                    takePhotoEnable: imageViewConfig.takePhotoEnable)
        // 上传媒体文件的回调
        skImagePickerVC?.imagePickerFinishSelect = { [weak self] viewController, result in
            guard let self = self else { return }
            guard let imagePickerCallback = self.imagePickerCallback else { return }
            // transform to media results
            // call config.imagePickerCallback(viewController, results)
            let assets = result.selectedAssets
            let orignal = result.isOriginal
            let files = assets.map { asset in
                return MediaFile(asset: asset, isVideo: asset.mediaType == .video)
            }
            viewController.dismiss(animated: false, completion: nil)
            if orignal {
                let results = self.handleOriginalPHAsset(files: files, writeToPathToken: PSDATokens.Space.space_upload_original_asset_click_confirm, isGifToken: PSDATokens.Space.space_upload_gif_click_upload)
                imagePickerCallback(viewController, results)
            } else {
                if self.isAllGIF(files: files, isGifToken: PSDATokens.Space.space_upload_gif_click_upload) {
                    let results = self.handleOriginalPHAsset(files: files, writeToPathToken: PSDATokens.Space.space_upload_original_asset_click_confirm, isGifToken: PSDATokens.Space.space_upload_gif_click_upload)
                    imagePickerCallback(viewController, results)
                } else {
                    self.mediaCompressService?.compress(files: files, urlToken: PSDATokens.Space.space_upload_compress_video, writeToPathToken: PSDATokens.Space.space_upload_original_asset_click_confirm, isGifToken: PSDATokens.Space.space_upload_gif_click_upload, complete: { [weak self] status in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            switch status {
                            case .progress(let progress):
                                self.progressView?.updateProgress(Float(progress))
                            case .failed:
                                self.progressView?.dismiss()
                            case .success(let result):
                                self.progressView?.updateProgress(1.0)
                                var delayTime = 1.0 - (CFAbsoluteTimeGetCurrent() - self.startTime)
                                if  CFAbsoluteTimeGetCurrent() - self.startTime > 1.0 {
                                    delayTime = 0.0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                                    self.progressView?.dismiss()
                                }
                                imagePickerCallback(viewController, result)
                            case .start:
                                self.startTime = CFAbsoluteTimeGetCurrent()
                                self.showProgress(files: files)
                            }
                        }
                    })
                }
            }
        }
        
        skImagePickerVC?.imagePikcerCancelSelect = { [weak self] viewController, result in
            // call config.imagePickerCallback(viewController, nil)
            guard let self = self else { return }
            guard let imagePickerCallback = self.imagePickerCallback else { return }
            imagePickerCallback(viewController, nil)
        }

        // 拍照的回调
        skImagePickerVC?.imagePickerFinishTakePhoto = { [weak self] viewController, image in
            // transform to media results
            // call config.imagePickerCallback(viewController, results)
            guard let self = self else { return }
            if UserScopeNoChangeFG.LJW.cameraStoragePermission {
                do {
                    try Utils.savePhoto(token: Token(PSDATokens.Space.space_takephoto_click_upload), image: image) { _, _ in }
                } catch {
                    DocsLogger.error("Utils savePhoto error")
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let imagePickerCallback = self.imagePickerCallback else { return }
                let imageResult = self.handleUIImage(image: image)
                imagePickerCallback(viewController, imageResult)
            }
        }
    }
    
    private func showProgress(files: [MediaFile]) {
        self.progressView = ProgressAlertView()
        self.progressView?.cancelAction = {[weak self] in
            self?.mediaCompressService?.cancelCompress(files: files)
        }
        self.progressView?.titleText = BundleI18n.SKResource.LarkCCM_Drive_Compressing_Title
        guard let rootVC = commonConfig.rootVC else {
            DocsLogger.info("no root vc")
            return
        }
        self.progressView?.show(on: rootVC)
    }
    
    private func initCompressService(_ path: SKFilePath) {
        guard let dependency = DocsContainer.shared.resolve(MediaCompressDependency.self) else { return }
        path.createDirectoryIfNeeded()
        mediaCompressService = MediaCompressService(dependency: dependency, cacheDir: path)
    }
    
    private func exportURL(file: MediaFile, cacheDir: SKFilePath, isGifToken: String) -> SKFilePath {
        var savedName: String = ""
        if file.isVideo {
            (savedName, _) = MediaCompressHelper.getVideoName(from: file.asset, compress: false)

        } else {
            (savedName, _) = MediaCompressHelper.getImageNames(from: file.asset, compress: false, isGifToken: isGifToken)
        }
        let exportPath = cacheDir.appendingRelativePath(savedName)
        return exportPath
    }
    
    private func getOriginalImageResult(from file: MediaFile, isCompress: Bool, exportPath: SKFilePath, isGifToken: String) -> MediaResult {
        let fileName = MediaCompressHelper.getImageNames(from: file.asset, compress: isCompress, isGifToken: isGifToken).originName
        let fileSize = exportPath.fileSize ?? 0
        let imageSize = SKImagePreviewUtils.originSizeOfImage(path: exportPath) ?? CGSize.zero
        DocsLogger.info("image fileSize: \(fileSize), imageSize: \(imageSize), taskID: \(file.taskID)")
        return MediaResult.image(result: ImageResult(exportURL: exportPath.pathURL,
                                                     name: fileName,
                                                     fileSize: fileSize,
                                                     imageSize: imageSize,
                                                     taskID: file.taskID))
        
    }
    
    private func getOriginalVideoResult(from file: MediaFile, isCompress: Bool, exportPath: SKFilePath) -> MediaResult {
        let fileName = MediaCompressHelper.getVideoName(from: file.asset, compress: isCompress).originName
        let fileSize = exportPath.fileSize ?? 0
        let duration = file.asset.duration
        let videoSize = MediaCompressHelper.resolutionSizeForLocalVideo(url: exportPath.pathURL)
        return MediaResult.video(result: VideoResult(exportURL: exportPath.pathURL,
                                                     name: fileName,
                                                     fileSize: fileSize,
                                                     videoSize: videoSize,
                                                     duraion: duration,
                                                     taskID: file.taskID))
    }
    // save origin file
    private func saveOriginFile(_ file: MediaFile,
                                exportPath: SKFilePath,
                                writeToPathToken: String,
                                isGifToken: String,
                                complete: (DriveCompressStatus) -> Void) {
        DocsLogger.info("taskID: \(file.taskID) start saving origin file")
        let saveResult = mediaWriter.saveOrigin(asset: file.asset, to: exportPath, writeToPathToken: writeToPathToken)
        switch saveResult {
        case .success(_):
            if file.isVideo {
                let videoResult = getOriginalVideoResult(from: file, isCompress: false, exportPath: exportPath)
                DocsLogger.info("taskID: \(file.taskID) did saved origin video")
                complete(.success(result: [videoResult]))
            } else {
                let imageResult = getOriginalImageResult(from: file, isCompress: false, exportPath: exportPath, isGifToken: isGifToken)

                DocsLogger.info("taskID: \(file.taskID) did saved origin image")
                complete(.success(result: [imageResult]))
            }
        case let .failure(error):
            DocsLogger.error("save origin file failed taskID: \(file.taskID)", error: error)
            complete(.failed)
        }
    }
    
    private func handleOriginalPHAsset(files: [MediaFile], writeToPathToken: String, isGifToken: String) -> [MediaResult] {
        var results = [MediaResult]()
        for file in files {
            let exportPath: SKFilePath = self.exportURL(file: file, cacheDir: commonConfig.path, isGifToken: isGifToken)
            self.saveOriginFile(file, exportPath: exportPath, writeToPathToken: writeToPathToken, isGifToken: isGifToken) { [weak self] status in
                guard let self = self else { return }
                switch status {
                case let .success(mediaResult):
                    if file.isVideo {
                        let result = getOriginalVideoResult(from: file, isCompress: false, exportPath: exportPath)
                        results.append(result)
                    } else {
                        let result = getOriginalImageResult(from: file, isCompress: false, exportPath: exportPath, isGifToken: isGifToken)
                        results.append(result)
                    }
                case let .failed:
                    DocsLogger.error("save to sandbox failed")
                default:
                    DocsLogger.error("save to sandbox in progress")
                }
            }
        }
        return results
    }
    
    private func handleCompressPHAsset(files: [MediaFile]) {
        self.mediaCompressService?.compress(files: files, urlToken: PSDATokens.Bitable.bitable_upload_compress_video, writeToPathToken: PSDATokens.Bitable.bitable_upload_original_asset_click_confirm, isGifToken: PSDATokens.Bitable.bitable_compress_gif_click_upload, complete: { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch status {
                case .progress(let progress):
                    self.progressView?.updateProgress(Float(progress))
                case .failed:
                    self.progressView?.dismiss()
                case .success(let result):
                    self.progressView?.updateProgress(1.0)
                    var delayTime = 1.0 - (CFAbsoluteTimeGetCurrent() - self.startTime)
                    if  CFAbsoluteTimeGetCurrent() - self.startTime > 1.0 {
                        delayTime = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                        self.progressView?.dismiss()
                    }
                    self.delegate?.didFinishPickingMedia(results: result)
                case .start:
                    self.startTime = CFAbsoluteTimeGetCurrent()
                    self.showProgress(files: files)
                }
            }
        })
    }
    
    private func handleUIImage(image: UIImage) -> [MediaResult] {
        var imageResult: [MediaResult] = []
        guard let data = image.jpegData(compressionQuality: 0.9) else { return [] } // compressionQuality 如果用 1 会造成图片变得非常大
        let fileSize = data.count
        let fileName = UniqueNameUtil.makeUniqueNewImageName()
        let savedURL = self.commonConfig.path.appendingRelativePath(fileName)
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        let imageSize = CGSize(width: width, height: height)
        let taskID = UUID().uuidString
        do {
            try data.write(to: savedURL)
            DocsLogger.info("[DATA] saving taked photo to sandbox succeeded")
            imageResult.append(MediaResult.image(result: ImageResult(exportURL: savedURL.pathURL,
                                                                     name: fileName,
                                                                     fileSize: UInt64(fileSize),
                                                                     imageSize: imageSize,
                                                                     taskID: taskID)))
        } catch {
            DocsLogger.error("[DATA] failed saving taked photo to sandbox")
        }
        return imageResult
    }
    
    private func handleURLVideo(url: URL) -> [MediaResult] {
        var imageResult: [MediaResult] = []
        let videoName = UniqueNameUtil.makeUniqueVideoName()
        let videoSize = MediaCompressHelper.resolutionSizeForLocalVideo(url: url)
        do {
            let path = SKFilePath(absPath: url.path)
            let taskID = UUID().uuidString
            let byteSize = path.fileSize ?? 0
            let asset = AVURLAsset(url: url)
            let durationInSeconds = asset.duration.seconds
            imageResult.append(MediaResult.video(result: VideoResult(exportURL: url,
                                                                     name: videoName,
                                                                     fileSize: byteSize,
                                                                     videoSize: videoSize,
                                                                     duraion: durationInSeconds,
                                                                     taskID: taskID)))
        } catch {
            DocsLogger.error("[DATA] failed saving taked video to sandbox")
        }
        return imageResult
    }

    
    private func isAllGIF(files: [MediaFile], isGifToken: String) -> Bool {
        for file in files {
            if !MediaCompressHelper.isGIFType(asset: file.asset, isGifToken: isGifToken) {
                return false
            }
        }
        return true
    }

}
    
public struct CommonPickMediaConfig {
    public var path: SKFilePath//存储路径
    public weak var rootVC: UIViewController?//当前VC
    public var sendButtonTitle: String?//发送按钮的文案
    public var isOriginButtonHidden: Bool//是否隐藏原图按钮
    public init(rootVC: UIViewController? = nil,
                path: SKFilePath,
                sendButtonTitle: String? = nil,
                isOriginButtonHidden: Bool = false) {
        self.rootVC = rootVC
        self.path = path
        self.sendButtonTitle = sendButtonTitle
        self.isOriginButtonHidden = isOriginButtonHidden
    }
}

public struct SuiteViewConfig {
    public var assetType: PhotoPickerAssetType
    public var cameraType: CameraType
    public init(assetType: PhotoPickerAssetType,
                cameraType: CameraType) {
        self.assetType = assetType
        self.cameraType = cameraType
    }
}

public struct ImageViewConfig {
    public var assetType: ImagePickerAssetType
    public var isOriginal: Bool
    public var takePhotoEnable: Bool
    public init(assetType: ImagePickerAssetType = .imageOrVideo(imageMaxCount: 9, videoMaxCount: 1),
                isOriginal: Bool = true,
                takePhotoEnable: Bool = true) {
        self.assetType = assetType
        self.takePhotoEnable = takePhotoEnable
        self.isOriginal = isOriginal
    }
}

extension CommonPickMediaManager: AssetPickerSuiteViewDelegate {
    //AssetPickerSuiteView获取相册图片或视频的信息回调
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        let assets = result.selectedAssets
        let orignal = result.isOriginal
        let files = assets.map { asset in
            return MediaFile(asset: asset, isVideo: asset.mediaType == .video)
        }
        if orignal {
            let results = self.handleOriginalPHAsset(files: files, writeToPathToken: PSDATokens.Bitable.bitable_upload_original_asset_click_confirm, isGifToken: PSDATokens.Bitable.bitable_compress_gif_click_upload)
            self.delegate?.didFinishPickingMedia(results: results)
        } else {
            if self.isAllGIF(files: files, isGifToken: PSDATokens.Bitable.bitable_compress_gif_click_upload) {
                let results = self.handleOriginalPHAsset(files: files, writeToPathToken: PSDATokens.Bitable.bitable_upload_original_asset_click_confirm, isGifToken: PSDATokens.Bitable.bitable_compress_gif_click_upload)
                self.delegate?.didFinishPickingMedia(results: results)
            } else {
                self.handleCompressPHAsset(files: files)
            }
        }
    }
    //AssetPickerSuiteView获取拍照的信息回调
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        let result = self.handleUIImage(image: photo)
        DispatchQueue.main.async {
            self.delegate?.didFinishPickingMedia(results: result)
        }
    }
    //AssetPickerSuiteView获取拍视频的信息回调
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        let result = self.handleURLVideo(url: url)
        DispatchQueue.main.async {
            self.delegate?.didFinishPickingMedia(results: result)
        }
    }
}
