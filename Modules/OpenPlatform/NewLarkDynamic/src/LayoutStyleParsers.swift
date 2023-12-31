//
//  LayoutStyleParsers.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/21.
//

import Foundation
import EEFlexiable

protocol CSSStyleParser {
    var names: [String] { get }
    func handler(style: LDStyle, key: String, value: String)
}

class FlexStyleParser {
    private var parsers: [String: CSSStyleParser] = [:]

    init(_ parsers: [CSSStyleParser]) {
        regist(parsers: parsers)
    }

    func regist(parsers: [CSSStyleParser]) {
        for parser in parsers {
            for name in parser.names {
                self.parsers[name] = parser
            }
        }
    }

    func parse(style: LDStyle, map: [String: String]) {
        map.forEach({ parsers[$0.key]?.handler(style: style, key: $0.key, value: $0.value) })
    }
}

// MARK: - position
class PositionParser: CSSStyleParser {
    private enum Values: String {
        case absolute
        case relative
    }

    var names: [String] {
        return ["position"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value) else {
            assertionFailure()
            return
        }
        switch value {
        case .absolute:
            style.position = .absolute
        case .relative:
            style.position = .relative
        }
    }
}

// MARK: - display
class DisplayParser: CSSStyleParser {
    private enum Values: String {
        case flex
        case none
    }

    var names: [String] {
        return ["display"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value) else {
            assertionFailure()
            return
        }
        switch value {
        case .flex:
            style.display = .flex
        case .none:
            style.display = .none
        }
    }
}

// MARK: - flexDirection
class FlexDirectionParser: CSSStyleParser {
    private enum Values: String {
        case column
        case columnReverse
        case row
        case rowReverse
    }

    var names: [String] {
        return ["flexDirection"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            assertionFailure()
            return
        }
        switch value {
        case .column:
            style.flexDirection = .column
        case .columnReverse:
            style.flexDirection = .columnReverse
        case .row:
            style.flexDirection = .row
        case .rowReverse:
            style.flexDirection = .rowReverse
        }
    }
}

// MARK: - flexWrap
class FlexWrapParser: CSSStyleParser {
    private enum Values: String {
        case noWrap
        case wrap
        case wrapReverse
    }

    var names: [String] {
        return ["flexWrap"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            assertionFailure()
            return
        }
        switch value {
        case .noWrap:
            style.flexWrap = .noWrap
        case .wrap:
            style.flexWrap = .wrap
        case .wrapReverse:
            style.flexWrap = .wrapReverse
        }
    }
}

// MARK: - justifyContent
class JustifyContentParser: CSSStyleParser {
    private enum Values: String {
        case center
        case spaceAround
        case spaceEvenly
        case spaceBetween
        case flexStart
        case flexEnd
    }

    var names: [String] {
        return ["justifyContent"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        switch value {
        case .center:
            style.justifyContent = .center
        case .spaceAround:
            style.justifyContent = .spaceAround
        case .spaceEvenly:
            style.justifyContent = .spaceEvenly
        case .spaceBetween:
            style.justifyContent = .spaceBetween
        case .flexStart:
            style.justifyContent = .flexStart
        case .flexEnd:
            style.justifyContent = .flexEnd
        }
    }
}

class OverflowParser: CSSStyleParser {
    private enum Values: String {
        case visible
        case hidden
        case scroll
    }

    var names: [String] {
        return ["overflow"]
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let value = Values(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        switch value {
        case .visible:
            style.overflow = .visible
        case .hidden:
            style.overflow = .hidden
        case .scroll:
            style.overflow = .scroll
        }
    }
}

class CSSValueParser: CSSStyleParser {
    private enum Keys: String, CaseIterable {
        case left
        case top
        case right
        case bottom
        case margin
        case marginLeft
        case marginTop
        case marginRight
        case marginBottom
        case padding
        case paddingLeft
        case paddingTop
        case paddingRight
        case paddingBottom
        case flexBasis
        case width
        case maxWidth
        case minWidth
        case height
        case maxHeight
        case minHeight
    }

    private enum Value: String {
        case unset
        case undefined
        case auto
    }

    static func sizeValueParse(_ value: String) -> CSSValue? {
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var isPercent = false
        if value.last == "%" {
            value = String(value.prefix(value.count - 1))
            isPercent = true
        }
        let num = (value.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).floatValue
        return CSSValue(value: num, unit: isPercent ? .percent : .point)
    }

    private lazy var _names: [String] = {
        return Keys.allCases.map({ $0.rawValue })
    }()

    var names: [String] {
        return _names
    }

    func cssValueParse(_ value: String) -> CSSValue? {
        if let value = Value(rawValue: value) {
            switch value {
            case .auto:
                return CSSValueAuto
            case .undefined, .unset:
                return CSSValueUndefined
            }
        }
        return CSSValueParser.sizeValueParse(value)
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let key = Keys(rawValue: key),
            let value = cssValueParse(value) else {
            return
        }
        switch key {
        case .margin:
            style.margin = value
        case .marginTop:
            style.marginTop = value
        case .marginRight:
            style.marginRight = value
        case .marginBottom:
            style.marginBottom = value
        case .marginLeft:
            style.marginLeft = value
        case .padding:
            style.padding = value
        case .paddingLeft:
            style.paddingLeft = value
        case .paddingTop:
            style.paddingTop = value
        case .paddingRight:
            style.paddingRight = value
        case .paddingBottom:
            style.paddingBottom = value
        case .flexBasis:
            style.flexBasis = value
        case .width:
            style.width = value
        case .maxWidth:
            style.maxWidth = value
        case .minWidth:
            style.minWidth = value
        case .height:
            style.height = value
        case .maxHeight:
            style.maxHeight = value
        case .minHeight:
            style.minHeight = value
        case .left:
            style.left = value
        case .top:
            style.top = value
        case .right:
            style.right = value
        case .bottom:
            style.bottom = value
        }
    }
}

class FloatValueParser: CSSStyleParser {
    private enum Keys: String, CaseIterable {
        case flexShrink
        case flexGrow
        case aspectRatio
    }

    private lazy var _names: [String] = {
        return Keys.allCases.map({ $0.rawValue })
    }()

    var names: [String] {
        return _names
    }

    func floatValueParse(_ value: String) -> CGFloat? {
        return StyleHelpers.floatValue(value)
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let key = Keys(rawValue: key),
            let value = floatValueParse(value) else {
            return
        }
        switch key {
        case .flexShrink:
            style.flexShrink = value
        case .flexGrow:
            style.flexGrow = value
        case .aspectRatio:
            style.aspectRatio = value
        }
    }
}

class AlignValueParser: CSSStyleParser {
    private enum Keys: String, CaseIterable {
        case alignContent
        case alignItems
        case alignSelf
    }

    private enum Values: String {
        case auto
        case flexStart
        case start
        case center
        case flexEnd
        case stretch
        case baseline
        case spaceBetween
        case spaceAround
    }

    private lazy var _names: [String] = {
        return Keys.allCases.map({ $0.rawValue })
    }()

    var names: [String] {
        return _names
    }

    func handler(style: LDStyle, key: String, value: String) {
        guard let key = Keys(rawValue: key),
            let value = alignValueParse(value) else {
            return
        }
        switch key {
        case .alignContent:
            style.alignContent = value
        case .alignItems:
            style.alignItems = value
        case .alignSelf:
            style.alignSelf = value
        }
    }

    private func alignValueParse(_ value: String) -> CSSAlign? {
        guard let value = Values(rawValue: value.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        switch value {
        case .auto:
            return .auto
        case .flexStart, .start:
            return .flexStart
        case .center:
            return .center
        case .flexEnd:
            return .flexEnd
        case .stretch:
            return .stretch
        case .baseline:
            return .baseline
        case .spaceBetween:
            return .spaceBetween
        case .spaceAround:
            return .spaceAround
        }
    }
}
