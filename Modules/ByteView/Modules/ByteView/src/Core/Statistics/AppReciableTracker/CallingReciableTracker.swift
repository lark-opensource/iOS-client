//
//  CallingReciableTracker.swift
//  ByteView
//
//  Created by chentao on 2021/3/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class CallingReciableTracker {
    static func startEnterCalling(source: String, isVoiceCall: Bool) {
        LarkAppreciableTracker.shared.start(scene: .VCCalling, event: .vc_enter_calling,
                                            extraCategory: ["source": source, "is_voiceCall": isVoiceCall])
    }

    static func endEnterCalling() {
        LarkAppreciableTracker.shared.end(event: .vc_enter_calling)
    }

    static func cancelStartCalling() {
        LarkAppreciableTracker.shared.cancel(event: .vc_enter_calling)
    }
}
