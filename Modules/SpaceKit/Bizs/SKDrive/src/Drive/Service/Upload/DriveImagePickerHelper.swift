//
//  DriveImagePickerManager.swift
//  SpaceKit
//
//  Created by liweiye on 2019/3/29.
//

import Foundation
import LarkUIKit
import Photos
import SKCommon
import SKFoundation
import SKResource
import LarkAssetsBrowser
import RxSwift
import UIKit
import LarkFoundation
import SpaceInterface
import LarkSensitivityControl
import SKInfra

class DriveImagePickerHelper {
    private static var bag = DisposeBag()
    static var imagePickerFinishCallBack: ((Bool) -> Void)?
    static var commonMediaManager: CommonPickMediaManager?
    static var picker: SKImagePickerViewController?
    private static let uploadQueue = DispatchQueue(label: "drive.upload")
    private static let compressLibraryDir = "drive/drive_upload_caches/media"

    deinit {
        DocsLogger.driveInfo("DriveImagePickerManager ----- deinit")
    }

    private static let imagePickerMaxImageCount = 99
    private static let imagePickerMaxVideoCount = 99

    static func getImagePicker(mountToken: String, mountPoint: String, scene: DriveUploadScene, rootVC: UIViewController) -> UIViewController {
        if LKFeatureGating.ccmDriveMobileVideoCompress {
            var uploadEntitys: [(path: String, fileName: String)] = []
            let path = SKFilePath.driveLibraryDir.appendingRelativePath(compressLibraryDir)
            path.createDirectoryIfNeeded()
            let config = CommonPickMediaConfig(rootVC: rootVC,
                                               path: path,
                                               sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                               isOriginButtonHidden: false)
            let imageViewConfig = ImageViewConfig(assetType: .imageAndVideo(imageMaxCount: imagePickerMaxImageCount,
                                                                            videoMaxCount: imagePickerMaxVideoCount),
                                                  isOriginal: true,
                                                  takePhotoEnable: true)
            commonMediaManager = CommonPickMediaManager(config, imageViewConfig, imagePickerCallback: { _, results in
                guard let results = results else {
                    imagePickerFinishCallBack?(false)
                    return
                }
                var count = results.count
                uploadQueue.async {
                    for result in results {
                        count -= 1
                        switch result {
                        case let .video(result):
                            uploadEntitys.append((path: result.exportURL.path, fileName: result.name))
                        case let .image(result):
                            uploadEntitys.append((path: result.exportURL.path, fileName: result.name))
                        }
                    }
                    if count <= 0 {
                        DriveUploadCacheService.upload(entitys: uploadEntitys, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
                    }
                }
                imagePickerFinishCallBack?(true)
            })
            picker = commonMediaManager?.skImagePickerVC
            guard let picker = picker else { return UIViewController() }
            picker.modalPresentationStyle = .fullScreen
            picker.showMultiSelectAssetGridViewController()
            setupNetworkMonitor(viewController: picker)
            return picker
        } else {
            let picker = ImagePickerViewController(assetType: .imageAndVideo(imageMaxCount: imagePickerMaxImageCount,
                                                                             videoMaxCount: imagePickerMaxVideoCount),
                                                   isOriginal: true,
                                                   isOriginButtonHidden: true,
                                                   sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                                   takePhotoEnable: true)
            picker.modalPresentationStyle = .fullScreen
            picker.showMultiSelectAssetGridViewController()
            setupImagePickerCallback(imagePicker: picker, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
            setupNetworkMonitor(viewController: picker)
            return picker
        }
    }

    private static func setupImagePickerCallback(imagePicker: ImagePickerViewController, mountToken: String, mountPoint: String, scene: DriveUploadScene) {
        // 上传媒体文件的回调
        imagePicker.imagePickerFinishSelect = { viewController, result in
            // Drive数据埋点：上传多媒体的确认
            let assets = result.selectedAssets
            DriveUploadCacheService.savePickedAssetsToLocal(assetArr: assets, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
            viewController.dismiss(animated: false, completion: {
                imagePickerFinishCallBack?(true)
            })

        }
        imagePicker.imagePikcerCancelSelect = { _, result in
            imagePickerFinishCallBack?(false)
        }

        // 拍照的回调
        imagePicker.imagePickerFinishTakePhoto = { viewController, image in
            DriveUploadCacheService.saveTakedPhotoToLocal(image: image, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
            if UserScopeNoChangeFG.LJW.cameraStoragePermission {
                //保存到相册
                do {
                    try Utils.savePhoto(token: Token(PSDATokens.Space.space_takephoto_click_upload_no_fg), image: image) { _, _ in }
                } catch {
                    DocsLogger.driveError("Utils savePhoto error")
                }
            }
            DispatchQueue.main.async {
                viewController.dismiss(animated: false, completion: {
                    imagePickerFinishCallBack?(true)
                })
            }
        }
    }
}

// MARK: - 监听网络状态
extension DriveImagePickerHelper {
    private static func setupNetworkMonitor(viewController: UIViewController) {
        DocsNetStateMonitor.shared.addObserver(viewController) { [weak viewController] _, isReachable in
            // 如果网络不可用则退出媒体选择器，弹出无网通知
            if isReachable == false {
                guard let viewController = viewController else { return }
                viewController.dismiss(animated: true, completion: nil)
                guard let sourceViewController = UIViewController.docs.topMost(of: viewController) else { return }
                self.showNoNetworkAlert(sourceViewController)
            }
        }
    }
    
    private static func showNoNetworkAlert(_ viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: BundleI18n.SKResource.Drive_Drive_NetInterrupt, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Confirm, style: UIAlertAction.Style.default, handler: nil))
        viewController.present(alert, animated: false, completion: nil)
    }
}
