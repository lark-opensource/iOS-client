//
//  UtilOrientionService.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/9/19.
//  

import Foundation
import SKCommon
import SKUIKit

public final class UtilOrientionService: BaseJSService {

}

extension UtilOrientionService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.getOrientation]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.getOrientation.rawValue, let callback = params["callback"] as? String else {
            return
        }

        var result = UIApplication.shared.statusBarOrientation.isLandscape ? "landscape" : "portrait"
        // 在 iPad 时，告诉前端保持竖屏的逻辑就可以
        if SKDisplay.pad {
            result = "portrait"
        }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["type": result], completion: nil)
    }
}
