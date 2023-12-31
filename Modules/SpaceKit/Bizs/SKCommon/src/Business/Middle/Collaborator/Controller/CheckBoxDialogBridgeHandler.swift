//
//  CheckBoxDialogBridgeHandler.swift
//  SKCommon
//
//  Created by peilongfei on 2022/12/2.
//  


import Foundation
import BDXServiceCenter
import BDXBridgeKit
import UniverseDesignDialog
import UniverseDesignColor
import SKFoundation
import EENavigator
import UIKit

class CheckBoxDialogBridgeHandler: BridgeHandler {

    enum ActionType: Int {
        case normal
        case secondary
        case destructive
    }

    let methodName = "ccm.showCheckBoxDialog"
    let handler: BDXLynxBridgeHandler
    private weak var hostController: UIViewController?

    init(hostController: UIViewController) {
        self.hostController = hostController
        handler = { [weak hostController] (_, _, params, callback) in
            guard let hostController = hostController else { return }
            Self.handleEvent(hostController: hostController, params: params, completion: callback)
        }
    }

    private static func handleEvent(hostController: UIViewController, params: [AnyHashable: Any]?, completion: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.isAutorotatable = true
        let title = params?["title"] as? String
        let content = params?["content"] as? String
        let hintStr = params?["hintStr"] as? String
        guard let actions = params?["actions"] as? [[String: Any]] else {
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        if let title = title {
            dialog.setTitle(text: title)
        }
        if let content = content {
            dialog.setContent(text: content, checkButton: true)
        }
        if let hintStr = hintStr {
            dialog.setCheckButton(text: hintStr)
        }
        var hasValidButton = false
        actions.forEach { info in
            guard let actionID = info["actionID"] as? String,
                  let actionText = info["actionText"] as? String,
                  let actionTypeValue = info["actionType"] as? Int,
                  let actionType = ActionType(rawValue: actionTypeValue) else {
                DocsLogger.error("unable to parse action info: \(info)")
                return
            }

            let dismissCompletion = { [weak dialog] in
                guard let dialog = dialog else { return }
                completion(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": actionID, "isChecked": dialog.isChecked])
            }
            switch actionType {
            case .normal:
                dialog.addPrimaryButton(text: actionText, dismissCompletion: dismissCompletion)
            case .destructive:
                dialog.addDestructiveButton(text: actionText, dismissCompletion: dismissCompletion)
            case .secondary:
                dialog.addSecondaryButton(text: actionText, dismissCompletion: dismissCompletion)
            }
            hasValidButton = true
        }
        guard hasValidButton else {
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        hostController.present(dialog, animated: true)
    }
}
