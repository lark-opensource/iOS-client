//
//  HyperLinkService.swift
//  SKBrowser
//
//  Created by xiongmin on 2022/8/17.
//

import LarkWebViewContainer
import SKCommon
import SKFoundation
import SpaceInterface

final class HyperLinkService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension HyperLinkService: DocsJSServiceHandler {
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        guard let navigator = navigator else { return }
        if let type = params["type"] as? String {
            let text = params["text"] as? String
            let url = params["url"] as? String
            let blockDocsInfo = self.getblockDocsInfo(params: params) //区分syncedBlock权限
            let docsInfo = blockDocsInfo ?? self.hostDocsInfo
            let dialogType = EditLinkDialog.DialogType.from(type: type, text: text, url: url)
            DocsTracker.newLog(enumEvent: .docsLinkEditDialog, parameters: ["view_type": type == "edit" ? "edit_link" : "add_link"])
            let dialog = EditLinkDialog(docsInfo: docsInfo)
            
            dialog.setCopyPermission { [weak self] in
                guard let self = self else { return (true, true) }
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    return self.checkCanCopy(token: docsInfo?.token)
                } else {
                    // 这里无法判断禁止原因，内部判断
                    return (self.canCopy(token: docsInfo?.token), nil)
                }
            }
            dialog.show(with: dialogType, from: navigator) { result in
                callback?.callbackSuccess(param: result)
            }
        } else {
            DocsLogger.error("HyperLinkService: params error, type could not be null")
            callback?.callbackSuccess(param: ["success": false, "errorMsg": "params error type could not be null"])
        }
    }

    func handle(params: [String: Any], serviceName: String) {
    }

    var handleServices: [DocsJSService] {
        return [.openEditHyperLinkAlter]
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func canCopy(token: String?) -> Bool {
        if let token {
            return model?.permissionConfig.checkCanCopy(for: .referenceDocument(objToken: token)) ?? false
        } else {
            return model?.permissionConfig.checkCanCopy(for: .hostDocument) ?? false
        }
    }

    // 判断能否直接复制或允许单文档保护复制
    private func checkCanCopy(token: String?) -> (Bool, Bool) {
        let service: UserPermissionService
        if let token {
            guard let referService = model?.permissionConfig.getPermissionService(for: .referenceDocument(objToken: token)) else {
                return (false, false)
            }
            service = referService
        } else {
            guard let hostService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                return (false, false)
            }
            service = hostService
        }
        let response = service.validate(operation: .copyContent)
        guard case let .forbidden(denyType, _) = response.result else {
            return (true, true)
        }
        guard case let .blockByUserPermission(reason) = denyType else {
            return (false, false)
        }
        switch reason {
        case .unknown, .userPermissionNotReady, .blockByServer, .blockByAudit:
            return (false, true)
        case .blockByCAC, .cacheNotSupport:
            return (false, false)
        }
    }
}
