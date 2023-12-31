//
//  LabEffectService+Apply.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewRtcBridge

extension EffectType {
    var rtcCameraDeviceType: RtcCameraEffectType {
        switch self {
        case .retuschieren:
            return .retuschieren
        case .animoji:
            return .animoji
        case .filter:
            return .filter
        case .virtualbg:
            return .virtualbg
        }
    }
}
