//
//  DriveVCFactory.swift
//  SKDrive
//
//  Created by Huang JinZhu on 2018/7/5.

import UIKit
import SwiftyJSON
import SpaceInterface
import LarkUIKit
import LarkSplitViewController
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import RxRelay
import UniverseDesignToast
import SKInfra
import LarkDocsIcon

// TODO: 和 DriveRouter 合并
public final class DriveVCFactory: DriveVCFactoryType {

    public static let shared = DriveVCFactory()

    private init() {
        
    }

    public func openDriveFileWithOtherApp(file: SpaceEntry,
                                          originName: String?,
                                          sourceController: UIViewController,
                                          sourceRect: CGRect?,
                                          arrowDirection: UIPopoverArrowDirection,
                                          previewFrom: DrivePreviewFrom = .docsList) {
        let meta = makeDriveFileMeta(file: file, originName: originName)
        // 调用方需要保证鉴权完整，这里的兜底鉴权没有用户权限维度的数据，考虑去掉
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
                spaceAssertionFailure("PermissionSDK not found")
                return
            }
            let request = PermissionRequest(token: file.objToken,
                                            type: .file,
                                            operation: .openWithOtherApp,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: sourceController)
            guard response.allow else { return }
        } else {
            let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                                               docType: .file, token: file.objToken)
            if !result.allow && result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: .ccm, docType: .file, token: file.objToken)
                return
            } else if !result.allow && result.validateSource == .securityAudit {
                UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage,
                                 on: sourceController.view.window ?? sourceController.view)
                return
            }
        }
        let sourceParam = ActivityAnchorParam(sourceController: sourceController,
                                              sourceView: nil,
                                              sourceRect: sourceRect,
                                              arrowDirection: arrowDirection)
        let open3rdAppContext = OpenInOtherAppContext(fileMeta: meta,
                                                      sourceParam: sourceParam,
                                                      isLatest: true,
                                                      actionSource: .unknow,
                                                      previewFrom: previewFrom,
                                                      skipCellularCheck: false,
                                                      additionalParameters: nil,
                                                      appealAlertFrom: .unknown)
        DriveRouter.openWith3rdApp(context: open3rdAppContext)
        DocsLogger.debug("DocsList-openDriveFileWithOtherApp param file: \(meta)")
    }
    
    public func saveToLocal(file: SpaceEntry,
                            originName: String?,
                            sourceController: UIViewController,
                            previewFrom: DrivePreviewFrom = .docsList) {
        let meta = makeDriveFileMeta(file: file, originName: originName)
        let info = DriveFileInfo(fileMeta: meta)
        let params = ["scene": previewFrom.rawValue, "click": "download", "target": "none"]
        DriveStatistic.reportEvent(DocsTracker.EventType.spaceRightClickMenuClick, fileId: info.fileID, fileType: info.type, params: params)
        DriveRouter.saveToLocal(fileInfo: info, from: sourceController, appealAlertFrom: .driveDetailSideSlipDownload)
        DocsLogger.debug("DocsList-downloadDriveFileToLocal param file: \(meta)")
    }
    
    public func saveToLocal(data: [String: Any],
                            fileToken: String,
                            mountNodeToken: String,
                            mountPoint: String,
                            fromVC: UIViewController,
                            previewFrom: DrivePreviewFrom = .docsList) {
        guard let info = DriveFileInfo(data: data,
                                 fileToken: fileToken,
                                 mountNodeToken: mountNodeToken,
                                 mountPoint: mountPoint) else {
            return
        }
        let params = ["scene": previewFrom.rawValue, "click": "download", "target": "none"]
        DriveStatistic.reportEvent(DocsTracker.EventType.spaceRightClickMenuClick, fileId: info.fileID, fileType: info.type, params: params)
        DriveRouter.saveToLocal(fileInfo: info, from: fromVC, appealAlertFrom: .unknown)
        DocsLogger.debug("DocsList-downloadDriveFileToLocal param file: \(info)")
    }

    /// Docs List 进入Drive预览
    ///
    /// - Parameters:
    ///     - file:SpaceEntry
    ///     - fileList:[SpaceEntry]
    ///     - from:DrivePreviewFrom
    ///     - statisticInfo: 埋点数据
    /// - Returns: DrivePreviewController
    public func makeDrivePreview(file: SpaceEntry, fileList: [SpaceEntry], from: DrivePreviewFrom?, statisticInfo: [String: String]) -> UIViewController {
        DocsLogger.debug("""
            DocsList-makeDrivePreview param
            fileToken: \(file.objToken),
            fileType: \(String(describing: file.fileType))
            """)
        guard DriveFeatureGate.driveEnabled else {
            if let hostWindow = DriveRouter.viewControllerForDriveRouter()?.view.window {
                UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage,
                                    on: hostWindow)
            }
            return ContinuePushedVC()
        }
        if fileList.count == 0 {
            return makeDrivePreviewCore(from: from ?? .docsList, file: file, fileList: [file], feedId: nil, statisticInfo: statisticInfo)
        } else {
            return makeDrivePreviewCore(from: from ?? .docsList, file: file, fileList: fileList, feedId: nil, statisticInfo: statisticInfo)
        }
    }

    /// Lark feed open url
    ///
    /// - Parameter url: URL
    /// - Paraeter context: extra infos
    /// - Returns: DrivePreviewController
    public func makeDrivePreview(url: URL, context: [String: Any]?) -> UIViewController {
        guard DriveFeatureGate.driveEnabled else {
            if let hostWindow = DriveRouter.viewControllerForDriveRouter()?.view.window {
                UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage,
                                    on: hostWindow)
            }
            return ContinuePushedVC()
        }
        // 新接口从context取previewFrom,当前只有Docs附件使用新接口，from值为"docs_attach"， 数据上报用
        // 旧接口从URL参数取previewFrom:
        //      1. lark聊天界面跳转: from = message, 不做特殊处理
        //      2. Docs drive链接: from = tab_link, 数据上报
        guard let previewContext = context,
              let fromValue = previewContext["from"] as? String,
              let from = DrivePreviewFrom(rawValue: fromValue) else {
            return makeDrivePreview(from: nil, url: url, context: context)
        }
        return makeDrivePreview(from: from, url: url, context: previewContext)
    }
    
    public func makeDriveLocalPreview(files: [DriveLocalFileEntity], index: Int) -> UIViewController? {
        let localFiles = files.map { (localFile) -> DriveSDKLocalFileV2 in
            let moreVisable: Observable<Bool> = localFile.moreActions.count > 0 ? .just(true) : .just(false)
            let more = DKLocalFileDefaultMoreDependencyImpl(localActions: localFile.moreActions, moreMenueVisable: moreVisable, moreMenuEnable: .just(true))
            let action = DKLocalFileDefaultActionDependencyImpl()
            let dependency = DKLocalFileDefaultDependency(actionDependency: action, moreDependency: more)
            let name = localFile.name ?? localFile.absFilePath.getFileName()
            let file = DriveSDKLocalFileV2(fileName: name,
                                           fileType: localFile.fileType,
                                           fileURL: localFile.fileURL,
                                           fileId: localFile.fileID ?? "",
                                           dependency: dependency)
            return file
        }

        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
        return DocsContainer.shared.resolve(DriveSDK.self)!.createLocalFileController(localFiles: localFiles,
                                                                               index: index,
                                                                               appID: DKSupportedApp.mail.rawValue,
                                                                               thirdPartyAppID: nil,
                                                                               naviBarConfig: naviBarConfig)
    }
    
    public func makeDriveThirdPartyPreview(files: [DriveThirdPartyFileEntity],
                                           index: Int,
                                           moreActions: [DriveAlertVCAction],
                                           isInVCFollow: Bool,
                                           bussinessId: String) -> UIViewController {
        guard DriveFeatureGate.driveEnabled else {
            if let hostWindow = DriveRouter.viewControllerForDriveRouter()?.view.window {
                UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage,
                                    on: hostWindow)
            }
            return ContinuePushedVC()
        }
        guard index >= 0, index < files.count else {
            spaceAssertionFailure("index out of ranged or files is empty")
            return UIViewController()
        }
        guard let previewFrom = DrivePreviewFrom(rawValue: bussinessId), let app = previewFrom.driveSDKApp else {
            spaceAssertionFailure("bussinessID has no appID")
            return UIViewController()
        }
        let files = files.map { (entity) -> DriveSDKAttachmentFile in
            let moreVisable: Observable<Bool> = moreActions.count > 0 ? .just(true) : .just(false)
            let actions: [DriveSDKMoreAction] = moreActions.map { $0.sdkMoreAction }
            let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .just(true))
            let action = DKAttachDefaultActionDependencyImpl()
            let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
            return DriveSDKAttachmentFile(fileToken: entity.fileToken,
                                          mountNodePoint: entity.mountNodePoint,
                                          mountPoint: entity.mountPoint,
                                          fileType: entity.fileType,
                                          name: nil,
                                          authExtra: entity.authExtra,
                                          urlForSuspendable: nil,
                                          dependency: dependency)
        }
        
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        return DocsContainer.shared.resolve(DriveSDK.self)!.createAttachmentFileController(attachFiles: files,
                                                                                           index: index,
                                                                                           appID: app.rawValue,
                                                                                           isCCMPermission: false,
                                                                                           isInVCFollow: isInVCFollow,
                                                                                           attachmentDelegate: nil,
                                                                                           naviBarConfig: naviBarConfig)
    }

    public func isDriveMainViewController(_ viewController: UIViewController) -> Bool {
        return viewController is DKMainViewController
    }

    public func makeImportToDriveController(file: SpaceEntry, actionSource: DriveStatisticActionSource, previewFrom: DrivePreviewFrom) -> UIViewController {
        // 用这个方法获取到loadingView，在docs里面是羽毛动画，在lark里面会被动态替换为小球撞来撞去的
        let loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
        return DriveConvertFileViewController(file: file,
                                              loadingView: loadingView,
                                              actionSource: actionSource,
                                              previewFrom: previewFrom)
    }

    private func makeDriveFileMeta(file: SpaceEntry, originName: String?) -> DriveFileMeta {
        return DriveFileMeta(size: file.fileSize,
                             name: originName ?? file.name,
                             type: file.fileType ?? "",
                             fileToken: file.objToken,
                             mountNodeToken: file.parent ?? "",
                             mountPoint: DriveConstants.driveMountPoint,
                             version: nil,
                             dataVersion: nil,
                             source: .other,
                             tenantID: file.ownerTenantID,
                             authExtra: nil)
    }

    private func makeDrivePreviewCore(from: DrivePreviewFrom,
                                      file: SpaceEntry,
                                      fileList: [SpaceEntry],
                                      feedId: String?,
                                      statisticInfo: [String: String] = [:]) -> UIViewController {
        var statisticInfo = statisticInfo
        if statisticInfo.isEmpty {
            statisticInfo = getStatisticInfo()
        }
        let driveFileEntryList = fileList.filter { $0.type == .file }
        let files: [DriveSDKAttachmentFile]
        let intialIndex: Int
        let driveFileType = DriveFileType(fileExtension: file.fileType)
        // 参考 DKMainViewModel 判断逻辑
        if driveFileType.isSupportMultiPics || driveFileType == .svg {
            files = driveFileEntryList.map(Self.convert(entry:))
            intialIndex = driveFileEntryList.firstIndex { entity in
                return entity.objToken == file.objToken
            } ?? 0
        } else {
            files = [Self.convert(entry: file)]
            intialIndex = 0
        }
        let context = [DKContextKey.from.rawValue: from.rawValue]
        return DocsContainer.shared.resolve(DriveSDK.self)!
            .createSpaceFileController(files: files,
                                       index: intialIndex,
                                       appID: DKSupportedApp.space.rawValue,
                                       isInVCFollow: false,
                                       context: context,
                                       statisticInfo: statisticInfo)
    }

    private static func convert(entry: SpaceEntry) -> DriveSDKAttachmentFile {
        // space的更多选项不需要外部配置
        let moreVisable: Observable<Bool> = .never()
        let actions: [DriveSDKMoreAction] = []
        let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .never())
        let action = DKAttachDefaultActionDependencyImpl()
        let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
        let docsInfo = entry.transform()
        return DriveSDKAttachmentFile(fileToken: entry.objToken,
                                      mountNodePoint: entry.parent,
                                      mountPoint: DriveConstants.driveMountPoint,
                                      fileType: entry.fileType,
                                      name: entry.name,
                                      authExtra: nil,
                                      urlForSuspendable: docsInfo.urlForSuspendable(),
                                      dependency: dependency)
    }

    private func makeDrivePreview(from: DrivePreviewFrom?, url: URL, context: [String: Any]?) -> UIViewController {
        let previewFrom = from ?? getPreviewFrom(from: url)
        let statisticInfo = getStatisticInfo(from: url)
        let pdfPageNumber = getPDFPageNumber(from: url)
        
        let curToken = DocsUrlUtil.getFileToken(from: url, with: .file) ?? ""
        let curFile = SpaceEntryFactory.createEntry(type: .file, nodeToken: "", objToken: curToken)
        curFile.updateShareURL(url.absoluteString)
        DocsLogger.debug("Lark open url: \(url.absoluteString), fileToken: \(curToken.encryptToken), shareUrl: \(String(describing: curFile.shareUrl)), pdfPageNumber: \(pdfPageNumber)")
        // 处理associatedFiles
        var fileList = [SpaceEntry]()
        if let associatedFiles = context?["associatedFiles"] as? [[String: String]] {
            associatedFiles.forEach { (params) in
                guard let path = params["path"], let type = params["type"] else {
                    return
                }
                if let url = URL(string: path) {
                    let token = DocsUrlUtil.getFileToken(from: url, with: .file) ?? ""
                    if token == curToken {
                        curFile.updateFileType(type)
                        fileList.append(curFile)
                    } else {
                        let file = SpaceEntryFactory.createEntry(type: .file, nodeToken: "", objToken: token)
                        file.updateShareURL(url.absoluteString)
                        file.updateFileType(type)
                        fileList.append(file)
                    }
                }
            }
        }
        if fileList.isEmpty {
            fileList.append(curFile)
        }
        let intialIndex = fileList.firstIndex { entity in
            return entity.objToken == curFile.objToken
        }
        let files = fileList.map { (entity) -> DriveSDKAttachmentFile in
            let moreVisable: Observable<Bool> = .never()
            let actions: [DriveSDKMoreAction] = []
            let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .never())
            let action = DKAttachDefaultActionDependencyImpl()
            let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
            return DriveSDKAttachmentFile(fileToken: entity.objToken,
                                          mountNodePoint: entity.parent,
                                          mountPoint: DriveConstants.driveMountPoint,
                                          fileType: entity.fileType,
                                          name: entity.name,
                                          authExtra: nil,
                                          urlForSuspendable: nil,
                                          dependency: dependency)
        }
        var commonContext = context ?? [:]
        commonContext.merge(other: [DKContextKey.from.rawValue: previewFrom.rawValue])
        commonContext.merge(other: [DKContextKey.pdfPageNumber.rawValue: pdfPageNumber])
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        return DocsContainer.shared.resolve(DriveSDK.self)!
            .createSpaceFileController(files: files,
                                       index: intialIndex ?? 0,
                                       appID: DKSupportedApp.space.rawValue,
                                       isInVCFollow: previewFrom == .vcFollow,
                                       context: commonContext,
                                       statisticInfo: statisticInfo)

    }

    private func getPreviewFrom(from url: URL) -> DrivePreviewFrom {
        guard let fromValue = url.queryParameters[DKContextKey.from.rawValue],
            let from = DrivePreviewFrom(rawValue: fromValue) else {
                return DrivePreviewFrom.unknown
        }
        return from
    }
    
    private func getPDFPageNumber(from url: URL) -> Int? {
        guard let pageNumber = url.queryParameters[DKContextKey.pdfPageNumber.rawValue]  else {
            return nil
        }
        return Int(pageNumber)
    }
    
    /// 通过 URL 参数组装 Drive 埋点数据
    private func getStatisticInfo(from url: URL) -> [String: String] {
        var module = SKCreateTracker.moduleString
        var srcModule = SKCreateTracker.srcModuleString
        let subModule = SKCreateTracker.subModuleString
        let srcFolderID = SKCreateTracker.srcFolderID ?? ""
        
        if let fromValue = url.queryParameters[DKContextKey.from.rawValue] {
            if let source = FromSource(rawValue: fromValue),
               let driveStatisticModule = source.driveStatisticModule {
                srcModule = module
                module = driveStatisticModule.rawValue
            } else {
                switch fromValue {
                case "calendar":
                    module = StatisticModule.calendarLink.rawValue
                case "message":
                    module = StatisticModule.imLink.rawValue
                case "search":
                    module = StatisticModule.search.rawValue
                case "docs_attach":
                    srcModule = module
                    module = StatisticModule.doc.rawValue
                case "sheet_attach":
                    srcModule = module
                    module = StatisticModule.sheet.rawValue
                default:
                    module = StatisticModule.otherLink.rawValue
                }
            }
        } else {
            module = StatisticModule.otherLink.rawValue
        }
        
        var info = [DriveStatistic.ReportKey.module.rawValue: module,
                    DriveStatistic.ReportKey.srcModule.rawValue: srcModule,
                    DriveStatistic.ReportKey.subModule.rawValue: subModule,
                    DriveStatistic.ReportKey.srcObjId.rawValue: srcFolderID]
        reviseStatisticInfo(&info)
        return info
    }
    
//    /// 通过 context 参数组装 Drive 埋点数据
//    private func getStatisticInfo(from context: [String: Any]) -> [String: String] {
//        var module = SKCreateTracker.moduleString
//        var srcModule = SKCreateTracker.srcModuleString
//        let subModule = SKCreateTracker.subModuleString
//        let srcFolderID = SKCreateTracker.srcFolderID ?? ""
//        if let bussinessID = context["bussinessId"] as? String {
//            srcModule = ""
//            switch bussinessID {
//            case "calendar":
//                module = StatisticModule.calendar.rawValue
//            case "mail":
//                module = StatisticModule.email.rawValue
//            default:
//                break
//            }
//        }
//
//        var info = [DriveStatistic.ReportKey.module.rawValue: module,
//                    DriveStatistic.ReportKey.srcModule.rawValue: srcModule,
//                    DriveStatistic.ReportKey.subModule.rawValue: subModule,
//                    DriveStatistic.ReportKey.srcObjId.rawValue: srcFolderID]
//        reviseStatisticInfo(&info)
//        return info
//    }
    
    /// 获取当前路径相关的埋点数据
    private func getStatisticInfo() -> [String: String] {
        var info = [DriveStatistic.ReportKey.module.rawValue: SKCreateTracker.moduleString,
                      DriveStatistic.ReportKey.srcModule.rawValue: SKCreateTracker.srcModuleString,
                      DriveStatistic.ReportKey.subModule.rawValue: SKCreateTracker.subModuleString,
                      DriveStatistic.ReportKey.srcObjId.rawValue: SKCreateTracker.srcFolderID ?? ""]
        
        reviseStatisticInfo(&info)
        return info
    }
    
    /// 校正 StatisticInfo，过滤特定场景下无需上报的 srcModule/subModule 数据
    private func reviseStatisticInfo(_ info: inout [String: String]) {
        guard let moduleValue = info[DriveStatistic.ReportKey.module.rawValue],
              let module = StatisticModule(rawValue: moduleValue) else {
            return
        }
        switch module {
        case .calendar, .calendarLink, .im, .imLink, .search, .email, .emailLink, .otherLink:
            info[DriveStatistic.ReportKey.srcModule.rawValue] = ""
            info[DriveStatistic.ReportKey.subModule.rawValue] = ""
        default:
            break
        }
    }
}

extension FromSource {
    var driveStatisticModule: StatisticModule? {
        switch self {
        case .linkInParentDocs:
            return .doc
        case .linkInParentSheet:
            return .sheet
        case .linkInParentMindnote:
            return .mindnote
        default:
            return nil
        }
    }
}
