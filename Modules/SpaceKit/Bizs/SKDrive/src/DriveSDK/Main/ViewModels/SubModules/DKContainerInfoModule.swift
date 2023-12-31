//
//  DKContainerInfoModule.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2023/8/7.
//  

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKInfra
import EENavigator
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface
import UniverseDesignToast
import SKResource

class DKContainerInfoModule: DKBaseSubModule {

    @InjectedSafeLazy var temporaryTabService: TemporaryTabService

    deinit {
        DocsLogger.driveInfo("DKContainerInfoModule -- deinit")
    }

    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        hostModule?.reachabilityChanged.distinctUntilChanged().subscribe(onNext: { [weak self] reachable in
            if reachable {
                self?.fetchContainerInfo()
            }
        }).disposed(by: bag)

        hostModule?.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .redirectToWiki(let wikiToken):
                self.redirectToWiki(wikiToken: wikiToken)
            default: break
            }

        }).disposed(by: bag)

        return self
    }

    func fetchContainerInfo() {
        if hostModule?.commonContext.previewFrom == .wiki {
            return
        }
        WorkspaceCrossNetworkAPI.getContainerInfo(objToken: docsInfo.token, objType: docsInfo.inherentType)
            .subscribe { [weak self] containerInfo, logID in
                guard let self = self else { return }
                guard let containerInfo = containerInfo else {
                    DocsLogger.driveError("fetch containerInfo fail", extraInfo: ["log-id": logID as Any])
                    return
                }
                if let token = containerInfo.wikiToken {
                    self.redirectToWiki(wikiToken: token, logID: logID)
                }
                self.docsInfo.update(containerInfo: containerInfo)
            } onError: { error in
                DocsLogger.driveError("fetch containerInfo failed with error", error: error)
            }
            .disposed(by: bag)
    }

    private func redirectToWiki(wikiToken: String, logID: String? = nil) {
        DocsLogger.driveInfo("prepare redirect space document to wiki", extraInfo: ["logID": logID as Any])
        let record = WorkspaceCrossRouteRecord(wikiToken: wikiToken,
                                               objToken: docsInfo.objToken,
                                               objType: docsInfo.inherentType,
                                               inWiki: true,
                                               logID: logID)
        DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.notifyRedirect(record: record)

        let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
        guard let vc = SKRouter.shared.open(with: url).0 else {
            spaceAssertionFailure("get wiki VC failed when redirect")
            return
        }
        guard let current = hostModule?.hostController as? DKMainViewController else {
            DocsLogger.warning("current host is not DriveVC")
            return
        }
        current.shouldRedirect = true
        let redirectAction = {
            if current.isTemporaryChild {
                // 移除 iPad 主导航记录
                self.temporaryTabService.removeTab(id: current.tabContainableIdentifier)
                Navigator.shared.showTemporary(vc, from: current)
            } else {
                current.navigationController?.pushViewController(vc, animated: false)
            }
            if let coordinate = current.navigationController?.transitionCoordinator {
                coordinate.animate(alongsideTransition: nil) { _ in
                    current.navigationController?.viewControllers.removeAll(where: { $0 == current })
                }
            } else {
                current.navigationController?.viewControllers.removeAll(where: { $0 == current })
            }
        }

        if let presentedVC = current.presentedViewController {
            presentedVC.dismiss(animated: false, completion: redirectAction)
        } else {
            redirectAction()
        }
    }
}

