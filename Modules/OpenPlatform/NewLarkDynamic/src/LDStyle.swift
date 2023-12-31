//
//  LDStyle.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/19.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor

private var _borderRadiusKey = "_borderRadiusKey"
extension UIView {
    var borderRadius: CSSValue? {
        get {
            return objc_getAssociatedObject(self, &_borderRadiusKey) as? CSSValue
        }
        set {
            objc_setAssociatedObject(self, &_borderRadiusKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
            if let borderRadius = newValue {
                self.layer.cornerRadius = StyleHelpers.cornerRadius(
                    borderRadius: borderRadius,
                    elementSize: self.bounds.size
                )
            }
        }
    }
}

let originLDStyleFontSize: CGFloat = 16.0
class LDStyle: ASComponentStyle {
    var styleValues: [StyleValue] = [] {
        didSet {
            parse(styleValues)
        }
    }
    /// 默认的font
    var font: UIFont
    var color: UIColor?
    var borderRadius: CSSValue = 0
    var underlineStyle: NSUnderlineStyle?
    let context: LDContext?
    let elementId: String?
    private var _underlineColor: UIColor?
    var underlineColor: UIColor? {
        get {
            return _underlineColor ?? self.color
        }
        set {
            _underlineColor = newValue
        }
    }
    var strikethroughStyle: NSUnderlineStyle?
    private var _strikethroughColor: UIColor?
    var strikethroughColor: UIColor? {
        get {
            return _strikethroughColor ?? self.color
        }
        set {
            _strikethroughColor = newValue
        }
    }
    let originFontSize: CGFloat = originLDStyleFontSize
    var fontSize: CGFloat = originLDStyleFontSize
    var fontObliqueness: NSNumber = 0
    var fontWeight: NSNumber = 0
    var backgroundColorActive: UIColor = .clear
    var backgroundColorDisable: UIColor = .clear
    var textAlign: NSTextAlignment = .left
    var wordBreak: NSLineBreakMode = .byWordWrapping
    /// DarkMode
    var colorDarkMode: UIColor?
    var colorToken: String?
    var underlineColorDarkMode: UIColor?
    var underlineColorToken: String?
    var strikethroughColorDarkMode: UIColor?
    var strikethroughColorToken: String?
    var backgroundColorDarkMode: UIColor?
    var backgroundColorToken: String?
    var backgroundColorActiveDarkMode: UIColor?
    var backgroundColorActiveToken: String?
    var backgroundColorDisableDarkMode: UIColor?
    var backgroundColorDisableToken: String?
    var borderDarkMode: UIColor?
    var borderToken: String?
    var disabledTextColor: UIColor?
    var disabledTextColorDarkMode: UIColor?
    var disabledTextColorToken: String?

    init(context: LDContext? = nil, elementId: String? = nil) {
        self.context = context
        self.elementId = elementId
        let fontSize = context?.zoomFontSize(originSize: originLDStyleFontSize, elementId: elementId) ?? originLDStyleFontSize
        self.fontSize = fontSize
        self.font = UIFont.systemFont(ofSize: fontSize)
        super.init(ASComponentUIStyle())
        // Default values
        self.backgroundColor = .clear
        self.flexWrap = .wrap
        self.alignContent = .auto
        self.margin = 0
        self.marginTop = 0
        self.marginLeft = 0
        self.marginRight = 0
        self.marginBottom = 0
        self.padding = 0
        self.paddingTop = 0
        self.paddingLeft = 0
        self.paddingRight = 0
        self.paddingBottom = 0
        self.aspectRatio = 10E8
        self.alignContent = .flexStart
        self.alignItems = .flexStart
    }

    override func applyToView(_ view: UIView) {
        super.applyToView(view)
        view.borderRadius = borderRadius
    }

    private func parse(_ styles: [StyleValue]) {
        color = nil
        for style in styleValues {
            switch style {
            case .borderColor(let color):
                border = Border(BorderEdge(
                    width: border?.top.width ?? 0,
                    color: color
                ))
            case .borderColorDarkMode(let color):
                borderDarkMode = color
                break
            case .borderColorToken(let token):
                borderToken = token
                break
            case .borderWidth(let width):
                border = Border(BorderEdge(
                    width: width,
                    color: border?.top.color ?? .clear
                ))
                break
            case .borderRadius(let radius):
                borderRadius = radius
                break
            case .underlineStyle(let style):
                underlineStyle = style
                break
            case .underlineColor(let color):
                underlineColor = color
                break
            case .underlineColorDarkMode(let color):
                underlineColorDarkMode = color
                break
            case .underlineColorToken(let token):
                underlineColorToken = token
                break
            case .strikethroughStyle(let style):
                strikethroughStyle = style
                break
            case .strikethroughColor(let color):
                strikethroughColor = color
                break
            case .strikethroughColorDarkMode(let color):
                strikethroughColorDarkMode = color
                break
            case .strikethroughColorToken(let token):
                strikethroughColorToken = token
                break
            case .fontSize(let size):
                fontSize = context?.zoomFontSize(originSize: size, elementId: elementId) ?? size
            case .backgroundColor(let color):
                backgroundColor = color
            case .backgroundColorDarkMode(let color):
                backgroundColorDarkMode = color
                break
            case .backgroundColorToken(let token):
                backgroundColorToken = token
                break
            case .color(let color):
                self.color = color
            case .colorDarkMode(let color):
                colorDarkMode = color
                break
            case .colorToken(let token):
                colorToken = token
                break
            case .fontObliqueness(let value):
                fontObliqueness = value
                break
            case .fontWeight(let value):
                fontWeight = value
                break
            case .backgroundColorActive(let color):
                backgroundColorActive = color
                break
            case .backgroundColorActiveDarkMode(let color):
                backgroundColorActiveDarkMode = color
                break
            case .backgroundColorActiveToken(let token):
                backgroundColorActiveToken = token
                break
            case .backgroundColorDisable(let color):
                backgroundColorDisable = color
                break
            case .backgroundColorDisableDarkMode(let color):
                backgroundColorDisableDarkMode = color
                break
            case .backgroundColorDisableToken(let token):
                backgroundColorDisableToken = token
                break
            case .textAlign(let value):
                self.textAlign = value
            case .wordBreak(let value):
                self.wordBreak = value
            case .disabledTextColor(let value):
                self.disabledTextColor = value
            case .disabledTextColorDarkMode(let value):
                self.disabledTextColorDarkMode = value
            case .disabledTextColorToken(let value):
                self.disabledTextColorToken = value
            }
        }
        font = LDStyle.font(
            originFont: UIFont.systemFont(ofSize: fontSize),
            enumValue: fontWeight.doubleValue + fontObliqueness.doubleValue
        )
    }

    static func font(originFont: UIFont, enumValue: Double) -> UIFont {
        switch enumValue {
        case 0.25: return originFont.bold()
        case 0.50: return originFont.italic()
        case 0.75: return originFont.italicBold()
        default: return UIFont.systemFont(ofSize: originFont.pointSize)
        }
    }
}
/// DarkMode下的扩展
extension LDStyle {
    private func logWrongToken(token: String?) {
        if let colorNotExistToken = token {
            cardlog.warn("LDStyle parse color \(colorNotExistToken) without color")
        }
    }
    public func getColor() -> UIColor? {
        if let token = colorToken, let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = colorDarkMode, let lightColor = color {
            return lightColor & darkColor
        }
        return color
    }
    
    public func getUnderlineColor() -> UIColor? {
        if let token = underlineColorToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = underlineColorDarkMode, let lightColor = underlineColor {
            return lightColor & darkColor
        }
        return underlineColor
    }
    
    public func getStrikethroughColor() -> UIColor? {
        if let token = strikethroughColorToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = strikethroughColorDarkMode, let lightColor = strikethroughColor {
            return lightColor & darkColor
        }
        return strikethroughColor
    }
    public func getBackgroundColor() -> UIColor? {
        if let token = backgroundColorToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = backgroundColorDarkMode, let lightColor = backgroundColor {
            return lightColor & darkColor
        }
        return backgroundColor
    }
    
    public func getBackgroundColorActive() -> UIColor? {
        if let token = backgroundColorActiveToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = backgroundColorActiveDarkMode {
            return backgroundColorActive & darkColor
        }
        return backgroundColorActive
    }
    
    public func getBackgroundColorDisable() -> UIColor? {
        if let token = backgroundColorDisableToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        logWrongToken(token: colorToken)
        if let darkColor = backgroundColorDisableDarkMode {
            return backgroundColorDisable & darkColor
        }
        return backgroundColorDisable
    }
    
    public func getBorderColor() -> UIColor? {
        if let token = borderToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        if let darkColor = borderDarkMode, let lightColor = border?.top.color {
            return lightColor & darkColor
        }
        return border?.top.color
    }
    public func updateBorderColor(color: UIColor) {
        if let _border = border {
            border = Border(BorderEdge(width: _border.top.width,
                                       color: color,
                                       style: _border.top.style))
        }
    }
    public func getDisableTextColor() -> UIColor? {
        if let token = disabledTextColorToken,
           let tokenColor = UDColor.getValueByKey(UDColor.Name(token)) {
            return tokenColor
        }
        if let darkColor = disabledTextColorDarkMode, let lightColor = disabledTextColor {
            return lightColor & darkColor
        }
        return nil
    }
}

enum StyleValue {
    case underlineStyle(NSUnderlineStyle)
    case underlineColor(UIColor)
    case underlineColorDarkMode(UIColor)
    case underlineColorToken(String)
    case strikethroughStyle(NSUnderlineStyle)
    case strikethroughColor(UIColor)
    case strikethroughColorDarkMode(UIColor)
    case strikethroughColorToken(String)
    case fontSize(CGFloat)
    case fontObliqueness(NSNumber)
    case fontWeight(NSNumber)
    case backgroundColor(UIColor)
    case backgroundColorDarkMode(UIColor)
    case backgroundColorToken(String)
    case backgroundColorActive(UIColor)
    case backgroundColorActiveDarkMode(UIColor)
    case backgroundColorActiveToken(String)
    case backgroundColorDisable(UIColor)
    case backgroundColorDisableDarkMode(UIColor)
    case backgroundColorDisableToken(String)
    case color(UIColor)
    case colorDarkMode(UIColor)
    case colorToken(String)
    case borderRadius(CSSValue)
    case borderColor(UIColor)
    case borderColorDarkMode(UIColor)
    case borderColorToken(String)
    case borderWidth(CGFloat)
    case textAlign(NSTextAlignment)
    case wordBreak(NSLineBreakMode)
    case disabledTextColor(UIColor)
    case disabledTextColorDarkMode(UIColor)
    case disabledTextColorToken(String)
    var getKeyAndValue: (String, Any) {
        switch self {
        case .underlineStyle(let value):
            return ("underlineStyle", value)
        case .underlineColor(let value):
            return ("underlineColor", value)
        case .underlineColorDarkMode(let value):
            return ("underlineColorDarkMode", value)
        case .underlineColorToken(let value):
            return ("underlineColorToken", value)
        case .strikethroughStyle(let value):
            return ("strikethroughStyle", value)
        case .strikethroughColor(let value):
            return ("strikethroughColor", value)
        case .strikethroughColorDarkMode(let value):
            return ("strikethroughColorDarkMode", value)
        case .strikethroughColorToken(let value):
            return ("strikethroughColorToken", value)
        case .fontSize(let value):
            return ("fontSize", value)
        case .fontObliqueness(let value):
            return ("fontObliqueness", value)
        case .fontWeight(let value):
            return ("fontWeight", value)
        case .backgroundColor(let value):
            return ("backgroundColor", value)
        case .backgroundColorDarkMode(let value):
            return ("backgroundColorDarkMode", value)
        case .backgroundColorToken(let value):
            return ("backgroundColorToken", value)
        case .backgroundColorActive(let value):
            return ("backgroundColorActive", value)
        case .backgroundColorActiveDarkMode(let value):
            return ("backgroundColorActiveDarkMode", value)
        case .backgroundColorActiveToken(let value):
            return ("backgroundColorActiveToken", value)
        case .backgroundColorDisable(let value):
            return ("backgroundColorDisable", value)
        case .backgroundColorDisableDarkMode(let value):
            return ("backgroundColorDisableDarkMode", value)
        case .backgroundColorDisableToken(let value):
            return ("backgroundColorDisableToken", value)
        case .color(let value):
            return ("color", value)
        case .colorDarkMode(let value):
            return ("colorDarkMode", value)
        case .colorToken(let value):
            return ("colorToken", value)
        case .borderColor(let value):
            return ("borderColor", value)
        case .borderColorDarkMode(let value):
            return ("borderColorDarkMode", value)
        case .borderColorToken(let value):
            return ("borderColorToken", value)
        case .borderWidth(let value):
            return ("borderWidth", value)
        case .borderRadius(let value):
            return ("borderRadius", value)
        case .textAlign(let value):
            return ("textAlign", value)
        case .wordBreak(let value):
            return ("wordBreak", value)
        case .strikethroughColorDarkMode(let value):
            return ("strikethroughColorDarkMode", value)
        case .backgroundColorDarkMode(let value):
            return ("backgroundColorDarkMode", value)
        case .colorDarkMode(let value):
            return ("colorDarkMode", value)
        case .backgroundColorActiveDarkMode(let value):
            return ("backgroundColorActiveDarkMode", value)
        case .backgroundColorDisableDarkMode(let value):
            return ("backgroundColorDisableDarkMode", value)
        case .disabledTextColor(let value):
            return ("disabledTextColor", value)
        case .disabledTextColorDarkMode(let value):
            return ("disabledTextColorDarkMode", value)
        case .disabledTextColorToken(let value):
            return ("disabledTextColorToken", value)
        }
    }
}

typealias StyleParseHandler = (String) -> [StyleValue]

class StyleParser {
    private static var uiParsers: [String: StyleParseHandler] = [
        "textDecoration": textDecorationParser,
        "textDecorationLine": textDecorationLineParser,
        "textDecorationColor": textDecorationColorParser,
        "fontSize": fontSizeParser,
        "fontStyle": fontStyleParser,
        "fontWeight": fontWeightParser,
        "backgroundColor": backgroundColorParser,
        "backgroundColorActive": backgroundColorActiveParser,
        "backgroundColorDisable": backgroundColorDisableParser,
        "color": colorParser,
        "colorDarkMode": commonHexColorParser(style: .colorDarkMode(.white)),
        "colorToken": commonTokenColorParser(style: .colorToken("")),
        "borderColor": borderColorParser,
        "borderColorDarkMode": commonHexColorParser(style: .borderColorDarkMode(.white)),
        "borderColorToken": commonTokenColorParser(style: .borderColorToken("")),
        "borderWidth": borderWidthParser,
        "borderRadius": borderRadiusParser,
        "textAlign": textAlignParser,
        "wordBreak": wordBreakParser,
        "backgroundColorDarkMode": backgroundColorDarkModeParser,
        "backgroundColorToken": commonTokenColorParser(style: .backgroundColorToken("")),
        "backgroundColorActiveDarkMode": backgroundColorActiveDarkModeParser,
        "backgroundColorActiveToken": commonTokenColorParser(style: .backgroundColorActiveToken("")),
        "backgroundColorDisableDarkMode": backgroundColorDisableDarkModeParser,
        "backgroundColorDisableToken": commonTokenColorParser(style: .backgroundColorDisableToken("")),
        "underlineColor": commonHexColorParser(style: .underlineColor(.black)),
        "underlineColorDarkMode": commonHexColorParser(style: .underlineColorDarkMode(.black)),
        "underlineColorToken": commonHexColorParser(style: .underlineColorToken("")),
        "strikethroughColor": commonHexColorParser(style: .strikethroughColor(.black)),
        "strikethroughColorDarkMode": commonHexColorParser(style: .strikethroughColorDarkMode(.black)),
        "strikethroughColorToken": commonTokenColorParser(style: .strikethroughColorToken("")),
        "disabledTextColor": commonHexColorParser(style: .disabledTextColor(.black)),
        "disabledTextColorDarkMode": commonHexColorParser(style: .disabledTextColorDarkMode(.black)),
        "disabledTextColorToken": commonTokenColorParser(style: .disabledTextColorToken("")),
    ]

    class func parse(_ map: [String: String]) -> [StyleValue] {
        return map.compactMap({
                                uiParsers[$0.key]?($0.value)
        }).flatMap({ $0 })
    }
}

func textDecorationParser(_ value: String) -> [StyleValue] {
    let values = value.split(separator: " ")
    let handlers = [textDecorationLineParser, textDecorationColorParser]
    if values.count > handlers.count {
        return []
    }
    var styles: [StyleValue] = []

    for i in 0..<values.count {
        styles.append(contentsOf: handlers[i](String(values[i])))
    }
    return styles
}

func textDecorationLineParser(_ value: String) -> [StyleValue] {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "underLine":
        return [.underlineStyle(.single)]
    case "lineThrough", "line-through":
        return [.strikethroughStyle(.single)]
    default:
        return []
    }
}

func textDecorationColorParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value.trimmingCharacters(in: .whitespacesAndNewlines))
    return [.underlineColor(color), .strikethroughColor(color)]
}

func fontSizeParser(_ value: String) -> [StyleValue] {
    guard let number = StyleHelpers.floatValue(value) else {
        return []
    }
    return [.fontSize(number)]
}

func fontStyleParser(_ value: String) -> [StyleValue] {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "normal":
        return []
    case "italic":
        return [.fontObliqueness(0.5)]
    default:
        return []
    }
}

func fontWeightParser(_ value: String) -> [StyleValue] {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "normal":
        return []
    case "bold":
        return [.fontWeight(0.25)]
    default:
        return []
    }
}
/// DarkMode
func commonHexColorParser(style: StyleValue) -> StyleParseHandler {
    func hexColorParser(_ value: String) -> [StyleValue] {
        let color = UIColor.hexColorARGB(hexARGB: value)
        switch style {
        case .underlineColor(_):
            return [.underlineColor(color)]
        case .underlineColorDarkMode(let value):
            return [.underlineColorDarkMode(color)]
        case .strikethroughColor(let value):
            return [.strikethroughColor(color)]
        case .backgroundColor(let value):
            return [.backgroundColor(color)]
        case .backgroundColorActive(let value):
            return [.backgroundColorActive(color)]
        case .backgroundColorDisable(let value):
            return [.backgroundColorDisable(color)]
        case .color(let value):
            return [.color(color)]
        case .borderColor(let value):
            return [.borderColor(color)]
        case .borderColorDarkMode(let value):
            return [.borderColorDarkMode(color)]
        case .strikethroughColorDarkMode(let value):
            return [.strikethroughColorDarkMode(color)]
        case .backgroundColorDarkMode(let value):
            return [.backgroundColorDarkMode(color)]
        case .colorDarkMode(let value):
            return [.colorDarkMode(color)]
        case .backgroundColorActiveDarkMode(let value):
            return [.backgroundColorActiveDarkMode(color)]
        case .backgroundColorDisableDarkMode(let value):
            return [.backgroundColorDisableDarkMode(color)]
        case .disabledTextColor(let value):
            return [.disabledTextColor(color)]
        case .disabledTextColorDarkMode(let value):
            return [.disabledTextColorDarkMode(color)]
        default:
            return []
        }
    }
    return hexColorParser(_:)
}

func commonTokenColorParser(style: StyleValue) -> StyleParseHandler {
    func tokenColorParser(_ value: String) -> [StyleValue] {
        let token = value
        switch style {
        case .borderColorToken(_):
            return [.borderColorToken(token)]
        case .colorToken(_):
            return [.colorToken(token)]
        case .underlineColorToken(_):
            return [.underlineColorToken(token)]
        case .strikethroughColorToken(_):
            return [.strikethroughColorToken(token)]
        case .backgroundColorToken(_):
            return [.backgroundColorToken(token)]
        case .backgroundColorActiveToken(_):
            return [.backgroundColorActiveToken(token)]
        case .backgroundColorDisableToken(_):
            return [.backgroundColorDisableToken(token)]
        case .disabledTextColorToken(_):
            return [.disabledTextColorToken(token)]
        default:
            return []
        }
    }
    return tokenColorParser(_:)
}
func backgroundColorDarkModeParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColorDarkMode(color)]
}
func borderColorDarkModeParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.borderColorDarkMode(color)]
}
func borderColorTokenParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.borderColorToken(value)]
}
func colorDarkModeParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.colorDarkMode(color)]
}

func backgroundColorActiveDarkModeParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColorActiveDarkMode(color)]
}

func backgroundColorDisableDarkModeParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColorDisableDarkMode(color)]
}

func backgroundColorParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColor(color)]
}

func backgroundColorActiveParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColorActive(color)]
}

func backgroundColorDisableParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.backgroundColorDisable(color)]
}

func colorParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.color(color)]
}

func borderRadiusParser(_ value: String) -> [StyleValue] {
    if let sizeValue = CSSValueParser.sizeValueParse(value) {
        return [.borderRadius(sizeValue)]
    } else {
        return []
    }
}

func borderColorParser(_ value: String) -> [StyleValue] {
    let color = UIColor.hexColorARGB(hexARGB: value)
    return [.borderColor(color)]
}

func borderWidthParser(_ value: String) -> [StyleValue] {
    guard let number = StyleHelpers.floatValue(value) else {
        return []
    }
    return [.borderWidth(number)]
}

func textAlignParser(_ value: String) -> [StyleValue] {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "left":
        return [.textAlign(.left)]
    case "right":
        return [.textAlign(.right)]
    case "center":
        return [.textAlign(.center)]
    default:
        return []
    }
}

func wordBreakParser(_ value: String) -> [StyleValue] {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
    case "breakWord":
        return [.wordBreak(.byWordWrapping)]
    case "breakAll":
        /// 开放平台 非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        return [.wordBreak(.byCharWrapping)]
        // swiftlint:enable ban_linebreak_byChar
    default:
        return [.wordBreak(.byWordWrapping)]
    }
}

public enum HeaderTheme: String, Codable {
    case blue
    case wathet
    case turquoise
    case green
    case lime
    case yellow
    case orange
    case red
    case carmine
    case violet
    case purple
    case indigo
    case neutral
    case grey
    case gray
    case `default`
    
    public func getColors() -> (UIColor, UIColor)? {
        switch self {
        case .blue:
            return (.ud.udtokenMessageCardBgBlue,
                    .ud.udtokenMessageCardTextBlue)
        case .wathet:
            return (.ud.udtokenMessageCardBgWathet,
                    .ud.udtokenMessageCardTextWathet)
        case .turquoise:
            return (.ud.udtokenMessageCardBgTurquoise,
                    .ud.udtokenMessageCardTextTurquoise)
        case .green:
            return (.ud.udtokenMessageCardBgGreen,
                    .ud.udtokenMessageCardTextGreen)
        case .lime:
            return (.ud.udtokenMessageCardBgLime,
                    .ud.udtokenMessageCardTextLime)
        case .yellow:
            return (.ud.udtokenMessageCardBgYellow,
                    .ud.udtokenMessageCardTextYellow)
        case .orange:
            return (.ud.udtokenMessageCardBgOrange,
                    .ud.udtokenMessageCardTextOrange)
        case .red:
            return (.ud.udtokenMessageCardBgRed,
                    .ud.udtokenMessageCardTextRed)
        case .carmine:
            return (.ud.udtokenMessageCardBgCarmine,
                    .ud.udtokenMessageCardTextCarmine)
        case .violet:
            return (.ud.udtokenMessageCardBgViolet,
                    .ud.udtokenMessageCardTextViolet)
        case .purple:
            return (.ud.udtokenMessageCardBgPurple,
                    .ud.udtokenMessageCardTextPurple)
        case .indigo:
            return (.ud.udtokenMessageCardBgIndigo,
                    .ud.udtokenMessageCardTextIndigo)
        case .neutral, .grey, .gray:
            return (.ud.udtokenMessageCardBgNeutral,
                    .ud.udtokenMessageCardTextNeutral)
        default:
            return (.ud.udtokenMessageCardBgNeutral,
                    .ud.udtokenMessageCardTextNeutral)
        }
    }
}

extension String {
    public func themeTextColor() -> UIColor? {
        return HeaderTheme(rawValue: self)?.getColors()?.1
    }
    
    public func themeHeaderBGColor() -> UIColor? {
        return HeaderTheme(rawValue: self)?.getColors()?.0
    }
}
