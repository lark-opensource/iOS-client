//
//  RenderText.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/26.
//

import UIKit
import Foundation

final class RenderText: RenderInline {

    let text: String

    lazy var utf16Array: [Unicode.UTF16.CodeUnit] = {
        return Array(text.utf16)
    }()

    override var isRenderInline: Bool {
        true
    }
    override var isRenderBlock: Bool {
        false
    }
    override var isRenderFloat: Bool {
        false
    }
    override var shouldAddSubview: Bool {
        false
    }

    init(text: String, renderStyle: LKRenderRichStyle, ownerElement: LKRichElement?) {
        self.text = text
        super.init(nodeType: .text, renderStyle: renderStyle, ownerElement: ownerElement)
        self.renderContextLength = text.utf16.count
    }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            switch runBox {
            case .normal(let runbox):
                runbox?._renderContextLocation = renderContextLocation
            case .split(let runboxs):
                for runbox in runboxs {
                    runbox._renderContextLocation = renderContextLocation
                }
            }
            return size
        }
        // 得到NSAttributedString，生成[CTLine]
        let attributedText = Self.createAttributedStringWith(text: text, renderStyle: renderStyle)
        let frameSetter = TextFrameSetter(attributedText, self.debugOptions?.fixSplitForTextRunBox ?? false)
        let lines = frameSetter.getLines(length: attributedText.length)
        let typeSetter = TextTypeSetter(frameSetter)

        var location = renderContextLocation
        // 得到的[RunBox]是不限制宽的，由父RunBox进行split折行
        var runBoxs = [RunBox]()
        for line in lines {
            let runBox = TextRunBox(
                style: renderStyle,
                typeSetter: typeSetter,
                lineRange: line.range,
                renderContextLocation: location
            )
            // 这里有个假设：如何CTFrame得到多个CTLine，说明CTLine间有换行符，需要设置换行标记
            runBox.isLineBreak = true
            runBox.ownerRenderObject = self
            runBox.layout(line: line)
            runBoxs.append(runBox)
            location += runBox.renderContextLength
        }

        // 需要额外处理文本最后是换行符的情况
        if let lastRunBox = runBoxs.last {
            if let lastCharacter = text.last {
                lastRunBox.isLineBreak = ["\n", "\r\n", "\r"].contains(lastCharacter)
            } else {
                // 对齐之前的写法："isLineBreak = text.last == "\n""在text.last为nil时，isLineBreak为false
                lastRunBox.isLineBreak = false
            }
        }

        renderContextLength = location - renderContextLocation
        if runBoxs.count == 1 {
            self.runBox = .normal(runBoxs[0])
            contentSize = runBoxs[0].size
            return contentSize
        } else if runBoxs.count > 1 {
            // 多 runBox 的 contentSize 会直接按折行来取，不会按整体
            self.runBox = .split(runBoxs)
        }
        return .zero
    }

    override func paint(_ paintInfo: PaintInfo) {
        switch runBox {
        case .normal(let unwrappedBox):
            unwrappedBox?.draw(paintInfo)
        case .split(let runBoxs):
            runBoxs.forEach({ $0.draw(paintInfo) })
        }
    }

    static func createAttributedStringWith(text: String, renderStyle: RenderStyleOM) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [
            AttributedKey.font.nsAttrKey: createCTFontWith(
                font: renderStyle.font,
                size: renderStyle.fontSize,
                style: renderStyle.fontStyle,
                weight: renderStyle.fontWeight
            ),
            AttributedKey.color.nsAttrKey: renderStyle.color,
            .paragraphStyle: NSMutableParagraphStyle()
        ]
        if let backgroundColor = renderStyle.backgroundColor {
            // 目前没有支持背景色
            attributes[AttributedKey.backgroundColor.nsAttrKey] = backgroundColor
        }
        return NSAttributedString(string: text, attributes: attributes)
    }

    @inline(__always)
    static func createCTFontWith(font: CTFont, size: CGFloat, style: FontStyle, weight: FontWeight) -> CTFont {
        var symbolicTrait: UInt32 = 0
        var fontWeightValue: CGFloat = weight.rawValue // UIAccessibility.isBoldTextEnabled ? weight.boldTextWeightValue : weight.rawValue
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            symbolicTrait += CTFontSymbolicTraits.traitBold.rawValue
        default:
            break
        }

        let traits: [CFString: Any] = [
            kCTFontSymbolicTrait: NSNumber(value: symbolicTrait),
            kCTFontWeightTrait: NSNumber(value: fontWeightValue)
        ]
        let attributes = NSMutableDictionary(
            dictionary: CTFontDescriptorCopyAttributes(CTFontCopyFontDescriptor(font))
        )
        attributes[kCTFontTraitsAttribute] = traits
        if attributes[kCTFontNameAttribute] != nil {
            attributes.removeObject(forKey: kCTFontNameAttribute)
        }
        if attributes[kCTFontFamilyNameAttribute] == nil {
            attributes[kCTFontFamilyNameAttribute] = CTFontCopyFamilyName(font)
        }

        // 斜体，自己用CGAffineTransform实现
        if var matrix = createMatrixWith(fontStyle: style) {
            return CTFontCreateWithFontDescriptor(
                CTFontDescriptorCreateWithAttributes(attributes),
                size,
                &matrix
            )
        } else {
            return CTFontCreateWithFontDescriptor(
                CTFontDescriptorCreateWithAttributes(attributes),
                size,
                nil
            )
        }
    }

    @inline(__always)
    static func createMatrixWith(fontStyle: FontStyle) -> CGAffineTransform? {
        switch fontStyle {
        case .normal:
            return nil
        case .italic:
            return .init(a: 1, b: 0, c: CGFloat(tanf(.pi / 180 * 15)), d: 1, tx: 0, ty: 0)
        }
    }
}
