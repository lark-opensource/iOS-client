//
//  LKSelectionLable+Interaction.swift
//  RichLabel
//
//  Created by 李晨 on 2021/2/25.
//

import UIKit
import Foundation

extension LKSelectionLabel: UIPointerInteractionDelegate {
    func setupPointerInteraction() {
        if #available(iOS 13.4, *) {
            let pointer = UIPointerInteraction(delegate: self)
            self.addInteraction(pointer)
        }
    }

    @available(iOS 13.4, *)
    public func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        // 在拖拽过程中，返回当前区域
        if isInDragMode {
            return defaultRegion
        }

        // 不在textRect中，返回圆形光标
        if !self.render.textRect.contains(request.location) {
            return nil
        }

        // 在attachmentFrames（包含attachment和AT）中，返回圆形光标
        for item in self.render.attachmentFrames {
            if item.contains(request.location) {
                return nil
            }
        }

        // 根据在文字中的位置判断
        let pointAt = self.attributedIndex(at: request.location)
        switch pointAt {
        // 不在文字上，返回当前区域
        case .notInText, .outOfRangeText:
            return defaultRegion
        // 在文字上
        case .inText(let index):
            // 如果处于可点击位置上，直接返回nil为圆形光标
            var i = self.indexAtTapableText(at: index.nearist)
            if i != kCFNotFound { return defaultRegion }
            i = self.indexAtTapableText(at: index.other)
            if i != kCFNotFound { return defaultRegion }
            if (getTmpActiveLink(index.nearist) ?? getTmpActiveLink(index.other)) != nil {
                return nil
            }
        }

        // 返回当前区域
        return defaultRegion
    }

    @available(iOS 13.4, *)
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        if !pointerInteractionEnable {
            return nil
        }
        return UIPointerStyle(shape: .verticalBeam(length: 20))
    }
}

extension LKSelectionLabel: UIDragInteractionDelegate {

    func setupDragInteraction() {
        let dragInteraction = UIDragInteraction(delegate: self)
        self.addInteraction(dragInteraction)
    }

    public func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard self.inSelectionMode,
              let view = interaction.view,
              let text = self.selectedText(),
              let path = self.selectedBezierPath() else {
            return []
        }
        let location = session.location(in: view)
        if path.contains(location) &&
            !startCursor.hitTest(location) &&
            !endCursor.hitTest(location) {
            let itemProvider = NSItemProvider(object: text as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            return [dragItem]
        }
        return []
    }

    public func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        guard let view = interaction.view,
              let window = interaction.view?.superview,
              let selectedBezierPath = self.selectedBezierPath() else {
            return nil
        }
        if #available(iOS 13.0, *) {
            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            let imageView = UIImageView(frame: view.bounds)
            imageView.image = image
            let parameters = UIPreviewParameters()
            parameters.visiblePath = selectedBezierPath
            let bounds = selectedBezierPath.bounds
            let center: CGPoint = view.convert(CGPoint(x: bounds.midX, y: bounds.midY), to: window)
            let target = UIPreviewTarget(container: window, center: center)
            return UITargetedDragPreview(view: imageView, parameters: parameters, target: target)
        } else {
            return nil
        }
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        self.selectionDelegate?.selectionLabelBeginDragInteraction(label: self)
    }
}
