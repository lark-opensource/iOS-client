//
//  WPCommonAppBundle.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2021/12/30.
//

import Foundation
import UIKit

final class WPMovingItemInfo {
    var offset: CGPoint = .zero

    var sourceCell: UICollectionViewCell

    var snapshotImageView: UIView?

    /// 正在被拖拽的 cell 的 indexPath，拖拽过程中 cell 位置交换会导致 currentIndexPath 变化
    var currentIndexPath: IndexPath

    var didCreateSnapshot: Bool = false

    /// 由于icon拖动时会把标题隐藏，所以可见部分的高度是图标部分
    var visibleAreaHeight: CGFloat = 0

    var originTouchPoint: CGPoint

    init(
        offset: CGPoint,
        sourceCell: UICollectionViewCell,
        currentIndexPath: IndexPath,
        originTouchPoint: CGPoint,
        snapshotImageView: UIView?
    ) {
        self.offset = offset
        self.sourceCell = sourceCell
        self.snapshotImageView = snapshotImageView
        self.currentIndexPath = currentIndexPath
        self.originTouchPoint = originTouchPoint
    }
}
