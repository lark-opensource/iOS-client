//
//  BlockMenuActionPlugin.swift
//  SKBrowser
//
//  Created by liujinwei on 2022/8/22.
//  


import Foundation
import SKCommon
import SpaceInterface
import SKResource
import SKFoundation
import SKInfra
import UniverseDesignToast
import RxSwift
import RxCocoa

public final class BlockMenuActionPlugin {
    
    struct FileInfo {
        let blockToken: String
        let fileSize: UInt64
        let fileName: String
    }
    
    public weak var navigator: BrowserNavigator?
    public weak var model: BrowserModelConfig?

    private static let handleAction: [BlockMenuV2Identifier] = [.fileDownload, .fileSaveToDrive, .fileOpenWith]
    
    public static func canHandle(actionId: String) -> Bool {
        return Self.handleAction.contains { return $0.rawValue == actionId }
    }
    private let disposeBag = DisposeBag()
    private var attachmentPermissionServices: [String: UserPermissionService] = [:]

    private let blockActionHandler = DocsContainer.shared.resolve(DriveMoreActionProtocol.self)
    public init(model: BrowserModelConfig?, navigator: BrowserNavigator?) {
        self.model = model
        self.navigator = navigator
    }
    public func handle(params: [String: Any]?, actionName: String) {
        let action = BlockMenuV2Identifier(rawValue: actionName)
        switch action {
        case .fileDownload:
            saveToLocal(params: params)
        case .fileSaveToDrive:
            saveToSpace(params: params)
        case .fileOpenWith:
            openDriveFileWithOtherApp(params: params)
        default:
            ()
        }
    }
    
    private func saveToLocal(params: [String: Any]?) {
        guard let currentBrowserVC = navigator?.currentBrowserVC,
              let fileInfo = getFileInfo(params: params) else {
            return
        }
        checkFileAttachmentPermission(fileToken: fileInfo.blockToken,
                                      operation: .saveFileToLocal,
                                      controller: currentBrowserVC) { [weak self, weak currentBrowserVC] allow in
            guard let self, let currentBrowserVC, allow else { return }
            self.blockActionHandler?.saveToLocal(fileSize: fileInfo.fileSize,
                                                 fileObjToken: fileInfo.blockToken,
                                                 fileName: fileInfo.fileName,
                                                 sourceController: currentBrowserVC)
        }
    }

    private func saveToSpace(params: [String: Any]?) {
        guard let currentBrowserVC = navigator?.currentBrowserVC,
              let fileInfo = getFileInfo(params: params) else {
            return
        }
        blockActionHandler?.saveToSpace(fileObjToken: fileInfo.blockToken,
                                        fileSize: fileInfo.fileSize,
                                        fileName: fileInfo.fileName,
                                        sourceController: currentBrowserVC)
    }
    
    private func openDriveFileWithOtherApp(params: [String: Any]?) {
        guard let currentBrowserVC = navigator?.currentBrowserVC,
              let fileInfo = getFileInfo(params: params) else {
            return
        }
        checkFileAttachmentPermission(fileToken: fileInfo.blockToken,
                                      operation: .openWithOtherApp,
                                      controller: currentBrowserVC) { [weak self, weak currentBrowserVC] allow in
            guard let self, let currentBrowserVC, allow else { return }
            self.blockActionHandler?.openDriveFileWithOtherApp(fileSize: fileInfo.fileSize,
                                                          fileObjToken: fileInfo.blockToken,
                                                          fileName: fileInfo.fileName,
                                                          sourceController: currentBrowserVC)
        }
    }

    private func getFileAttachmentPermissionService(fileToken: String) -> UserPermissionService? {
        spaceAssertMainThread()
        if let service = attachmentPermissionServices[fileToken] {
            return service
        }
        // drive 第三方附件权限要用 DrivePermissionSDK 的特化实现
        guard let permissionSDK = DocsContainer.shared.resolve(DrivePermissionSDK.self) else {
            spaceAssertionFailure("resolve DrivePermissionSDK failed")
            return nil
        }
        let service = permissionSDK.attachmentUserPermissionService(fileToken: fileToken,
                                                                    mountPoint: "docx_file", // 暂时假设都是 docx 附件
                                                                    authExtra: nil, // docx 附件都为 nil
                                                                    bizDomain: .ccm)
        // 假定附件的 tenantID 与文档相同
        if let hostTenantID = model?.hostBrowserInfo.docsInfo?.tenantID {
            service.update(tenantID: hostTenantID)
        }
        attachmentPermissionServices[fileToken] = service
        return service
    }

    private func checkFileAttachmentPermission(fileToken: String,
                                               operation: PermissionRequest.Operation,
                                               controller: UIViewController,
                                               completion: @escaping (Bool) -> Void) {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnable,
              UserScopeNoChangeFG.WWJ.attachmentBlockMenuPermissionFixEnable else {
            // FG 没开，无条件放行
            completion(true)
            return
        }
        guard let permissionService = getFileAttachmentPermissionService(fileToken: fileToken) else {
            spaceAssertionFailure("failed to get file attachment permissionService")
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Document_ExportNoPermission,
                                on: controller.view)
            completion(false)
            return
        }
        // 对齐安卓，每次都要实时拉一下权限
        UDToast.showDefaultLoading(on: controller.view)
        permissionService.updateUserPermission()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak controller, weak permissionService] _ in
                guard let controller, let permissionService else {
                    completion(false)
                    return
                }
                UDToast.removeToast(on: controller.view)
                let response = permissionService.validate(operation: operation)
                response.didTriggerOperation(controller: controller)
                completion(response.allow)
        } onError: { [weak controller] error in
            DocsLogger.error("update file attachment permission failed", error: error)
            if let controller {
                UDToast.removeToast(on: controller.view)
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_OpenFile_Fail,
                                    on: controller.view)
            }
            completion(false)
        }.disposed(by: disposeBag)
    }

    private func getFileInfo(params: [String: Any]?) -> FileInfo? {
        guard let params = params,
              let blockToken = params["blockToken"] as? String,
              let fileSize = params["fileSize"] as? UInt64,
              let fileName = params["fileName"] as? String else {
                  DocsLogger.error("BlockMenu, fileInfo is nil", extraInfo: [
                    "size": params?["fileSize"] ?? 0,
                    "name": params?["name"] ?? ""
                  ])
                  return nil
              }
        return FileInfo(blockToken: blockToken, fileSize: fileSize, fileName: fileName)
    }
}
