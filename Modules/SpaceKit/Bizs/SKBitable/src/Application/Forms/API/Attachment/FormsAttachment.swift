import Foundation
import LarkAssetsBrowser
import LarkOpenAPIModel
import LKCommonsLogging
import RxSwift
import SKBrowser
import SKCommon
import SKFoundation
import SKInfra
import SKResource
import SpaceInterface

final class FormsAttachment {
    
    static let logger = Logger.formsSDKLog(FormsAttachment.self, category: "FormsAttachment")
    
    lazy var uploader: DocCommonUploadProtocol? = DocsContainer
        .shared
        .resolve(DocCommonUploadProtocol.self)
    
    var manager: CommonPickMediaManager?
    
    static var choosenAttachments = [String: FormsChooseAttachmentInfo]()
    
    var chooseAttachmentSuccessBlock: (([FormsChooseAttachmentInfo]) -> Void)?
    
    var chooseAttachmentFailureBlock: ((OpenAPIError) -> Void)?
    
    var chooseAttachmentCancelBlock: (() -> Void)?
    
    let bag = DisposeBag()
    
    init() {
        Self.logger.info("FormsAttachment init")
    }
    
    deinit {
        Self.logger.info("FormsAttachment deinit")
        let infos = Array(
            Self
                .choosenAttachments
                .values
        )
        cancelOrDeleteUploadTasks(attachmentInfos: infos, needRemoveMemoryAndDeleteAttachment: false)
    }
    
    func setupManager(
        vc: UIViewController?,
        assetType: PhotoPickerAssetType = .imageAndVideoWithTotalCount(totalCount: 9)
    ) -> CommonPickMediaManager {
        let path = SKFilePath
            .bitableFormDir
            .appendingRelativePath("drive/drive_upload_caches/media")
        path.createDirectoryIfNeeded()
        
        let suiteConfig = CommonPickMediaConfig(
            rootVC: vc,
            path: path,
            sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
            isOriginButtonHidden: false
        )
        
        let suiteViewConfig = SuiteViewConfig(assetType: assetType, cameraType: .custom(true))
        let mng = CommonPickMediaManager(
            delegate: self,
            suiteConfig,
            suiteViewConfig: suiteViewConfig
        )
        manager = mng
        
        manager?
            .pickSuiteView?
            .imagePickerVCDidCancel = { [weak self] in
                guard let self = self else {
                    Self.logger.error("imagePickerVCDidCancel error, self is nil")
                    return
                }
                self.chooseAttachmentCancelBlock?()
                self.cleanChooseAttachmentBlocks()
            }
        
        manager?
            .pickSuiteView?
            .cameraVCDidDismiss = { [weak self] in
                guard let self = self else {
                    Self.logger.error("cameraVCDidDismiss error, self is nil")
                    return
                }
                self.chooseAttachmentCancelBlock?()
                self.cleanChooseAttachmentBlocks()
            }
        
        return mng
    }
    
    /// 取消及删除上传任务
    /// - Parameters:
    ///   - attachmentInfos: 需要被取消或者删除的附件集合
    ///   - needRemoveMemoryAndDeleteAttachment: 是否从内存缓存移除附件句柄以及删除已上传的附件
    func cancelOrDeleteUploadTasks(attachmentInfos: [FormsChooseAttachmentInfo], needRemoveMemoryAndDeleteAttachment: Bool) {
        guard let uploader = uploader else {
            Self.logger.error("cancelOrDeleteUploadTasks error, uploader is nil")
            return
        }
        
        let infos = attachmentInfos
            .map { attachment in
                attachment
                    .uploadStatus
                    .values
            }
            .flatMap { $0 }
        
        var needCancelIDs = [String]()
        var needDeleteIDs = [String]()
        
        infos.forEach { status in
            let key = status.0
            switch status.3 {
            case .pending:
                needCancelIDs.append(key)
            case .inflight:
                needCancelIDs.append(key)
            case .failed:
                break
            case .success:
                needDeleteIDs.append(key)
            case .queue:
                needCancelIDs.append(key)
            case .ready:
                needCancelIDs.append(key)
            case .cancel:
                break
            }
        }
        
        attachmentInfos
            .map { info in
                info.attachmentID
            }
            .forEach { attachmentID in
                if needRemoveMemoryAndDeleteAttachment {
                    Self.choosenAttachments[attachmentID] = nil
                } else {
                    Self.choosenAttachments[attachmentID]?.uploadStatus.removeAll()
                }
            }
        
        needCancelIDs
            .forEach { id in
                Self.logger.info("cancel \(id) upload start")
                uploader
                    .cancelUpload(key: id)
                    .subscribe(
                        onNext: { result in
                            Self.logger.info("cancel \(id) upload end, result: \(result)")
                        }
                    )
                    .disposed(by: self.bag)
            }
        
        if needRemoveMemoryAndDeleteAttachment {
            needDeleteIDs
                .forEach { id in
                    Self.logger.info("delete \(id) upload start")
                    uploader
                        .deleteUploadResource(key: id)
                        .subscribe(
                            onNext: { result in
                                Self.logger.info("delete \(id) upload end, result: \(result)")
                            }
                        )
                        .disposed(by: self.bag)
                }
        }
        
    }
    
}
