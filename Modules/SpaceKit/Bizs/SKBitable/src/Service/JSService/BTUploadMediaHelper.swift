//
// Created by duanxiaochen.7 on 2021/5/23.
// Affiliated with SKBitable.
//
// Description:
// swiftlint:disable file_length type_body_length

import SKFoundation
import RxSwift
import RxDataSources
import SKBrowser
import SKResource
import LarkUIKit
import Photos
import SKCommon
import SpaceInterface
import ByteWebImage
import UniverseDesignToast
import UIKit
import SKInfra
import LarkSensitivityControl
import LarkDocsIcon
import EEAtomic

typealias BTUploadMediaObservable = Observable<BTMediaUploadInfo> // drive -> helper

struct DriveUploadObserver {
    var jobKey: String?
    var uploadObserver: BTUploadMediaObservable
}

struct BTUploadTableInfo {
    var tableID: String
    var viewID: String
    var recordID: String
    var baseID: String
}

enum BTUploadingAttachmentsStatus {
    case uploading                       // 正在上传
    case uploadingWithSomeUploadFailed   // 有其他附件正在上传，同时也有附件上传失败
    case allUploaded                     // 所有附件都已上传完成
    case uploadedWithSomeUploadFailed(failedCount: Int)    // 有附件上传失败，其他的附件均已上传完成
}

enum BTUploadMountPoint: String, Codable {
    /// 默认挂载点
    case `default` = "bitable_file"
    /// 预上传的临时挂载点，不占用租户空间。提交后转移到默认挂载点内。
    case tmp = "bitable_tmp_point"
}

struct PendingAttachment: Equatable {
    static func == (lhs: PendingAttachment, rhs: PendingAttachment) -> Bool {
        return lhs.mediaInfo == rhs.mediaInfo
            && lhs.location == rhs.location
            && lhs.jobKey == rhs.jobKey
    }

    let mediaInfo: BTUploadMediaHelper.MediaInfo
    let location: BTFieldLocation
    var jobKey: String?
    let logHandler: (String) -> Void
}

extension PendingAttachment {
    struct LocalFile {
        let fileName: String
        let fileURL: URL
    }
}

enum BTAttachmentType: Equatable, IdentifiableType {

    typealias Identity = String

    var identity: String {
        switch self {
        case .pending(let pendingAttachment):
            return pendingAttachment.mediaInfo.uniqueId
        case .uploading(let uploadInfo):
            return uploadInfo.jobKey
        case .existing(let attachmentModel):
            return attachmentModel.attachmentToken
        }
    }

    case pending(PendingAttachment)
    case uploading(BTMediaUploadInfo)
    case existing(BTAttachmentModel)
}

struct BTAttachment: AnimatableSectionModelType {

    typealias Identity = String

    typealias Item = BTAttachmentType

    var identity: String

    var items: [BTAttachmentType]

    init(fieldID: String, attachments: [BTAttachmentType]) {
        identity = fieldID
        items = attachments
    }

    init(original: Self, items: [Self.Item]) {
        self = original
        self.items = items
    }
}


enum BTError: Error {
    case attachmentSizeLimit
}


fileprivate enum BTResolveError: Error {
    case unwrapperWithNil
}

protocol BTUploadMediaHelperDelegate: AnyObject {
    func beginUploading()
    func updateUploadProgress(infos: [BTFieldLocation: [BTMediaUploadInfo]], updatesUI: Bool)
    func updateAttachmentLocalStorageURLs(infos: [String: URL], updatesUI: Bool)
    func updatePendingAttachments(infos: [PendingAttachment], updatesUI: Bool)
    func markAllUploadFinished()
    func trackAttachmentSize(imageSize: Int)
    func notifyFrontendDidUploadMedia(forLocation: BTFieldLocation, attachmentModel: BTAttachmentModel, callback: String)
    func handleUploadMediaFailure(error: Error, mountNodeToken: String, mountNode: String)
    func localEditAttachment(with type: BTFieldEditType,
        pendingAttachment: PendingAttachment,
        callback: String
    )
}

final class BTUploadMediaHelper {

    static var attachmentLimitedSize: Int {
        return 2 * 1024 * 1024 * 1024
    }
    
    @AtomicObject
    var fileToken: String {
        didSet {
            if oldValue != fileToken {
                // in wiki filetoken is update when open card
                resume(originBaseID: fileToken, tableID: tableID)
            }
        }
    }
    
    @AtomicObject
    var tableID: String
    var jsCallBack: String
    
//    let mountPoint: String
    /// 默认挂载点
//    static let defaultMountPoint = "bitable_file"
    /// 预上传的临时挂载点，不占用租户空间。提交后转移到默认挂载点内。
//    static let tmpMountPoint = "bitable_tmp_point"
    
//    private var isUploadToTmpMountPoint: Bool {
//        return mountPoint == BTUploadMediaHelper.tmpMountPoint
//    }

    weak var delegate: BTUploadMediaHelperDelegate?

    private let uploader = DocsContainer.shared.resolve(DocCommonUploadProtocol.self)

    private let uploadQueue = DispatchQueue(label: "bitable.upload.attachment.to.drive")
    
    private let compressLibraryDir = "drive/drive_upload_caches/media"

    // drive -> helper
    private var driveUploadObservers: [DriveUploadObserver] = []

    // helper -> field
    private(set) var uploadingAttachments: ThreadSafeDictionary<BTFieldLocation, [BTMediaUploadInfo]> = ThreadSafeDictionary<BTFieldLocation, [BTMediaUploadInfo]>()

    // 表单、高级权限新增卡片场景下，上传附件要延后到点击提交按钮时，由于只存在一张卡片，所以简单点用数组了
    private var pendingAttachments: [PendingAttachment] = []

    // 高级权限表单 添加附件后，如果中途取消，会导致已经上传完成的图片无权限查看，因为这个时候并没有记录的表格中，鉴权不通过
    // 所以得用本地路径预览
    private var attachmentStorageURL: [String: URL] = [:]

    private lazy var mediaFileCachePath: SKFilePath = {
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath(compressLibraryDir)
        try? path.createDirectoryIfNeeded(withIntermediateDirectories: true)
        return path
    }()
    
    // 判断是否是主动取消上传的字典
    private var isCancelState = ThreadSafeDictionary<String, Bool>()
    private var isResumable = ThreadSafeDictionary<String, Bool>()
    
    // 保存每个附件的上传字节数
    private var attachmentsUploadingProgress = ThreadSafeDictionary<String, Int>()
    
    struct MediaInfo: Equatable {
        let uniqueId: String
        let storageURL: URL
        let name: String
        let driveType: DriveFileType
        let byteSize: Int // in bytes
        let width: Int?
        let height: Int?
        let previewImage: UIImage?
        let destinationBaseID: String
        let callback: String
        let mountPoint: BTUploadMountPoint
        let localPreview: Bool
    }

    private typealias SaveImageResult = Result<MediaInfo, Error>
    private enum SaveError: Error {
        case invalidAssetMediaType(type: PHAssetMediaType)
        case resourceNotFound
    }

    private let bag = DisposeBag()
    private var waitingAttachmentsDisposeBag = DisposeBag()

    init(fileToken: String, tableID: String, jsCallBack: String, delegate: BTUploadMediaHelperDelegate) {
        self.fileToken = fileToken
        self.tableID = tableID
        self.jsCallBack = jsCallBack
        self.delegate = delegate
        setupNetworkMonitor()
    }
    
    deinit {
        stopAllUploadingTasks(originBaseID: fileToken)
        DocsLogger.info("deinit")
    }
    
    func switchTable(with baseID: String, tableID: String) {
        guard !self.jsCallBack.isEmpty else {
            DocsLogger.btInfo("[DATA] jsCallback is empty")
            return
        }
        if self.fileToken != baseID { // 文档token发生变化，暂停之前文档的所有上传任务, 恢复当前文档表格上传任务
            stopAllUploadingTasks(originBaseID: fileToken)
            resume(originBaseID: baseID, tableID: tableID)
        } else if self.tableID != tableID { // 只是切换了表，暂停原表格任务，恢复当前表格任务
            stopAllUploadingTasks(originBaseID: fileToken, tableID: self.tableID)
            resume(originBaseID: baseID, tableID: tableID)
        } else {
            DocsLogger.info("[DATA] baseID and tableID no change")
        }
        self.fileToken = baseID
        self.tableID = tableID
    }
    // swiftlint:disable cyclomatic_complexity function_body_length
    /// 将选择的媒体文件保存到本地沙盒，返回媒体文件所在的本地路径
    private func savePickedAssetsToLocal(assetArr: [PHAsset],
                                         uploadMode: BTUploadMode,
                                         logHandler: @escaping (String) -> Void,
                                         uploadHandler: @escaping (MediaInfo) -> Void) {
        let destinationBaseID = fileToken
        let callback = jsCallBack
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            guard assetArr.isEmpty == false else {
                DocsLogger.btError("[DATA] empty [PHAsset]")
                return
            }

            var uploadEntities: [MediaInfo] = []
            var total = assetArr.count

            func onSaveCompletion(_ result: SaveImageResult) {
                total -= 1
                switch result {
                case let .failure(error):
                    DocsLogger.btError("[DATA] failed saving picked assets to sandbox, \(error.localizedDescription)")
                case let .success(info):
                    DocsLogger.btInfo("[DATA] saving to sandbox succeeded")
                    uploadEntities.append(info)
                }
                if total <= 0 {
                    for entity in uploadEntities {
                        uploadHandler(entity)
                    }
                }
            }

            for asset in assetArr {
                let resources = PHAssetResource.assetResources(for: asset)
                let mediaType = asset.mediaType
                let matchedResources: [PHAssetResource]
                let fileName: String
                let width = asset.pixelWidth
                let height = asset.pixelHeight

                if mediaType == .image {
                    // 本地编辑过的图片，要取 .fullSizePhoto, 否则取 .photo 兜底
                    let editedResource = resources.first(where: { $0.type == .fullSizePhoto })
                    let originResource = resources.first(where: { $0.type == .photo })

                    if let editedPhoto = editedResource {
                        matchedResources = [editedPhoto]
                        // 这里优先读取 originPhoto 的文件名
                        // editedPhoto 的文件名会被系统修改为 "fullSizeRender"
                        if let originPhoto = originResource {
                            fileName = originPhoto.originalFilename
                        } else {
                            fileName = editedPhoto.originalFilename
                        }
                    } else if let originPhoto = originResource {
                        matchedResources = [originPhoto]
                        fileName = originPhoto.originalFilename
                    } else {
                        matchedResources = []
                        fileName = "unknown.JPG"
                    }
                } else if mediaType == .video {
                    // 本地编辑过的视频，要取 .fullSizeVideo, 否则取 .video 兜底
                    let editedResource = resources.first(where: { $0.type == .fullSizeVideo })
                    let originResource = resources.first(where: { $0.type == .video })
                    if let editedVideo = editedResource {
                        matchedResources = [editedVideo]
                        // 这里优先读取 originVideo 的文件名
                        // editedVideo 的文件名会被系统修改为 "fullSizeRender"
                        if let originVideo = originResource {
                            fileName = originVideo.originalFilename
                        } else {
                            fileName = editedVideo.originalFilename
                        }
                    } else if let originVideo = originResource {
                        matchedResources = [originVideo]
                        fileName = originVideo.originalFilename
                    } else {
                        matchedResources = []
                        fileName = "unknown.MOV"
                    }
                } else {
                    onSaveCompletion(.failure(SaveError.invalidAssetMediaType(type: mediaType)))
                    continue
                }

                let pathExtention = SKFilePath.getFileExtension(from: fileName)
                let driveType = DriveFileType(fileExtension: pathExtention)
                /// 存储名，与文件原名不同
                let savedName = UniqueNameUtil.makeUniqueName(extention: pathExtention)
                let savedURL = self.mediaFileCachePath.appendingRelativePath(savedName)

                if let editImage = asset.editImage {
                    DocsLogger.btInfo("[DATA] writing edited asset to sandbox")
                    do {
                        try editImage.write(to: savedURL)
                        DocsLogger.btInfo("[DATA] writing edited asset to sandbox succeeded")
                        let byteSize = Int(savedURL.fileSize ?? 0)
                        logHandler(driveType.rawValue)
                        onSaveCompletion(.success(MediaInfo(uniqueId: savedName,
                                                            storageURL: savedURL.pathURL,
                                                            name: fileName,
                                                            driveType: driveType,
                                                            byteSize: byteSize,
                                                            width: width,
                                                            height: height,
                                                            previewImage: nil,
                                                            destinationBaseID: destinationBaseID,
                                                            callback: callback,
                                                            mountPoint: uploadMode.mountPoint,
                                                            localPreview: uploadMode.localPreView)))
                    } catch {
                        onSaveCompletion(.failure(error))
                    }
                    continue
                }

                guard matchedResources.count != 0, let resource = matchedResources.first else {
                    DocsLogger.warning("找不到合适的resource")
                    onSaveCompletion(.failure(SaveError.resourceNotFound))
                    continue
                }
                let resourceOptions = PHAssetResourceRequestOptions()
                resourceOptions.isNetworkAccessAllowed = true
                do {
                    try AlbumEntry.writeData(forToken: Token(PSDATokens.Bitable.bitable_upload_image_do_confirm), manager: PHAssetResourceManager.default(), forResource: resource, toFile: URL(fileURLWithPath: savedURL.pathString), options: resourceOptions) { [weak self] error in
                        if let error = error {
                            onSaveCompletion(.failure(error))
                            return
                        }
                        let byteSize = (savedURL.fileSize as? NSNumber)?.intValue ?? 0
                        var previewImage: UIImage?
                        if mediaType == .video {
                            previewImage = self?.getFirstFrameOfVideo(url: savedURL.pathURL)
                        }
                        logHandler(driveType.rawValue)
                        onSaveCompletion(.success(MediaInfo(uniqueId: savedName,
                                                            storageURL: savedURL.pathURL,
                                                            name: fileName,
                                                            driveType: driveType,
                                                            byteSize: byteSize,
                                                            width: width,
                                                            height: height,
                                                            previewImage: previewImage,
                                                            destinationBaseID: destinationBaseID,
                                                            callback: callback,
                                                            mountPoint: uploadMode.mountPoint,
                                                            localPreview: uploadMode.localPreView)))
                    }
                } catch {
                    onSaveCompletion(.failure(error))
                    DocsLogger.error("AlbumEntry writeData error")
                }

            }
        }
    }

    /// 保存拍摄的照片到本地沙盒
    private func saveTakedPhotoToLocal(
        image: UIImage,
        uploadMode: BTUploadMode,
        logHandler: @escaping (String) -> Void,
        uploadHandler: @escaping (MediaInfo) -> Void
    ) {
        let destinationBaseID = fileToken
        let callback = jsCallBack
        uploadQueue.async { [weak self] in
            guard let self = self, let data = image.jpegData(compressionQuality: 0.9) else { return } // compressionQuality 如果用 1 会造成图片变得非常大

            let byteSize = data.count
            let imageName = UniqueNameUtil.makeUniqueImageName()
            do {
                let savedURL = try data.unifyWrite(to: self.mediaFileCachePath, imageName: imageName)
                DocsLogger.btInfo("[DATA] saving taked photo to sandbox succeeded")
                logHandler("JPEG")
                let mediaInfo = MediaInfo(uniqueId: imageName,
                                          storageURL: savedURL,
                                          name: imageName,
                                          driveType: .jpeg,
                                          byteSize: byteSize,
                                          width: Int(image.size.width * image.scale),
                                          height: Int(image.size.height * image.scale),
                                          previewImage: image,
                                          destinationBaseID: destinationBaseID,
                                          callback: callback,
                                          mountPoint: uploadMode.mountPoint,
                                          localPreview: uploadMode.localPreView)
                uploadHandler(mediaInfo)
            } catch {
                DocsLogger.btError("[DATA] failed saving taked photo to sandbox")
            }
        }
    }

    /// 保存拍摄的录像到本地沙盒
    private func saveTakedVideoToLocal(url: URL,
                                       uploadMode: BTUploadMode,
                                       logHandler: @escaping (String) -> Void,
                                       uploadHandler: @escaping (MediaInfo) -> Void) {
        let destinationBaseID = fileToken
        let callback = jsCallBack
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            let videoName = UniqueNameUtil.makeUniqueVideoName()
            do {
                let filePath = SKFilePath(absUrl: url)
                let byteSize = Int(filePath.fileSize ?? 0)
                logHandler("MOV")
                let thumbnail = self.getFirstFrameOfVideo(url: url)
                let mediaInfo = MediaInfo(uniqueId: videoName,
                                          storageURL: url,
                                          name: videoName,
                                          driveType: .mov,
                                          byteSize: byteSize,
                                          width: 1280,
                                          height: 720,
                                          previewImage: thumbnail,
                                          destinationBaseID: destinationBaseID,
                                          callback: callback,
                                          mountPoint: uploadMode.mountPoint,
                                          localPreview: uploadMode.localPreView)
                uploadHandler(mediaInfo)
            } catch {
                DocsLogger.btError("[DATA] failed saving taked video to sandbox")
            }

        }
    }
    
    private func saveICloudFileToLocal(urls: [URL],
                                       uploadMode: BTUploadMode,
                                       logHandler: @escaping (String) -> Void,
                                       uploadHandler: @escaping (MediaInfo) -> Void) {
        
        let destinationBaseID = fileToken
        let callback = jsCallBack
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            /// 存到本地成功后处理
            func handleWhenSaveLocal(_ result: SaveICloudFileResult) {
                switch result {
                case let .success(model):
                    let saveName = UniqueNameUtil.makeUniqueName(extention: model.localURL.pathExtension)
                    let previewImage: UIImage? = self.getFirstFrameOfVideo(url: model.localURL)
                    let mediaInfo = MediaInfo(uniqueId: saveName,
                                              storageURL: model.localURL,
                                              name: model.fileName,
                                              driveType: DriveFileType(fileExtension: model.localURL.pathExtension),
                                              byteSize: Int(model.fileSize),
                                              width: nil,
                                              height: nil,
                                              previewImage: previewImage,
                                              destinationBaseID: destinationBaseID,
                                              callback: callback,
                                              mountPoint: uploadMode.mountPoint,
                                              localPreview: uploadMode.localPreView)
                    logHandler("File")
                    uploadHandler(mediaInfo)
                case let .fail(iCloudURL, error):
                    DocsLogger.btError("[DATA] failed saving iCloudFile error: \(error.localizedDescription)")
                }
            }
            let service = DocsContainer.shared.resolve(DriveUploadCacheServiceBase.self)?.type()
            service?.saveICloudFile(urls: urls,
                                    isContinueWhenContainInvalidItem: false,
                                    eachFileSaveResult: handleWhenSaveLocal,
                                    completion: nil)
        }
    }

    private func getFirstFrameOfVideo(url: URL) -> UIImage? {
        let avAsset = AVURLAsset(url: url, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        let ctTime = CMTime(seconds: 0, preferredTimescale: 1)
        return try? UIImage(cgImage: imageGenerator.copyCGImage(at: ctTime, actualTime: nil))
    }

    /// 将存好的本地资源上传到 drive
    /// resumeKey: 如果 不为nil尝试恢复之前的上传任务
    private func uploadToDrive(mediaInfo: MediaInfo, copyInsteadMoveAfterSuccess: Bool, resumeKey: String? = nil) -> BTUploadMediaObservable {
        guard mediaInfo.byteSize <= Self.attachmentLimitedSize else {
            DocsLogger.error("uploadToDrive attachmentSizeLimit")
            return .error(BTError.attachmentSizeLimit)
        }
        guard let uploader = self.uploader else {
            DocsLogger.error("uploadToDrive with exception, self.uploader is nil")
            return .error(BTResolveError.unwrapperWithNil)
        }
        let mountPoint = mediaInfo.mountPoint
        if let resumeKey = resumeKey {
            return uploader.resumeUpload(key: resumeKey, copyInsteadMoveAfterSuccess: copyInsteadMoveAfterSuccess)
                .map { (jobID, progress, fileToken, status) -> BTMediaUploadInfo in
                    return BTMediaUploadInfo(jobKey: jobID,
                                             progress: progress,
                                             fileToken: fileToken,
                                             status: status,
                                             mediaInfo: mediaInfo)
                }
        } else {
            return uploader
                .upload(localPath: mediaInfo.storageURL.path,
                        fileName: mediaInfo.name,
                        mountNodePoint: fileToken,
                        mountPoint: mountPoint.rawValue,
                        copyInsteadMoveAfterSuccess: copyInsteadMoveAfterSuccess,
                        priority: .default)
                .map { (jobID, progress, fileToken, status) -> BTMediaUploadInfo in
                    return BTMediaUploadInfo(jobKey: jobID, progress: progress, fileToken: fileToken, status: status, mediaInfo: mediaInfo)
                }
        }
    }
}

enum BTUploadMode {
    case uploadImmediately              // 立即上传模式
    case preUploadForAddRecord          // Base 外 addRecord 模式下预上传
    case preUploadForSubmit             // Base 内 submit 模式下预上传
    case uploadUntillSubmit             // Base 内 submit 模式下等 submit 再上传
    
    var uploadImmediately: Bool {
        return self == .uploadImmediately || self == .preUploadForAddRecord || self == .preUploadForSubmit
    }
    
    var mountPoint: BTUploadMountPoint {
        switch self {
        case .uploadImmediately:
            return .default
        case .preUploadForAddRecord:
            return .tmp
        case .preUploadForSubmit:
            return .default         // Base 内目前只能先上传到默认节点
        case .uploadUntillSubmit:
            return .default
        }
    }
    
    var localPreView: Bool {
        switch self {
        case .uploadImmediately:
            return false
        case .preUploadForAddRecord:
            return true
        case .preUploadForSubmit:
            return true
        case .uploadUntillSubmit:
            return false
        }
    }
}

protocol BTUploadObservingDelegate: AnyObject {
    func didPickMedia(content: SKPickContent,
                      forLocation: BTFieldLocation,
                      inRecord: BTRecord?,
                      uploadMode: BTUploadMode,
                      logHandler: @escaping (String) -> Void)
    func removePendingAttachment(_: PendingAttachment)
    func cancelUploadingAttachment(_: BTMediaUploadInfo)
    func didNewPickMedia(results: [MediaResult],
                      forLocation: BTFieldLocation,
                      inRecord: BTRecord?,
                      uploadMode: BTUploadMode,
                      logHandler: @escaping (String) -> Void)
}

extension BTUploadMediaHelper: BTUploadObservingDelegate {
    func didPickMedia(content: SKPickContent,
                      forLocation location: BTFieldLocation,
                      inRecord record: BTRecord?,
                      uploadMode: BTUploadMode,
                      logHandler: @escaping (String) -> Void) {
        if uploadMode.uploadImmediately {
            delegate?.beginUploading()
        }
        let mountPoint = uploadMode.mountPoint
        let uploadHandler: (MediaInfo) -> Void = { [weak self, weak record] mediaInfo in
            guard let `self` = self else { return }
            if !uploadMode.uploadImmediately {
                DispatchQueue.main.async {
                    let info = PendingAttachment(mediaInfo: mediaInfo,
                                                 location: location,
                                                 logHandler: logHandler)
                    self.pendingAttachments.insert(info, at: 0)
                    self.delegate?.updatePendingAttachments(infos: self.pendingAttachments, updatesUI: true)
                    self.localAddAttachment(pendingAttachment: info)
                }
            } else {
                self.handleUpload(mediaInfo, forLocation: location)
            }
        }
        switch content {
        case .asset(let assets, _):
            savePickedAssetsToLocal(
                assetArr: assets,
                uploadMode: uploadMode,
                logHandler: logHandler,
                uploadHandler: uploadHandler
            )
        case .takePhoto(let photo):
            saveTakedPhotoToLocal(
                image: photo,
                uploadMode: uploadMode,
                logHandler: logHandler,
                uploadHandler: uploadHandler
            )
        case .takeVideo(let videoUrl):
            saveTakedVideoToLocal(
                url: videoUrl,
                uploadMode: uploadMode,
                logHandler: logHandler,
                uploadHandler: uploadHandler
            )
        case .iCloudFiles(let fileURLs):
            saveICloudFileToLocal(
                urls: fileURLs,
                uploadMode: uploadMode,
                logHandler: logHandler,
                uploadHandler: uploadHandler
            )
        default: ()
        }
    }
    
    func didNewPickMedia(results: [MediaResult], forLocation: BTFieldLocation, inRecord: BTRecord?, uploadMode: BTUploadMode, logHandler: @escaping (String) -> Void) {
        if uploadMode.uploadImmediately {
            delegate?.beginUploading()
        }
        let destinationBaseID = fileToken
        let callback = jsCallBack
        var uploadEntities: [MediaInfo] = []
        var total = results.count
        let mountPoint = uploadMode.mountPoint
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            guard results.isEmpty == false else {
                DocsLogger.btError("[DATA] empty [PHAsset]")
                return
            }
            for result in results {
                total -= 1
                switch result {
                case let .image(result):
                    let uniqueId = result.exportURL.lastPathComponent
                    let pathExtention = SKFilePath.getFileExtension(from: uniqueId)
                    let driveType = DriveFileType(fileExtension: pathExtention)
                    let info = MediaInfo(uniqueId: uniqueId,
                                         storageURL: result.exportURL,
                                         name: result.name,
                                         driveType: driveType,
                                         byteSize: Int(result.fileSize),
                                         width: Int(result.imageSize.width),
                                         height: Int(result.imageSize.height),
                                         previewImage: nil,
                                         destinationBaseID: destinationBaseID,
                                         callback: callback,
                                         mountPoint: uploadMode.mountPoint,
                                         localPreview: uploadMode.localPreView)
                    uploadEntities.append(info)
                case let .video(result):
                    let uniqueId = result.exportURL.lastPathComponent
                    let previewImage = self.getFirstFrameOfVideo(url: result.exportURL)
                    let pathExtention = SKFilePath.getFileExtension(from: uniqueId)
                    let driveType = DriveFileType(fileExtension: pathExtention)
                    let info = MediaInfo(uniqueId: uniqueId,
                                         storageURL: result.exportURL,
                                         name: result.name,
                                         driveType: driveType,
                                         byteSize: Int(result.fileSize),
                                         width: Int(result.videoSize.width),
                                         height: Int(result.videoSize.height),
                                         previewImage: previewImage,
                                         destinationBaseID: destinationBaseID,
                                         callback: callback,
                                         mountPoint: uploadMode.mountPoint,
                                         localPreview: uploadMode.localPreView)
                    uploadEntities.append(info)
                }
                if total <= 0 {
                    for entity in uploadEntities {
                        self.uploadHandler(mediaInfo: entity, uploadMode: uploadMode, forLocation: forLocation, inRecord: inRecord, logHandler: logHandler)
                    }
                }
            }
        }
    }
    
    func uploadHandler(mediaInfo: MediaInfo,
                       uploadMode: BTUploadMode,
                       forLocation: BTFieldLocation,
                       inRecord: BTRecord?, logHandler: @escaping (String) -> Void) {
        if !uploadMode.uploadImmediately {
            DispatchQueue.main.async {
                let info = PendingAttachment(mediaInfo: mediaInfo,
                                             location: forLocation,
                                             logHandler: logHandler)
                self.pendingAttachments.insert(info, at: 0)
                self.delegate?.updatePendingAttachments(infos: self.pendingAttachments, updatesUI: true)
                self.localAddAttachment(pendingAttachment: info)
            }
        } else {
            self.handleUpload(mediaInfo, forLocation: forLocation)
        }
    }
    
    func localAddAttachment(
        pendingAttachment: PendingAttachment
    ) {
        guard let delegate = delegate else {
            DocsLogger.error("localAddAttachment error, self.delegate is nil")
            return
        }
        delegate.localEditAttachment(with: .localAdd, pendingAttachment: pendingAttachment, callback: jsCallBack)
    }
    
    func localDeleteAttachment(pendingAttachment: PendingAttachment) {
        guard let delegate = delegate else {
            DocsLogger.error("localDeleteAttachment error, self.delegate is nil")
            return
        }
        delegate.localEditAttachment(with: .localDelete, pendingAttachment: pendingAttachment, callback: jsCallBack)
    }

    @discardableResult
    private func handleUpload(_ mediaInfo: MediaInfo, forLocation location: BTFieldLocation, resumeKey: String? = nil) -> BTUploadMediaObservable {
        // 如果是上传临时挂载点，不能在上传完成后就立即move掉文件，因为还需要本地预览
        let mountPoint = mediaInfo.mountPoint
        let observable = self.uploadToDrive(mediaInfo: mediaInfo, copyInsteadMoveAfterSuccess: mediaInfo.localPreview, resumeKey: resumeKey)
        observable
            .throttle(DispatchQueueConst.MilliSeconds_250, latest: true, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak observable] uploadInfo in
                guard let self = self, let observable = observable else { return }
                let key = uploadInfo.jobKey
                DocsLogger.btInfo(
                    """
                    [DATA] OBSERVER
                    observed uploading job: \(key),
                    toField: '\(location.fieldID)'
                    fileToken '\(DocsTracker.encrypt(id: uploadInfo.fileToken))',
                    progress '\(uploadInfo.progress)',
                    status '\(uploadInfo.status)'
                    """
                )
                if uploadInfo.status == .success {
                    if mediaInfo.localPreview {
                        // 支持本地预览
                        self.attachmentStorageURL[uploadInfo.fileToken] = uploadInfo.mediaInfo.storageURL
                        self.delegate?.updateAttachmentLocalStorageURLs(infos: self.attachmentStorageURL, updatesUI: false)
                    }
                    self.removeUploadingObserver(forJobKey: key)
                    self.updateUploadingInfo(forLocation: location, jobKey: key, to: nil)
                    self.delegate?.updateUploadProgress(infos: self.uploadingAttachments.safeDict, updatesUI: false)
                    self.delegate?.notifyFrontendDidUploadMedia(forLocation: location,
                                                                attachmentModel: uploadInfo.attachmentModel,
                                                                callback: self.jsCallBack)
                    BTUploadAttachCacheManager.shared.delete(with: location.originBaseID, uploadKey: key)
                } else {
                    // 该 field 有正在上传的附件
                    if var infos = self.uploadingAttachments.value(ofKey: location) {

                        // 该 field 有正在上传的其他附件，但是没有这个附件的上传信息
                        if !infos.contains(where: { $0.jobKey == key }) {
                            infos.append(uploadInfo)
                            self.uploadingAttachments.updateValue(infos, forKey: location)
                            DocsLogger.info("[ACTION] resume task insert path: \(mediaInfo.storageURL)")
                            BTUploadAttachCacheManager.shared.insert(location: location, mediaInfo: mediaInfo, uploadKey: key)
                        // 更新该附件的信息（将旧的替换掉）
                        } else {
                            self.updateUploadingInfo(forLocation: location, jobKey: key, to: uploadInfo)
                        }

                    // 该 field 第一次上传附件
                    } else {
                        self.driveUploadObservers.append(DriveUploadObserver(jobKey: key, uploadObserver: observable))
                        self.uploadingAttachments.updateValue([uploadInfo], forKey: location)
                        DocsLogger.info("[ACTION] resume task path: \(mediaInfo.storageURL)")
                        BTUploadAttachCacheManager.shared.insert(location: location, mediaInfo: mediaInfo, uploadKey: key)
                    }

                    self.delegate?.updateUploadProgress(infos: self.uploadingAttachments.safeDict, updatesUI: true)
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                guard let jobKey = (error as NSError).userInfo["fileKey"] as? String else {
                    DocsLogger.btError("[DATA] handleUpload error without errorjobkey: \(error)")
                    self.delegate?.handleUploadMediaFailure(error: error,
                                                            mountNodeToken: self.fileToken,
                                                            mountNode: mountPoint.rawValue)
                    
                    return
                }
                
                // 无网络场景不移除监听 不移除占位
                if UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable &&
                    (error as NSError).code == DocCommonUploadErrorCode.offline.rawValue {
                    DocsLogger.btInfo("[DATA] upload job failed offline \(jobKey)")
                    return
                }
                // 退出文档或者切换表格导致的自动暂停
                if self.isResumable.value(ofKey: jobKey) ?? false {
                    DocsLogger.btInfo("[DATA] upload job is stop but resumable \(jobKey)")
                    self.isResumable.removeValue(forKey: jobKey)
                    return
                }
                // 如果不是手动取消才弹toast
                if !(self.isCancelState.value(ofKey: jobKey) ?? false) {
                    DocsLogger.btError("[DATA] handleUpload error: \(error)")
                    self.delegate?.handleUploadMediaFailure(error: error,
                                                            mountNodeToken: self.fileToken,
                                                            mountNode: mountPoint.rawValue)
                }
                self.isCancelState.removeValue(forKey: jobKey)
                self.removeUploadingObserver(forJobKey: jobKey)
                self.updateUploadingInfo(forLocation: location, jobKey: jobKey, to: nil)
                BTUploadAttachCacheManager.shared.delete(with: self.fileToken, uploadKey: jobKey)
                self.delegate?.updateUploadProgress(infos: self.uploadingAttachments.safeDict, updatesUI: true)
               
            })
            .disposed(by: bag)
        return observable
    }

    func removeUploadingObserver(forJobKey key: String) {
        driveUploadObservers = driveUploadObservers.filter { $0.jobKey != key }
        if driveUploadObservers.isEmpty {
            delegate?.markAllUploadFinished()
        }
    }

    func updateUploadingInfo(forLocation location: BTFieldLocation, jobKey: String, to newInfo: BTMediaUploadInfo?) {
        guard let oldInfo = uploadingAttachments.value(ofKey: location) else { return }
        let newValue = oldInfo.compactMap({ info in
            if info.jobKey == jobKey {
                return newInfo
            } else {
                return info
            }
        })
        uploadingAttachments.updateValue(newValue, forKey: location)
    }

    func pendingAttachments(baseID: String,
                            tableID: String,
                            viewID: String,
                            recordID: String) -> [PendingAttachment] {
        return pendingAttachments.filter {
            return $0.location.baseID == baseID &&
                $0.location.tableID == tableID &&
                $0.location.viewID == viewID &&
                $0.location.recordID == recordID
        }
    }

    func removePendingAttachment(_ pendingAttachment: PendingAttachment) {
        DocsLogger.btInfo("[ACTION] remove pendingAttachment \(pendingAttachment.mediaInfo.uniqueId)")
        pendingAttachments.removeAll { $0.mediaInfo.uniqueId == pendingAttachment.mediaInfo.uniqueId }
        delegate?.updatePendingAttachments(infos: pendingAttachments, updatesUI: true)
        DispatchQueue.global().async {
            let filePath = SKFilePath(absUrl: pendingAttachment.mediaInfo.storageURL)
            do {
                try filePath.removeItem()
            } catch {
                DocsLogger.btError("[ACTION] remove pendingAttachment failed, \(pendingAttachment.mediaInfo.uniqueId) error \(error.localizedDescription)")
            }
        }
        localDeleteAttachment(pendingAttachment: pendingAttachment)
    }

    func removeAllPendingAttachments() {
        DocsLogger.btInfo("[ACTION] removeAllPendingAttachments")
        let pendingUrls = pendingAttachments.map { $0.mediaInfo.storageURL }
        var removeUrls = Set(pendingUrls)
        attachmentStorageURL.values.forEach {
            removeUrls.insert($0)
        }
        DocsLogger.btInfo("[ACTION] removeAllPendingAttachments removeUrlsCount: \(removeUrls.count)")
        DispatchQueue.global().async {
            removeUrls.forEach {
                let filePath = SKFilePath(absUrl: $0)
                do {
                    try filePath.removeItem()
                } catch {
                    DocsLogger.btError("[ACTION] remove all pendingAttachment failed, error \(error.localizedDescription)")
                }
            }
        }
        pendingAttachments = []
        delegate?.updatePendingAttachments(infos: [], updatesUI: false)
        attachmentStorageURL = [:]
        delegate?.updateAttachmentLocalStorageURLs(infos: [:], updatesUI: false)
    }

    func uploadWaitingAttachments(with info: BTUploadTableInfo,
                                  progress: @escaping (Int, Int) -> Void,
                                  completion: @escaping (Bool) -> Void) {
        guard self.attachmentsUploadingProgress.count() == 0 else {
            DocsLogger.btInfo("[DATA] uploadingAttachments, can not start new uploading")
            return
        }
        var obs: [BTUploadMediaObservable] = []
        let attachmentInfos = pendingAttachments(baseID: info.baseID,
                                                 tableID: info.tableID,
                                                 viewID: info.viewID,
                                                 recordID: info.recordID)
        attachmentInfos.forEach { media in
            let ob = self.uploadToDrive(mediaInfo: media.mediaInfo, copyInsteadMoveAfterSuccess: true)
                .map { [weak self] uploadInfo -> BTMediaUploadInfo in
                    guard let `self` = self else { return uploadInfo }
                    if uploadInfo.status == .success {
                        self.attachmentStorageURL[uploadInfo.fileToken] = media.mediaInfo.storageURL
                        self.delegate?.updateAttachmentLocalStorageURLs(infos: self.attachmentStorageURL, updatesUI: true)
                        self.delegate?.notifyFrontendDidUploadMedia(
                            forLocation: media.location,
                            attachmentModel: uploadInfo.attachmentModel,
                            callback: self.jsCallBack
                        )
                        self.delegate?.trackAttachmentSize(imageSize: uploadInfo.mediaInfo.byteSize)
                    }
                    return uploadInfo
                }
            obs.append(ob)
        }
        if obs.isEmpty {
            completion(true)
            return
        }
        DocsLogger.btInfo("[DATA] uploadWaitingAttachments count: \(obs.count)")
        delegate?.beginUploading()
        
        var totalByte = 0
        for info in attachmentInfos {
            totalByte += info.mediaInfo.byteSize
            if let jobkey = info.jobKey {
                self.attachmentsUploadingProgress.updateValue(0, forKey: jobkey)
            }
        }
        
        progress(0, totalByte)
        Observable.merge(obs)
            .observeOn(MainScheduler.instance)
            .catchError { [weak self] error -> Observable<BTMediaUploadInfo> in
                guard let `self` = self else { return .empty() }
                DocsLogger.btError("[DATA] uploadWaitingAttachments error: \(error)")
                self.pendingAttachments.forEach { info in
                    if let jobKey = info.jobKey {
                        self.uploader?.cancelUpload(key: jobKey).subscribe()
                            .disposed(by: self.waitingAttachmentsDisposeBag)
                    }
                }
                self.delegate?.handleUploadMediaFailure(error: error,
                                                        mountNodeToken: self.fileToken,
                                                        mountNode: BTUploadMountPoint.default.rawValue)
                return .empty()
            }
            .subscribe(onNext: { [weak self] uploadInfo in
                guard let `self` = self else { return }
                DocsLogger.btInfo("[DATA] uploadInfo status: \(uploadInfo.status) name: \(uploadInfo.mediaInfo.name) jobkey: \(uploadInfo.jobKey)")
                if uploadInfo.status == .queue {
                    self.pendingAttachments = self.pendingAttachments.map { attachment -> PendingAttachment in
                        var attachment = attachment
                        if uploadInfo.mediaInfo.uniqueId == attachment.mediaInfo.uniqueId {
                            attachment.jobKey = uploadInfo.jobKey
                        }
                        return attachment
                    }
                    self.delegate?.updatePendingAttachments(infos: self.pendingAttachments, updatesUI: false)
                }
                
                // 更新单个附件的已上传字节数
                if !UserScopeNoChangeFG.QYK.btAttachmentUploadingCrashFixDisable {
                    let uploadInfoProgress = uploadInfo.progress
                    let mediaInfoByteSize = Float(uploadInfo.mediaInfo.byteSize)
                    if !uploadInfoProgress.isNaN, !uploadInfoProgress.isInfinite, !mediaInfoByteSize.isNaN, !mediaInfoByteSize.isInfinite {
                        self.attachmentsUploadingProgress.updateValue(Int(uploadInfoProgress * mediaInfoByteSize), forKey: uploadInfo.jobKey)
                    } else {
                        DocsLogger.error("BTUploadMediaHelper uploadInfo.progress: \(uploadInfoProgress), uploadInfo.mediaInfo.byteSize: \(mediaInfoByteSize)")
                        return
                    }
                } else {
                    self.attachmentsUploadingProgress.updateValue(Int(uploadInfo.progress * Float(uploadInfo.mediaInfo.byteSize)), forKey: uploadInfo.jobKey)
                }
                
                if uploadInfo.status == .success {
                    self.pendingAttachments.removeAll {
                        $0.mediaInfo.uniqueId == uploadInfo.mediaInfo.uniqueId
                    }
                    self.delegate?.updatePendingAttachments(infos: self.pendingAttachments, updatesUI: false)
                }
                var completedByte = 0
                for value in self.attachmentsUploadingProgress.all().values {
                    completedByte += value
                }
                progress(completedByte, totalByte)
            }, onError: { [weak self] _ in
                self?.attachmentsUploadingProgress.removeAll()
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                self.attachmentsUploadingProgress.removeAll()
                DocsLogger.btInfo("[DATA] uploadWaitingAttachments onCompleted")
                completion(self.pendingAttachments.isEmpty)
                self.delegate?.markAllUploadFinished()
            })
            .disposed(by: waitingAttachmentsDisposeBag)
    }

    func cancelUploadWaitingAttachments() {
        let attachments = self.pendingAttachments
        // 重置信号，因为cancel后 uploadToDrive Observable 会收到error事件
        self.waitingAttachmentsDisposeBag = DisposeBag()
        attachments.forEach { info in
            if let jobKey = info.jobKey {
                DocsLogger.btInfo("[DATA] cancelUploadWaitingAttachments key: \(jobKey)")
                self.uploader?.cancelUpload(key: jobKey).subscribe().disposed(by: self.waitingAttachmentsDisposeBag)
                BTUploadAttachCacheManager.shared.delete(with: info.location.originBaseID, uploadKey: jobKey)
            }
        }
        self.attachmentsUploadingProgress.removeAll()
        delegate?.markAllUploadFinished()
    }
    
    func cancelUploadingAttachment(_ data: BTMediaUploadInfo) {
        DocsLogger.btInfo("[ACTION] removeUploadingAttachment \(data.jobKey)")
        self.isCancelState.updateValue(true, forKey: data.jobKey)
        self.uploader?.cancelUpload(key: data.jobKey).subscribe().disposed(by: self.bag)
        BTUploadAttachCacheManager.shared.delete(with: fileToken, uploadKey: data.jobKey)
        do {
            let filePath = SKFilePath(absUrl: data.mediaInfo.cachePath)
            try filePath.removeItem()
        } catch {
            DocsLogger.btInfo("[ACTION] removeUploadingAttachment failed, \(data.jobKey), error \(error)")
        }
    }
    
    func updateUploadingAttachmentsWhenNoNet() {
        guard UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable else {
            DocsLogger.btInfo("[ACTION] resume task disable")
            return
        }
        guard !fileToken.isEmpty, !tableID.isEmpty else {
            DocsLogger.btInfo("[ACTION] resume task baseID is empty")
            return
        }
        guard !DocsNetStateMonitor.shared.isReachable else {
            DocsLogger.btInfo("[ACTION] resume task no need to update uploading attachments")
            return
        }
        executeGlobalAsync() {
            [weak self] in
            guard let self = self else { return }
            let attachs = BTUploadAttachCacheManager.shared.getUploadingAttachInfos(with: self.fileToken, tableID: self.tableID)
            DocsLogger.btInfo("[ACTION] resume task update uploading count \(attachs.count)")
            for attach in attachs {
                do {
                    let mediaInfo = try attach.getMediaInfo()
                    DocsLogger.btInfo("[ACTION] resume task update uploading key: \(attach.uploadKey)")
                    let uploadingInfo = BTMediaUploadInfo(jobKey: attach.uploadKey,
                                                          progress: 0,
                                                          fileToken: "",
                                                          status: .pending,
                                                          mediaInfo: mediaInfo)
                    if var uploadInfos = self.uploadingAttachments.value(ofKey: attach.localtion),
                        !uploadInfos.contains(where: { $0.jobKey == uploadingInfo.jobKey }) {
                        uploadInfos.append(uploadingInfo)
                        self.uploadingAttachments.updateValue(uploadInfos, forKey: attach.localtion)
                    } else {
                        self.uploadingAttachments.updateValue([uploadingInfo], forKey: attach.localtion)
                    }
                    self.delegate?.updateUploadProgress(infos: self.uploadingAttachments.safeDict, updatesUI: true)
                } catch {
                    DocsLogger.error("[ACTION] resume task update uploading failed key: \(attach.uploadKey)")
                }
            }
        }
    }
    
    func resume(originBaseID: String, tableID: String) {
        guard UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable else {
            DocsLogger.btInfo("[ACTION] resume task disable")
            return
        }
        guard !originBaseID.isEmpty else {
            DocsLogger.btInfo("[ACTION] resume task baseID is empty")
            return
        }
        let attachs = BTUploadAttachCacheManager.shared.getUploadingAttachInfos(with: originBaseID, tableID: tableID)
        DocsLogger.btInfo("[ACTION] resume task count \(attachs.count)")
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            for attach in attachs {
                do {
                    let mediaInfo = try attach.getMediaInfo()
                    DocsLogger.btInfo("[ACTION] resume task cacheURL: \(mediaInfo.cachePath)")
                    let filePath = SKFilePath(absUrl: mediaInfo.cachePath)
                    if filePath.exists {
                        DocsLogger.btInfo("[ACTION] resume task key: \(attach.uploadKey)")
                        self.handleUpload(mediaInfo, forLocation: attach.localtion, resumeKey: attach.uploadKey)
                    } else {
                        DocsLogger.btInfo("[ACTION] resume task key: \(attach.uploadKey) not found")
                        BTUploadAttachCacheManager.shared.delete(with: originBaseID, uploadKey: attach.uploadKey)
                    }
                } catch {
                    DocsLogger.error("[ACTION] resume task failed key: \(attach.uploadKey)")
                }
            }
        }
    }
    
    func stopAllUploadingTasks(originBaseID: String, tableID: String = "") {
        guard UserScopeNoChangeFG.ZYZ.btUploadAttachRestorable else {
            DocsLogger.btInfo("[ACTION] resume task disable")
            return
        }
        guard !originBaseID.isEmpty else {
            DocsLogger.btInfo("[ACTION] resume task disable no originBaseID")
            return
        }
        let attachs = BTUploadAttachCacheManager.shared.getUploadingAttachInfos(with: originBaseID, tableID: tableID)
        DocsLogger.btInfo("[ACTION] resume task cancel count \(attachs.count)")
        for attach in attachs {
            DocsLogger.btInfo("[ACTION] resume task cancel key \(attach.uploadKey)")
            self.uploader?.cancelUpload(key: attach.uploadKey).subscribe().disposed(by: self.bag)
            self.isResumable.updateValue(true, forKey: attach.uploadKey)
        }
    }
    
    private func setupNetworkMonitor() {
        executeGlobalAsync() {
            DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
                guard let self = self else { return }
                DocsLogger.btInfo("[ACTION] Current networkType is \(networkType)")
                guard !self.fileToken.isEmpty, !self.tableID.isEmpty else {
                    DocsLogger.btInfo("[ACTION] baseID, tableID invalid")
                    return
                }
                if isReachable {
                    DocsLogger.btInfo("[ACTION] network reachable start resume")
                    self.resume(originBaseID: self.fileToken, tableID: self.tableID)
                }
            }
        }
    }
    
    func getUploadingStatus(baseID: String, tableID: String, recordID: String, fieldIDs: [String]) -> BTUploadingAttachmentsStatus {
        var hasUploading: Bool = false
        var failedCount: Int = 0
        self.uploadingAttachments.safeDict.forEach { (key: BTFieldLocation, value: [BTMediaUploadInfo]) in
            guard key.baseID == baseID, 
                    key.tableID == tableID,
                    key.recordID == recordID,
                    fieldIDs.contains(key.fieldID)
            else {
                return
            }
            value.forEach { info in
                if info.status == .failed {
                    failedCount += 1
                } else if info.status == .inflight || info.status == .queue {
                    hasUploading = true
                }
            }
        }
        let hasUploadFailed = failedCount > 0
        if hasUploading && !hasUploadFailed {
            return .uploading
        } else if hasUploading && hasUploadFailed {
            return .uploadingWithSomeUploadFailed
        } else if !hasUploading && !hasUploadFailed {
            return .allUploaded
        } else if !hasUploading && hasUploadFailed {
            return .uploadedWithSomeUploadFailed(failedCount: failedCount)
        }
        return .allUploaded
    }
}
