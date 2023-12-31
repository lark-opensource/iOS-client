//
//  OpenURLActionHandler.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/12/1.
//

import Foundation
import RustPB
import LarkModel
import LarkFoundation

public struct OpenURLActionHandler: ActionBaseHandler {
    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler?,
                                    actionDepth: Int) {
        assert(action.method == .openURL, "invalidate method")
        let openURL = action.openURLV2.openURL
        let urlStr = openURL.hasIos ? openURL.ios : openURL.url
        if let url = try? URL.forceCreateURL(string: urlStr), let from = dependency.targetVC {
            dependency.userResolver.navigator.open(url, from: from, completion: { _, _ in
                completion?(nil)
            })
        } else {
            completion?(NSError(domain: "invalidate url: \(urlStr)", code: -1))
        }
    }
}
