//
//  DKPreviewVCFactory.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/28.
//

import Foundation
import SKCommon
import SKFoundation
import LarkFoundation
import RxSwift
import RxCocoa
import CoreMedia
import PDFKit
import LarkDocsIcon
import SpaceInterface

struct DKPreviewVCFactoryContext {
    let mainVC: BaseViewController?
    let hostModule: DKHostModuleType?
    let delegate: DriveBizViewControllerDelegate?
    let areaCommentDelegate: DriveAreaCommentDelegate?
    let screenModeDelegate: DrivePreviewScreenModeDelegate?
    let isiOSAppOnMacSystem: Bool
    let previewFromScene: DrivePreviewFrom?
    let permissionService: UserPermissionService
    let disposeBag: DisposeBag
}

class DKPreviewVCFactory {
    private let isiOSAppOnMacSystem: Bool
    private var previewFromScene: DrivePreviewFrom?
    private weak var bizDelegate: DriveBizViewControllerDelegate?
    private weak var parentVC: BaseViewController?
    private weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private weak var areaCommentDelegate: DriveAreaCommentDelegate?
    private weak var hostModule: DKHostModuleType?
    private var editable = BehaviorRelay<Bool>(value: false)
    private var canComment = BehaviorRelay<Bool>(value: false)
    private var canCopy = BehaviorRelay<Bool>(value: false)
    private let bag: DisposeBag

    private let sameTenantRelay = BehaviorRelay<Bool>(value: false)
    private let permissionService: UserPermissionService

    init(context: DKPreviewVCFactoryContext) {
        self.isiOSAppOnMacSystem = context.isiOSAppOnMacSystem
        self.previewFromScene = context.previewFromScene
        self.bizDelegate = context.delegate
        self.parentVC = context.mainVC
        self.screenModeDelegate = context.screenModeDelegate
        self.areaCommentDelegate = context.areaCommentDelegate
        self.hostModule = context.hostModule
        self.permissionService = context.permissionService
        self.bag = context.disposeBag
        bindPermissions()
        if let hostModule {
            hostModule.docsInfoRelay.map(\.isSameTenantWithOwner).bind(to: sameTenantRelay).disposed(by: bag)
        }
    }
    
    private func bindPermissions() {
        if !UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            bindLegacyPermissions()
            return
        }
        let isHistory = (hostModule?.commonContext.previewFrom == .history)
        let isSpaceFile = (hostModule?.scene == .space)
        let service = permissionService
        let permissionUpdated = service.onPermissionUpdated.compactMap { [weak service] _ in
            service
        }

        permissionUpdated.map { service in
            service.validate(operation: .edit).allow
        }
        .bind(to: editable).disposed(by: bag)

        permissionUpdated.map { service in
            service.validate(operation: .comment).allow && !isHistory && isSpaceFile
        }
        .bind(to: canComment).disposed(by: bag)

        permissionUpdated.map { service in
            service.validate(operation: .copyContent).allow
        }
        .do(onDispose: {
            DocsLogger.driveDebug("preview vc factory observe permission update disposed")
        })
        .bind(to: canCopy).disposed(by: bag)
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func bindLegacyPermissions() {
        if let hostModule {
            let isHistory = (hostModule.commonContext.previewFrom == .history)
            let isSpaceFile = (hostModule.scene == .space)
            hostModule.permissionRelay.map({ info in
                DocsLogger.driveInfo("can edit \(info.isEditable)")
                return info.isEditable
            }).bind(to: editable).disposed(by: bag)
            hostModule.permissionRelay.map({ info in
                return info.canComment && !isHistory && isSpaceFile
            }).bind(to: canComment).disposed(by: bag)
            hostModule.permissionRelay.map({ info in
                DocsLogger.driveInfo("can copy \(info.canCopy)")
                return info.canCopy
            }).bind(to: canCopy).disposed(by: bag)
        } else { // IM 场景没有 hostModule
            editable.accept(false)
            canComment.accept(false)
            canCopy.accept(true)
        }
    }
    // previewFileType: 实际预览的文件类型
    func previewVC(previewInfo: DKFilePreviewInfo, previewFileType: DriveFileType, isInVCFollow: Bool) -> UIViewController? {
        switch previewInfo {
        case .linearizedImage(let dependency):
            guard let displaySize = parentVC?.view.frame.size else {
                assertionFailure()
                return nil
            }
            var skipCellularCheck = false /* 图片不支持在 follow 中预览，暂时写死不跳过检查 */
            if hostModule?.currentDisplayMode == .card {
                skipCellularCheck = true
            }

            let downloader = DriveImageDownloader(dependency: dependency,
                                                  skipCellularCheck: skipCellularCheck,
                                                  displaySize: displaySize)
            let viewModel = DriveLinearizedImageViewModel(downloader: downloader)
            return linearizedImageVC(viewModel: viewModel)
        case .archive(let viewModel):
            return archivePreviewVC(viewModel: viewModel)
        case let .local(data):
            return localPreviewVC(localData: data, previewFileType: previewFileType, isInVCFollow: isInVCFollow)
        case .streamVideo(let video):
            return videoPlayerVC(video: video, isInVCFollow: isInVCFollow)
        case let .localMedia(url, video):
            return playLocalMediaVC(url: url, video: video, previewFileType: previewFileType, isInVCFollow: isInVCFollow)
        case .webOffice(let info):
            return wpsPreviewVC(info: info)
        case .excelHTML(let info):
            return excelHtmlPreivewVC(info: info)
        case let .thumbnail(dependency):
            return thumbImageVC(dependency: dependency)
        }
    }
    
    // 除音视频外的其他本地预览
    private func localPreviewVC(localData: DKFilePreviewInfo.LocalPreviewData, previewFileType: DriveFileType, isInVCFollow: Bool) -> UIViewController? {
        if canOpenWithWebview(type: previewFileType) && !isiOSAppOnMacSystem {
            // iwork在卡片模式下全屏后空白，先展示不支持
            if previewFileType.isIWork && hostModule?.isFromCardMode == true {
                DocsLogger.driveInfo("DKPreviewVCFactory -- card mode not support iwork")
                return nil
            }
            return webPreviewVC(url: localData.url)
        } else if previewFileType.isText {
            return textPreviewVC(url: localData.url)
        } else if previewFileType == .gif {
            return gifPreviewVC(url: localData.url)
        } else if previewFileType.isSupportMultiPics {
            return localImageVC(url: localData.url)
        } else if previewFileType == .pdf {
            if canPreviewWithPDFKit(path: localData.url) {
                return pdfPreviewVC1(data: localData, isInVCFollow: isInVCFollow)
            } else if let vc = parentVC {
                // 使用QuickLook打开需要将父VC设置为不显示水印
                return quickLookPreviewVC(url: localData.url, parentVC: vc)
            } else {
                DocsLogger.driveInfo("DKPreviewVCFactory -- pdf using quicklook has no parentVC")
                return nil
            }
        } else if previewFileType.isArchive {
            return archiveLocalPreviewVC(data: localData)
        } else if DriveQLPreviewController.canPreview(localData.url.pathURL), let vc = parentVC {
            // 卡片模式下iwork和svg显示不支持， 各种特化逻辑
            if typeNotSupportInCardmode(type: previewFileType) && hostModule?.isFromCardMode == true {
                DocsLogger.driveInfo("DKPreviewVCFactory -- card mode not support iwork")
                return nil
            }
            // 使用QuickLook打开需要将父VC设置为不显示水印
            return quickLookPreviewVC(url: localData.url, parentVC: vc)
        } else {
            spaceAssertionFailure("missing preview hander")
            DocsLogger.error("drive preview: missing preview hander")
            return nil
        }
    }
    
    // pdf预览
    private func pdfPreviewVC1(data: DKFilePreviewInfo.LocalPreviewData, isInVCFollow: Bool) -> UIViewController {
        var config: DrivePDFViewModel.Config
        
        if isInVCFollow && data.originFileType.isPPT {
            if let isPreviousInPresentationMode = bizDelegate?.context?[DrivePDFViewController.contextPresentationModeKey] as? Bool {
                // 如果之前已经在演示模式下（如 VC Follow 场景下刷新），则保留演示模式，否则不自动进入演示模式
                config = isPreviousInPresentationMode ? .presentationPPTMode : .normalPPTMode
            } else {
                // 初始默认 Normal (三端对齐，加载完毕后只有是主讲人才会自动进入演示模式)
                config = .normalPPTMode
            }
        } else if data.originFileType.isPPT {
            // 文件类型是 PPT 才会展示演示模式按钮
            config = .normalPPTMode
        } else {
            config = .default
        }
        // 文档附件场景隐藏演示模式按钮
        if data.previewFrom.isAttachment {
            config = .default
        }
        config.minScale = DriveFeatureGate.pdfMinScale
        config.maxScale = DriveFeatureGate.pdfMaxScale
        
        let pageNumber = bizDelegate?.pageNumber

        let viewModel = DrivePDFViewModel(fileURL: data.url,
                                          hostToken: hostModule?.hostToken,
                                          canCopy: canCopy,
                                          canEdit: editable,
                                          config: config,
                                          originFileType: data.originFileType.rawValue,
                                          fileToken: hostModule?.fileInfoRelay.value.fileToken,
                                          copyManager: DriveCopyMananger(previewFrom: previewFromScene,
                                                                         sameTenantRelay: sameTenantRelay,
                                                                         permissionService: permissionService),
                                          pageNumer: pageNumber,
                                          pageNumberChangedReleay: hostModule?.pdfAIBridge,
                                          pdfInlineAIAction: hostModule?.pdfInlineAIAction)
        viewModel.additionalStatisticParameters = data.additionalStatisticParameters
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let bizVC = DrivePDFViewController(viewModel: viewModel, displayMode: mode)
        bizVC.bizVCDelegate = bizDelegate
        
        bizVC.screenModeDelegate = screenModeDelegate
    
        return bizVC
    }

    // 文本浏览器
    private func textPreviewVC(url: SKFilePath) -> UIViewController {
        let vm = DriveTextPreviewViewModel(fileURL: url,
                                           token: hostModule?.fileInfoRelay.value.fileToken,
                                           hostToken: hostModule?.hostToken,
                                           canEdit: editable,
                                           canCopy: canCopy,
                                           copyMananger: DriveCopyMananger(previewFrom: previewFromScene,
                                                                           sameTenantRelay: sameTenantRelay,
                                                                           permissionService: permissionService))
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveTextViewController(viewModel: vm, displayMode: mode)
        vc.bizVCDelegate = bizDelegate
        return vc
    }
    
    // 网页浏览器
    private func webPreviewVC(url: SKFilePath) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveWebViewController(fileURL: url,
                                        token: hostModule?.fileInfoRelay.value.fileToken,
                                        hostToken: hostModule?.hostToken,
                                        displayMode: mode,
                                        canCopy: canCopy,
                                        canEdit: editable, copyManager: DriveCopyMananger(previewFrom: previewFromScene,
                                                                                          sameTenantRelay: sameTenantRelay,
                                                                                          permissionService: permissionService))
        vc.bizVCDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        return vc
    }

    // MARK: - Image
    /// 线性图片在线预览
    private func linearizedImageVC(viewModel: DriveLinearizedImageViewModel) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveImageViewController(viewModel: viewModel, canComment: canComment, displayMode: mode)
        vc.canComment = canComment.value
        vc.bizDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        vc.areaCommentDelegate = areaCommentDelegate
        return vc
    }
    
    /// 本地图片预览
    private func localImageVC(url: SKFilePath) -> UIViewController {
        let viewModel = DriveLocalImageViewModel(url: url)
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveImageViewController(viewModel: viewModel, canComment: canComment, displayMode: mode)
        vc.bizDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        vc.areaCommentDelegate = areaCommentDelegate
        vc.canComment = canComment.value
        return vc
    }
    
    /// 缩略图预览流程
    private func thumbImageVC(dependency: DriveThumbImageViewModelDepencency) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vm = DriveThumbImageViewModel(dependency: dependency)
        let vc = DriveImageViewController(viewModel: vm, canComment: canComment, displayMode: mode)
        vc.bizDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        vc.areaCommentDelegate = areaCommentDelegate
        vc.canComment = canComment.value
        return vc
    }
    
    /// GIF预览
    private func gifPreviewVC(url: SKFilePath) -> UIViewController {
        let vm = DriveGIFPreviewViewModel(fileURL: url)
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveGIFPreviewController(viewModel: vm, displayMode: mode)
        vc.bizVCDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        return vc
    }

    // MARK: - Media
    private func playLocalMediaVC(url: SKFilePath, video: DriveVideo, previewFileType: DriveFileType, isInVCFollow: Bool) -> UIViewController {
        if let codec = url.getVideoCodecType(), codec == "mp4v" {
            DocsLogger.driveInfo("DKPreviewVCFactory -- mp4v with avplayer")
            return avPlayerVC(url: url, video: video, isInVCFollow: isInVCFollow)
        } else if previewFileType.isVideo && previewFileType.isTTPlayerSupport {
            DocsLogger.driveInfo("DKPreviewVCFactory -- ttplayer support type")
            return videoPlayerVC(video: video, isInVCFollow: isInVCFollow)
        } else {
            DocsLogger.driveInfo("DKPreviewVCFactory -- ttplayer unsupport type with avplayer")
            return avPlayerVC(url: url, video: video, isInVCFollow: isInVCFollow)
        }
    }
    /// 本地视频打开，使用原生播放器
    private func avPlayerVC(url: SKFilePath, video: DriveVideo, isInVCFollow: Bool) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vm = DriveVideoPlayerViewModel(video: video, player: DriveAVPlayer(url: url.pathURL), displayMode: mode, isInVCFollow: isInVCFollow)
        let vc = DriveVideoPlayerViewController(viewModel: vm)
        vc.portraitFullScreenModeEnable = false
        // VCFollow 下禁止横版视频进入全屏模式
        // VC 嵌套在 VCFollow 内，横屏是通过旋转动画然后更新播放器页面约束为整个屏幕的 Window，会导致横屏后横屏按钮被盖住的情况，目前暂时隐藏
        vc.landscapeModeEnable = !isInVCFollow
        vc.bizVCDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        return vc
    }

    /// 本地视频打开/在线视频，使用头条播放器
    private func videoPlayerVC(video: DriveVideo, isInVCFollow: Bool) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let fileInfo = hostModule?.fileInfoRelay.value
        let vm = DriveVideoPlayerViewModel(video: video,
                                           player: DriveTTVideoPlayer(),
                                           displayMode: mode,
                                           isInVCFollow: isInVCFollow,
                                           fileInfo: fileInfo)
        let vc = DriveVideoPlayerViewController(viewModel: vm)
        vc.portraitFullScreenModeEnable = true
        vc.landscapeModeEnable = !isInVCFollow
        vc.bizVCDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        return vc
    }

    // MARK: - Zip
    /// 压缩文件预览器
    private func archivePreviewVC(viewModel: DriveArchivePreviewViewModel) -> UIViewController {
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveArchivePreviewController(viewModel: viewModel, displayMode: mode)
        vc.bizDelegate = bizDelegate
        return vc
    }
    
    private func archiveLocalPreviewVC(data: DKFilePreviewInfo.LocalPreviewData) -> UIViewController {
        let viewModel = DriveArchiveLocalPreviewViewModel(url: data.url,
                                                          fileName: data.fileName,
                                                          previewFrom: .localFile,
                                                          additionalStatisticParameters: data.additionalStatisticParameters)
        let vc = DriveArchivePreviewController(viewModel: viewModel, displayMode: .normal)
        vc.bizDelegate = bizDelegate
        return vc
    }

    // MARK: - QuickLook
    /// 兜底 quikLookVC
    private func quickLookPreviewVC(url: SKFilePath, parentVC: UIViewController) -> UIViewController? {
        guard let baseVC = parentVC as? BaseViewController else {
                DocsLogger.error("parentVC is Not subClass of BaseViewController")
                spaceAssertionFailure("parentVC is Not subClass of BaseViewController")
                return nil
        }
        // PDF/ Office等不能显示水印，否则会出现卡死
        baseVC.watermarkConfig.needAddWatermark = false
        let vc = DriveQLPreviewController(fileURL: url)
        vc.bizVCDelegate = bizDelegate
        return vc
    }
    
    // MARK: - WPS
    /// 在线 WPS 预览
    private func wpsPreviewVC(info: DriveWPSPreviewInfo) -> UIViewController {
        var newInfo = info
        if let scene = hostModule?.scene {
            switch scene {
            case .attach:
                // 第三方附件预览不支持编辑
                newInfo.isEditable = BehaviorRelay(value: false)
            case .space:
                // 云空间文件绑定编辑权限
                newInfo.isEditable = editable
            case .im:
                // IM 附件编辑能力由外部传入
                break
            }
        }
        newInfo.permissionInfo = hostModule?.permissionRelay
        newInfo.docsInfo = hostModule?.docsInfoRelay
        var presentationModeEnable = true
        if hostModule?.statisticsService.previewFrom.isAttachment == true {
            // 文档附件场景 PPT 不开启演示模式功能
            presentationModeEnable = false
        }
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveWPSPreviewController(previewInfo: newInfo, displayMode: mode,
                                           presentationModeEnable: presentationModeEnable)
        vc.bizVCDelegate = bizDelegate
        vc.screenModeDelegate = screenModeDelegate
        return vc
    }
    
    // MARK: - Html
    private func excelHtmlPreivewVC(info: DriveHTMLPreviewInfo) -> UIViewController {
        let htmlPreviewViewModel = DriveHTMLPreviewViewModel(htmlInfo: info,
                                                             hostToken: hostModule?.hostToken,
                                                             canEdit: editable,
                                                             copyManager: DriveCopyMananger(previewFrom: previewFromScene,
                                                                                            sameTenantRelay: sameTenantRelay,
                                                                                            permissionService: permissionService))
        let mode: DrivePreviewMode = hostModule?.currentDisplayMode ?? .normal
        let vc = DriveHtmlPreviewViewController(viewModel: htmlPreviewViewModel, displayMode: mode)
        vc.bizVCDelegate = bizDelegate
        return vc
    }
}

// helper
extension DKPreviewVCFactory {
    func canPreviewWithPDFKit(path: SKFilePath) -> Bool {
        guard let document = PDFDocument(url: path.pathURL) else {
            DocsLogger.driveInfo("cannot initialize pdf document")
            // 仍然使用pdfkit打开，错误让pdfviewcontroller 上报
            return true
        }
        
        guard let fileSize = path.fileSize else {
            DocsLogger.error("drive.pdfkit --- no page in document")
            // 仍然使用pdfkit打开，错误让pdfviewcontroller 上报
            return true
        }

        let size = sizePerPage(document: document, fileSize: fileSize)
        if size > DriveFeatureGate.pdfkitMaxSizePerPage {
            return false
        }
        return true
    }
    
    private func sizePerPage(document: PDFDocument, fileSize: UInt64) -> UInt64 {
        guard document.pageCount > 0 else { return 0 }
        return fileSize / UInt64(document.pageCount)
    }
    
    func typeNotSupportInCardmode(type: DriveFileType) -> Bool {
        // svg和iwork使用quicklook打开无法响应单击进入全屏态事件，在卡片态显示不支持
        return type.isIWork || type == .svg
    }
    
    // office iwork和svg优先使用webview打开，在卡片模式下不会影响点击事件
    // 使用quicklook打开卡片模式下无法响应点击事件进入全屏
    func canOpenWithWebview(type: DriveFileType) -> Bool {
        return type.isOffice || type == .svg
    }
}
