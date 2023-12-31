//
//  RenderCode.swift
//  LKRichView
//
//  Created by 李勇 on 2022/6/23.
//

import Foundation
import UIKit

class RenderCodeLine: RenderBlock {
    /// 渲染行号
    private let lineNumberRender: RenderText
    /// 行号的宽度
    var codeLineOffset: CGFloat = 0.0
    /// 行号和内容的间隔
    var codeLineSpace: CGFloat = 4.0

    init(nodeType: Node.TypeEnum, renderStyle: LKRenderRichStyle, ownerElement: LKRichElement?, lineNumberRender: RenderText) {
        self.lineNumberRender = lineNumberRender
        super.init(nodeType: nodeType, renderStyle: renderStyle, ownerElement: ownerElement)
    }

    /// 这里传入的size没有考虑本RenderObject的padding、border，自己在布局chilren时需要考虑
    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        // 如果size入参是zero，说明当前LKRichView没有展示，此时不需要进行布局计算
        guard size != .zero else { return .zero }
        if prevLayoutSize != .zero, prevLayoutSize == size { return boxRect.size }
        self.prevLayoutSize = size

        // 布局行号，不参与maxLines逻辑
        _ = lineNumberRender.layout(size, context: nil)
        guard case .normal(let box) = lineNumberRender.createRunBox(), let textRunBox = box as? TextRunBox else { return .zero }

        let mainAxisWidth = size.mainAxisWidth(writingMode: renderStyle.writingMode)
        let crossAxisWidth = size.crossAxisWidth(writingMode: renderStyle.writingMode)
        // 布局chilren时，需要减去行号占用的宽度
        let codeLineRunBox = CodeLineContainerRunBox(
            style: renderStyle,
            avaliableMainAxisWidth: mainAxisWidth - self.codeLineOffset - self.codeLineSpace,
            avaliableCrossAxisWidth: crossAxisWidth,
            renderContextLocation: renderContextLocation
        )
        codeLineRunBox.lineNumberBox = textRunBox
        codeLineRunBox.codeLineOffset = self.codeLineOffset
        codeLineRunBox.codeLineSpace = self.codeLineSpace
        _ = layoutInline(CGSize(width: size.width - self.codeLineOffset - self.codeLineSpace, height: size.height), isInlineBlock: false, container: codeLineRunBox, context: context)
        return CGSize(width: codeLineRunBox.size.width + self.codeLineOffset + self.codeLineSpace, height: codeLineRunBox.size.height)
    }
}

class CodeLineContainerRunBox: InlineBlockContainerRunBox {
    /// 绘制行号
    var lineNumberBox: TextRunBox?
    /// 行号的宽度
    var codeLineOffset: CGFloat = 0.0
    /// 行号和内容的间隔
    var codeLineSpace: CGFloat = 4.0

    override var origin: CGPoint {
        didSet {
            guard let textRunBox = lineNumberBox else { return }
            // 布局完所有的LineBox后，需要对行号的位置进行布局：行号和第一行内容顶部对齐，所有行号右对齐
            textRunBox.origin = CGPoint(x: globalOrigin.x - textRunBox.size.width - self.codeLineSpace, y: globalOrigin.y + size.height - textRunBox.size.height)
        }
    }

    override var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        // 需要减去行号的宽度，做到无法选中行号
        return CGPoint(x: origin.x + baseOrigin.x + self.codeLineOffset + self.codeLineSpace, y: origin.y + baseOrigin.y)
    }

    override func draw(_ paintInfo: PaintInfo) {
        super.draw(paintInfo)
        // 绘制行号，有时是个空行，但是也需要绘制行号
        lineNumberBox?.draw(paintInfo)
    }

    /// copy from ListInlineContainerRunBox，分片渲染时能展示出行号
    override func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        guard canTiledByLines() else {
            return [TiledInfo(runBoxs: [self], area: multiplication(size))]
        }
        var infos = [TiledInfo]()
        if let lineNumber = lineNumberBox {
            let info = TiledInfo(runBoxs: [lineNumber], area: multiplication(lineNumber.size))
            infos.append(info)
        }
        infos.append(contentsOf: super.getTiledInfos())
        return infos
    }
}
