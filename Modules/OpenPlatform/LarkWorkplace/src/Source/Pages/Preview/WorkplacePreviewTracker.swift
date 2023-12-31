//
//  WorkplacePreviewTracker.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/20.
//

import Foundation
import LKCommonsTracker
import Homeric

final class PreviewTracker {
    /// 客户端预览页面曝光
    /// - Parameter templateId: 创建门户 id
    static func previewPageView(templateId: String) {
        Tracker.post(TeaEvent(Homeric.OPENPLATFORM_WORKSPACE_PREVIEW_MAIN_PAGE_VIEW, params: [
            "workspace_id": templateId
        ]))
    }
}
