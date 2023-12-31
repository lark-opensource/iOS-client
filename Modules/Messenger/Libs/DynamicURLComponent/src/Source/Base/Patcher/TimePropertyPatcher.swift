//
//  TimePropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct TimePropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .time, "type unmatched!")

        var time = base?.time ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .startTimeStamp: time.startTimeStamp = value.i64
            case .isCountdown: time.isCountdown = value.b
            case .ntpActionID: time.ntpActionID = value.str
            case .isEnd: time.isEnd = value.b
            case .endTimeStamp: time.endTimeStamp = value.i64
            @unknown default: return
            }
        }
        return .time(time)
    }
}
