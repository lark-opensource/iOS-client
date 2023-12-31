//
//  SKBitableRecommendNativeController+SSR.swift
//  SKBitable
//
//  Created by X-MAN on 2023/12/4.
//

import Foundation
import SKFoundation
import SKCommon

extension SKBitableRecommendNativeController {
    func preloadSSR(with urls: [String]) {
        let tokens = urls.compactMap { urlString in
            if let url = URL(string: urlString),
               let token = url.bitable.getBitableLinkedDocxToken() {
                return PreloadKey(objToken: token, type: .docX)
            }
            return nil
        }
        guard !tokens.isEmpty else {
            DocsLogger.info("SKBitableRecommendNativeController preload docx ssr tokens is empty")
            return
        }
        let userInfo = [DocPreloaderManager.preloadNotificationKey: tokens]
        NotificationCenter.default.post(name: Notification.Name.Docs.addToPreloadQueue, object: nil, userInfo: userInfo)
        DocsLogger.info("SKBitableRecommendNativeController preload docx ssr")
    }
}
