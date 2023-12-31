//
//  BlockitTracker.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/12/1.
//

import Homeric
import LKCommonsTracker

class BlockitTracker {

    // MARK: PropsView
    // props-view曝光
    static func trackShowPropsview(tagCount: Int, extra: [String: Any]?) {
        var params = ["tag_count": tagCount] as [String: Any]
        if let dict = extra {
            params = params.merging(dict) { (first, _) -> Any in return first }
        }
        Tracker.post(TeaEvent(Homeric.PANO_SHOW_PROPSVIEW, params: params))
    }

    // 跳转进入pano页
    static func trackJumpPano(tagId: String) {
        let params = ["tag_id": tagId,
                      "from": "view"]
        Tracker.post(TeaEvent(Homeric.PANO_PANEL_AND_VIEW_JUMP, params: params))
    }
}
