//
//  FolderBlockService+More.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/7/27.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import SKInfra
import SpaceInterface


// MARK: Drive Upload相关
extension FolderBlockService {
    
    func uploadCallback(callback: String, subId: String) {
        let params: [String: Any] = ["objType": DocsType.file.rawValue, "subId": subId]
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
    }
    
    func showMediaPicker(params: [String: Any]) {
        guard let callbackId = params["callback"] as? String else {
            DocsLogger.error("folder block service: show media panel brige params invalid")
            return
        }
        
        var pickImageOrVideoMaxCount: Int = 99  //  允许选择上传的最大数量
        if let maxCount = params["maxCount"] as? Int {
            pickImageOrVideoMaxCount = maxCount
        }
        let path = SKFilePath.driveLibraryDir.appendingRelativePath(compressLibraryDir)
        path.createDirectoryIfNeeded()
        let config = CommonPickMediaConfig(rootVC: navigator?.currentBrowserVC,
                                           path: path,
                                           sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                           isOriginButtonHidden: false)
        let imageViewConfig = ImageViewConfig(assetType: .imageAndVideo(imageMaxCount: pickImageOrVideoMaxCount,
                                                                        videoMaxCount: pickImageOrVideoMaxCount),
                                              isOriginal: true,
                                              takePhotoEnable: true)
        imagePickerManager = CommonPickMediaManager(config, imageViewConfig, imagePickerCallback: { [weak self] vc, results in
            guard let results else {
                vc.dismiss(animated: true)
                return
            }
            self?.handleAfterPickMidiaResult(results: results, callback: callbackId)
        })
        guard let picker = imagePickerManager?.skImagePickerVC else {
            return
        }
        picker.modalPresentationStyle = .fullScreen
        picker.showMultiSelectAssetGridViewController()
        navigator?.currentBrowserVC?.present(picker, animated: true)
    }
    
    private func handleAfterPickMidiaResult(results: [MediaResult], callback: String) {
        var thumbs: [[String: Any]] = []
        
        uploadQueue.async { [weak self] in
            for result in results {
                let uuid = SKPickImageUtil.makeUniqueId()
                let src = SKPickImageUtil.makeImageCacheUrl(with: uuid)
                let cacheKey = SKPickImageUtil.makeImageCacheKey(with: uuid)
                switch result {
                case let .image(result):
                    let skPath = SKFilePath(absUrl: result.exportURL)
                    guard let data = try? Data.read(from: skPath) else {
                        DocsLogger.error("get image data failed from url")
                        break
                    }
                    self?.newCacheAPI.storeImage(data as NSCoding, token: self?.docsInfo?.wikiInfo?.wikiToken, forKey: cacheKey, needSync: true)
                    let thumb: [String: Any] = ["uuid": uuid,
                                                "src": src,
                                                "fileSize": result.fileSize,
                                                "fileName": result.name,
                                                "width": result.imageSize.width,
                                                "height": result.imageSize.height,
                                                "contentType": "image"]
                    thumbs.append(thumb)
                case let .video(result):
                    let lastCompoment: String = result.exportURL.lastPathComponent
                    let assetInfo = SKAssetInfo(objToken: self?.docsInfo?.wikiInfo?.wikiToken,
                                                uuid: uuid,
                                                cacheKey: lastCompoment,
                                                fileSize: Int(result.fileSize),
                                                assetType: SKPickContentType.video.rawValue)
                    self?.newCacheAPI.updateAsset(assetInfo)
                    // 从drive的上传picker选择上传视频，本地文件在drive缓存路径下
                    // Docx文档上传路径下无本地文件，需要手动copy一份过去Docx文档的上传路径
                    do {
                        let skPath = SKPickContentType.getUploadCacheUrl(lastComponent: uuid)
                        try skPath.copyItemFromUrl(from: result.exportURL)
                    } catch {
                        DocsLogger.error("folder.block.service: copy drive cache to doc upload directory path error")
                    }
                    let thumb: [String: Any] = ["uuid": uuid,
                                                "src": src,
                                                "fileSize": result.fileSize,
                                                "fileName": result.name,
                                                "width": result.videoSize.width,
                                                "height": result.videoSize.height,
                                                "contentType": "video",
                                                "duration": result.duraion]
                    thumbs.append(thumb)
                }
            }
            DispatchQueue.main.async { [weak self] in
                let params: [String: Any] = ["code": 0, "thumbs": thumbs]
                self?.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
            }
        }
    }

}
