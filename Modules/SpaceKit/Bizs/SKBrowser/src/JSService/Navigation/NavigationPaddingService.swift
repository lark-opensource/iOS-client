//
//  NavigationPaddingService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/25.
//

import Foundation
import SKCommon

class NavigationPaddingService: BaseJSService {
}

extension NavigationPaddingService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.getPadding]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let callback = params["callback"] as? String else { return }
        if let inset = ui?.scrollProxy?.contentInset {
            let getPaddingParams = ["top": inset.top, "left": inset.left, "right": inset.right, "bottom": inset.bottom]
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: getPaddingParams, completion: nil)
        }
    }
}
