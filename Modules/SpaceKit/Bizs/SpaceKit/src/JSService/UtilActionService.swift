//
//  UtilActionService.swift
//  SKBrowser
//
//  Created by liujinwei on 2023/2/9.
//


import SKFoundation
import SKCommon
import SKResource
import UniverseDesignToast
import SpaceInterface
import SKInfra

///前端调用space能力
class UtilActionService: BaseJSService {

    enum ActionName: String {
        case subscribe = "FollowPage" //关注文档更新
        case copyFile = "DuplicatePage"//创建副本
    }
    
    private lazy var wikiMoreActionHandler: WikiMoreActionHandler? = {
        guard let hostDocsInfo, let topVC = topMostOfBrowserVC() else { return nil }
        let browser = navigator?.currentBrowserVC as? WikiContextProxy
        let synergyUUID = browser?.wikiContextProvider?.synergyUUID
        return WikiMoreActionHandler(docsInfo: hostDocsInfo, hostViewController: topVC, synergyUUID: synergyUUID)
    }()
    
    private lazy var moreActionHandler: UtilMoreActionHandler? = {
        let spaceAPI = DocsContainer.shared.resolve(SpaceManagementAPI.self)!
        return UtilMoreActionHandler(hostVC: topMostOfBrowserVC(), spaceAPI: spaceAPI, from: .other)
    }()

}

extension UtilActionService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilPerformAction]
    }
    
    var netActions: [ActionName] {
        return [.subscribe, .copyFile]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let name = params["action"] as? String else {
            DocsLogger.error("no action name received")
            return
        }
        
        guard let topVC = topMostOfBrowserVC(), let docsInfo = hostDocsInfo else { return }
        let viewForHUD: UIView = topVC.view.window ?? topVC.view
        guard DocsNetStateMonitor.shared.isReachable else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: viewForHUD)
            return
        }
        
        let action = ActionName(rawValue: name)
        switch action {
        case .copyFile:
            if docsInfo.wikiInfo != nil {
                wikiMoreActionHandler?.showWikiCopyFilePanel()
            } else {
                moreActionHandler?.copyFileWithPicker(docsInfo: docsInfo, fileSize: nil)
            }
        case .subscribe:
            guard !docsInfo.subscribed else {
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_SubscribeSuccess, on: viewForHUD)
                return
            }
            guard let spaceApi = DocsContainer.shared.resolve(SpaceManagementAPI.self) else { return }
            
            let fileMeta: SpaceMeta
            if let wikiEntry = docsInfo.actualFileEntry as? WikiEntry,
               let wikiInfo = wikiEntry.wikiInfo { // wiki类型
                fileMeta = SpaceMeta(objToken: wikiInfo.wikiToken, objType: .wiki)
            } else {
                fileMeta = SpaceMeta(objToken: docsInfo.actualFileEntry.objToken, objType: docsInfo.actualFileEntry.docsType)
            }
            
            spaceApi.addSubscribe(fileMeta: fileMeta, subType: 0) { (error) in
                guard error == nil else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: viewForHUD)
                    return
                }
                docsInfo.subscribed = true
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_SubscribeSuccess, on: viewForHUD)
            }
            break
        default:
            DocsLogger.error("unknown action performed")
        }
    }
}

