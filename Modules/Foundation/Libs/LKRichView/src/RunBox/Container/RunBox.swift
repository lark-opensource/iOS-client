//
//  RunBox.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/15.
//

import UIKit
import Foundation

protocol RunBox: AnyObject {

    var ownerLineBox: LineBox? { get set }
    var ownerRenderObject: RenderObject? { get set }
    var writingMode: WritingMode { get }
    var crossAxisAlign: VerticalAlign { get }

    var debugOptions: ConfigOptions? { get set }

    // origin
    /// CoreText坐标系的原点，左下角，相对于ownerLineBox的布局
    var origin: CGPoint { get set }
    /// CoreText coordinate
    var baselineOrigin: CGPoint { get set }
    /// 整个RichView坐标系下的origin
    var globalOrigin: CGPoint { get }
    var globalBaselineOrigin: CGPoint { get }

    // width
    var mainAxisWidth: CGFloat { get }
    var crossAxisWidth: CGFloat { get }
    var contentMainAxisWidth: CGFloat { get }
    var contentCrossAxisWidth: CGFloat { get }

    // size
    var ascent: CGFloat { get }
    var descent: CGFloat { get }
    var leading: CGFloat { get }
    var size: CGSize { get }
    var contentSize: CGSize { get }
    var edges: UIEdgeInsets { get }

    // context
    var _renderContextLocation: Int { get set }
    /// 在文字流中占的位置
    var renderContextLocation: Int { get }
    /// 在文字流中占的长度
    var renderContextLength: Int { get }
    var renderContextRange: CFRange { get }

    var isSplit: Bool { get }
    var isLineBreak: Bool { get set }
    /// 目前只有InlineBlockContainerRunBox、TextRubBox支持split；mainAxisWidth：留给当前RunBox的宽度，first：是不是一行当中的第一个RunBox
    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult
    func layoutIfNeeded(context: LayoutContext?)
    func layout(context: LayoutContext?)
    /// return false：对前一个RunBox进行truncate；return true：token已经展示下，无需再处理
    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat)
    func draw(_ paintInfo: PaintInfo)

    // 分片
    func canRender() -> Bool
    /// 是否能按行分片：默认当RenderObject无backgroundColor & border时，可按行分片
    func canTiledByLines() -> Bool
    /// 获取分片信息，叶子结点使用默认方式返回自己，container节点需要按需复写
    func getTiledInfos() -> [TiledInfo]
}

extension RunBox {
    var renderContextLocation: Int {
        ownerRenderObject?.renderContextLocation ?? _renderContextLocation
    }

    /// 相对原本的 RenderInlineContext 中的range
    var renderContextRange: CFRange {
        CFRangeMake(renderContextLocation, renderContextLength)
    }

    var globalRect: CGRect {
        return CGRect(origin: globalOrigin, size: size)
    }

    /// 在 y 轴方向，填满了整行
    var fullLineGlobalRect: CGRect {
        guard let line = ownerLineBox else {
            return globalRect
        }
        return CGRect(x: globalOrigin.x, y: line.origin.y, width: size.width, height: line.crossAxisWidth)
    }

    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {

    }

    func canRender() -> Bool {
        return ownerRenderObject?.isNeedRender ?? true
    }

    func canTiledByLines() -> Bool {
        guard let renderObject = ownerRenderObject else { return true }
        return renderObject.renderStyle.backgroundColor == nil && renderObject.renderStyle.border == nil
    }

    func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        return [TiledInfo(runBoxs: [self], area: multiplication(size))]
    }
}

enum RunBoxSplitResult {
    /// split 成功
    case success(lhs: RunBox, rhs: RunBox)
    /// 不支持 split
    case disable(lhs: RunBox, rhs: RunBox?)
    /// split 失败，留给 lhs 的空间不足
    case failure(lhs: RunBox, rhs: RunBox?)
    /// 因为换行符触发的 split，实际空间足够放下自己
    case breakLine
}

@inline(__always)
func drawDebugLines(_ context: CGContext, _ rect: CGRect) {
    context.saveGState()
    context.addPath(CGPath(rect: rect, transform: nil))
    UIColor.red.setStroke()
    context.strokePath()
    context.restoreGState()
}
