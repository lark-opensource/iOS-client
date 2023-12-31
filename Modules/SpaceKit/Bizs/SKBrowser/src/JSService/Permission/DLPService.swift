//
//  DLPService.swift
//  SKBrowser
//
//  Created by peilongfei on 2022/7/18.
//  


import Foundation
import SKCommon
import SKFoundation
import EENavigator
import LarkUIKit
import SpaceInterface
import SKInfra

class DLPService: BaseJSService, BrowserViewLifeCycleEvent {
    
    private var permStatistics: PermissionStatistics?

    private weak var dlpTimer: Timer?
    // 记录某一个 Block 的 DLP 状态是否预拉取过
    private var blockDLPFetched: [String: Bool] = [:]
    
    private lazy var dlpBannerView: DLPBannerView = {
        let view = DLPBannerView()
        view.bannerDelegate = self
        return view
    }()
    
    private var currentTopVC: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    func browserDidUpdateDocsInfo() {
        guard LKFeatureGating.docDlpEnable else { return }
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.error("DocsInfo does not exist")
            return
        }

        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            checkDLP(docsInfo: docsInfo)
        } else {
            legacyCheckDLP(docsInfo: docsInfo)
        }
    }

    private func checkDLP(docsInfo: DocsInfo) {
        guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure("check DLP failed, failed to get host permission service")
            return
        }
        service.asyncValidate(exemptScene: .dlpBannerVisable) { [weak self] response in
            guard let self else { return }
            DocsLogger.info("check DLP status", extraInfo: [
                "response": response
            ])
            self.model?.permissionConfig.notifyDidUpdate(permisisonResponse: nil, for: .hostDocument, objType: self.hostDocsInfo?.inherentType ?? .docX)
            guard docsInfo.isOwner else {
                DocsLogger.info("Not doc owner", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }
            let uid = User.current.info?.userID ?? ""
            let closedKey = "ccm.permission.dlp.closed" + docsInfo.encryptedObjToken + uid
            if CacheService.normalCache.containsObject(forKey: closedKey) {
                DocsLogger.info("Doc have been closed", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }

            if !response.allow, self.dlpBannerView.superview == nil {
                PermissionStatistics.shared.reportDlpSecurityBannerHintView()
                self.ui?.bannerAgent.requestShowItem(self.dlpBannerView)
            }
            self.updateDLPTimerWithPermissionSDK()
        }
    }


    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckDLP(docsInfo: DocsInfo) {
        DocsLogger.info("Fetch DLP status", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
        DlpManager.status(with: docsInfo.token, type: docsInfo.inherentType, action: .OPENEXTERNALACCESS) { [weak self] status in
            guard let self = self else { return }
            DocsLogger.info("Return DLP status", extraInfo: [
                "encryptedObjToken": docsInfo.encryptedObjToken,
                "dlpStatus": status.rawValue
            ])
            self.model?.permissionConfig.notifyPermissionUpdate(for: .hostDocument, type: self.hostDocsInfo?.inherentType ?? .docX)
            guard docsInfo.isOwner else {
                DocsLogger.info("Not doc owner", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }

            let uid = User.current.info?.userID ?? ""
            let closedKey = "ccm.permission.dlp.closed" + docsInfo.encryptedObjToken + uid
            if CacheService.normalCache.containsObject(forKey: closedKey) {
                DocsLogger.info("Doc have been closed", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }

            if status == .Sensitive, self.dlpBannerView.superview == nil {
                PermissionStatistics.shared.reportDlpSecurityBannerHintView()
                self.ui?.bannerAgent.requestShowItem(self.dlpBannerView)
            }
            self.updateDLpTimer(token: docsInfo.token, type: docsInfo.inherentType)
        }
    }

    private func updateDLPTimerWithPermissionSDK() {
        guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else { return }
        service.notifyResourceWillAppear()
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func updateDLpTimer(token: String, type: DocsType) {
        dlpTimer?.invalidate()
        dlpTimer = nil
        let timeout = DlpManager.timerTime(token: token)
        let timer = Timer(timeInterval: timeout, repeats: true) { _ in
            DlpManager.status(with: token, type: type, action: .OPENEXTERNALACCESS) { [weak self] status in
                DocsLogger.info("timer update", extraInfo: [
                    "encryptedObjToken": token,
                    "dlpStatus": status.rawValue
                ])
                DispatchQueue.main.async {
                    self?.model?.permissionConfig.notifyPermissionUpdate(for: .hostDocument, type: self?.hostDocsInfo?.inherentType ?? .docX)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        dlpTimer = timer
    }

    deinit {
        dlpTimer?.invalidate()
        dlpTimer = nil
    }
}

extension DLPService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] { return [.blockInfo] }

    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .blockInfo:
            handle(blockInfo: params)
        default:
            return
        }
    }

    private func handle(blockInfo: [String: Any]) {
        guard let token = blockInfo["token"] as? String,
              let rawType = blockInfo["type"] as? Int,
              let tenantID = blockInfo["creatorTenantId"] as? String else {
            DocsLogger.error("failed to parse block info")
            return
        }
        let type = DocsType(rawValue: rawType)
        if let permissionService = model?.permissionConfig.getPermissionService(for: .referenceDocument(objToken: token)) {
            permissionService.update(tenantID: tenantID)
        }

        let fetched = blockDLPFetched[token] ?? false
        if fetched {
            DocsLogger.info("DLP status already prefetched, skipped", extraInfo: ["token": DocsTracker.encrypt(id: token)])
            return
        }
        blockDLPFetched[token] = true
        DocsLogger.info("prefetching DLP status", extraInfo: ["token": DocsTracker.encrypt(id: token)])

        guard let service = model?.permissionConfig.getPermissionService(for: .referenceDocument(objToken: token)) else { return }
        service.notifyResourceWillAppear()
    }

    private func prefetchDLPStatus(token: String, type: DocsType, tenantID: String) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(token: token, type: type, operation: .shareToExternal, bizDomain: .ccm, tenantID: tenantID)
            permissionSDK.asyncValidate(request: request) { [weak self] _ in
                self?.model?.permissionConfig.notifyDidUpdate(permisisonResponse: nil,
                                                              for: .referenceDocument(objToken: token),
                                                              objType: type)
            }
        } else {
            DlpManager.prefetchDLP(token: token, type: type) { [weak self] in
                guard let self else { return }
                self.model?.permissionConfig.notifyPermissionUpdate(for: .referenceDocument(objToken: token), type: type)
            }
        }
    }
}

extension DLPService: DLPBannerViewDelegate {
    
    func shouldClose(_ dlpBannerView: DLPBannerView) {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.error("DocsInfo does not exist")
            return
        }
        DocsLogger.info("DLP banner should close", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
        
        let uid = User.current.info?.userID ?? ""
        let closedKey = "ccm.permission.dlp.closed" + docsInfo.encryptedObjToken + uid
        if !CacheService.normalCache.containsObject(forKey: closedKey) {
            if let saveData = try? JSONEncoder().encode(true) {
                CacheService.normalCache.set(object: saveData, forKey: closedKey)
                
            } else {
                DocsLogger.error("SaveData encode fail", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
            }
        }
        
        PermissionStatistics.shared.reportDlpSecurityBannerHintClick(isClose: true)
        ui?.bannerAgent.requestHideItem(dlpBannerView)
    }
    
    func shouldOpenLink(_ dlpBannerView: DLPBannerView, _ url: URL) {
        guard let currentTopMost = currentTopVC else {
            DocsLogger.error("CurrentTopVC not exist", extraInfo: ["encryptedObjToken": hostDocsInfo?.encryptedObjToken])
            return
        }
        DocsLogger.info("Should open link", extraInfo: [
            "encryptedObjToken": hostDocsInfo?.encryptedObjToken,
            "url": url.absoluteString
        ])
        PermissionStatistics.shared.reportDlpSecurityBannerHintClick(isClose: false)
        if let type = DocsType(url: url),
            let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            model?.userResolver.navigator.docs.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: currentTopMost)
        } else {
            model?.userResolver.navigator.push(url, from: currentTopMost)
        }
    }
}
