//longweiwei

import Foundation
import SKCommon
import SKFoundation

public final class UtilToggleSwipeGestureService: BaseJSService {

}

extension UtilToggleSwipeGestureService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.toggleSwipeGesture]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let enableSwipeGesture = params["enabled"] as? Bool else {
            DocsLogger.info("缺少是否开启左滑返回手势状态")
            return
        }

        ui?.displayConfig.setToggleSwipeGestureEnable(enableSwipeGesture)
    }
}
