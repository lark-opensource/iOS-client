//
//  DialogBridgeHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/3/31.
//

import Foundation
import BDXServiceCenter
import BDXBridgeKit
import UniverseDesignDialog
import UniverseDesignColor
import SKFoundation
import EENavigator
import UIKit

class DialogBridgeHandler: BridgeHandler {

    enum ActionType: Int {
        case normal
        case secondary
        case destructive
    }

    let methodName = "ccm.showDialog"
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
        let dialog = UDDialog()
        let title = params?["title"] as? String
        let content = params?["content"] as? String
        let contentGravity = params?["contentGravity"] as? Int
        guard let actions = params?["actions"] as? [[String: Any]] else {
            completion(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
            return
        }
        if let title = title {
            dialog.setTitle(text: title)
        }
        if let content = content {
            if let contentGravity = contentGravity {
                var alignment: NSTextAlignment = .center
                switch contentGravity {
                case 0:
                    alignment = .center
                case 1:
                    alignment = .left
                case 2:
                    alignment = .right
                default:
                    DocsLogger.error("unable to parse contentGravity: \(contentGravity)")
                }
                dialog.setContent(text: content, alignment: alignment)
            } else {
                dialog.setContent(text: content)
            }
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
            let dismissCompletion = {
                completion(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": actionID])
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
