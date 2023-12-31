//
//  UpdateSecretLevelBridgeHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/14.
//

import Foundation
import BDXBridgeKit
import BDXServiceCenter
import SKFoundation
import SwiftyJSON

protocol UpdateSecretLevelHandler: AnyObject {
    func updateSecretLevel(token: String, type: ShareDocsType, meta: ShareBizMeta, completion: @escaping (Bool) -> Void)
}

class UpdateSecretLevelBridgeHandler: BridgeHandler {
    let methodName = "ccm.permission.updateSecretLevel"
    let handler: BDXLynxBridgeHandler
    private weak var hostController: UpdateSecretLevelHandler?

    init(hostController: UpdateSecretLevelHandler) {
        self.hostController = hostController
        handler = { [weak hostController] (_, _, params, callback) in
            guard let hostController = hostController else { return }
            Self.handleEvent(hostController: hostController, params: params, completion: callback)
        }
    }

    private static func handleEvent(hostController: UpdateSecretLevelHandler, params: [AnyHashable: Any]?, completion: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        guard let params = params,
              let token = params["token"] as? String,
              let docTypeRawValue = params["type"] as? Int,
              let metaInfo = params["meta"] as? [String: Any] else {
            DocsLogger.error("failed to parse update secret level params")
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        let docType = ShareDocsType(rawValue: docTypeRawValue)
        let metaJSON = JSON(metaInfo)
        let meta = ShareBizMeta(metaJSON)
        hostController.updateSecretLevel(token: token, type: docType, meta: meta) { didChanged in
            completion(BDXBridgeStatusCode.succeeded.rawValue, ["didChanged": didChanged])
        }
    }
}
