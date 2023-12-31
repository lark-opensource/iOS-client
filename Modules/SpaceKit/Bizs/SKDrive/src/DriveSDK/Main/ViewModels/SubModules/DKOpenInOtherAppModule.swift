//
//  DKOpenInOtherAppModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/20.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import SKResource
import UniverseDesignToast

class DKOpenInOtherAppModule: DKBaseSubModule {
    private var cacManager: CACManagerBridge.Type
    var dependency: OpenInOtherAppSubModuleDependency

    init(hostModule: DKHostModuleType,
         submodulesMethod: OpenInOtherAppSubModuleDependency = DefaultOpenInOtherAppDependency(),
         cacManager: CACManagerBridge.Type = CACManager.self) {
        self.dependency = submodulesMethod
        self.cacManager = cacManager
        super.init(hostModule: hostModule)
    }

    deinit {
        DocsLogger.driveInfo("DKOpenInOtherAppModule -- deinit")
    }

    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            if case .spaceOpenWithOtherApp = action {
                self.openWithOtherApp(actionSource: .fileDetail)
            }
        }).disposed(by: bag)
        return self
    }
    
    // MARK: - Actions
    /// 用其他应用打开
    ///
    /// - Parameter sender: sender description
    func openWithOtherApp(actionSource: DriveStatisticActionSource) {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule or hostVC not found")
            return
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let response = host.permissionService.validate(operation: .openWithOtherApp)
            response.didTriggerOperation(controller: hostVC)
            guard response.allow else { return }
        } else {
            let result = cacManager.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                                 docType: .file, token: self.fileInfo.fileToken)
            if !result.allow && result.validateSource == .fileStrategy {
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileDownload, fileBizDomain: .ccm, docType: .file, token: self.fileInfo.fileToken)
            } else if !result.allow && result.validateSource == .securityAudit {
                dependency.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: hostVC.view.window ?? hostVC.view)
            }
            guard result.allow else { return }
        }

        let meta = self.fileInfo.getFileMeta()

        let button = hostVC.navigationBar.trailingButtons.first
        let isLatest = host.commonContext.previewFrom != .history
        let sourceParam = ActivityAnchorParam(sourceController: hostVC,
                                              sourceView: button,
                                              sourceRect: button?.bounds,
                                              arrowDirection: .up)
        let context = OpenInOtherAppContext(fileMeta: meta,
                                            sourceParam: sourceParam,
                                            isLatest: isLatest,
                                            actionSource: actionSource,
                                            previewFrom: host.commonContext.previewFrom,
                                            skipCellularCheck: false,
                                            additionalParameters: nil,
                                            appealAlertFrom: .driveDetailOpenInOtherApp)
        dependency.openWith3rdApp(context: context)
    }
}


protocol OpenInOtherAppSubModuleDependency {

    func openWith3rdApp(context: OpenInOtherAppContext)
    
    func showFailure(with text: String, on view: UIView)
}
