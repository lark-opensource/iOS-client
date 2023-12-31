//
//  ScopePickerBridgeHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/3/31.
//

import Foundation
import BDXBridgeKit
import BDXServiceCenter
import SKFoundation
import SwiftyJSON

protocol ScopePickerBridgeDelegate: AnyObject {
    func showScopePicker(needLockTips: Bool, defaultScopeType: PermissionScopeType, completion: @escaping (PermissionScopeType?) -> Void)
}

class ScopePickerBridgeHandler: BridgeHandler {
    let methodName = "ccm.permission.showWikiScopePicker"
    let handler: BDXLynxBridgeHandler
    private weak var hostController: ScopePickerBridgeDelegate?

    init(hostController: ScopePickerBridgeDelegate) {
        self.hostController = hostController
        handler = { [weak hostController] (_, _, params, callback) in
            guard let hostController = hostController else { return }
            Self.handleEvent(hostController: hostController, params: params, completion: callback)
        }
    }

    private static func handleEvent(hostController: ScopePickerBridgeDelegate, params: [AnyHashable: Any]?, completion: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        guard let params = params,
              let needLockTips = params["shouldShowLockTips"] as? Bool,
              let defaultScopeTypeValue = params["defaultScopeType"] as? Int,
              let defaultScopeType = PermissionScopeType(rawValue: defaultScopeTypeValue) else {
            DocsLogger.error("failed to parse show wiki scope picker params")
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        hostController.showScopePicker(needLockTips: needLockTips, defaultScopeType: defaultScopeType) { scopeType in
            completion(BDXBridgeStatusCode.succeeded.rawValue, ["scopeType": scopeType?.rawValue])
        }
    }
}
