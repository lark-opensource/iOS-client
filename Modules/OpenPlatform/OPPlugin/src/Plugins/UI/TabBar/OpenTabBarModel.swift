//
//  OpenTabBarModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/7.
//

import Foundation
import LarkOpenAPIModel

private enum APIParamsKey: String {
    case animation
    case index
    case text
    case iconPath
    case selectedIconPath
    case color
    case selectedColor
    case backgroundColor
    case borderStyle
    case tag
    case borderColor
    case pagePath
    case dark
    case light
}

final class OpenAPIShowTabBarParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: APIParamsKey.animation.rawValue, defaultValue: false)
    public var animation: Bool

    public convenience init(animation: Bool) throws {
        let dict: [String: Any] = [APIParamsKey.animation.rawValue: animation]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_animation]
    }
}

final class OpenAPIHideTabBarParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: APIParamsKey.animation.rawValue, defaultValue: false)
    public var animation: Bool

    public convenience init(animation: Bool) throws {
        let dict: [String: Any] = [APIParamsKey.animation.rawValue: animation]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_animation]
    }
}

final class OpenAPIShowTabBarRedDotParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int

    public convenience init(index: Int) throws {
        let dict: [String: Any] = [APIParamsKey.index.rawValue: index]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index]
    }
}

final class OpenAPIHideTabBarRedDotParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int

    public convenience init(index: Int) throws {
        let dict: [String: Any] = [APIParamsKey.index.rawValue: index]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index]
    }
}

final class OpenAPIRemoveTabBarBadgeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int

    public convenience init(index: Int) throws {
        let dict: [String: Any] = [APIParamsKey.index.rawValue: index]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index]
    }
}

final class OpenAPISetTabBarBadgeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.text.rawValue)
    public var text: String

    public convenience init(index: Int, text: String) throws {
        let dict: [String: Any] = [APIParamsKey.index.rawValue: index, APIParamsKey.text.rawValue: text]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index, _text]
    }
}

final class OpenAPISetTabBarItemParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: APIParamsKey.text.rawValue, defaultValue: "")
    public var text: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: APIParamsKey.iconPath.rawValue, defaultValue: "")
    public var iconPath: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: APIParamsKey.selectedIconPath.rawValue, defaultValue: "")
    public var selectedIconPath: String

    public convenience init(index: Int, text: String, iconPath: String, selectedIconPath: String) throws {
        let dict: [String: Any] = [APIParamsKey.index.rawValue: index, APIParamsKey.text.rawValue: text, APIParamsKey.iconPath.rawValue: iconPath, APIParamsKey.selectedIconPath.rawValue: selectedIconPath]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index, _text, _iconPath, _selectedIconPath]
    }
}

final class OpenAPISetTabBarStyleParams: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.color.rawValue)
    public var color: String?
    
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.selectedColor.rawValue)
    public var selectedColor: String?
    
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.backgroundColor.rawValue)
    public var backgroundColor: String?
    
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.borderStyle.rawValue)
    public var borderStyle: String?
    
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.borderColor.rawValue)
    public var borderColor: String?     // 优先级：borderColor > borderStyle 需求单：https://bits.bytedance.net/meego/larksuite/story/detail/1100077

    public convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_color, _selectedColor, _backgroundColor, _borderStyle, _borderColor]
    }
}

final class OpenAPIRemoveTabBarItemParams: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: APIParamsKey.tag.rawValue)
    public var tag: String?

    public convenience init() throws {
        let dict: [String: Any] = [:]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_tag]
    }
}

final class OpenAPIAddTabBarItemParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.index.rawValue)
    public var index: Int
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.pagePath.rawValue)
    public var pagePath: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.text.rawValue)
    public var text: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.light.rawValue)
    public var light: [String : String]
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: APIParamsKey.dark.rawValue)
    public var dark: [String : String]

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_index, _pagePath, _text, _light, _dark]
    }
}
