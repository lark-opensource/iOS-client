//
//  DKPublicPermissionSettingModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import UIKit
import SKInfra

class DKPublicPermissionSettingModule: DKBaseSubModule {
    var navigator: DKNavigatorProtocol
    weak var windowSizeDependency: WindowSizeProtocol?
    private var filePermissionRequest: DocsRequest<[String: Any]>?
    init(hostModule: DKHostModuleType,
         windowSizeDependency: WindowSizeProtocol?,
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        self.windowSizeDependency = windowSizeDependency
        super.init(hostModule: hostModule)
    }
    deinit {
        DocsLogger.driveInfo("DKPublicPermissionSettingModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }

            if case .publicPermissionSetting = action {
                self.showPublicPermissionSettingVC()
            }
        }).disposed(by: bag)
        return self
    }
    
    func showPublicPermissionSettingVC() {
        guard let hostVC = hostModule?.hostController else { return }
        guard let hostVCDependencyImpl = windowSizeDependency else { return }
        let wikiV2SingleContainer = docsInfo.isFromWiki
        let spaceSingleContainer = (docsInfo.ownerType == 5)
        let fileModel = PublicPermissionFileModel(objToken: docsInfo.objToken,
                                                  wikiToken: docsInfo.wikiInfo?.wikiToken,
                                                                 type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                                 fileType: docsInfo.fileType ?? "",
                                                                 ownerID: docsInfo.ownerID ?? "",
                                                                 tenantID: docsInfo.tenantID ?? "",
                                                                 createTime: docsInfo.createTime ?? 0,
                                                                 createDate: docsInfo.createDate ?? "",
                                                  createID: docsInfo.creatorID ?? "",
                                                  wikiV2SingleContainer: wikiV2SingleContainer, wikiType: docsInfo.inherentType,
                                                                 spaceSingleContainer: spaceSingleContainer)
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: "drive",
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        guard let url = try? HelpCenterURLGenerator.generateURL(article: .dlpBannerHelpCenter).absoluteString else {
            DocsLogger.error("failed to generate helper center URL when showPublicPermissionSettingVC from dlpBannerHelpCenter")
            return
        }
        var permissionVC: BaseViewController
        if ShareFeatureGating.newPermissionSettingEnable(type: docsInfo.type.rawValue) {
            permissionVC = PublicPermissionLynxController(token: docsInfo.objToken,
                                                          type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                          isSpaceV2: spaceSingleContainer,
                                                          isWikiV2: wikiV2SingleContainer,
                                                          needCloseButton: hostVC.isMyWindowRegularSizeInPad,
                                                          fileModel: fileModel,
                                                          permStatistics: permStatistics,
                                                          dlpDialogUrl: url)
            (permissionVC as? PublicPermissionLynxController)?.supportOrientations = hostVC.supportedInterfaceOrientations
        } else {
            permissionVC = PublicPermissionViewController(fileModel: fileModel,
                                                              needCloseBarItem: hostVC.isMyWindowRegularSizeInPad,
                                                              permStatistics: permStatistics)
        }
        permissionVC.watermarkConfig.needAddWatermark = hostVC.watermarkConfig.needAddWatermark
        if hostVCDependencyImpl.isMyWindowRegularSizeInPad {
            let navVC = LkNavigationController(rootViewController: permissionVC)
            navVC.modalPresentationStyle = .formSheet
            navigator.present(vc: navVC, from: hostVC, animated: true)
        } else {
            navigator.push(vc: permissionVC, from: hostVC, animated: true)
        }
    }
}

//将UIViewController中的两个窗口大小值抽象出来重写
public protocol WindowSizeProtocol: NSObjectProtocol {
    var isMyWindowRegularSizeInPad: Bool { get }
    func isMyWindowRegularSize() -> Bool
}
