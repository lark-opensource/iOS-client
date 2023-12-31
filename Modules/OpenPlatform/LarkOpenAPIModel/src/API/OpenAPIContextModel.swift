//
//  OpenAPIContextModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/4.
//

import Foundation

public class OpenAPIFireEventParams: OpenAPIBaseParams {
    public enum PreCheckType: String {
        case shouldInterruption
        case isVCActive
        case none
    }

    public enum SceneType: String {
        case normal // fireEvent 到当前engine
        case render // fireEvent 到render
        case worker // fireEvent 到worker
    }

    public enum SourceType: String {
        case none
        case webViewComponent // 从web-view组件fireEvent到小程序worker
    }

    @OpenAPIRequiredParam(userOptionWithJsonKey: "event", defaultValue: "")
    public var event: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "sourceID", defaultValue: NSNotFound)
    public var sourceID: Int

    @OpenAPIOptionalParam(jsonKey: "data")
    public var data: [AnyHashable: Any]?

    // fire_event的前置判断，目前在调用fire_event时有的接口是判断isVCActiveContext，有的接口是判断shouldInterruption等，需要考虑一下fire_event的统一性，所以这里加了这个前置判断条件，以方便后续统一后，外部调用方无感
    @OpenAPIOptionalParam(jsonKey: "preCheckType")
    public var preCheckType: String?

    @OpenAPIOptionalParam(jsonKey: "sceneType")
    public var sceneType: String?

    @OpenAPIOptionalParam(jsonKey: "sourceType")
    public var sourceType: String?
    

    public convenience init(event: String, sourceID: Int = NSNotFound, data: [AnyHashable: Any]? = nil, preCheckType: PreCheckType, sceneType: SceneType = .normal, sourceType: SourceType = .none) throws {
        var dict: [String: Any] = ["event": event, "preCheckType": preCheckType.rawValue, "sourceID": sourceID, "sceneType": sceneType.rawValue, "sourceType": sourceType.rawValue]
        if let data = data {
            dict["data"] = data
        }
        try self.init(with: dict)
    }

    public var preCheck: PreCheckType {
        return PreCheckType(rawValue: preCheckType ?? "") ?? .none
    }

    public var scene: SceneType {
        return SceneType(rawValue: sceneType ?? "") ?? .normal
    }

    public var source: SourceType {
        return SourceType(rawValue: sourceType ?? "") ?? .none
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_event, _sourceID, _data, _preCheckType, _sceneType, _sourceType]
    }
}
