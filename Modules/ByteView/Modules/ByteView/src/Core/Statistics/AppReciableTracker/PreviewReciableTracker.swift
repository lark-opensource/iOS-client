//
//  PreviewReciableTracker.swift
//  ByteView
//
//  Created by chentao on 2021/3/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class PreviewReciableTracker {
    static func startEnterPreview() {
        LarkAppreciableTracker.shared.start(scene: .VCPreview, event: .vc_enter_preview_total)
    }

    static func startEnterPreviewForPure() {
        LarkAppreciableTracker.shared.start(scene: .VCPreview, event: .vc_enter_preview_pure)
    }

    static func endEnterPreview() {
        LarkAppreciableTracker.shared.end(event: .vc_enter_preview_total)
    }

    static func endEnterPreviewForPure() {
        LarkAppreciableTracker.shared.end(event: .vc_enter_preview_pure)
    }

    static func cancelStartPreview() {
        LarkAppreciableTracker.shared.cancel(event: .vc_enter_preview_total)
    }
    // 下面埋点展示用不到，存打开页面目前没有报错失败的概率
    static func cancelStartPreviewForPure() {
        LarkAppreciableTracker.shared.cancel(event: .vc_enter_preview_pure)
    }

    static func startOpenCamera() {
        LarkAppreciableTracker.shared.start(scene: .VCPreview, event: .vc_open_camera_time)
    }

    static func endOpenCamera() {
        LarkAppreciableTracker.shared.end(event: .vc_open_camera_time)
    }
}
