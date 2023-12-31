//
//  StyleProperties.swift
//  LKRichView
//
//  Created by qihongye on 2019/11/14.
//

import UIKit
import Foundation

public final class StyleProperties {
    var storage: [Int8: StyleProperty] = [:]

    public init(_ properties: [StyleProperty]) {
        var i = properties.count - 1
        var property: StyleProperty
        while i >= 0 {
            property = properties[i]
            if storage[property.id] != nil {
                i -= 1
                continue
            }
            storage[property.id] = property
            i -= 1
        }
    }

    func mergeProperties(_ styleProperties: StyleProperties) {
        for (key, property) in styleProperties.storage {
            storage[key] = storage[key] + property
        }
    }

    func applyToRenderStyle(_ node: Node) {
        for (_, property) in storage {
            property.applyToRenderStyle(&(node.style.storage), false)
        }
    }
}

public final class StyleProperty {
    private let name: LKRenderRichStyle.Key
    private let value: Any

    var id: Int8 {
        return name.rawValue
    }

    init(name: LKRenderRichStyle.Key, value: Any) {
        self.name = name
        self.value = value
    }

    static func + (_ lhs: StyleProperty?, _ rhs: StyleProperty) -> StyleProperty {
        guard let lhs = lhs else {
            return rhs
        }
        assert(lhs.name == rhs.name, "You can not pass two different StyleProperty \(lhs.name) and \(rhs.name) to this.")
        switch lhs.name {
        case .textDecoration:
            if let l = lhs.textDecorationRichStyleValue()?.value,
               let r = rhs.textDecorationRichStyleValue()?.value {
                return StyleProperty(name: lhs.name, value: LKRichStyleValue(.value, l + r))
            }
            return rhs
        default:
            return rhs
        }
    }

    @inline(__always)
    func applyToRenderStyle(_ style: inout LKRenderRichStyle, _ isOverride: Bool) {
        switch name {
        case .writingMode:
            if isOverride {
                style.writingMode =! writingMode()
            }
        case .backgroundColor:
            if isOverride || style.backgroundColor.type != .value {
                style.backgroundColor =! colorRichStyleValue()
            }
        case .border:
            if isOverride || style.border.type != .value {
                style.border =! borderRichStyleValue()
            }
        case .borderRadius:
            if isOverride || style.borderRadius.type != .value {
                style.borderRadius =! borderRadiusRichStyleValue()
            }
        case .color:
            if isOverride || style.color.type != .value {
                style.color =! colorRichStyleValue()
            }
        case .display:
            if isOverride || style.display.type != .value {
                style.display =! displayRichStyleValue()
            }
        case .font:
            if isOverride || style.font.type != .value {
                style.font =! fontRichStyleValue()
            }
        case .fontSize:
            if isOverride {
                style.fontSize =! numbericRichStyleValue()
                return
            }
            switch style.fontSize.type {
            case .auto, .inherit, .unset:
                style.fontSize =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .fontStyle:
            if isOverride || style.fontStyle.type != .value {
                style.fontStyle =! fontStyleRichStyleValue()
            }
        case .fontWeight:
            if isOverride || style.fontWeight.type != .value {
                style.fontWeight =! fontWeightRichStyleValue()
            }
        case .height:
            if isOverride {
                style.height =! numbericRichStyleValue()
                return
            }
            switch style.height.type {
            case .auto, .inherit, .unset:
                style.height =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .lineHeight:
            if isOverride {
                style.lineHeight =! numbericRichStyleValue()
                return
            }
            switch style.lineHeight.type {
            case .auto, .inherit, .unset:
                style.lineHeight =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .margin:
            if isOverride || style.margin.type != .value {
                style.margin =! edgesRichStyleValue()
            }
        case .padding:
            if isOverride || style.padding.type != .value {
                style.padding =! edgesRichStyleValue()
            }
        case .textAlign:
            if isOverride || style.textAlign.type != .value {
                style.textAlign =! textAlignRichStyleValue()
            }
        case .textDecoration:
            guard isOverride || style.textDecoration.type != .value else {
                return
            }
            let textDecoration = textDecorationRichStyleValue()
            guard let new = textDecoration?.value else {
                return
            }
            guard let old = style.textDecoration.value else {
                style.textDecoration =! textDecoration
                return
            }
            style.textDecoration = .init(.value, old + new)
        case .verticalAlign:
            if isOverride || style.verticalAlign.type != .value {
                style.verticalAlign =! verticalAlignRichStyleValue()
            }
        case .width:
            if isOverride {
                style.width =! numbericRichStyleValue()
                return
            }
            switch style.width.type {
            case .auto, .inherit, .unset:
                style.width =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .maxWidth:
            if isOverride {
                style.maxWidth =! numbericRichStyleValue()
                return
            }
            switch style.maxWidth.type {
            case .auto, .inherit, .unset:
                style.maxWidth =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .maxHeight:
            if isOverride {
                style.maxHeight =! numbericRichStyleValue()
                return
            }
            switch style.maxHeight.type {
            case .auto, .inherit, .unset:
                style.maxHeight =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .minWidth:
            if isOverride {
                style.minWidth =! numbericRichStyleValue()
                return
            }
            switch style.minWidth.type {
            case .auto, .inherit, .unset:
                style.minWidth =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .minHeight:
            if isOverride {
                style.minHeight =! numbericRichStyleValue()
                return
            }
            switch style.minHeight.type {
            case .auto, .inherit, .unset:
                style.minHeight =! numbericRichStyleValue()
            case .em, .percent, .point, .value:
                break
            }
        case .textOverflow:
            if isOverride {
                style.textOverflow =! textOverflowRichStyleValue()
                return
            }
        case .lineCamp:
            if isOverride {
                style.lineCamp =! lineCampRichStyleValue()
            }
            return
        }
    }

    @inline(__always)
    func displayRichStyleValue() -> LKRichStyleValue<Display>? {
        if name == .display {
            return value as? LKRichStyleValue<Display>
        }
        return nil
    }

    @inline(__always)
    func numbericRichStyleValue() -> LKRichStyleValue<CGFloat>? {
        switch name {
        case .lineHeight, .fontSize, .width, .height, .maxWidth, .maxHeight, .minWidth, .minHeight:
            return value as? LKRichStyleValue<CGFloat>
        case .writingMode, .display, .font, .fontWeight, .fontStyle, .color, .backgroundColor,
             .textDecoration, .border, .borderRadius, .margin, .padding, .verticalAlign,
             .textAlign, .textOverflow, .lineCamp:
            return nil
        }
    }

    @inline(__always)
    func writingMode() -> WritingMode? {
        if name == .writingMode {
            return value as? WritingMode
        }
        return nil
    }

    @inline(__always)
    func fontRichStyleValue() -> LKRichStyleValue<UIFont>? {
        if name == .font {
            return value as? LKRichStyleValue<UIFont>
        }
        return nil
    }

    @inline(__always)
    func fontWeightRichStyleValue() -> LKRichStyleValue<FontWeight>? {
        if name == .fontWeight {
            return value as? LKRichStyleValue<FontWeight>
        }
        return nil
    }

    @inline(__always)
    func fontStyleRichStyleValue() -> LKRichStyleValue<FontStyle>? {
        if name == .fontStyle {
            return value as? LKRichStyleValue<FontStyle>
        }
        return nil
    }

    @inline(__always)
    func colorRichStyleValue() -> LKRichStyleValue<UIColor>? {
        if name == .backgroundColor || name == .color {
            return value as? LKRichStyleValue<UIColor>
        }
        return nil
    }

    @inline(__always)
    func textAlignRichStyleValue() -> LKRichStyleValue<TextAlign>? {
        if name == .textAlign {
            return value as? LKRichStyleValue<TextAlign>
        }
        return nil
    }

    @inline(__always)
    func verticalAlignRichStyleValue() -> LKRichStyleValue<VerticalAlign>? {
        if name == .verticalAlign {
            return value as? LKRichStyleValue<VerticalAlign>
        }
        return nil
    }

    @inline(__always)
    func textDecorationRichStyleValue() -> LKRichStyleValue<TextDecoration>? {
        if name == .textDecoration {
            return value as? LKRichStyleValue<TextDecoration>
        }
        return nil
    }

    @inline(__always)
    func borderRichStyleValue() -> LKRichStyleValue<Border>? {
        if name == .border {
            return value as? LKRichStyleValue<Border>
        }
        return nil
    }

    @inline(__always)
    func borderRadiusRichStyleValue() -> LKRichStyleValue<BorderRadius>? {
        if name == .borderRadius {
            return value as? LKRichStyleValue<BorderRadius>
        }
        return nil
    }

    @inline(__always)
    func edgesRichStyleValue() -> LKRichStyleValue<Edges>? {
        if name == .margin || name == .padding {
            return value as? LKRichStyleValue<Edges>
        }
        return nil
    }

    @inline(__always)
    func textOverflowRichStyleValue() -> LKRichStyleValue<LKTextOverflow>? {
        if name == .textOverflow {
            return value as? LKRichStyleValue<LKTextOverflow>
        }
        return nil
    }

    @inline(__always)
    func lineCampRichStyleValue() -> LKRichStyleValue<LineCamp>? {
        if name == .lineCamp {
            return value as? LKRichStyleValue<LineCamp>
        }
        return nil
    }
}

extension StyleProperty: StylePropertyProtocol {
    public static func display(_ value: LKRichStyleValue<Display>) -> StyleProperty {
        return StyleProperty(name: .display, value: value)
    }

    public static func writingMode(_ value: WritingMode) -> StyleProperty {
        return StyleProperty(name: .writingMode, value: value)
    }

    public static func lineHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .lineHeight, value: value)
    }

    public static func fontSize(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .fontSize, value: value)
    }

    public static func width(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .width, value: value)
    }

    public static func height(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .height, value: value)
    }

    public static func maxWidth(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .maxWidth, value: value)
    }

    public static func maxHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .maxHeight, value: value)
    }

    public static func minWidth(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .minWidth, value: value)
    }

    public static func minHeight(_ value: LKRichStyleValue<CGFloat>) -> StyleProperty {
        return StyleProperty(name: .minHeight, value: value)
    }

    public static func font(_ value: LKRichStyleValue<UIFont>) -> StyleProperty {
        return StyleProperty(name: .font, value: value)
    }

    public static func fontWeigth(_ value: LKRichStyleValue<FontWeight>) -> StyleProperty {
        return StyleProperty(name: .fontWeight, value: value)
    }

    public static func fontStyle(_ value: LKRichStyleValue<FontStyle>) -> StyleProperty {
        return StyleProperty(name: .fontStyle, value: value)
    }

    public static func backgroundColor(_ value: LKRichStyleValue<UIColor>) -> StyleProperty {
        return StyleProperty(name: .backgroundColor, value: value)
    }

    public static func color(_ value: LKRichStyleValue<UIColor>) -> StyleProperty {
        return StyleProperty(name: .color, value: value)
    }

    public static func textAlign(_ value: LKRichStyleValue<TextAlign>) -> StyleProperty {
        return StyleProperty(name: .textAlign, value: value)
    }

    public static func verticalAlign(_ value: LKRichStyleValue<VerticalAlign>) -> StyleProperty {
        return StyleProperty(name: .verticalAlign, value: value)
    }

    public static func textDecoration(_ value: LKRichStyleValue<TextDecoration>) -> StyleProperty {
        return StyleProperty(name: .textDecoration, value: value)
    }

    public static func border(_ value: LKRichStyleValue<Border>) -> StyleProperty {
        return StyleProperty(name: .border, value: value)
    }

    public static func borderRadius(_ value: LKRichStyleValue<BorderRadius>) -> StyleProperty {
        return StyleProperty(name: .borderRadius, value: value)
    }

    public static func margin(_ value: LKRichStyleValue<Edges>) -> StyleProperty {
        return StyleProperty(name: .margin, value: value)
    }

    public static func padding(_ value: LKRichStyleValue<Edges>) -> StyleProperty {
        return StyleProperty(name: .padding, value: value)
    }

    public static func textOverflow(_ value: LKRichStyleValue<LKTextOverflow>) -> StyleProperty {
        return StyleProperty(name: .textOverflow, value: value)
    }

    public static func lineCamp(_ value: LKRichStyleValue<LineCamp>) -> StyleProperty {
        return StyleProperty(name: .lineCamp, value: value)
    }
}
