//
//  OpenToastModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/15.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIShowToastParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "title", validChecker: {
        !$0.isEmpty
    })
    public var title: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "icon", defaultValue: "")
    public var icon: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "duration", defaultValue: 1500)
    public var duration: Int

    @OpenAPIRequiredParam(userOptionWithJsonKey: "mask", defaultValue: false)
    public var mask: Bool



    public convenience init(title: String, icon: String, duration: Int, mask: Bool) throws {
        let dict: [String: Any] = ["title": title, "icon": icon, "duration": duration, "mask": mask]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _icon, _duration, _mask]
    }

}
