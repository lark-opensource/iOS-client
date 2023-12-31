//
//  UtilAtService.swift
//  SpaceKit
//
//  Created by bytedance on 2018/9/6.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra

public final class UtilAtService: BaseJSService {
    private var atAuthorizeView: AtAuthorizeView?
    private var permStatistics: PermissionStatistics?

    private func showAtAuthorizeView(params: [String: Any]) {
        var atAuthorizeViewConfig = AtAuthorizeViewConfig()

        guard let items = params["items"] as? [[String: Any]] else {
            DocsLogger.info("传入 items 为空")
            return
        }

        for (index, item) in items.enumerated() {
            let id = (item["id"] as? Int) ?? 0
            let base64Image = item["base64Image"] as? String ?? ""
            let text = item["text"] as? String ?? ""
            let buttonConfig = AtAuthorizeViewConfig.Button(id: id, base64Image: base64Image, text: text)
            if index == 0 {
                atAuthorizeViewConfig.leftButton = buttonConfig
            } else if index == 1 {
                atAuthorizeViewConfig.titleString = text
            } else if index == 2 {
                atAuthorizeViewConfig.rightButton = buttonConfig
            }
        }

        if let callback = params["callback"] as? String {
            atAuthorizeViewConfig.callBack = callback
        }
        let docsInfo = model?.browserInfo.docsInfo
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo?.objToken ?? "")
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo?.objToken ?? "")
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo?.encryptedObjToken ?? "",
                                                      fileType: docsInfo?.type.name ?? "",
                                                      appForm: (docsInfo?.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo?.fileType,
                                                      module: docsInfo?.type.name ?? "",
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        self.permStatistics?.reportPermissionCommentWithoutPermissionView()
        atAuthorizeView?.removeFromSuperview()
        atAuthorizeView = AtAuthorizeView()
        atAuthorizeView?.delegate = self
        atAuthorizeView?.permStatistics = permStatistics
        atAuthorizeView?.setupConfig(atAuthorizeViewConfig)
        ui?.bannerAgent.requestShowItem(atAuthorizeView!)
    }

    private func hideAtAuthorizeView() {
        atAuthorizeView.map { ui?.bannerAgent.requestHideItem($0) }
    }
}

extension UtilAtService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilAtHideTips, .utilAtShowTips]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilAtShowTips.rawValue:
            self.showAtAuthorizeView(params: params)
        case DocsJSService.utilAtHideTips.rawValue:
            self.hideAtAuthorizeView()
        default:
            break
        }
    }
}

extension UtilAtService: AtAuthorizeViewDelegate {
    func clickButton(callback: String, params: [String: Any]?) {
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
    }
}
