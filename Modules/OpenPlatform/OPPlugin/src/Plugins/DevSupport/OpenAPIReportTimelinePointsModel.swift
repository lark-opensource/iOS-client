//
//  OpenAPIReportTimelinePointsModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/5.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIReportTimelinePointsModel: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "points")
    public var points: String

    public convenience init(points: String) throws {
        let dict: [String: Any] = ["points": points]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_points]
    }

}
