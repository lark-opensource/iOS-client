//
//  RenderStyleOM.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/26.
//

import Foundation
import UIKit

final class RenderStyleOM {
    weak var parent: RenderStyleOM?
    let storage: LKRenderRichStyle
    init(_ style: LKRenderRichStyle) {
        storage = style
    }

    var writingMode: WritingMode {
        return storage.writingMode
    }

    var isBlockSelection: Bool {
        switch storage.isBlockSelection.type {
        case .inherit:
            return parent?.isBlockSelection ?? false
        case .em, .percent, .point, .auto, .unset:
            return false
        case .value:
            return storage.isBlockSelection.value ?? false
        }
    }

    var display: Display {
        switch storage.display.type {
        case .inherit:
            return parent?.display ?? .none
        case .em, .percent, .point, .auto, .unset:
            return .none
        case .value:
            return storage.display.value ?? .none
        }
    }

    var fontSize: CGFloat {
        switch storage.fontSize.type {
        case .inherit:
            return parent?.fontSize ?? SYSTEM_FONT_SIZE
        case .unset, .auto, .value:
            return SYSTEM_FONT_SIZE
        case .em:
            if let value = storage.fontSize.value {
                return (parent?.fontSize ?? SYSTEM_FONT_SIZE) * value
            }
            return SYSTEM_FONT_SIZE
        case .percent, .point:
            return storage.fontSize.value ?? SYSTEM_FONT_SIZE
        }
    }

    private var _font: UIFont?
    var font: UIFont {
        if let _font = _font {
            return _font
        }
        var font: UIFont
        switch storage.font.type {
        case .inherit:
            font = parent?.font ?? SYSTEM_FONT(fontSize)
        case .unset, .em, .auto:
            font = SYSTEM_FONT(fontSize)
        case .percent, .point, .value:
            font = storage.font.value ?? SYSTEM_FONT(fontSize)
        }
        let finalFont = RenderText.createCTFontWith(font: font, size: fontSize, style: fontStyle, weight: fontWeight)
        _font = finalFont
        return finalFont
    }

    var fontWeight: FontWeight {
        switch storage.fontWeight.type {
        case .inherit:
            return parent?.fontWeight ?? .normal
        case .unset, .em, .percent, .point, .auto:
            return .normal
        case .value:
            return storage.fontWeight.value ?? .normal
        }
    }

    var fontStyle: FontStyle {
        switch storage.fontStyle.type {
        case .inherit:
            return parent?.fontStyle ?? .normal
        case .unset, .em, .percent, .point, .auto:
            return .normal
        case .value:
            return storage.fontStyle.value ?? .normal
        }
    }

    var color: UIColor {
        switch storage.color.type {
        case .inherit:
            return parent?.color ?? UIColor.black
        case .auto, .unset, .em, .percent, .point:
            return UIColor.black
        case .value:
            return storage.color.value ?? UIColor.black
        }
    }

    var backgroundColor: UIColor? {
        switch storage.backgroundColor.type {
        case .inherit:
            return parent?.backgroundColor
        case .auto, .unset, .em, .percent, .point:
            return nil
        case .value:
            return storage.backgroundColor.value
        }
    }

    var lineHeight: CGFloat {
        switch storage.lineHeight.type {
        case .auto, .value, .unset, .inherit:
            guard let lineHeight = parent?.lineHeight else {
                break
            }
            return lineHeight
        case .em:
            guard let value = storage.lineHeight.value else {
                break
            }
            return fontSize * value
        case .percent:
            guard let value = storage.lineHeight.value else {
                break
            }
            return fontSize * value / 100
        case .point:
            guard let value = storage.lineHeight.value else {
                break
            }
            return value
        }
        return fontSize * 1.2
    }

    var textAlign: TextAlign {
        switch storage.textAlign.type {
        case .inherit:
            return parent?.textAlign ?? .left
        case .auto, .em, .percent, .point, .unset:
            return .left
        case .value:
            return storage.textAlign.value ?? .left
        }
    }

    var verticalAlign: VerticalAlign {
        switch storage.verticalAlign.type {
        case .inherit:
            return parent?.verticalAlign ?? .baseline
        case .auto, .em, .percent, .point, .unset:
            return .baseline
        case .value:
            return storage.verticalAlign.value ?? .baseline
        }
    }

    var textDirection: TextDecorations? {
        switch storage.textDecoration.type {
        case .inherit, .value:
            if let parentValue = parent?.textDirection,
                let value = storage.textDecoration.value {
                return parentValue + value
            }
            if let value = storage.textDecoration.value {
                return TextDecorations(value)
            }
            return parent?.textDirection
        case .auto, .em, .percent, .unset, .point:
            return nil
        }
    }

    var border: Border? {
        guard storage.border.type == .value else {
            return nil
        }
        return storage.border.value
    }

    var borderEdgeInsets: UIEdgeInsets? {
        guard let border = border else {
            return nil
        }
        return UIEdgeInsets(
            top: convertNumbericValue(border.top?.width ?? .point(0)),
            left: convertNumbericValue(border.left?.width ?? .point(0)),
            bottom: convertNumbericValue(border.bottom?.width ?? .point(0)),
            right: convertNumbericValue(border.right?.width ?? .point(0))
        )
    }

    var borderRadius: BorderRadius? {
        guard storage.borderRadius.type == .value else {
            return nil
        }
        return storage.borderRadius.value
    }

    var margin: UIEdgeInsets {
        guard storage.margin.type == .value, let margin = storage.margin.value else {
            return .zero
        }
        return UIEdgeInsets(
            top: convertNumbericValue(margin.top),
            left: convertNumbericValue(margin.left),
            bottom: convertNumbericValue(margin.bottom),
            right: convertNumbericValue(margin.right)
        )
    }

    var padding: UIEdgeInsets {
        guard storage.padding.type == .value, let padding = storage.padding.value else {
            return .zero
        }
        return UIEdgeInsets(
            top: convertNumbericValue(padding.top),
            left: convertNumbericValue(padding.left),
            bottom: convertNumbericValue(padding.bottom),
            right: convertNumbericValue(padding.right)
        )
    }

    var textOverflow: LKTextOverflow {
        switch storage.textOverflow.type {
        case .inherit:
            return parent?.textOverflow ?? .none
        case .unset, .auto, .em, .percent, .point:
            return .none
        case .value:
            return storage.textOverflow.value ?? .none
        }
    }

    var lineCamp: LineCamp? {
        switch storage.lineCamp.type {
        case .value:
            return storage.lineCamp.value
        case .inherit, .unset, .auto, .em, .percent, .point:
            return nil
        }
    }

    func genContextLineCamp(context: LayoutContext?, maxLine: Int? = nil) -> LineCamp? {
        if let contextLineCamp = context?.lineCamp, let lineCamp = lineCamp {
            return LineCamp(
                maxLine: maxLine ?? min(contextLineCamp.maxLine, lineCamp.maxLine),
                blockTextOverflow: lineCamp.blockTextOverflow
            )
        }
        return LineCamp(
            maxLine: maxLine ?? calcMaxLine(style: self, context: context),
            blockTextOverflow: lineCamp?.blockTextOverflow ?? context?.lineCamp?.blockTextOverflow
        )
    }

    func width(avalidWidth: CGFloat) -> CGFloat {
        switch storage.width.type {
        case .auto, .inherit, .unset, .value:
            return avalidWidth
        case .em:
            guard let value = storage.width.value else {
                return avalidWidth
            }
            return value * fontSize
        case .percent:
            guard let value = storage.width.value else {
                return avalidWidth
            }
            return avalidWidth / 100 * value
        case .point:
            guard let value = storage.width.value else {
                return avalidWidth
            }
            return value
        }
    }

    func height(avalidHeight: CGFloat) -> CGFloat {
        switch storage.height.type {
        case .auto, .inherit, .unset, .value:
            return avalidHeight
        case .em:
            guard let value = storage.height.value else {
                return avalidHeight
            }
            return value * fontSize
        case .percent:
            guard let value = storage.height.value else {
                return avalidHeight
            }
            return avalidHeight / 100 * value
        case .point:
            guard let value = storage.height.value else {
                return avalidHeight
            }
            return value
        }
    }

    func maxWidth(avalidWidth: CGFloat) -> CGFloat? {
        guard let value = storage.maxWidth.value else {
            return nil
        }
        switch storage.maxWidth.type {
        case .auto, .unset, .value:
            return nil
        case .inherit:
            return parent?.maxWidth(avalidWidth: avalidWidth)
        case .em:
            return value * fontSize
        case .percent:
            return avalidWidth / 100 * value
        case .point:
            return value
        }
    }

    func maxHeight(avalidHeight: CGFloat) -> CGFloat? {
        guard let value = storage.maxHeight.value else {
            return nil
        }
        switch storage.maxHeight.type {
        case .auto, .unset, .value:
            return nil
        case .inherit:
            return parent?.maxHeight(avalidHeight: avalidHeight)
        case .em:
            return value * fontSize
        case .percent:
            return avalidHeight / 100 * value
        case .point:
            return value
        }
    }

    func minWidth(avalidWidth: CGFloat) -> CGFloat? {
        guard let value = storage.minWidth.value else {
            return nil
        }
        switch storage.minWidth.type {
        case .auto, .unset, .value:
            return nil
        case .inherit:
            return parent?.minWidth(avalidWidth: avalidWidth)
        case .em:
            return value * fontSize
        case .percent:
            return avalidWidth / 100 * value
        case .point:
            return value
        }
    }

    func minHeight(avalidHeight: CGFloat) -> CGFloat? {
        guard let value = storage.minHeight.value else {
            return nil
        }
        switch storage.minHeight.type {
        case .auto, .unset, .value:
            return nil
        case .inherit:
            return parent?.minHeight(avalidHeight: avalidHeight)
        case .em:
            return value * fontSize
        case .percent:
            return avalidHeight / 100 * value
        case .point:
            return value
        }
    }

    func calculateWidthWithEdge(avalidWidth: CGFloat) -> CGFloat {
        return width(avalidWidth: avalidWidth) - padding.left - padding.right - (borderEdgeInsets?.left ?? 0) - (borderEdgeInsets?.right ?? 0)
    }

    func calculateHeightWithEdge(avalidHeight: CGFloat) -> CGFloat {
        return height(avalidHeight: avalidHeight) - padding.top - padding.bottom - (borderEdgeInsets?.top ?? 0) - (borderEdgeInsets?.bottom ?? 0)
    }

    func calculateMainAxisWidth(contentSize size: CGSize) -> CGFloat {
        switch writingMode {
        case .horizontalTB:
            return size.width + padding.left + padding.right + (borderEdgeInsets?.left ?? 0) + (borderEdgeInsets?.right ?? 0)
        case .verticalLR, .verticalRL:
            return size.height + padding.top + padding.bottom + (borderEdgeInsets?.top ?? 0) + (borderEdgeInsets?.bottom ?? 0)
        }
    }

    func calculateCrossAxisWidth(contentSize size: CGSize) -> CGFloat {
        switch writingMode {
        case .horizontalTB:
            return size.height + padding.top + padding.bottom + (borderEdgeInsets?.top ?? 0) + (borderEdgeInsets?.bottom ?? 0)
        case .verticalLR, .verticalRL:
            return size.width + padding.left + padding.right + (borderEdgeInsets?.left ?? 0) + (borderEdgeInsets?.right ?? 0)
        }
    }

    @inline(__always)
    private func convertNumbericValue(_ value: NumbericValue) -> CGFloat {
        switch value {
        case .em(let em):
            return fontSize * em
        case .percent:
            return 0
        case .point(let point):
            return point
        }
    }
}

extension CGRect {
    /// 减去UIEdgeInsets，坐标系为CoreText坐标系，左下角原点
    /// - Parameter lhs: CGRect
    /// - Parameter rhs: UIEdegeInsets
    static func - (_ lhs: CGRect, _ rhs: UIEdgeInsets) -> CGRect {
        return CGRect(
            x: lhs.origin.x - rhs.left,
            y: lhs.origin.y + rhs.top,
            width: lhs.width - rhs.left - rhs.right,
            height: lhs.height - rhs.top - rhs.bottom
        )
    }
}
