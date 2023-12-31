//
//  OpenAppBadgeModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/9.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIUpdateBadgeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "badgeNum")
    public var badgeNum: Int

    public convenience init(badgeNum: Int) throws {
        let dict: [String: Any] = ["badgeNum": badgeNum]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_badgeNum]
    }
}

final class OpenAPIServerBadgePush: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: "appId")
    public var appId: String?

    @OpenAPIOptionalParam(jsonKey: "appIds")
    public var appIds: [String]?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_appId, _appIds]
    }
}

final class OpenAPIReportBadgeResult: OpenAPIBaseResult {
    public var isMatched: Bool

    public init(isMatched: Bool) {
        self.isMatched = isMatched
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["isMatched": isMatched]
    }
}
