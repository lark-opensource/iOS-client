//
//  OpenWebViewComponentModel.swift
//  OPPlugin
//
//  Created by yi on 2021/5/13.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIInsertHTMLWebViewResult: OpenAPIBaseResult {

    public var htmlId: Int

    public init(htmlId: Int) {
        self.htmlId = htmlId
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["htmlId": htmlId]
    }
}

class OpenAPIHTMLWebViewParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "htmlId", defaultValue: 0)
    public var htmlId: Int

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_htmlId]
    }
}

final class OpenAPIInsertHTMLWebViewParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "position", defaultValue: [:])
    public var position: [AnyHashable : Any]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "progressBarColor", defaultValue: "")
    public var progressBarColor: String

    public var frame: CGRect = CGRect.zero
    
    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        var left: Double = 0.0
        if let leftParam = self.position["left"] as? NSNumber {
            left = leftParam.doubleValue
        }
        var top: Double = 0.0
        if let topParam = self.position["top"] as? NSNumber {
            top = topParam.doubleValue
        }
        var width: Double = 0.0
        if let widthParam = self.position["width"] as? NSNumber {
            width = widthParam.doubleValue
        }
        var height: Double = 0.0
        if let heightParam = self.position["height"] as? NSNumber {
            height = heightParam.doubleValue
        }
        self.frame = CGRect(x: left, y: top, width: width, height: height)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_position, _progressBarColor]
    }
}

final class OpenAPIResizeHTMLWebViewParams: OpenAPIHTMLWebViewParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "position", defaultValue: [:])
    public var position: [AnyHashable : Any]

    public var frame: CGRect = CGRect.zero

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        var left: Double = 0.0
        if let leftParam = self.position["left"] as? NSNumber {
            left = leftParam.doubleValue
        }
        var top: Double = 0.0
        if let topParam = self.position["top"] as? NSNumber {
            top = topParam.doubleValue
        }
        var width: Double = 0.0
        if let widthParam = self.position["width"] as? NSNumber {
            width = widthParam.doubleValue
        }
        var height: Double = 0.0
        if let heightParam = self.position["height"] as? NSNumber {
            height = heightParam.doubleValue
        }
        self.frame = CGRect(x: left, y: top, width: width, height: height)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return super.autoCheckProperties + [_position]
    }
}

final class OpenAPIUpdateHTMLWebViewParams: OpenAPIHTMLWebViewParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "src", validChecker: {
        !$0.isEmpty
    })
    public var src: String

    public var srcURL: URL?

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)

        let mutableSet = NSMutableCharacterSet.alphanumeric()
        mutableSet.formIntersection(with: CharacterSet(charactersIn: "#:/;?+-.@&=%$_!*'(),{}|^~[]`<>\\\""))
        if let urlString = self.src.addingPercentEncoding(withAllowedCharacters: mutableSet.inverted), var url = URL(string: urlString) {
            self.srcURL = url
        } else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("Format of src parameter is error")
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return super.autoCheckProperties + [_src]
    }
}

final class OpenAPIOperateHTMLWebViewParams: OpenAPIHTMLWebViewParams {
    public var hide = false

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if let hideParam = params["hide"] as? NSNumber {
            self.hide = hideParam.boolValue
        }
    }
}

class OpenPluginTransferMessageParams: OpenAPIBaseParams {

    @OpenAPIOptionalParam(jsonKey: "channel")
    public var channel: String?

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "from", validChecker: {
        $0 == "worker" || $0 == "webview"
    })
    public var from: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: [:])
    public var data: Dictionary

    public convenience init(channel: String?, from: String, data: [AnyHashable: Any]) throws {
        var dict = [String : Any]()
        dict["channel"] = channel
        dict["from"] = from
        dict["data"] = data
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_channel, _from, _data]
    }
}
