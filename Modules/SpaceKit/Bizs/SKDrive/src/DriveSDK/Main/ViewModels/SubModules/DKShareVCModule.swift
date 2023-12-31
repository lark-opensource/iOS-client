//
//  DKShareVCModule.swift
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
import UniverseDesignColor
import SKInfra

class DKShareVCModule: DKBaseSubModule {
    /// 分享面板
    var dependency: DKShareVCModuleDependency
    var navigator: DKNavigatorProtocol
    weak var uiDependency: WindowSizeProtocol?
    init(hostModule: DKHostModuleType,
         uiDependency: WindowSizeProtocol?,
         dependency: DKShareVCModuleDependency = DefaultShareVCModuleDependencyImpl(),
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.dependency = dependency
        self.navigator = navigator
        self.uiDependency = uiDependency
        super.init(hostModule: hostModule)
    }
    weak var shareViewController: UIViewController?
    deinit {
        DocsLogger.driveInfo("DKShareVCModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                guard self.hostModule?.permissionService.ready == true else {
                    DocsLogger.driveInfo("permission service not ready")
                    return
                }
            } else {
                guard let permission = self.permissionInfo.userPermissions else {
                    DocsLogger.driveInfo("no user permissions")
                    return
                }
            }
            if case .showShareVC = action {
                self.showShareVC(fileInfo: self.fileInfo,
                                 docsInfo: self.docsInfo,
                                 delegate: self,
                                 router: self)
            }
        }).disposed(by: bag)
        return self
    }
    
    // 打开分享面板
    func showShareVC(fileInfo: DriveFileInfo,
                     docsInfo: DocsInfo,
                     delegate: ShareViewControllerDelegate,
                     router: ShareRouterAbility) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let hostVCDependencyImpl = uiDependency else { return }
        hostVC.view.endEditing(true)
        let info = docsInfo
        let context = DriveShareVCContext(shareEntity: SKShareEntity.transformFrom(info: info),
                                          hostViewController: hostVC,
                                          delegate: delegate,
                                          router: router,
                                          source: .content,
                                          isInVideoConference: info.isInVideoConference ?? false,
                                          shouldShowWatermark: info.shouldShowWatermark)
        let shareVC = DocsContainer.shared.resolve(SKDriveDependency.self)!
            .makeShareViewControllerV2(context: context)
        let completion: () -> Void = { [weak self] in
            guard let self = self else { return }
            // 消除分享按钮的红点
            self.hostModule?.subModuleActionsCenter.accept(.refreshNaviBarItemsDots)
        }
        if let shareVC = shareVC as? SKShareViewController {
            shareVC.supportOrientations = hostVC.supportedInterfaceOrientations
        }
        let navi = LkNavigationController(rootViewController: shareVC)
        navi.modalPresentationStyle = .overFullScreen
        if dependency.pad, hostVCDependencyImpl.isMyWindowRegularSize() {
            shareVC.modalPresentationStyle = .popover
            shareVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            let shareBarBtnIndex = -2
            hostVC.showPopover(to: navi, at: shareBarBtnIndex, completion: completion)
        } else {
            navigator.present(vc: navi, from: hostVC, animated: false, completion: completion)
        }
        self.shareViewController = shareVC
        
        DriveStatistic.reportClickEvent(DocsTracker.EventType.navigationBarClick,
                                        clickEventType: DriveStatistic.DriveTopBarClickEventType.share,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType)
    }
}


extension DKShareVCModule: ShareViewControllerDelegate {
    func requestExist(controller: UIViewController) {
        self.shareViewController = nil
    }

    func requestDisplayShareViewAccessory() -> UIView? {
        guard let feedId = hostModule?.commonContext.feedId else { return nil }
        return HostAppBridge.shared.call(RequestShareAccessory(feedId: feedId)) as? UIView
    }
}

extension DKShareVCModule: ShareRouterAbility {
    func shareRouterToOtherApp(_ vc: UIViewController) -> Bool {
        guard let host = hostModule else { return false }
        host.subModuleActionsCenter.accept(.spaceOpenWithOtherApp)
        return true
    }
}


public protocol DKShareVCModuleDependency {
    var pad: Bool { get }
}

class DefaultShareVCModuleDependencyImpl: DKShareVCModuleDependency {
    var pad: Bool {
        return SKDisplay.pad
    }
}
