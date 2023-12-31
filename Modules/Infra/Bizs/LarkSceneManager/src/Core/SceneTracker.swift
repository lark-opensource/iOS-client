//
//  SceneTracker.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/2/2.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker

final class SceneTracker {
    class func trackCreateScene(_ scene: Scene) {
        let params: [AnyHashable: Any] = [
            "window_type": scene.windowType ?? "",
            "create_way": scene.createWay ?? ""
        ]
        Tracker.post(
            TeaEvent(Homeric.IM_AUX_WINDOW_CREATE, params: params)
        )
    }

    @available(iOS 13.0, *)
    class func trackCloseScene(_ scene: UIScene) {
        let params = ["close_way": scene.isClickDelete ? "click" : "sys"]
        Tracker.post(TeaEvent(Homeric.IM_AUX_WINDOW_CLOSE, params: params))
    }

    class func trackShowScene() {
        Tracker.post(TeaEvent(Homeric.IM_AUX_WINDOW_SHOW))
    }
}
