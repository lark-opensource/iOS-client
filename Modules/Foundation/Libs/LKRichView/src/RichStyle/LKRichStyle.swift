//
//  LKRichStyle.swift
//  LKRichView
//
//  Created by qihongye on 2019/8/27.
//

import Foundation
import UIKit

let SYSTEM_FONT_SIZE = UIFont.systemFontSize
@inline(__always)
func SYSTEM_FONT(_ fontSize: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: fontSize)
}

public protocol LKCopying {
    func copy() -> Any
}

public enum NumbericValue: Equatable, LKCopying {
    case point(CGFloat)
    case percent(CGFloat)
    case em(CGFloat)

    var style: LKRichStyleValue<CGFloat> {
        switch self {
        case .point(let value):
            return .init(.point, value)
        case .percent(let value):
            return .init(.percent, value)
        case .em(let value):
            return .init(.em, value)
        }
    }

    public init?(_ style: LKRichStyleValue<CGFloat>) {
        guard let value = style.value else {
            return nil
        }
        switch style.type {
        case .point:
            self = .point(value)
        case .percent:
            self = .percent(value)
        case .em:
            self = .em(value)
        default:
            return nil
        }
    }

    public static func == (_ lhs: NumbericValue, _ rhs: NumbericValue) -> Bool {
        switch (lhs, rhs) {
        case (.point(let l), .point(let r)):
            return l == r
        case (.percent(let l), .percent(let r)):
            return l == r
        case (.em(let l), .em(let r)):
            return l == r
        default:
            return false
        }
    }

    public func copy() -> Any {
        return self
    }
}

public enum LKRichStyleValueType: Int8 {
    case inherit
    case point
    case percent
    case em
    case auto
    case unset
    case value
}

public struct LKRichStyleValue<T: Equatable & LKCopying>: Equatable, LKCopying {
    var type: LKRichStyleValueType
    var value: T?

    public init(_ type: LKRichStyleValueType = .unset, _ value: T? = nil) {
        self.type = type
        self.value = value
    }

    public static func == (_ lhs: LKRichStyleValue<T>, _ rhs: LKRichStyleValue<T>) -> Bool {
        return lhs.type == rhs.type && lhs.value == rhs.value
    }

    public static func != (_ lhs: LKRichStyleValue<T>, _ rhs: LKRichStyleValue<T>) -> Bool {
        return lhs.type != rhs.type || lhs.value != rhs.value
    }

    public func copy() -> Any {
        return LKRichStyleValue(self.type, self.value?.copy() as? T)
    }
}

func !=<T: Equatable>(_ lhs: LKRichStyleValue<T>, _ rhs: T) -> Bool {
    return lhs.value != rhs
}

func ==<T: Equatable>(_ lhs: LKRichStyleValue<T>, _ rhs: T) -> Bool {
    return lhs.value == rhs
}

infix operator =!=
/// Set value when not equalt
func =!=<T: Equatable>(_ lhs: inout LKRichStyleValue<T>, _ rhs: LKRichStyleValue<T>) {
    if lhs != rhs {
        lhs = rhs
    }
}

infix operator =!
/// set optional value
@inline(__always)
func =! <T>(_ lhs: inout T, _ rhs: T?) {
    if let v = rhs {
        lhs = v
    }
}

#if DEBUG
extension LKRichStyleValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "RichStyleValue(\(self.type), \(String(describing: value)))"
    }
}
#endif

public struct BorderEdge: Equatable, LKCopying {
    public enum Style: Int8 {
        case none
        case solid
        case dashed
    }
    public let style: Style
    public let width: NumbericValue
    public let color: UIColor

    public init(style: Style = .none, width: NumbericValue = .point(0), color: UIColor = UIColor.black) {
        self.style = style
        self.width = width
        self.color = color
    }

    public func copy() -> Any {
        var color = self.color.copy() as? UIColor
        assert(color == nil, "BorderEdge copy: UIColor copy failed.")
        return BorderEdge(style: style, width: width, color: color ?? UIColor.black)
    }

    public static func == (_ lhs: BorderEdge, _ rhs: BorderEdge) -> Bool {
        return lhs.style == rhs.style
            && lhs.width == rhs.width
            && lhs.color.hashValue == rhs.color.hashValue
    }
}

public struct Border: Equatable, LKCopying {
    private var borderEdges = [BorderEdge?](repeating: nil, count: 4)

    public init() {}

    public init(_ top: BorderEdge?) {
        borderEdges[0] = top
    }

    public init(_ top: BorderEdge?, _ right: BorderEdge?) {
        borderEdges[0] = top
        borderEdges[1] = right
    }

    public init(_ top: BorderEdge?, _ right: BorderEdge?, _ bottom: BorderEdge?) {
        borderEdges[0] = top
        borderEdges[1] = right
        borderEdges[2] = bottom
    }

    public init(_ top: BorderEdge?, _ right: BorderEdge?, _ bottom: BorderEdge?, _ left: BorderEdge?) {
        borderEdges[0] = top
        borderEdges[1] = right
        borderEdges[2] = bottom
        borderEdges[3] = left
    }

    public var top: BorderEdge? {
        get {
            return borderEdges[0]
        }
        set {
            borderEdges[0] = newValue
        }
    }

    public var right: BorderEdge? {
        get {
            return borderEdges[1] ?? borderEdges[0]
        }
        set {
            borderEdges[1] = newValue
        }
    }

    public var bottom: BorderEdge? {
        get {
            return borderEdges[2] ?? borderEdges[0]
        }
        set {
            borderEdges[2] = newValue
        }
    }

    public var left: BorderEdge? {
        get {
            return borderEdges[3] ?? borderEdges[1] ?? borderEdges[0]
        }
        set {
            borderEdges[3] = newValue
        }
    }

    public func copy() -> Any {
        return Border(self.top?.copy() as? BorderEdge,
                      self.right?.copy() as? BorderEdge,
                      self.bottom?.copy() as? BorderEdge,
                      self.left?.copy() as? BorderEdge)
    }

    public static func == (_ lhs: Border, _ rhs: Border) -> Bool {
        return lhs.top == rhs.top
            && lhs.right == rhs.right
            && lhs.bottom == rhs.bottom
            && lhs.left == rhs.left
    }
}

public enum FontStyle: Int8, LKCopying {
    case normal
    case italic

    public func copy() -> Any {
        return self
    }
}

public enum FontWeight: Equatable, LKCopying {
    public static var boundary = 1000
    private static var midBoundary = CGFloat(boundary >> 1)

    case ultraLight
    case thin
    case light
    case normal
    case medium
    case semibold
    case bold
    case heavy
    case black
    case numberic(CGFloat)

    var rawValue: CGFloat {
        switch self {
        case .ultraLight:
            return UIFont.Weight.ultraLight.rawValue
        case .thin:
            return UIFont.Weight.thin.rawValue
        case .light:
            return UIFont.Weight.light.rawValue
        case .normal:
            return UIFont.Weight.regular.rawValue
        case .medium:
            return UIFont.Weight.medium.rawValue
        case .semibold:
            return UIFont.Weight.semibold.rawValue
        case .bold:
            return UIFont.Weight.bold.rawValue
        case .heavy:
            return UIFont.Weight.heavy.rawValue
        case .black:
            return UIFont.Weight.black.rawValue
        case .numberic(let weight):
            return (max(min(weight - Self.midBoundary, Self.midBoundary), -Self.midBoundary)) / Self.midBoundary
        }
    }

    var uiFontWeight: UIFont.Weight {
        switch self.rawValue {
        case ...Self.ultraLight.rawValue: return .ultraLight
        case Self.ultraLight.rawValue...Self.thin.rawValue: return .thin
        case Self.thin.rawValue...Self.light.rawValue: return .light
        case Self.light.rawValue..<Self.medium.rawValue: return .regular
        case Self.medium.rawValue..<Self.semibold.rawValue: return .medium
        case Self.semibold.rawValue..<Self.bold.rawValue: return .semibold
        case Self.bold.rawValue..<Self.heavy.rawValue: return .bold
        case Self.heavy.rawValue..<Self.black.rawValue: return .heavy
        case Self.black.rawValue...: return .black
        default:
            return .regular
        }
    }

    var boldTextWeightValue: CGFloat {
        switch self.rawValue {
        case ...Self.medium.rawValue: return UIFont.Weight.semibold.rawValue
        case Self.medium.rawValue...Self.black.rawValue: return UIFont.Weight.black.rawValue
        default: return UIFont.Weight.semibold.rawValue
        }
    }

    public func copy() -> Any {
        return self
    }

    public static func == (_ lhs: FontWeight, _ rhs: FontWeight) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public enum LKTextOverflow: Equatable, LKCopying {
    typealias RawValue = String

    case none
    case noWrapEllipsis
    case noWrapCustom(String)

    var rawValue: Int {
        switch self {
        case .none:
            return 0
        case .noWrapEllipsis:
            return 1
        case .noWrapCustom(let token):
            return token.hashValue
        }
    }

    public func copy() -> Any {
        return self
    }
}

/// LineCamp 计算方式说明
/// 参考：https://w3c.github.io/csswg-drafts/css-overflow/#propdef-line-clamp
/// 预期计算：
///  针对Block元素的一级子节点计算MaxLine。针对Inline元素计算整体LineBox数目。
/// 实际计算：
///  这里默认使用自定义计算方式，针对Block元素，使用一级Inline子元素的全部LineBox来计算LineBox数目。
/// 例子：    A { maxLine: 4 }                                                      _________________
//           A{Block}                         |    Text1     |
//          /        \                        |    Text2     |
//       B{Block}   C{Block}                  |    Text3     |
//      /   |    \     |   \                  |____Text4_____|
//  Text1 Text2 Text3 Text4 Text5             |_Not Visiable_|
///
///
public struct LineCamp: Equatable, LKCopying {
    public let maxLine: Int
    public let blockTextOverflow: String

    public init(maxLine: Int, blockTextOverflow: String? = nil) {
        self.maxLine = maxLine
        self.blockTextOverflow = blockTextOverflow ?? "\u{2026}"
    }

    public func copy() -> Any {
        return LineCamp(maxLine: self.maxLine, blockTextOverflow: self.blockTextOverflow)
    }

    public static func == (_ lhs: LineCamp, _ rhs: LineCamp) -> Bool {
        return lhs.maxLine == rhs.maxLine && lhs.blockTextOverflow == rhs.blockTextOverflow
    }
}

public struct TextDecoration: Equatable, LKCopying {
    public struct Line: OptionSet {
        public static let underline = Line(rawValue: 1 << 0)
        public static let lineThrough = Line(rawValue: 1 << 1)

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        static func + (_ lhs: Line, _ rhs: Line) -> Line {
            return [lhs, rhs]
        }
    }

    public enum Style: UInt8 {
        case solid
        case dashed
        case wave
    }

    public let line: Line
    public let style: Style
    public let thickness: CGFloat?
    public let color: UIColor?

    public init(line: Line = .underline, style: Style, thickness: CGFloat? = nil, color: UIColor? = nil) {
        self.line = line
        self.style = style
        self.thickness = thickness
        self.color = color
    }

    public func copy() -> Any {
        return TextDecoration(line: self.line, style: self.style, thickness: self.thickness, color: self.color?.copy() as? UIColor)
    }

    public static func + (_ lhs: TextDecoration, _ rhs: TextDecoration) -> TextDecoration {
        if lhs.style == rhs.style {
            return TextDecoration(
                line: lhs.line + rhs.line,
                style: rhs.style,
                thickness: rhs.thickness,
                color: rhs.color
            )
        }
        return rhs
    }

    public static func == (_ lhs: TextDecoration, _ rhs: TextDecoration) -> Bool {
        return lhs.line == rhs.line
            && lhs.style == rhs.style
            && lhs.thickness == rhs.thickness
            && lhs.color?.cgColor.components == rhs.color?.cgColor.components
    }
}

struct TextDecorations {
    var lineThrough: TextDecoration?
    var underline: TextDecoration?

    init(_ td: TextDecoration) {
        if td.line.contains(.lineThrough) {
            self.lineThrough = td
        }
        if td.line.contains(.underline) {
            self.underline = td
        }
    }

    init(lineThrough: TextDecoration?, underline: TextDecoration?) {
        self.lineThrough = lineThrough
        self.underline = underline
    }

    static func + (_ lhs: TextDecorations, _ rhs: TextDecoration) -> TextDecorations {
        var lineThrough = lhs.lineThrough
        var underline = lhs.underline
        if rhs.line.contains(.lineThrough) {
            lineThrough = rhs
        }
        if rhs.line.contains(.underline) {
            underline = rhs
        }
        return .init(lineThrough: lineThrough, underline: underline)
    }
}

public struct Edges: Equatable, LKCopying {
    private var edges = [LKRichStyleValue<CGFloat>](repeating: LKRichStyleValue(), count: 4)

    public init() {
    }

    public init(_ top: NumbericValue?) {
        if let value = top?.style {
            edges[0] = value
        }
    }

    public init(_ top: NumbericValue?, _ right: NumbericValue?) {
        if let value = top?.style {
            edges[0] = value
        }
        if let value = right?.style {
            edges[1] = value
        }
    }

    public init(_ top: NumbericValue?, _ right: NumbericValue?, _ bottom: NumbericValue?) {
        if let value = top?.style {
            edges[0] = value
        }
        if let value = right?.style {
            edges[1] = value
        }
        if let value = bottom?.style {
            edges[2] = value
        }
    }

    public init(_ top: NumbericValue?, _ right: NumbericValue?, _ bottom: NumbericValue?, _ left: NumbericValue?) {
        if let value = top?.style {
            edges[0] = value
        }
        if let value = right?.style {
            edges[1] = value
        }
        if let value = bottom?.style {
            edges[2] = value
        }
        if let value = left?.style {
            edges[3] = value
        }
    }

    public var top: NumbericValue {
        get {
            return NumbericValue(edges[0]) ?? .point(0)
        }
        set {
            edges[0] = newValue.style
        }
    }

    public var right: NumbericValue {
        get {
            return NumbericValue(edges[1]) ?? top
        }
        set {
            edges[1] = newValue.style
        }
    }

    public var bottom: NumbericValue {
        get {
            return NumbericValue(edges[2]) ?? top
        }
        set {
            edges[2] = newValue.style
        }
    }

    public var left: NumbericValue {
        get {
            return NumbericValue(edges[3]) ?? right
        }
        set {
            edges[3] = newValue.style
        }
    }

    /// NumbericValue is basic value type, so `copy()` can return self.
    public func copy() -> Any {
        return self
    }

    public static func == (_ lhs: Edges, _ rhs: Edges) -> Bool {
        return lhs.top == rhs.top && lhs.right == rhs.right
            && lhs.bottom == rhs.bottom && lhs.left == rhs.left
    }
}

public struct LengthSize: Equatable, LKCopying {
    var width: NumbericValue?
    var height: NumbericValue?

    public init(width: NumbericValue? = nil, height: NumbericValue? = nil) {
        self.width = width
        self.height = height
    }

    /// NumbericValue is basic value type, so `copy()` can return self.
    public func copy() -> Any {
        return self
    }

    public static func == (_ lhs: LengthSize, _ rhs: LengthSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

/// 对LineBox生效，设置LineBox的主轴对齐方式
public enum TextAlign: Int8, LKCopying {
    case left
    case right
    case center
    case start
    case end

    public func copy() -> Any {
        return self
    }
}

/// 设置纵轴对齐方式，当前RunBox在LineBox内生效
public enum VerticalAlign: Int8, LKCopying {
    case baseline
    case top
    case middle
    case bottom

    public func copy() -> Any {
        return self
    }
}

extension NumbericValue {
    public static func / (_ lhs: NumbericValue, _ rhs: NumbericValue) -> LengthSize {
        return LengthSize(width: lhs, height: rhs)
    }
}

public struct BorderRadius: Equatable, LKCopying {
    // LengthSize.width = horizonal radius. LengthSize.height = vertical radius
    private var radius = [LengthSize?](repeating: nil, count: 4)

    public init(_ topLeft: LengthSize? = nil, _ topRight: LengthSize? = nil, _ bottomRight: LengthSize? = nil, _ bottomLeft: LengthSize? = nil) {
        radius[0] = topLeft
        radius[1] = topRight
        radius[2] = bottomRight
        radius[3] = bottomLeft
    }

    public var topLeft: LengthSize? {
        get {
            return radius[0]
        }
        set {
            radius[0] = newValue
        }
    }

    public var topRight: LengthSize? {
        get {
            return radius[1] ?? radius[0]
        }
        set {
            radius[1] = newValue
        }
    }

    public var bottomRight: LengthSize? {
        get {
            return radius[2] ?? radius[0]
        }
        set {
            radius[2] = newValue
        }
    }

    public var bottomLeft: LengthSize? {
        get {
            return radius[3] ?? topRight
        }
        set {
            radius[3] = newValue
        }
    }

    public func copy() -> Any {
        return self
    }

    public static func == (_ lhs: BorderRadius, _ rhs: BorderRadius) -> Bool {
        return lhs.topLeft == rhs.topLeft && lhs.topRight == rhs.topRight
            && lhs.bottomRight == rhs.bottomRight && lhs.bottomLeft == rhs.bottomLeft
    }
}

public enum Display: Int8, LKCopying {
    case none
    case inline
    case inlineBlock
    case block

    public func copy() -> Any {
        return self
    }
}

public enum WritingMode: Int8, LKCopying {
    case horizontalTB
    case verticalLR
    case verticalRL

    public func copy() -> Any {
        return self
    }
}

public struct LKRenderRichStyle: LKCopying {
    enum Key: Int8 {
        case writingMode
        case display
        case font
        case fontSize
        case fontWeight
        case fontStyle
        case color
        case backgroundColor
        case lineHeight
        case textAlign
        case verticalAlign
        case textDecoration
        case border
        case borderRadius
        case margin
        case padding
        case width
        case height
        case maxWidth
        case maxHeight
        case minWidth
        case minHeight
        case textOverflow
        case lineCamp
    }

    /// 用于选区。若此值为 true，则选区在遇到当前元素是会把本元素当做一个整体，不会再继续感知子元素
    var isBlockSelection = LKRichStyleValue<Bool>(.unset, false)
    var writingMode: WritingMode = .horizontalTB
    var display = LKRichStyleValue<Display>(.unset, nil)
    var fontSize = LKRichStyleValue<CGFloat>(.inherit)
    /// CoreText is too bad. SystemFont has a series of font family with different font size.
    /// exp: UIFont.systemFont(ofSize: 14).family == 
    var font = LKRichStyleValue<UIFont>(.inherit, nil)
    var fontWeight = LKRichStyleValue<FontWeight>(.inherit, .normal)
    var fontStyle = LKRichStyleValue<FontStyle>(.inherit, .normal)
    var color = LKRichStyleValue<UIColor>(.inherit)
    var backgroundColor = LKRichStyleValue<UIColor>()
    var lineHeight = LKRichStyleValue<CGFloat>()
    var textAlign = LKRichStyleValue<TextAlign>(.inherit, .left)
    var verticalAlign = LKRichStyleValue<VerticalAlign>(.inherit, .baseline)
    var textDecoration = LKRichStyleValue<TextDecoration>(.inherit, nil)
    var border = LKRichStyleValue<Border>()
    var borderRadius = LKRichStyleValue<BorderRadius>(.unset, nil)
    var margin = LKRichStyleValue<Edges>(.unset, Edges())
    var padding = LKRichStyleValue<Edges>(.unset, Edges())
    var width = LKRichStyleValue<CGFloat>(.auto, nil)
    var height = LKRichStyleValue<CGFloat>(.auto, nil)
    var maxWidth = LKRichStyleValue<CGFloat>(.unset, nil)
    var maxHeight = LKRichStyleValue<CGFloat>(.unset, nil)
    var minWidth = LKRichStyleValue<CGFloat>(.unset, nil)
    var minHeight = LKRichStyleValue<CGFloat>(.unset, nil)
    var textOverflow = LKRichStyleValue<LKTextOverflow>(.inherit, nil)
    var lineCamp = LKRichStyleValue<LineCamp>(.unset, nil)

    public func copy() -> Any {
        var clone = LKRenderRichStyle()
        clone.isBlockSelection = isBlockSelection
        clone.writingMode = writingMode
        clone.display = display
        clone.fontSize = fontSize
        if let font = font.copy() as? LKRichStyleValue<UIFont> {
            clone.font = font
        }
        clone.fontWeight = fontWeight
        clone.fontStyle = fontStyle
        if let color = color.copy() as? LKRichStyleValue<UIColor> {
            clone.color = color
        }
        if let backgroundColor = backgroundColor.copy() as? LKRichStyleValue<UIColor> {
            clone.backgroundColor = backgroundColor
        }
        clone.lineHeight = lineHeight
        clone.textAlign = textAlign
        clone.verticalAlign = verticalAlign
        clone.textDecoration = textDecoration
        if let border = border.copy() as? LKRichStyleValue<Border> {
            clone.border = border
        }
        clone.borderRadius = borderRadius
        clone.margin = margin
        clone.padding = padding
        clone.width = width
        clone.height = height
        clone.maxWidth = maxWidth
        clone.maxHeight = maxHeight
        clone.minWidth = minWidth
        clone.minHeight = minHeight
        clone.textOverflow = textOverflow
        clone.lineCamp = lineCamp
        return clone
    }
}

public final class LKRichStyle {
    var storage: LKRenderRichStyle

    public init() {
        storage = LKRenderRichStyle()
    }

    fileprivate init(storage: LKRenderRichStyle) {
        self.storage = storage
    }

    public var writingMode: WritingMode {
        return storage.writingMode
    }

    @discardableResult
    public func writingMode(_ value: WritingMode) -> Self {
        storage.writingMode = value
        return self
    }

    public var isBlockSelection: Bool {
        return storage.isBlockSelection.value ?? false
    }

    @discardableResult
    public func isBlockSelection(_ value: Bool?) -> Self {
        guard let value = value else {
            storage.isBlockSelection =!= .init(.unset, false)
            return self
        }
        storage.isBlockSelection =!= .init(.value, value)
        return self
    }

    public var display: Display? {
        return storage.display.value
    }

    /// Set display.
    /// - Parameter value: If set nil, display will be unset nil.
    @discardableResult
    public func display(_ value: Display?) -> Self {
        guard let value = value else {
            storage.display =!= .init(.unset, nil)
            return self
        }
        storage.display =!= .init(.value, value)
        return self
    }

    public var fontSize: NumbericValue {
        return NumbericValue(storage.fontSize) ?? .point(SYSTEM_FONT_SIZE)
    }

    /// Set font size
    /// - Parameter value: If set nil, fontSize will be inherit
    @discardableResult
    public func fontSize(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.fontSize =!= .init(.inherit, nil)
            return self
        }
        storage.fontSize =!= value.style
        return self
    }

    public var font: UIFont? {
        return storage.font.value
    }

    /// Set font family
    /// - Parameter value: If set nil, fontFamily will be UIFont.systemFont().family
    @discardableResult
    public func font(_ value: UIFont?) -> Self {
        guard let value = value else {
            storage.font =!= .init(.inherit, nil)
            return self
        }
        storage.font =!= .init(.value, value)
        return self
    }

    public var fontWeight: FontWeight {
        return storage.fontWeight.value ?? .normal
    }

    /// Set font weight
    /// - Parameter value: If set nil, fontWeight will be normal
    @discardableResult
    public func fontWeight(_ value: FontWeight?) -> Self {
        let value = value ?? .normal
        storage.fontWeight =!= .init(.value, value)
        return self
    }

    public var fontStyle: FontStyle {
        return storage.fontStyle.value ?? .normal
    }

    /// Set font style
    /// - Parameter value: If set nil, fontStyle will be normal
    @discardableResult
    public func fontStyle(_ value: FontStyle?) -> Self {
        let value = value ?? .normal
        storage.fontStyle =!= .init(.value, value)
        return self
    }

    public var color: UIColor? {
        return storage.color.value
    }

    /// Set color
    /// - Parameter value: If set nil, color will be inherit
    @discardableResult
    public func color(_ value: UIColor?) -> Self {
        guard let value = value else {
            storage.color =!= .init(.inherit, nil)
            return self
        }
        storage.color =!= .init(.value, value)
        return self
    }

    public var backgroundColor: UIColor? {
        return storage.backgroundColor.value
    }

    /// Set background color
    /// - Parameter value: If set nil, backgroundColor will be unset.
    @discardableResult
    public func backgroundColor(_ value: UIColor?) -> Self {
        guard let value = value else {
            storage.backgroundColor =!= .init(.unset, nil)
            return self
        }
        storage.backgroundColor =!= .init(.value, value)
        return self
    }

    public var lineHeight: NumbericValue {
        return NumbericValue(storage.lineHeight) ?? .em(1.2)
    }

    /// Set line height
    /// - Parameter value: If set nil, lineHeight will be nil
    @discardableResult
    public func lineHeight(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.lineHeight =!= .init(.unset, nil)
            return self
        }
        storage.lineHeight =!= value.style
        return self
    }

    public var textAlign: TextAlign {
        return storage.textAlign.value ?? .left
    }

    @discardableResult
    public func textAlign(_ value: TextAlign?) -> Self {
        guard let value = value else {
            storage.textAlign =!= .init(.inherit, .left)
            return self
        }
        storage.textAlign =!= .init(.value, value)
        return self
    }

    public var verticalAlign: VerticalAlign {
        return storage.verticalAlign.value ?? .baseline
    }

    @discardableResult
    public func verticalAlign(_ value: VerticalAlign?) -> Self {
        guard let value = value else {
            storage.verticalAlign =!= .init(.inherit, .baseline)
            return self
        }
        storage.verticalAlign =!= .init(.value, value)
        return self
    }

    public var textDecoration: TextDecoration? {
        return storage.textDecoration.value
    }

    /// Set text decoration
    /// - Parameter value: If set nil, textDecoration will be nil
    @discardableResult
    public func textDecoration(_ value: TextDecoration?) -> Self {
        guard let value = value else {
            storage.textDecoration =!= .init(.unset, nil)
            return self
        }
        storage.textDecoration =!= .init(.value, value)
        return self
    }

    public var lineCamp: LineCamp? {
        return storage.lineCamp.value
    }

    /// Set lineCamp
    /// - Parameter value: LineCamp
    @discardableResult
    public func lineCamp(_ value: LineCamp?) -> Self {
        guard let value = value else {
            storage.lineCamp =!= .init(.unset, nil)
            return self
        }
        storage.lineCamp =!= .init(.value, value)
        return self
    }

    public var border: Border? {
        return storage.border.value
    }

    /// Set borders
    /// - Parameter top: borderTop default is nil
    /// - Parameter right: borderRight defult is borderTop
    /// - Parameter bottom: borderBottom default is borderTop
    /// - Parameter left: borderLeft default is borderRight
    @discardableResult
    public func border(top: BorderEdge? = nil, right: BorderEdge? = nil, bottom: BorderEdge? = nil, left: BorderEdge? = nil) -> Self {
        if top == nil, right == nil, bottom == nil, left == nil {
            storage.border =!= .init(.unset, nil)
            return self
        }
        storage.border = .init(.value, Border(top, right, bottom, left))
        return self
    }

    public var borderRadius: BorderRadius? {
        return storage.borderRadius.value
    }

    /// Set borderRadius
    /// - Parameter topLeft: borderRadius topLeft default is nil
    /// - Parameter topRight: borderRadius topRight default is nil
    /// - Parameter bottomRight: borderRadius bottomRight default is nil
    /// - Parameter bottomLeft: borderRadius bottomLeft default is nil
    @discardableResult
    public func borderRadius(topLeft: LengthSize? = nil, topRight: LengthSize? = nil, bottomRight: LengthSize? = nil, bottomLeft: LengthSize? = nil) -> Self {
        if topLeft == nil, topRight == nil, bottomRight == nil, bottomLeft == nil {
            storage.border =!= .init(.unset, nil)
            return self
        }
        storage.borderRadius = .init(.value, BorderRadius(topLeft, topRight, bottomRight, bottomLeft))
        return self
    }

    public var margin: Edges? {
        assert(storage.margin.value != nil)
        return storage.margin.value
    }

    /// Set margin
    /// - Parameter top: marginTop default is 0
    /// - Parameter right: marginRight default is marginTop
    /// - Parameter bottom: marginBottom default is marginTop
    /// - Parameter left: marginLeft default is marginRight
    @discardableResult
    public func margin(top: NumbericValue? = nil, right: NumbericValue? = nil, bottom: NumbericValue? = nil, left: NumbericValue? = nil) -> Self {
        if top == nil, right == nil, bottom == nil, left == nil {
            storage.margin =!= .init(.unset, Edges())
            return self
        }
        storage.margin = .init(.value, Edges(top, right, bottom, left))
        return self
    }

    public var padding: Edges? {
        assert(storage.padding.value != nil)
        return storage.padding.value
    }

    /// Set padding
    /// - Parameter top: paddingTop default is 0
    /// - Parameter right: paddingRight default is paddingTop
    /// - Parameter bottom: paddingBottom default is paddingTop
    /// - Parameter left: paddingLeft default is paddingRight
    @discardableResult
    public func padding(top: NumbericValue? = nil, right: NumbericValue? = nil, bottom: NumbericValue? = nil, left: NumbericValue? = nil) -> Self {
        if top == nil, right == nil, bottom == nil, left == nil {
            storage.padding =!= .init(.unset, Edges())
            return self
        }
        storage.padding = .init(.value, Edges(top, right, bottom, left))
        return self
    }

    public var width: NumbericValue? {
        return NumbericValue(storage.width)
    }

    /// Set width
    /// - Parameter value: width default is auto
    @discardableResult
    public func width(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.width =!= .init(.auto, nil)
            return self
        }
        storage.width =!= value.style
        return self
    }

    public var height: NumbericValue? {
        return NumbericValue(storage.height)
    }

    /// Set height
    /// - Parameter value: height default is auto
    @discardableResult
    public func height(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.height =!= .init(.auto, nil)
            return self
        }
        storage.height =!= value.style
        return self
    }

    public var maxWidth: NumbericValue? {
        return NumbericValue(storage.maxWidth)
    }

    /// Set maxWidth
    /// - Parameter value: maxWidth default is unset
    @discardableResult
    public func maxWidth(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.maxWidth =!= .init(.unset, nil)
            return self
        }
        storage.maxWidth =!= value.style
        return self
    }

    public var maxHeight: NumbericValue? {
        return NumbericValue(storage.maxHeight)
    }

    /// Set maxHeight
    /// - Parameter value: maxHeight default is unset
    @discardableResult
    public func maxHeight(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.maxHeight =!= .init(.auto, nil)
            return self
        }
        storage.maxHeight =!= value.style
        return self
    }

    public var minWidth: NumbericValue? {
        return NumbericValue(storage.minWidth)
    }

    /// Set minWidth
    /// - Parameter value: minWidth default is unset
    @discardableResult
    public func minWidth(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.minWidth =!= .init(.auto, nil)
            return self
        }
        storage.minWidth =!= value.style
        return self
    }

    public var minHeight: NumbericValue? {
        return NumbericValue(storage.minHeight)
    }

    /// Set minHeight
    /// - Parameter value: minHeight default is unset
    @discardableResult
    public func minHeight(_ value: NumbericValue?) -> Self {
        guard let value = value else {
            storage.minHeight =!= .init(.auto, nil)
            return self
        }
        storage.minHeight =!= value.style
        return self
    }

    public var textOverflow: LKTextOverflow {
        return storage.textOverflow.value ?? .none
    }

    @discardableResult
    public func textOverflow(_ value: LKTextOverflow?) -> Self {
        guard let value = value else {
            storage.textOverflow =!= .init(.unset, nil)
            return self
        }
        storage.textOverflow =!= .init(.value, value)
        return self
    }
}

extension LKRichStyle: LKCopying {
    public func copy() -> Any {
        // swiftlint:disable force_cast
        return LKRichStyle(storage: self.storage.copy() as! LKRenderRichStyle)
    }
}
