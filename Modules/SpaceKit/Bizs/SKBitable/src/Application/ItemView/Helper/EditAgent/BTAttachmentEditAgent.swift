//
// Created by duanxiaochen.7 on 2021/5/22.
// Affiliated with SKBitable.
//
// Description: 负责附件字段的上传工作



import RxSwift
import RxCocoa
import Photos
import SKFoundation
import SKBrowser
import SKResource
import SKCommon
import SKUIKit
import LarkUIKit
import LarkImageEditor
import LarkFoundation
import LarkAssetsBrowser
import LarkMedia
import EENavigator
import UniverseDesignActionPanel
import UniverseDesignToast
import UIKit
import LarkSensitivityControl
import SKInfra
import SpaceInterface

protocol SuiteViewProvider: AnyObject {
    var pickSuiteView: SKAssuiteView? { get }
}

enum AttachmentLogEvent {
    //camera: 拍摄, album: 相册, file：本地文件,cancel：取消
    case operateClick(action: OperateAction, isOnlyCamera: Bool?)
    case attachmentChooseViewShow
    //camera: 拍摄, album: 相册, file：本地文件,cancel：取消
    case attachmentChooseViewClick(action: ChooseViewClickAction)
    
    enum OperateAction: String {
        case add
        case delete
        case upload
    }
    
    enum ChooseViewClickAction: String {
        case camera
        case album
        case file
        case cancel
    }
}

protocol BTUploadMediaDelegate: AnyObject {
    func newLogAttachmentEvent(_ event: AttachmentLogEvent)
    func didFinishPickingMedia(content: SKPickContent, forFieldID: String)
    func didFinishNewPickingMedia(results: [MediaResult], forFieldID: String)
}

final class BTAttachmentEditAgent: BTBaseEditAgent, SKPickMediaDelegate {
    
    weak var delegate: BTUploadMediaDelegate?
    
    private var pickMediaManager: SuiteViewProvider?

    var hasActiveUploads = false

    private var scenario: AudioSessionScenario?

    private let audioQueue = DispatchQueue(label: "asset.picker.docs.view.queue")
    
    private let compressLibraryDir = "drive/drive_upload_caches/media"
    
    private var cameraPhotoDidQuitEdittingBlock: (() -> Void)?
    
    private var cameraPhotoDidFinishEdittingBlock: ((UIImage) -> Void)?
    
    let disposeBag = DisposeBag()

    private lazy var cancelBtn: UIButton = UIButton(type: .custom).construct { (it) in
        it.rx.tap
            .subscribe(onNext: { [weak self]_ in
                self?.stopEditing(immediately: false)
            })
            .disposed(by: disposeBag)
    }

    init(fieldID: String, recordID: String, delegate: BTUploadMediaDelegate) {
        super.init(fieldID: fieldID, recordID: recordID)
        self.delegate = delegate
    }

    override var editType: BTFieldType { .attachment }

    override func startEditing(_ cell: BTFieldCellProtocol) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard checkUploadPermission() else { return }
        } else {
            guard legacyCheckUploadPermission() else { return }
        }
        let bindField = relatedVisibleField as? BTFieldAttachmentCellProtocol
        if bindField?.onlyCamera == true {
            openCamera()
        } else {
            showAttachmentSelectActionSheet(coordinator?.attachedController, bindField)
        }
    }

    private func checkUploadPermission() -> Bool {
        let service: UserPermissionService
        if UserScopeNoChangeFG.YY.bitableReferPermission, let referService = coordinator?.viewModel.baseContext.permissionService {
            service = referService
        } else {
            guard let hostService = coordinator?.viewModel.baseContext.hostPermissionService else {
                spaceAssertionFailure("failed to fallback to host permission service")
                return false
            }
            service = hostService
        }
        let response = service.validate(operation: .uploadAttachment)
        response.didTriggerOperation(controller: inputSuperview.affiliatedViewController ?? UIViewController())
        return response.allow
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckUploadPermission() -> Bool {
        var docType = DocsType.bitable
        var token = coordinator?.editorDocsInfo.token
        if UserScopeNoChangeFG.YY.bitableReferPermission, let permissionObj = coordinator?.viewModel.baseContext.permissionObj {
            docType = permissionObj.objType
            token = permissionObj.objToken
        }
        let validation = CCMSecurityPolicyService.syncValidate(
            entityOperate: .ccmAttachmentUpload,
            fileBizDomain: .ccm,
            docType: docType,
            token: token
        )
        guard validation.allow else {
            switch validation.validateSource {
            case .fileStrategy:
                DocsLogger.error("attachment upload validation failed with file strategy")
                CCMSecurityPolicyService.showInterceptDialog(
                    entityOperate: .ccmAttachmentUpload,
                    fileBizDomain: .ccm,
                    docType: docType,
                    token: token
                )
            case .securityAudit:
                DocsLogger.error("attachment upload validation failed with security audit")
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: inputSuperview.window ?? UIView())
                spaceAssertionFailure("attachment upload validation failed with security audit")
            case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                DocsLogger.info("unknown type or dlp type")
            }
            return false
        }
        return true
    }

    override func stopEditing(immediately: Bool, sync: Bool = false) {
        let bindField = relatedVisibleField as? BTFieldAttachmentCellProtocol
        bindField?.stopEditing()
        baseDelegate?.didCloseEditPanel(self, payloadParams: nil)
        coordinator?.invalidateEditAgent()
        if bindField?.onlyCamera == false {
            cancelBtn.removeFromSuperview()
        }
    }
    
    deinit {
        pickMediaManager?.pickSuiteView?.removeFromSuperview()
        DocsLogger.info("BTAttachmentEditAgent - deinit", component: LogComponents.bitable)
    }
    
    func showAttachmentSelectActionSheet(_ rootVC: UIViewController?, _ bindField: BTFieldAttachmentCellProtocol?) {
        var popSource: UDActionSheetSource?
        if SKDisplay.pad {
            if let sourveView = bindField {
                popSource = UDActionSheetSource(sourceView: sourveView.sourceAddView,
                                                sourceRect: sourveView.sourceAddRect,
                                                arrowDirection: [.left, .right])
            }
        }
        
        let actionSheet = UDActionSheet.actionSheet(title: BundleI18n.SKResource.Bitable_Attachment_UploadMethod, popSource: popSource, dismissedByTapOutside: { [weak self] in
            self?.delegate?.newLogAttachmentEvent(.attachmentChooseViewClick(action: .cancel))
            self?.stopEditing(immediately: false)
        })
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_Camera, style: .default) { [weak self] in
            self?.delegate?.newLogAttachmentEvent(.attachmentChooseViewClick(action: .camera))
            self?.openCamera()
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_Photo, style: .default) { [weak self] in
            self?.delegate?.newLogAttachmentEvent(.attachmentChooseViewClick(action: .album))
            self?.setUpPickMediaManager(rootVC: rootVC)
            self?.pickMediaManager?.pickSuiteView?.showPhotoLibrary(selectedItems: [], useOriginal: false)
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Attachment_LocalFile, style: .default) { [weak self] in
            self?.delegate?.newLogAttachmentEvent(.attachmentChooseViewClick(action: .file))
            self?.showDocumentPicker(from: rootVC)
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, style: .cancel) {[weak self] in
            self?.delegate?.newLogAttachmentEvent(.attachmentChooseViewClick(action: .cancel))
            self?.stopEditing(immediately: false)
        }
        self.delegate?.newLogAttachmentEvent(.attachmentChooseViewShow)
        rootVC?.present(actionSheet, animated: true, completion: nil)
    }
    
    func setUpPickMediaManager(rootVC: UIViewController?) {
        guard pickMediaManager == nil else {
            return
        }
        if LKFeatureGating.ccmDriveMobileVideoCompress {
            let path = SKFilePath.driveLibraryDir.appendingRelativePath(compressLibraryDir)
            try? path.createDirectoryIfNeeded(withIntermediateDirectories: true)
            let suiteConfig = CommonPickMediaConfig(rootVC: rootVC,
                                                    path: path,
                                                    sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                                    isOriginButtonHidden: false)
            let suiteViewConfig = SuiteViewConfig(assetType: .imageOrVideo(imageMaxCount: 9, videoMaxCount: 9), cameraType: .custom(true))
            pickMediaManager = CommonPickMediaManager(delegate: self,
                                                      suiteConfig,
                                                      suiteViewConfig: suiteViewConfig)
        } else {
            pickMediaManager = SKPickMediaManager(delegate: self,
                                                  assetType: .imageOrVideo(imageMaxCount: 9, videoMaxCount: 9),
                                                  cameraType: .custom(true),
                                                  rootVC: rootVC)
        }
        pickMediaManager?.pickSuiteView?.cameraVCDidDismiss = {[weak self] in
            self?.stopEditing(immediately: false)
        }
        pickMediaManager?.pickSuiteView?.imagePickerVCDidCancel = {[weak self] in
            self?.stopEditing(immediately: false)
        }
        if let suiteView = pickMediaManager?.pickSuiteView {
            inputSuperview.addSubview(suiteView)
            suiteView.frame = .zero
            suiteView.clipsToBounds = true
        }
    }
    
    func openCamera() {
        setUpPickMediaManager(rootVC: coordinator?.attachedController)
        pickMediaManager?.pickSuiteView?.takePhoto()
    }

    private func showDocumentPicker(from rootVC: UIViewController?) {
        let documentPicker = DocsDocumentPickerViewController(deletage: self)
        if SKDisplay.pad {
            documentPicker.modalPresentationStyle = .formSheet
        }
        rootVC?.present(documentPicker, animated: false, completion: nil)
    }
}

extension BTAttachmentEditAgent {
    func didFinishPickingMedia(params: [String: Any]) {
        stopEditing(immediately: false)
        DocsLogger.btInfo("[DATA] bt attachment selection result: \(params)")
        guard let content = params[SKPickContent.pickContent] as? SKPickContent else {
            DocsLogger.btInfo("[DATA] no picked content detected")
            return
        }
        let bindField = relatedVisibleField as? BTFieldAttachmentCellProtocol
        delegate?.newLogAttachmentEvent(.operateClick(action: .upload, isOnlyCamera: bindField?.onlyCamera ?? false))
        delegate?.didFinishPickingMedia(content: content, forFieldID: fieldID)
    }
}

extension BTAttachmentEditAgent: ImageEditViewControllerDelegate {
    public func closeButtonDidClicked(vc: EditViewController) {
        DocsLogger.info("AttachmentEditAgent closeButtonDidClicked", component: LogComponents.bitable)
        self.cameraPhotoDidQuitEdittingBlock?()
        vc.exit()
    }

    public func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) {
        DocsLogger.info("AttachmentEditAgent finishButtonDidClicked", component: LogComponents.bitable)
        do {
            try Utils.savePhoto(token: Token(PSDATokens.Bitable.bitable_edita_image_click_upload), image: editImage) { _, _ in }
        } catch {
            DocsLogger.error("Utils savePhoto error")
        }
        DispatchQueue.main.async {
            vc.exit()
            self.cameraPhotoDidFinishEdittingBlock?(editImage)
        }
    }
}

extension BTAttachmentEditAgent: DocsDocumentPickerDelegate {
    func pickDocumentFinishSelect(urls: [URL]) {
        if isConatinLimitedSizeFile(urls: urls) {
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Download_UploadAttachmentExceedMax_Toast(2), on: self.inputSuperview.window ?? UIView())
            return
        }
        didFinishPickingMedia(params: [SKPickContent.pickContent: SKPickContent.iCloudFiles(fileURLs: urls)])
    }
    
    func pickDocumentDidCancel() {
        stopEditing(immediately: false)
    }
    
    func isConatinLimitedSizeFile(urls: [URL]) -> Bool {
        return urls.contains { (url) -> Bool in
            if let size = SKFilePath(absPath: url.path).fileSize, size > BTUploadMediaHelper.attachmentLimitedSize {
                return true
            }
            return false
        }
    }
}
extension BTAttachmentEditAgent: PickMediaDelegate {
    func didFinishPickingMedia(results: [MediaResult]) {
        self.delegate?.didFinishNewPickingMedia(results: results, forFieldID: fieldID)
        if !UserScopeNoChangeFG.ZJ.btItemViewAttachmentFieldEditFixDisable {
            self.stopEditing(immediately: false)
        }
    }
}

extension SKPickMediaManager: SuiteViewProvider {
    var pickSuiteView: SKAssuiteView? {
        return suiteView
    }
    
}

extension CommonPickMediaManager: SuiteViewProvider {
    var pickSuiteView: SKAssuiteView? {
        return self.skSuiteView
    }
}
