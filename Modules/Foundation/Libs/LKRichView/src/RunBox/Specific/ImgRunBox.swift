//
//  ImgRunBox.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/15.
//

import UIKit
import Foundation

final class ImgRunBox: RunBox {

    weak var ownerLineBox: LineBox?
    weak var ownerRenderObject: RenderObject?
    var writingMode: WritingMode {
        style.writingMode
    }
    var crossAxisAlign: VerticalAlign {
        style.verticalAlign
    }
    var isSplit: Bool = false

    var isLineBreak: Bool = false

    var debugOptions: ConfigOptions?

    // MARK: - origin

    var origin: CGPoint = .zero {
        didSet {
            ownerRenderObject?.boxOrigin = globalOrigin
        }
    }
    var baselineOrigin: CGPoint {
        get {
            CGPoint(x: origin.x, y: origin.y + descent + leading + edges.bottom)
        }
        set {
            origin = CGPoint(x: newValue.x, y: newValue.y - descent - leading - edges.bottom)
        }
    }
    var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + baseOrigin.x, y: origin.y + baseOrigin.y)
    }
    var globalBaselineOrigin: CGPoint {
        let origin = ownerLineBox?.baselineOrigin ?? .zero
        return CGPoint(x: baselineOrigin.x + origin.x, y: baselineOrigin.y + origin.y)
    }

    // MARK: - width

    var mainAxisWidth: CGFloat {
        contentMainAxisWidth
    }
    var contentMainAxisWidth: CGFloat {
        contentSize.mainAxisWidth(writingMode: writingMode)
    }
    var crossAxisWidth: CGFloat {
        contentCrossAxisWidth
    }
    var contentCrossAxisWidth: CGFloat {
        return contentSize.crossAxisWidth(writingMode: writingMode)
    }

    // MARK: - size

    var ascent: CGFloat {
        crossAxisWidth * style.font.ascender / style.font.lineHeight
    }
    var descent: CGFloat {
        crossAxisWidth * abs(style.font.descender) / style.font.lineHeight
    }
    var leading: CGFloat {
        crossAxisWidth * abs(style.font.leading) / style.font.lineHeight
    }
    private(set) var contentSize: CGSize = .zero
    let edges: UIEdgeInsets = .zero
    var size: CGSize {
        if writingMode == .horizontalTB {
            return CGSize(width: mainAxisWidth, height: crossAxisWidth)
        } else {
            return CGSize(width: crossAxisWidth, height: mainAxisWidth)
        }
    }

    // MARK: - context

    var _renderContextLocation: Int
    let renderContextLength: Int = 1

    // MARK: - out of RunBox protocol

    private let style: RenderStyleOM
    private let img: CGImage?
    private let avaliableMainAxisWidth: CGFloat
    private let avaliableCrossAxisWidth: CGFloat

    init(
        style: RenderStyleOM,
        img: CGImage?,
        avaliableMainAxisWidth: CGFloat,
        avaliableCrossAxisWidth: CGFloat,
        renderContextLocation: Int
    ) {
        self.style = style
        self.img = img
        self.avaliableMainAxisWidth = avaliableMainAxisWidth
        self.avaliableCrossAxisWidth = avaliableCrossAxisWidth
        self._renderContextLocation = renderContextLocation
    }

    func layoutIfNeeded(context: LayoutContext?) {
        if crossAxisWidth == 0 || mainAxisWidth == 0 {
            layout(context: context)
        }
    }

    func layout(context: LayoutContext?) {
        if calcMaxLine(style: style, context: context) == 0 {
            return
        }
        guard let image = img else {
            switch style.writingMode {
            case .horizontalTB:
                self.contentSize = CGSize(
                    width: style.width(avalidWidth: avaliableMainAxisWidth),
                    height: style.height(avalidHeight: avaliableMainAxisWidth)
                )
            case .verticalLR, .verticalRL:
                self.contentSize = CGSize(
                    width: style.height(avalidHeight: avaliableMainAxisWidth),
                    height: style.width(avalidWidth: avaliableMainAxisWidth)
                )
            }
            return
        }

        let width = style.storage.width
        let height = style.storage.height
        var size = computeSizeBy(
            writingMode: style.writingMode,
            main: avaliableMainAxisWidth,
            cross: avaliableCrossAxisWidth
        )

        var isWidthAuto = false
        var isHeightAuto = false

        if let value = width.value {
            switch width.type {
            case .point, .value:
                size.width = value
            case .auto, .inherit, .unset:
                isWidthAuto = true
            case .em:
                size.width = style.fontSize * value
            case .percent:
                size.width = value * size.width
            }
        } else {
            isWidthAuto = true
        }

        if let value = height.value {
            switch height.type {
            case .point, .value:
                size.height = value
            case .auto, .inherit, .unset:
                isHeightAuto = false
            case .em:
                size.height = style.fontSize * value
            case .percent:
                size.height = value * size.height
            }
        } else {
            isHeightAuto = true
        }

        if isWidthAuto, isHeightAuto {
            size.width = CGFloat(image.width)
            size.height = CGFloat(image.height)
        } else if isWidthAuto {
            size.width = size.height * CGFloat(image.width) / CGFloat(image.height)
        } else if isHeightAuto {
            size.height = size.width * CGFloat(image.height) / CGFloat(image.width)
        }

        contentSize = size
    }

    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        return .disable(lhs: self, rhs: nil)
    }

    func draw(_ paintInfo: PaintInfo) {
        guard let img = img else { return }
        let baseOrigin = ownerLineBox?.origin ?? .zero
        let context = paintInfo.graphicsContext
        context.saveGState()
        context.draw(img, in: getDrawRect(baseOrigin), byTiling: false)
        context.restoreGState()
    }

    /// Img是一个整体，没办法进行拆分，所以truncate的逻辑比较简单：删除自身
    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {
        guard let ownerLineBox = ownerLineBox else { return }

        remainedMainAxisWidth += self.mainAxisWidth
        ownerLineBox.runBoxs.removeLast()
    }

    @inline(__always)
    private func getDrawRect(_ baseOrigin: CGPoint) -> CGRect {
        return CGRect(origin: CGPoint(x: baseOrigin.x + origin.x, y: baseOrigin.y + origin.y), size: size)
    }
}

@inline(__always)
func computeSizeBy(writingMode: WritingMode, main: CGFloat, cross: CGFloat) -> CGSize {
    switch writingMode {
    case .horizontalTB:
        return CGSize(width: main, height: cross)
    case .verticalLR, .verticalRL:
        return CGSize(width: cross, height: main)
    }
}
