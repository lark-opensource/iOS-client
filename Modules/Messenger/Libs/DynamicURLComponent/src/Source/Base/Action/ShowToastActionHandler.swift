//
//  ShowToastActionHandler.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/11/30.
//

import Foundation
import RustPB
import LarkModel
import UniverseDesignToast

public struct ShowToastActionHandler: ActionBaseHandler {
    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler?,
                                    actionDepth: Int) {
        assert(action.method == .showToast, "invalidate method")

        mainOrAsync { [weak dependency] in
            guard let view = dependency?.targetVC?.view else {
                completion?(NSError(domain: "invalidate target view", code: -1, userInfo: nil))
                return
            }
            let toast = action.showToast
            var delay: TimeInterval = 3.0
            if toast.hasDuration, toast.duration > 0 {
                delay = TimeInterval(toast.duration) / 1000 // duration单位为ms
            }
            switch toast.type {
            case .success: UDToast.showSuccess(with: toast.content, on: view, delay: delay)
            case .error: UDToast.showFailure(with: toast.content, on: view, delay: delay)
            case .info: UDToast.showTips(with: toast.content, on: view, delay: delay)
            case .warning: UDToast.showWarning(with: toast.content, on: view, delay: delay)
            @unknown default: assertionFailure("unknown case")
            }
            completion?(nil)
        }
    }
}
