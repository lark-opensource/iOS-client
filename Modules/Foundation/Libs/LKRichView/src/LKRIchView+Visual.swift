//
//  LKRIchView+Visual.swift
//  LKRichView
//
//  Created by qihongye on 2021/10/7.
//

import UIKit
import Foundation

extension LKRichView {
    @objc
    func enterVisualMode() {
        guard selectionModule.getMode() == .visual,
              core.isLayoutFinished,
              let writingMode = core.getRenderer({ $0.renderStyle.writingMode }),
              var configOptions = configOptions else {
            leaveVisualMode()
            return
        }

        modeWatcher?.isPaused = true

        let rects = core.getAllSelectedRects().0.map { $0.convertCoreText2UIViewCoordinate(frame) }

        configOptions.bindVisulConfigToCuosor()

        // init cursor rect
        if let startRect = rects.first, let endRect = rects.last {
            configOptions.startCursor.rect.origin = CGPoint(
                x: startRect.minX - configOptions.startCursor.rect.width / 2,
                y: startRect.minY
            )
            configOptions.startCursor.rect.size.height = startRect.height
            configOptions.startCursor.location.point = CGPoint(
                x: configOptions.startCursor.rect.centerX,
                y: configOptions.startCursor.rect.centerY
            )

            configOptions.endCursor.rect.origin = CGPoint(
                x: endRect.maxX + configOptions.endCursor.rect.width / 2,
                y: endRect.minY
            )
            configOptions.endCursor.rect.size.height = endRect.height
            configOptions.endCursor.location.point = CGPoint(
                x: configOptions.endCursor.rect.centerX,
                y: configOptions.endCursor.rect.centerY
            )
        }

        selectionModule.setSelectedRects(rects, writingMode: writingMode)
        selectionModule.renderSelectionFromStartToEnd(
            selectionColor: configOptions.visualConfig?.selectionColor ?? UIColor.blue.withAlphaComponent(0.5)
        )

        if let layer = selectionModule.getSelectionLayer() {
            layer.addSublayer(configOptions.startCursor.renderLayer)
            layer.addSublayer(configOptions.endCursor.renderLayer)
            containerView?.layer.addSublayer(layer)
        }
        self.configOptions = configOptions
    }

    func leaveVisualMode() {
        // startCursor、endCursor都可以不用单独移除，selectionModule.enter(mode: .normal)时会移除它们的父layer
        // 这里单独移除的原因是为了节约内存，不一直持有，毕竟selection行为不频繁
        configOptions?.startCursor.renderLayer.removeFromSuperlayer()
        configOptions?.endCursor.renderLayer.removeFromSuperlayer()
        selectionModule.enter(mode: .normal)
        // 这里需要先判断放大镜视图是否创建
        if configOptions?.hasMagnifier ?? false {
            // 访问magnifier属性会导致视图被lazy创建
            configOptions?.magnifier.magnifierView.removeFromSuperview()
            configOptions?.magnifier.targetView = nil
        }
        modeWatcher?.isPaused = true
        modeWatcher?.remove(from: RunLoop.main, forMode: .default)
        modeWatcher = nil

        core.resetGlobalStartEnd()
    }

    @objc
    func copyTextCommand() {
        // 超长富文本折叠时内部没有全部的内容，此时也需要回调，由外部通过数据源决定复制内容
        if isSelectAll() {
            selectionDelegate?.handleCopyByCommand(self, text: nil)
            return
        }
        let copy = getCopyString()
        selectionDelegate?.handleCopyByCommand(self, text: copy)
    }
}
