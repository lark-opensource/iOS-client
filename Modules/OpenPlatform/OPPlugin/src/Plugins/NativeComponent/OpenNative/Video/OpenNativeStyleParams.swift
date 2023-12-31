//
//  OpenNativeStyleParams.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/4/25.
//

import Foundation
import LarkOpenAPIModel

/**
 映射至JSSDK base-native-element/src/index.ts baseStyleInfo类型
 */
final class OpenNativeBaseStyleInfo: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "hide", defaultValue: false)
    public var hide: Bool
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "top", defaultValue: 0)
    public var top: Double
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "left", defaultValue: 0)
    public var left: Double
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "height", defaultValue: 0)
    public var height: Double
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "width", defaultValue: 0)
    public var width: Double

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_hide, _top, _left, _height, _width]
    }
    
    public func frame() -> CGRect {
        return CGRect(origin: CGPoint(x: left, y: top), size: CGSize(width: width, height: height))
    }
}

/// text-align
/// @see as https://open.feishu.cn/document/uAjLw4CM/uYjL24iN/block/block-frame/view-layer/ttss/attributes/text/text-align
public enum TextAlignEnum: String, OpenAPIEnum {
    case left
    case center
    case right
    case start
    case end
}

public enum ObjectFitTypeEnum: String, OpenAPIEnum {
    case contain
    case fill
    case cover
}
