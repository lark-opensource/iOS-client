//
//  UtilTitleService.swift
//  SpaceKit
//
//  Created by Songwen Ding on 2018/6/20.
//

import Foundation
import SKCommon

class UtilTitleService {
    weak var uiDisplay: BrowserViewDisplayConfig?
    init(_ uiDisplay: BrowserViewDisplayConfig) {
        self.uiDisplay = uiDisplay
    }
}

extension UtilTitleService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilTitleSetOfflineName]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let objToken = params["objToken"] as? String,
            let name = params["newName"] as? String else { return }
        uiDisplay?.setTitle(name, for: objToken)
    }
}
