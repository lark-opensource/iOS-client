//
//  OpenNativeTextAreaParams.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/5/17.
//

import Foundation
import LarkOpenAPIModel
import LarkWebviewNativeComponent

final class OpenNativeTextAreaParams: OpenComponentBaseParams {
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "maxLength", defaultValue: 140)
    var maxLength: Int
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "placeholder", defaultValue: "")
    var placeholder: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "value", defaultValue: "")
    var value: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "fixed", defaultValue: false)
    var fixed: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "disabled", defaultValue: false)
    var disabled: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "hidden", defaultValue: false)
    var hidden: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "autoSize", defaultValue: false)
    var autoSize: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "adjustPosition", defaultValue: true)
    /// 键盘弹起时，是否自动上推页面
    var adjustPosition: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showConfirmBar", defaultValue: true)
    /// 是否显示键盘上方带有”完成“按钮那一栏
    var showConfirmBar: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "disableDefaultPadding", defaultValue: true)
    /// 是否取消系统textView自带的padding，上8下8左5右5
    var disableDefaultPadding: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "focus", defaultValue: false)
    /// 是否获得焦点
    var focus: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "autoFocus", defaultValue: false)
    /// 是否自动获得焦点
    var autoFocus: Bool
    
    @OpenComponentOptionalParam<OpenNativeTextAreaStyle>(jsonKey: "style")
    var style: OpenNativeTextAreaStyle?
    
    @OpenComponentOptionalParam<OpenNativeTextAreaPlaceholderStyle>(jsonKey: "placeholderStyle")
    var placeholderStyle: OpenNativeTextAreaPlaceholderStyle?
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "cursor", defaultValue: -1)
    var cursor: Int
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "selectionStart", defaultValue: -1)
    var selectionStart: Int
    @OpenComponentRequiredParam(userOptionWithJsonKey: "selectionEnd", defaultValue: -1)
    var selectionEnd: Int
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "holdKeyboard", defaultValue: false)
    var holdKeyboard: Bool
    
    @OpenComponentRequiredParam<OpenNativeTextAreaConfirmType>(userOptionWithJsonKey: "confirmType", defaultValue: .return)
    var confirmType: OpenNativeTextAreaConfirmType
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "confirmHold", defaultValue: false)
    var confirmHold: Bool
    
    @OpenComponentRequiredParam<OpenNativeTextAreaAdjustKeyboardTo>(userOptionWithJsonKey: "adjustKeyboardTo", defaultValue: .cursor)
    var adjustKeyboardTo: OpenNativeTextAreaAdjustKeyboardTo
    
    // properties between JSSDK and Native
    @OpenComponentRequiredParam(userOptionWithJsonKey: "data", defaultValue: "")
    var data: String
    
    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_maxLength, _placeholder, _value, _fixed, _disabled,
                _hidden, _autoSize, _adjustPosition, _showConfirmBar, _disableDefaultPadding,
                _focus, _autoFocus, _style, _placeholderStyle, _cursor,
                _selectionStart, _selectionEnd, _holdKeyboard, _confirmType,
                _confirmHold, _adjustKeyboardTo, _data
        ]
    }
}

enum OpenNativeTextAreaConfirmType: String, OpenAPIEnum {
    case send
    case search
    case next
    case go
    case done
    case `return`
}

enum OpenNativeTextAreaAdjustKeyboardTo: String, OpenAPIEnum {
    case cursor
    case bottom
}

// MARK: - OpenNativeTextAreaBaseFont

class OpenNativeTextAreaBaseFont: OpenComponentBaseParams {
    @OpenComponentRequiredParam(userOptionWithJsonKey: "fontWeight", defaultValue: "")
    public var fontWeight: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "fontFamily", defaultValue: "")
    public var fontFamily: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "color", defaultValue: "")
    public var color: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "fontSize", defaultValue: 0)
    public var fontSize: Double
    
    public override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_fontWeight, _fontFamily, _color, _fontSize];
    }
    
    func font() -> UIFont {
        return UIFont.css(fontFamily: fontFamily, fontSize: fontSize, fontWeight: fontWeight)
    }
}

// MARK: - OpenNativeTextAreaStyle

final class OpenNativeTextAreaStyle: OpenNativeTextAreaBaseFont {
    // MARK: css style
    @OpenComponentRequiredParam(userOptionWithJsonKey: "top", defaultValue: 0)
    public var top: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "left", defaultValue: 0)
    public var left: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "height", defaultValue: 0)
    public var height: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "width", defaultValue: 0)
    public var width: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "backgroundColor", defaultValue: "")
    public var backgroundColor: String
    
    // MARK: css style 2
    @OpenComponentRequiredParam(userOptionWithJsonKey: "minHeight", defaultValue: 0)
    public var minHeight: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "maxHeight", defaultValue: 0)
    public var maxHeight: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "marginBottom", defaultValue: 0)
    public var marginBottom: Double
    
    // MARK: font style
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "textAlign", defaultValue: .left)
    public var textAlign: TextAlignEnum
    
    public override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        var tmp = super.autoCheckProperties
        tmp.append(contentsOf: [
            _top, _left, _height, _width, _backgroundColor,
            _minHeight, _maxHeight, _marginBottom, _textAlign,
        ])
        return tmp
    }
    
    func textAlignment() -> NSTextAlignment {
        switch textAlign {
        case .left:
            return .left
        case .right:
            return .right
        case .center:
            return .center
        default:
            return .left
        }
    }
}

// MARK: - OpenNativeTextAreaPlaceholderStyle

typealias OpenNativeTextAreaPlaceholderStyle = OpenNativeTextAreaBaseFont

// MARK: - API

final class OpenNativeTextareaShowKeyboardParams: OpenAPIBaseParams {
    
    @OpenAPIOptionalParam(jsonKey: "cursor")
    var cursor: Int?
    
    @OpenAPIOptionalParam(jsonKey: "selectionStart")
    var selectionStart: Int?
    
    @OpenAPIOptionalParam(jsonKey: "selectionEnd")
    var selectionEnd: Int?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_cursor, _selectionStart, _selectionEnd]
    }
}

// MARK: - Event

final class OpenNativeTextAreaFocusResult: OpenComponentBaseResult {
    private let value: String
    private let height: Double
    
    init(value: String, height: Double) {
        self.value = value
        self.height = height
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "value": value,
            "height": height
        ]
    }
}

final class OpenNativeTextAreaBlurResult: OpenComponentBaseResult {
    private let value: String
    private let cursor: Int
    
    init(value: String, cursor: Int) {
        self.value = value
        self.cursor = cursor
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "value": value,
            "cursor": cursor
        ]
    }
}

final class OpenNativeTextAreaLineChangeResult: OpenComponentBaseResult {
    private let height: Double
    private let lineCount: Int
    
    init(height: Double, lineCount: Int) {
        self.height = height
        self.lineCount = lineCount
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "height": height,
            "lineCount": lineCount
        ]
    }
}

final class OpenNativeTextAreaInputResult: OpenComponentBaseResult {
    private let value: String
    private let cursor: Int
    
    init(value: String, cursor: Int) {
        self.value = value
        self.cursor = cursor
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "value": value,
            "cursor": cursor
        ]
    }
}

final class OpenNativeTextAreaConfirmResult: OpenComponentBaseResult {
    private let value: String
    
    init(value: String) {
        self.value = value
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "value": value
        ]
    }
}

final class OpenNativeTextAreaKeyboardHeightChangeResult: OpenComponentBaseResult {
    private let height: Double
    private let duration: Double
    
    init(height: Double, duration: Double) {
        self.height = height
        self.duration = duration
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "height": height,
            "duration": duration
        ]
    }
}
