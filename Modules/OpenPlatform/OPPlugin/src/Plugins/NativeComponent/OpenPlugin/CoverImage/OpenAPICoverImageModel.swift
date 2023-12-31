//
//  OpenAPICoverImageModel.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/5/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel

final class OpenAPICoverImageParams: OpenAPICoverImageBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "src", defaultValue: "")
    public var src: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "style", defaultValue: [:])
    public var style: [AnyHashable: Any]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: "")
    public var data: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "hidden", defaultValue: false)
    public var hidden: Bool

    // 固定在webview上
    @OpenAPIRequiredParam(userOptionWithJsonKey: "fixed", defaultValue: false)
    public var fixed: Bool

    // 固定在viewController.view上
    @OpenAPIRequiredParam(userOptionWithJsonKey: "absolutelyFixed", defaultValue: false)
    public var absolutelyFixed: Bool

    public var frame: CGRect = .zero

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        var properties = super.autoCheckProperties
        properties.append(contentsOf: [_src, _style, _data, _hidden, _fixed, _absolutelyFixed])
        return properties
    }

    public required init(with params: [AnyHashable : Any]) throws {
        try super.init(with: params)
        if absolutelyFixed {
            replace("left", params: &style)
            replace("top", params: &style)
            replace("width", params: &style)
            replace("height", params: &style)
        }
        
        let top = (style["top"] as? Double ?? 0).rounded(.up)
        let left = (style["left"] as? Double ?? 0).rounded(.up)
        let width = (style["width"] as? Double ?? 0).rounded(.up)
        let height = (style["height"] as? Double ?? 0).rounded(.up)
        self.frame = CGRect(x: left, y: top, width: width, height: height)
    }
    
    func replace(_ str: String, params: inout [AnyHashable: Any]) {
        if let value = params[str] as? String {
            let result = value.replacingOccurrences(of: "px", with: "")
            params[str] = Double(result)
        }
    }
}

class OpenAPICoverImageBaseParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "coverImageId", defaultValue: Int.max)
    public var componentID: Int

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_componentID]
    }

}

final class OpenAPIInsertCoverImageResult: OpenAPIBaseResult {
    public let componentID: Int

    public init(componentID: Int) {
        self.componentID = componentID
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["coverImageId": componentID]
    }
}
