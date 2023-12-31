//
//  AttachmentServiceImpl.swift
//  Todo
//
//  Created by baiyantao on 2022/12/27.
//

import Foundation
import TodoInterface
import LarkContainer
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import UniverseDesignActionPanel
import LarkVideoDirector
import LarkAssetsBrowser
import Photos
import LarkSensitivityControl
import LarkStorage

final class AttachmentServiceImpl: AttachmentService, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    let updateNoti = PublishRelay<(scene: AttachmentScene, info: TaskUploadInfo)>()

    private var scene2Infos = [AttachmentScene: [AttachmentInfo]]()

    @ScopedInjectedLazy private var driveDependency: DriveDependency?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    private let disposeBag = DisposeBag()
    private var rwLock = pthread_rwlock_t()

    init(resolver: UserResolver) {
        userResolver = resolver
        pthread_rwlock_init(&rwLock, nil)
    }

    deinit { pthread_rwlock_destroy(&rwLock) }

    func upload(scene: AttachmentScene, fileInfo: TaskFileInfo) {
        DetailAttachment.logger.info("service do upload, scene: \(scene.logInfo), fileInfo: \(fileInfo.logInfo)")
        driveDependency?.upload(
            localPath: fileInfo.fileURL,
            fileName: fileInfo.name
        ).subscribe(onNext: { [weak self] uploadInfo in
            DetailAttachment.logger.info("service upload, scene: \(scene.logInfo), uploadInfo: \(uploadInfo.logInfo)")
            guard let self = self else { return }
            self.saveInfoToDic(scene, uploadInfo, fileInfo)
            self.updateNoti.accept((scene, uploadInfo))
            self.saveToSdkIfNeeded(scene, uploadInfo)
        }, onError: { err in
            DetailAttachment.logger.error("service upload failed. err: \(err)")
        }).disposed(by: disposeBag)
    }

    func resumeUpload(scene: AttachmentScene, key: String) {
        DetailAttachment.logger.info("service do resumeUpload, scene: \(scene.logInfo), key: \(key)")
        driveDependency?.resumeUpload(key: key).subscribe(onNext: { [weak self] uploadInfo in
            DetailAttachment.logger.info("service resumeUpload, scene: \(scene.logInfo), uploadInfo: \(uploadInfo.logInfo)")
            guard let self = self else { return }
            self.saveInfoToDic(scene, uploadInfo)
            self.updateNoti.accept((scene, uploadInfo))
            self.saveToSdkIfNeeded(scene, uploadInfo)
        }, onError: { err in
            DetailAttachment.logger.error("service resumeUpload failed. err: \(err)")
        }).disposed(by: disposeBag)
    }

    func cancelUpload(key: String, onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        DetailAttachment.logger.info("service do cancelUpload, key: \(key)")
        driveDependency?.cancelUpload(key: key).flatMapLatest { [weak self] isSuccess -> Observable<Bool> in
            guard let self = self else { return .just(false) }
            return isSuccess ? self.driveDependency?.deleteUploadResource(key: key) ?? .just(false) : .just(false)
        }.observeOn(MainScheduler.asyncInstance).subscribe(onNext: { isSuccess in
            assert(isSuccess)
            onSuccess()
            DetailAttachment.logger.info("cancelUpload success. res: \(isSuccess)")
        }, onError: { err in
            DetailAttachment.logger.info("cancelUpload failed. err: \(err)")
            onError(err)
        }).disposed(by: disposeBag)
    }

    func getInfos(by scene: AttachmentScene) -> [AttachmentInfo] {
        DetailAttachment.logger.info("service do getInfos, scene: \(scene.logInfo)")
        pthread_rwlock_rdlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }
        return scene2Infos[scene] ?? []
    }

    func batchRemoveFromDic(_ scene: AttachmentScene, _ infos: [AttachmentInfo]) {
        DetailAttachment.logger.info("service do batchRemoveFromDic, scene: \(scene.logInfo), infos: \(infos.map { $0.fileInfo.logInfo + $0.uploadInfo.logInfo })")
        pthread_rwlock_wrlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }

        let needRemove = Set(infos.map(\.uploadInfo.uploadKey))
        let infos = scene2Infos[scene] ?? []
        scene2Infos[scene] = infos.filter { !needRemove.contains($0.uploadInfo.uploadKey) }
    }

    func selectLocalFiles(
        vc: BaseViewController,
        sourceView: UIView,
        sourceRect: CGRect,
        enableCount: Int,
        callbacks: SelectLocalFilesCallbacks
    ) {
        let source = UDActionSheetSource(
            sourceView: sourceView,
            sourceRect: sourceRect,
            arrowDirection: .down
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)

        actionSheet.addDefaultItem(text: I18N.Todo_Task_ChoosePhotoFromLibrary) { [weak self] in
            self?.showPhotoLibrary(
                vc: vc,
                enableCount: enableCount,
                callbacks: callbacks
            )
        }
        actionSheet.addDefaultItem(text: I18N.Todo_Task_TakePhoto) { [weak self] in
            guard let self else { return }
            let completion: ((UIImage, UIViewController) -> Void) = { [weak self] image, picker in
                let id = UUID().uuidString
                callbacks.selectCallback?([id])
                self?.image2FileInfo(image) { info in
                    guard let info = info else {
                        callbacks.finishCallback?([(id, nil)])
                        assertionFailure()
                        return
                    }
                    callbacks.finishCallback?([(id, info)])
                }
                picker.dismiss(animated: true, completion: nil)
            }
            LarkCameraKit.takePhoto(
                from: vc, userResolver: self.userResolver,
                didCancel: { _ in callbacks.cancelCallback?() }, completion: completion
            )
        }
        actionSheet.addDefaultItem(text: I18N.Todo_Task_SelectFile) { [weak self] in
            self?.routeDependency?.showLocalFile(
                from: vc,
                enableCount: enableCount,
                chooseLocalFiles: { callbacks.finishCallback?($0.map { ("", $0) }) },
                chooseFilesChange: nil,
                cancelCallback: callbacks.cancelCallback
            )
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        vc.present(actionSheet, animated: true, completion: nil)
    }

    private func showPhotoLibrary(
        vc: UIViewController,
        enableCount: Int,
        callbacks: SelectLocalFilesCallbacks
    ) {
        let picker = ImagePickerViewController(
            assetType: .imageOnly(maxCount: enableCount),
            isOriginal: true,
            isOriginButtonHidden: true,
            takePhotoEnable: false
        )
        picker.showMultiSelectAssetGridViewController()
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in
            picker.dismiss(animated: true)

            for asset in result.selectedAssets {
                let id = UUID().uuidString
                callbacks.selectCallback?([id])
                self?.asset2FileInfo(asset) { info in
                    guard let info = info else {
                        callbacks.finishCallback?([(id, nil)])
                        assertionFailure()
                        return
                    }
                    callbacks.finishCallback?([(id, info)])
                }
            }
        }
        picker.imagePikcerCancelSelect = { (picker, _) in
            callbacks.cancelCallback?()
            picker.dismiss(animated: true)
        }
        picker.modalPresentationStyle = .fullScreen
        vc.present(picker, animated: true, completion: nil)
    }

    private func asset2FileInfo(_ asset: PHAsset, callback: @escaping (TaskFileInfo?) -> Void) {
        let fileName = asset.assetResource?.originalFilename ?? getDefaultKey(from: asset)
        if let editImage = asset.editImage {
            image2FileInfo(editImage, callback: callback)
        } else {
            let opt = PHContentEditingInputRequestOptions()
            opt.canHandleAdjustmentData = { (_) in
                return false
            }
            asset.requestContentEditingInput(with: opt) { [weak self] (input, _) in
                guard let url = input?.fullSizeImageURL else {
                    if let image = self?.messengerDependency?.processPhotoAssets([asset], isOriginal: true).first?.image {
                        self?.image2FileInfo(image, callback: callback)
                    }
                    return
                }
                let fileInfo = TaskFileInfo(
                    name: fileName,
                    fileURL: url.path,
                    size: UInt(abs(asset.size))
                )
                callback(fileInfo)
            }
        }
    }

    private func image2FileInfo(_ image: UIImage, callback: @escaping (TaskFileInfo?) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let name = self.makeImageName()
            // compressionQuality 如果用 1 会造成图片变得非常大
            guard let data = image.jpegData(compressionQuality: 0.9),
                  let path = self.driveDependency?.getUploadCachePath(with: name) else {
                callback(nil)
                return
            }
            do {
                try data.write(to: path, options: .atomic)
                let fileInfo = TaskFileInfo(
                    name: name,
                    fileURL: path.absoluteString,
                    size: UInt(data.count)
                )
                callback(fileInfo)
            } catch {
                callback(nil)
                DetailAttachment.logger.error("failed saving taked photo to sandbox")
            }
        }
    }

    // 从 PHAsset 获取缓存 key
    private func getDefaultKey(from asset: PHAsset) -> String {
        if let resource = asset.assetResource {
            let assetLocalIdentifier = resource.assetLocalIdentifier
            let modificationDate: Double? = asset.modificationDate?.timeIntervalSince1970
            var date: String = ""
            if let modificationDate {
                date = "\(modificationDate)"
            }
            let key = (assetLocalIdentifier + date).md5()
            return key
        } else {
            return asset.localIdentifier.md5()
        }
    }

    private func makeImageName() -> String {
        let prefix = "photo_"
        let suffix = ".JPG"
        let timeStr = String(Int64(Date().timeIntervalSince1970 * 1_000))
        return prefix + timeStr + suffix
    }

    private func saveInfoToDic(
        _ scene: AttachmentScene,
        _ uploadInfo: TaskUploadInfo,
        _ fileInfo: TaskFileInfo? = nil
    ) {
        DetailAttachment.logger.info("service do saveInfoToDic, scene: \(scene.logInfo), upload: \(uploadInfo.logInfo), file: \(fileInfo?.logInfo ?? "")")
        pthread_rwlock_wrlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }

        guard let uploadKey = uploadInfo.uploadKey, !uploadKey.isEmpty else { return }
        var infos = scene2Infos[scene] ?? []
        if let index = infos.firstIndex(where: { $0.uploadInfo.uploadKey == uploadKey }) {
            guard infos[index].uploadInfo != uploadInfo else { return }
            switch uploadInfo.uploadStatus {
            case .cancel:
                infos.remove(at: index)
            default:
                infos[index].uploadInfo = uploadInfo
            }
        } else {
            guard let fileInfo = fileInfo else {
                assertionFailure()
                return
            }
            infos.append((fileInfo, uploadInfo))
        }
        scene2Infos[scene] = infos
    }

    private func getInfo(by scene: AttachmentScene, and uploadInfo: TaskUploadInfo) -> AttachmentInfo? {
        DetailAttachment.logger.info("service do getInfo, scene: \(scene.logInfo), upload: \(uploadInfo.logInfo)")
        pthread_rwlock_rdlock(&rwLock)
        defer { pthread_rwlock_unlock(&rwLock) }

        var infos = scene2Infos[scene] ?? []
        guard let uploadKey = uploadInfo.uploadKey, !uploadKey.isEmpty,
              let info = infos.first(where: { $0.uploadInfo.uploadKey == uploadKey }) else {
            return nil
        }
        return info
    }

    private func saveToSdkIfNeeded(_ scene: AttachmentScene, _ uploadInfo: TaskUploadInfo) {
        DetailAttachment.logger.info("service do saveToSdk, scene: \(scene.logInfo), upload: \(uploadInfo.logInfo)")
        switch scene {
        case .taskEdit(let guid):
            guard uploadInfo.uploadStatus == .success,
                  let info = getInfo(by: scene, and: uploadInfo),
                  let attachment = DetailAttachment.infos2Attachments([info]).first else {
                return
            }
            DetailAttachment.logger.info("service do saveToSdk, \(uploadInfo.uploadKey ?? "") -> \(attachment.guid)")
            fetchApi?.getTodo(guid: guid).flatMapLatest { [weak self] res -> Observable<Rust.Todo> in
                guard let self = self, let todo = res.todo else { return .empty() }
                var newTodo = todo
                newTodo.attachments.append(attachment)
                return self.operateApi?.updateTodo(from: todo, to: newTodo, with: nil) ?? .empty()
            }.subscribe(onNext: { _ in
                DetailAttachment.logger.info("saveToSdk success")
            }, onError: { err in
                DetailAttachment.logger.error("saveToSdk failed. err: \(err)")
            }).disposed(by: disposeBag)
        default:
            break
        }
    }
}
