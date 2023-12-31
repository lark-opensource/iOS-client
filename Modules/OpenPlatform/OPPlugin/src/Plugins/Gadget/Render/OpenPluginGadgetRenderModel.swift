//
//  OpenPluginGadgetRenderModel.swift
//  OPPluginBiz
//
//  Created by baojianjun on 2023/6/29.
//

import Foundation
import LarkOpenAPIModel

// MARK: reportTimeline

final class OpenPluginReportTimelineRequest: OpenAPIBaseParams {
    
    @OpenAPIOptionalParam(jsonKey: "phase")
    public var phase: String?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_phase]
    }
}
