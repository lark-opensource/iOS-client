//
//  ShowDialogActionHandler.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/1/7.
//

import Foundation
import RustPB
import LarkModel
import UniverseDesignDialog

public struct ShowDialogActionHandler: ActionBaseHandler {
    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler?,
                                    actionDepth: Int) {
        assert(action.method == .showDialog, "invalidate method")

        mainOrAsync { [weak dependency] in
            guard let dependency = dependency, let vc = dependency.targetVC else {
                completion?(NSError(domain: "invalidate params", code: -1, userInfo: nil))
                return
            }
            let dialog = UDDialog()
            let showDialog = action.showDialog
            if !showDialog.title.text.isEmpty {
                dialog.setTitle(text: showDialog.title.text,
                                numberOfLines: Int(showDialog.title.numberOfLines))
            }
            if !showDialog.content.text.isEmpty {
                dialog.setContent(text: showDialog.content.text,
                                  numberOfLines: Int(showDialog.content.numberOfLines))
            }
            for button in showDialog.buttons {
                switch button.type {
                case .default:
                    dialog.addSecondaryButton(text: button.text, numberOfLines: 0, dismissCompletion: {
                        handleButtonClick(entity: entity, button: button, dependency: dependency, actionDepth: actionDepth)
                    })
                case .primary:
                    dialog.addPrimaryButton(text: button.text, numberOfLines: 0, dismissCompletion: {
                        handleButtonClick(entity: entity, button: button, dependency: dependency, actionDepth: actionDepth)
                    })
                case .danger:
                    dialog.addDestructiveButton(text: button.text, numberOfLines: 0, dismissCompletion: {
                        handleButtonClick(entity: entity, button: button, dependency: dependency, actionDepth: actionDepth)
                    })
                @unknown default:
                    assertionFailure("unknown button type")
                    break
                }
            }
            dependency.userResolver.navigator.present(dialog, from: vc)
            completion?(nil)
        }
    }

    static func handleButtonClick(entity: URLPreviewEntity?,
                                  button: Basic_V1_UrlPreviewAction.ShowDialogAction.DialogButton,
                                  dependency: URLCardDependency,
                                  actionDepth: Int) {
        let currentStateID = entity?.previewBody?.currentStateID ?? ""
        let actions = entity?.previewBody?.states[currentStateID]?.actions ?? [:]
        guard let action = actions[button.actionID] else {
            ComponentActionRegistry.logger.error("[URLPreview] cannot find action: \(button.actionID) -> \(actions.keys)")
            return
        }
        let depth = actionDepth + 1
        ComponentActionRegistry.handleAction(entity: entity, action: action, actionID: button.actionID, dependency: dependency, actionDepth: depth)
    }
}
