//
//  ShortcutsCollectionView+MoveCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 拖拽cell操作
import UIKit
import Foundation
extension ShortcutsCollectionView {

    @objc
    func handleLongPress(ges: UILongPressGestureRecognizer) {
        let pressPoint = ges.location(in: self) // 获取此次点击的坐标，根据坐标获取cell对应的indexPath
        switch ges.state {
        case .began:
            guard let selectIndexPath: IndexPath = self.indexPathForItem(at: pressPoint) else {
                // 当没有点击到cell的时候不进行处理
                return
            }
            self.viewModel.freeze(true)
            if let cell = self.cellForItem(at: selectIndexPath), cell.isKind(of: ShortcutExpandMoreView.self) {
                self.cancelInteractiveMovement() // 取消移动
            } else {
                self.beginInteractiveMovementForItem(at: selectIndexPath)//开始移动
            }
        case .changed:
            var valiadPressPointY = pressPoint.y
            let firstRowCenterY = ShortcutLayout.edgeInset.top + ShortcutLayout.itemHeight / 2
            let lastRowCenterY = self.frame.height - ShortcutLayout.edgeInset.bottom - (ShortcutLayout.itemHeight) / 2

            if !self.viewModel.expanded {
                valiadPressPointY = firstRowCenterY
            } else if valiadPressPointY < firstRowCenterY {
                valiadPressPointY = firstRowCenterY
            } else if valiadPressPointY > lastRowCenterY {
                valiadPressPointY = lastRowCenterY
            }
            // 移动过程中更新位置坐标
            self.updateInteractiveMovementTargetPosition(CGPoint(x: pressPoint.x, y: valiadPressPointY))
        case .ended:
            // 通过显式调用CATransaction.begin, 将move动画包在一次CATransaction里
            // 以此间接的获取collectionView move动画的结束时机
            CATransaction.begin()
            // 设定CATransaction对应的动画操作执行结束后的回调
            CATransaction.setCompletionBlock { [weak self] in
                // 在动画结束后放开queue，处理move中收到的push
                self?.viewModel.freeze(false)
            }
            self.endInteractiveMovement() // 停止移动调用此方法
            CATransaction.commit()
        default:
            self.cancelInteractiveMovement()
            self.viewModel.freeze(false)
        }
    }
}
