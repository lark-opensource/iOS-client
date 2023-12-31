//
//  RenderList.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/10/9.
//

import UIKit
import Foundation

final class RenderList: RenderBlock {

    enum ListRenderType {
        case listItem(renderer: RenderObject)
        case listContainer
        case none
    }

    var listRenderType: ListRenderType = .none
    var listItemType: ListItemType?

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }

        var offsetSize: CGSize
        var listItemRunBox: RunBox?
        switch listRenderType {
        case .listItem(let renderer):
            offsetSize = renderer.layout(size, context: context)
            // 当前展示具体内容，需要偏移
            offsetSize.width += 15
            if let renderText = renderer as? RenderText,
               let renderBox = renderText.createRunBox(),
               case .normal(let box) = renderBox {
                listItemRunBox = box
            }
        case .listContainer:
            // 当前为容器，需要偏移
            offsetSize = CGSize(width: 24, height: 0)
        case .none:
            offsetSize = .zero
        }

        let writingMode = renderStyle.writingMode
        let fixedSize = CGSize(width: size.width - offsetSize.width, height: size.height)

        // 目前的逻辑，这个if不会为YES，children全是Block
        if isChildrenInline {
            let container = ListInlineContainerRunBox(
                style: renderStyle,
                avaliableMainAxisWidth: fixedSize.mainAxisWidth(writingMode: writingMode),
                avaliableCrossAxisWidth: fixedSize.crossAxisWidth(writingMode: writingMode),
                renderContextLocation: renderContextLocation
            )
            container.listItemRunBox = listItemRunBox
            container.listItemType = listItemType
            container.offsetSize = offsetSize

            _ = layoutInline(fixedSize, isInlineBlock: false, container: container, context: context)

            return CGSize(
                width: container.size.width + offsetSize.width,
                height: container.size.height
            )
        }

        if isChildrenBlock || children.isEmpty { // 空Block需要由max/min W/H决策大小
            let container = ListBlockContainerRunBox(
                style: renderStyle,
                avaliableMainAxisWidth: fixedSize.mainAxisWidth(writingMode: writingMode),
                avaliableCrossAxisWidth: fixedSize.crossAxisWidth(writingMode: writingMode),
                renderContextLocation: renderContextLocation
            )
            container.listItemRunBox = listItemRunBox
            container.listItemType = listItemType
            container.offsetSize = offsetSize

            _ = layoutBlock(fixedSize, isInlineBlock: false, container: container, context: context)

            return CGSize(
                width: container.size.width + offsetSize.width,
                height: container.size.height
            )
        }

        return CGSize(
            width: renderStyle.calculateWidthWithEdge(avalidWidth: fixedSize.width),
            height: renderStyle.calculateHeightWithEdge(avalidHeight: fixedSize.height)
        )
    }
}

fileprivate final class ListInlineContainerRunBox: InlineBlockContainerRunBox {
    var listItemRunBox: RunBox?
    var listItemType: ListItemType?
    var offsetSize: CGSize = .zero

    override var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + offsetSize.width + baseOrigin.x, y: origin.y + baseOrigin.y)
    }

    override func layout(context: LayoutContext?) {
        super.layout(context: context)
        if let box = listItemRunBox, let firstLine = lineBoxs.first {
            box.ownerLineBox = firstLine
            if case .ul = listItemType {
                let origin = firstLine.baselineOrigin
                // 这里的 y 参考了 font 的 ascent 和 lineheight 的比例，实现了仅依赖 ascent 就可以计算出近似居中的效果
                box.origin = CGPoint(x: origin.x - offsetSize.width + 3, y: origin.y + firstLine.ascent / 8 * 3 - offsetSize.height / 2)
            } else {
                let origin = firstLine.baselineOrigin
                box.baselineOrigin = CGPoint(x: origin.x - offsetSize.width + 3, y: origin.y)
            }
            box.layout(context: context)
        }
    }

    override func draw(_ paintInfo: PaintInfo) {
        super.draw(paintInfo)
        if let box = listItemRunBox {
            box.draw(paintInfo)
        }
    }

    override func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        guard canTiledByLines() else {
            return [TiledInfo(runBoxs: [self], area: multiplication(size))]
        }
        var infos = [TiledInfo]()
        if let listItem = listItemRunBox {
            let info = TiledInfo(runBoxs: [listItem], area: multiplication(listItem.size))
            infos.append(info)
        }
        infos.append(contentsOf: super.getTiledInfos())
        return infos
    }
}

fileprivate final class ListBlockContainerRunBox: BlockContainerRunBox {
    var listItemRunBox: RunBox?
    var listItemType: ListItemType?
    var offsetSize: CGSize = .zero

    override var globalOrigin: CGPoint {
        // ownerLineBox不一定有值，需要看是否自己是否处在InlineBlockContainerRunBox中
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + offsetSize.width + baseOrigin.x, y: origin.y + baseOrigin.y)
    }

    /// copy from ListInlineContainerRunBox
    override func layout(context: LayoutContext?) {
        super.layout(context: context)
        if let box = listItemRunBox, let firstLine = self.findInlineBlockContainerRunBox(runbox: self)?.lineBoxs.first {
            box.ownerLineBox = firstLine
            if case .ul = listItemType {
                let origin = firstLine.baselineOrigin
                // 这里的 y 参考了 font 的 ascent 和 lineheight 的比例，实现了仅依赖 ascent 就可以计算出近似居中的效果
                box.origin = CGPoint(x: origin.x - offsetSize.width + 3, y: origin.y + firstLine.ascent / 8 * 3 - offsetSize.height / 2)
            } else {
                let origin = firstLine.baselineOrigin
                box.baselineOrigin = CGPoint(x: origin.x - offsetSize.width + 3, y: origin.y)
            }
            box.layout(context: context)
        }
    }

    /// 递归找到第一个InlineBlockContainerRunBox
    private func findInlineBlockContainerRunBox(runbox: RunBox) -> InlineBlockContainerRunBox? {
        // 已经是目标对象
        if let inlineBlock = runbox as? InlineBlockContainerRunBox { return inlineBlock }
        // BlockContainer进行递归
        if let block = runbox as? BlockContainerRunBox, let first = block.children.first {
            return self.findInlineBlockContainerRunBox(runbox: first)
        }
        // 其他情况不处理
        return nil
    }

    override func draw(_ paintInfo: PaintInfo) {
        super.draw(paintInfo)
        if let box = listItemRunBox {
            box.draw(paintInfo)
        }
    }

    override func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        guard canTiledByLines() else {
            return [TiledInfo(runBoxs: [self], area: multiplication(size))]
        }
        var infos = [TiledInfo]()
        if let listItem = listItemRunBox {
            let info = TiledInfo(runBoxs: [listItem], area: multiplication(listItem.size))
            infos.append(info)
        }
        infos.append(contentsOf: super.getTiledInfos())
        return infos
    }
}
