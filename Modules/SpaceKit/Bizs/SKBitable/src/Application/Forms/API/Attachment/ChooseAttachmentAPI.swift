import AVFoundation
import Foundation
import LarkAssetsBrowser
import LarkDocsIcon
import LarkOpenAPIModel
import LKCommonsLogging
import SKBrowser
import SKCommon
import SKFoundation
import SKInfra
import SKResource
import SKUIKit
import SpaceInterface
import UniverseDesignActionPanel
import UniverseDesignToast

// MARK: - ChooseAttachment Model
enum FormsChooseAttachmentMode: String {
    
    case `default`
    
    case onlyCamera
    
    case onlyAlbum
    
    case onlyFile
    
}

final class FormsChooseAttachmentParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "mode")
    var mode: String
    
    @OpenAPIOptionalParam(jsonKey: "count")
    var count: Int?
    
    @OpenAPIOptionalParam(jsonKey: "mediaType")
    var mediaType: [String]?
    
    var assetType: PhotoPickerAssetType {
        let realCount = count ?? 9
        guard let mediaType = mediaType else {
            return .imageAndVideoWithTotalCount(totalCount: realCount)
        }
        if mediaType.contains("image"), mediaType.contains("video") {
            return .imageAndVideoWithTotalCount(totalCount: realCount)
        }
        if mediaType.contains("image") {
            return .imageOnly(maxCount: realCount)
        } else if mediaType.contains("video") {
            return .videoOnly(maxCount: realCount)
        } else {
            return .imageAndVideoWithTotalCount(totalCount: realCount)
        }
    }
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_mode, _count, _mediaType]
    }
    
}

struct FormsChooseAttachmentInfo {
    
    var attachmentID: String
    
    var type: String
    
    var mimeType: String
    
    var size: UInt64
    
    var name: String
    
    var width: Double?
    
    var height: Double?
    
    var url: URL
    
    var base64Image: String?
    
    var uploadStatus = [String: (String, Float, String, DocCommonUploadStatus)]()
    
}

final class BitableChooseAttachmentResult: OpenAPIBaseResult {
    
    let infos: [FormsChooseAttachmentInfo]
    
    init(infos: [FormsChooseAttachmentInfo]) {
        self.infos = infos
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        let arr = infos.map { info in
            var dic = [String: Any]()
            dic["attachmentID"] = info.attachmentID
            dic["type"] = info.type
            dic["mimeType"] = info.mimeType
            dic["size"] = info.size
            dic["name"] = info.name
            dic["base64Image"] = info.base64Image
            dic["width"] = info.width
            dic["height"] = info.height
            return dic
        }
        return [
            "infos": arr
        ]
    }
    
}

// MARK: - chooseAttachment
extension FormsAttachment {
    
    func chooseAttachment(
        vc: UIViewController,
        params: FormsChooseAttachmentParams,
        success: @escaping ([FormsChooseAttachmentInfo]) -> Void,
        failure: @escaping (OpenAPIError) -> Void,
        cancel: @escaping () -> Void) {
            
            let mng = setupManager(vc: vc, assetType: params.assetType)
            
            chooseAttachmentSuccessBlock = success
            chooseAttachmentFailureBlock = failure
            chooseAttachmentCancelBlock = cancel
            
            let mode = FormsChooseAttachmentMode(rawValue: params.mode) ?? .default
            
            switch mode {
            case .default:
                let actionSheet = UDActionSheet.actionSheet(title: BundleI18n.SKResource.Bitable_Attachment_UploadMethod, popSource: nil, dismissedByTapOutside: { [weak self] in
                    guard let self = self else {
                        Self.logger.error("UDActionSheet dismissedByTapOutside error, FormsAttachment is nil")
                        return
                    }
                    cancel()
                    self.cleanChooseAttachmentBlocks()
                })
                
                actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_Camera, style: .default) { [weak self] in
                    guard let self = self else {
                        Self.logger.error("open camera error, FormsAttachment is nil")
                        return
                    }
                    self.takePic(mana: mng, failure: failure)
                }
                
                actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_Photo, style: .default) { [weak self] in
                    guard let self = self else {
                        Self.logger.error("choose photo error, FormsAttachment is nil")
                        return
                    }
                    self.openAlbum(mana: mng, failure: failure)
                }
                
                actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_LocalFile, style: .default) { [weak self] in
                    guard let self = self else {
                        Self.logger.error("choose file error, FormsAttachment is nil")
                        return
                    }
                    self.openFile(vc: vc, failure: failure)
                }
                
                actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, style: .cancel) { [weak self] in
                    guard let self = self else {
                        Self.logger.error("cancel error, FormsAttachment is nil")
                        return
                    }
                    cancel()
                    self.cleanChooseAttachmentBlocks()
                }
                
                vc.present(actionSheet, animated: true)
                
            case .onlyCamera:
                takePic(mana: mng, failure: failure)
                
            case .onlyAlbum:
                openAlbum(mana: mng, failure: failure)
                
            case .onlyFile:
                openFile(vc: vc, failure: failure)
                
            }
        }
    
    private func takePic(mana: CommonPickMediaManager, failure: @escaping (OpenAPIError) -> Void) {
        
        guard let pick = mana.pickSuiteView else {
            let code = -5
            let msg = "takePhoto error, pickSuiteView is nil"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(error)
            self.cleanChooseAttachmentBlocks()
            return
        }
        
        Self.logger.info("start pick.takePhoto")
        pick.takePhoto()
    }
    
    private func openAlbum(mana: CommonPickMediaManager, failure: @escaping (OpenAPIError) -> Void) {
        
        guard let pick = mana.pickSuiteView else {
            let code = -5
            let msg = "showPhotoLibrary error, pickSuiteView is nil"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(error)
            self.cleanChooseAttachmentBlocks()
            return
        }
        
        Self.logger.info("start pick.showPhotoLibrary")
        pick.showPhotoLibrary(selectedItems: [], useOriginal: false)
    }
    
    private func openFile(vc: UIViewController, failure: @escaping (OpenAPIError) -> Void) {
        let documentPicker = DocsDocumentPickerViewController(deletage: self)
        if SKDisplay.pad {
            documentPicker.modalPresentationStyle = .formSheet
        }
        
        vc.present(documentPicker, animated: false, completion: nil)
    }
    
    private func chooseAttachmentSucc(infos: [FormsChooseAttachmentInfo]) {
        if let succ = chooseAttachmentSuccessBlock {
            succ(infos)
        } else {
            Self.logger.error("chooseAttachmentSucc error, chooseAttachmentSuccessBlock is nil")
        }
        cleanChooseAttachmentBlocks()
    }
    
    func cleanChooseAttachmentBlocks() {
        chooseAttachmentSuccessBlock = nil
        chooseAttachmentFailureBlock = nil
        chooseAttachmentCancelBlock = nil
    }
}

extension FormsAttachment: PickMediaDelegate {
    
    func didFinishPickingMedia(results: [SKCommon.MediaResult]) {
        if results.isEmpty {
            let code = -6
            let msg = "didFinishPickingMedia error, pick media results is empty"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            if let fail = chooseAttachmentFailureBlock {
                fail(error)
            } else {
                Self.logger.error("didFinishPickingMedia error, chooseAttachmentFailureBlock is nil")
            }
            
            cleanChooseAttachmentBlocks()
            
            return
        }
        
        let map = results.map { result in
            switch result {
                
            case let .image(result):
                let uniqueId = result.exportURL.lastPathComponent
                let pathExtention = SKFilePath.getFileExtension(from: uniqueId)
                let driveType = DriveFileType(fileExtension: pathExtention)
                
                let key = UUID().uuidString
                
                var str = ""
                do {
                    let tempData = try Data.unifyContentsOf(url: result.exportURL)
                    if let tempImage = UIImage(data: tempData) {
                        let quality = 0.8
                        let limitSize = 262114
                        if let limitSizeData = tempImage.data(quality: quality, limitSize: UInt(limitSize)) {
                            str = limitSizeData.base64EncodedString()
                        } else {
                            Self.logger.error("didFinishPickingMedia image error, UIImage(data: tempData) error")
                        }
                    } else {
                        Self.logger.error("didFinishPickingMedia image error, tempImage.data(quality: 0.8, limitSize: 50 * 1024) error")
                    }
                } catch {
                    Self.logger.error("didFinishPickingMedia image error, Data(contentsOf: result.exportURL) error", error: error)
                }
                
                let inf = FormsChooseAttachmentInfo(
                    attachmentID: key,
                    type: pathExtention ?? "",
                    mimeType: driveType.mimeType,
                    size: result.fileSize,
                    name: result.name,
                    width: result.imageSize.width,
                    height: result.imageSize.height,
                    url: result.exportURL,
                    base64Image: str
                )
                
                Self.choosenAttachments[key] = inf
                return inf
                
            case let .video(result):
                let uniqueId = result.exportURL.lastPathComponent
                let img = self.getFirstFrameOfVideo(url: result.exportURL)
                let data = img?.data(quality: 0.5, limitSize: 100 * 1024)
                let str = data?.base64EncodedString()
                
                let pathExtention = SKFilePath.getFileExtension(from: uniqueId)
                let driveType = DriveFileType(fileExtension: pathExtention)
                
                let key = UUID().uuidString
                let inf = FormsChooseAttachmentInfo(
                    attachmentID: key,
                    type: pathExtention ?? "",
                    mimeType: driveType.mimeType,
                    size: result.fileSize,
                    name: result.name,
                    width: result.videoSize.width,
                    height: result.videoSize.height,
                    url: result.exportURL,
                    base64Image: str
                )
                
                Self.choosenAttachments[key] = inf
                return inf
                
            }
        }
        
        chooseAttachmentSucc(infos: map)
    }
    
    private func getFirstFrameOfVideo(url: URL) -> UIImage? {
        let avAsset = AVURLAsset(url: url, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let ctTime = CMTime(seconds: 0, preferredTimescale: 1)
        do {
            return try UIImage(cgImage: imageGenerator.copyCGImage(at: ctTime, actualTime: nil))
        } catch {
            Self.logger.error("getFirstFrameOfVideo error", error: error)
            return nil
        }
    }
    
}

extension FormsAttachment: DocsDocumentPickerDelegate {
    
    func pickDocumentFinishSelect(urls: [URL]) {
        
        if isConatinLimitedSizeFile(urls: urls) {
            let code = -7
            let msg = "pickDocumentFinishSelect error, over size"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            
            if let fail = chooseAttachmentFailureBlock {
                fail(error)
            } else {
                Self.logger.error("pickDocumentFinishSelect error, chooseAttachmentFailureBlock is nil")
            }
            
            cleanChooseAttachmentBlocks()
            return
        }
        
        guard let ser = DocsContainer
            .shared
            .resolve(DriveUploadCacheServiceBase.self) else {
            let code = -8
            let msg = "pickDocumentFinishSelect error, resolve DriveUploadCacheServiceBase is nil"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            
            if let fail = chooseAttachmentFailureBlock {
                fail(error)
            } else {
                Self.logger.error("pickDocumentFinishSelect error, chooseAttachmentFailureBlock is nil")
            }
            
            cleanChooseAttachmentBlocks()
            return
        }
        
        var tempInfos = [FormsChooseAttachmentInfo]()
        ser
            .type()
            .saveICloudFile(
                urls: urls,
                isContinueWhenContainInvalidItem: false,
                eachFileSaveResult: { [weak self] result in
                    
                    guard let self = self else {
                        Self.logger.error("saveICloudFile error, self is nil")
                        return
                    }
                    
                    switch result {
                        
                    case let .success(model):
                        let key = UUID().uuidString
                        let driveType = DriveFileType(fileExtension: model.localURL.pathExtension)
                        
                        let info = FormsChooseAttachmentInfo(
                            attachmentID: key,
                            type: model.localURL.pathExtension,
                            mimeType: driveType.mimeType,
                            size: model.fileSize,
                            name: model.fileName,
                            url: model.localURL
                        )
                        tempInfos.append(info)
                        
                        Self.choosenAttachments[key] = info
                        
                    case let .fail(_, error):
                        Self.logger.error("saveICloudFile failed saving iCloudFile", error: error)
                        
                    }
                },
                completion: { [weak self] _ in
                    guard let self = self else {
                        Self.logger.error("saveICloudFile error, self is nil")
                        return
                    }
                    
                    self.chooseAttachmentSucc(infos: tempInfos)
                }
            )
    }
    
    private func isConatinLimitedSizeFile(urls: [URL]) -> Bool {
        urls.contains { (url) -> Bool in
            if let size = SKFilePath(absUrl: url).sizeExt(), size > BTUploadMediaHelper.attachmentLimitedSize {
                return true
            }
            return false
        }
    }
    
    func pickDocumentDidCancel() {
        if let cal = chooseAttachmentCancelBlock {
            cal()
        } else {
            Self.logger.error("pickDocumentDidCancel error, chooseAttachmentCancelBlock is nil")
        }
        cleanChooseAttachmentBlocks()
    }
    
}
