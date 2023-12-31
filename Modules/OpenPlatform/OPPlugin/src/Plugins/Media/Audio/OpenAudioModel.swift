//
//  OpenAudioModel.swift
//  OPPlugin
//
//  Created by yi on 2021/6/8.
//

import Foundation
import LarkOpenAPIModel

class OpenAPIAudioInstanceParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "audioId")
    var audioId: Int

    convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_audioId]
    }
}

final class OpenAPIOperateAudioParams: OpenAPIAudioInstanceParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "operationType")
    var operationType: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "currentTime", defaultValue: 0.0)
    var currentTime: NSNumber

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return super.autoCheckProperties + [_operationType, _currentTime]
    }
}

final class OpenAPISetAudioStateParams: OpenAPIAudioInstanceParams {
    var data: [AnyHashable: Any] = [:]

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}

final class OpenAPICreateAudioInstanceResult: OpenAPIBaseResult {
    let audioId: Int

    init(audioId: Int) {
        self.audioId = audioId
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["audioId": audioId]
    }
}

final class OpenAPIGetAudioStateResult: OpenAPIBaseResult {
    let state: [AnyHashable: Any]

    init(state: [AnyHashable: Any]) {
        self.state = state
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return state
    }
}

final class OpenAPIOperateRecorderParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "operationType", validChecker: {
        !$0.isEmpty
    })
    var operationType: String

    var data: [AnyHashable: Any] = [:]

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}
