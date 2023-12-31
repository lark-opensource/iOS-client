//
//  BTJSService+Jira.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/20.
//  


import UIKit
import SKCommon
import SKBrowser
import SKFoundation

extension BTJSService {
    func handleJiraActionSheet(_ param: [String: Any]) {
        guard let jiraMenuParams = BTJiraMenuParams.deserialize(from: param) else {
            DocsLogger.btError("[SYNC] jiraMenuParams wrong params \(param)")
            return
        }
        guard !jiraMenuParams.blockId.isEmpty else {
            if jiraVC != nil, jiraVC?.isViewLoaded ?? false {
                jiraVC?.dismiss(animated: false)
            }
            return
        }
        let stJiraMenuVC = BTJiraMenuController(jiraMenuParams: jiraMenuParams, parentVC: registeredVC).construct { it in
            it.delegate = self
        }
        let isInVCFollow = self.model?.hostBrowserInfo.docsInfo?.isInVideoConference ?? false
        if isInVCFollow {
            stJiraMenuVC.modalPresentationStyle = .overFullScreen
        }
        jiraVC = stJiraMenuVC
        registeredVC?.present(stJiraMenuVC, animated: true)
    }
}

protocol BTJiraMenuControllerDelegate: AnyObject {
    var jiraMenuDistanceToWindowBottom: CGFloat { get }
    func didSelectJiraMenuCell(_ menuController: BTJiraMenuController,
                               didSelect action: BTJiraMenuAction,
                               blockId: String,
                               callback: String)
    func jiraMenuVCDidDismiss(_ menuController: BTJiraMenuController, blockId: String, callback: String)
}

extension BTJSService: BTJiraMenuControllerDelegate {
    var jiraMenuDistanceToWindowBottom: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController else { return 0 }
        return dbvc.browserViewDistanceToWindowBottom
    }

    func didSelectJiraMenuCell(_ menuController: BTJiraMenuController,
                               didSelect action: BTJiraMenuAction,
                               blockId: String,
                               callback: String) {
        let param: [String: Any] = [
            "blockId": blockId,
            "actionId": action.id
        ]
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback),
                                     params: param,
                                     completion: nil)
    }

    func jiraMenuVCDidDismiss(_ menuController: BTJiraMenuController, blockId: String, callback: String) {
        let param: [String: Any] = [
            "blockId": blockId,
            "actionId": "cancel"
        ]
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback),
                                     params: param,
                                     completion: nil)
    }
}
