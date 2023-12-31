//
//  WebExtensionController.swift
//  Lark
//
//  Created by lichen on 2017/4/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit

/// 更多面板collection view布局
public final class WebExtensionFlowLayout: UICollectionViewFlowLayout {

    var interitemSpacing: CGFloat = 0//如果外部不设置interitemSpacing，内部会以一屏显示完全为原则，尝试自动计算一个interitemSpacing

    private var layoutAttrs: [UICollectionViewLayoutAttributes] = []
    private var contentSizeWidth: CGFloat = 0
    var itemPerLine: Int?

    public override func prepare() {
        super.prepare()
        if let collectionView = self.collectionView {
            let cellCount = collectionView.numberOfItems(inSection: 0)
            guard cellCount > 0 else { return }
            let countPerLine = itemPerLine ?? cellCount
            let lineCount = (cellCount / countPerLine) + (cellCount % countPerLine == 0 ? 0 : 1)
            if lineCount > 1 {
                self.layoutAttrs = getMoreLineCenterLayoutAttrs(cellCount: cellCount, countPerLine: countPerLine)
            } else {
                self.layoutAttrs = getSingleLineLayoutAttrs(cellCount: cellCount)
            }
            if let attr = layoutAttrs.last {
                if lineCount > 1 {
                    contentSizeWidth = self.collectionView?.frame.width ?? 0
                } else {
                    contentSizeWidth = attr.frame.origin.x + attr.frame.size.width + sectionInset.right
                }
            }
        }
    }

    @inline(__always)
    private func getSingleLineLayoutAttrs(cellCount: Int) -> [UICollectionViewLayoutAttributes] {
        var layoutAttrs: [UICollectionViewLayoutAttributes] = []
        for i in 0..<cellCount {
            let indexPath = IndexPath(item: i, section: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            var x = sectionInset.left
            if i > 0 {
                let preAttr = layoutAttrs[i - 1]
                x = preAttr.frame.origin.x + preAttr.frame.size.width + interitemSpacing
            }
            attr.frame = CGRect(x: x, y: sectionInset.top, width: itemSize.width, height: itemSize.height)
            layoutAttrs.append(attr)
        }
        return layoutAttrs
    }

    @inline(__always)
    private func getMoreLineCenterLayoutAttrs(cellCount: Int, countPerLine: Int) -> [UICollectionViewLayoutAttributes] {
        var layoutAttrs: [UICollectionViewLayoutAttributes] = []
        for i in 0..<cellCount {
            let indexPath = IndexPath(item: i, section: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            var x = sectionInset.left
            if i > 0 {
                let preAttr = layoutAttrs[i - 1]
                if i % countPerLine != 0 {
                    x = preAttr.frame.origin.x + preAttr.frame.size.width + interitemSpacing
                }
            }
            let y = CGFloat((i / countPerLine) * 104) + sectionInset.top
            attr.frame = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
            layoutAttrs.append(attr)
        }
        return layoutAttrs
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttrs
    }

    public override var collectionViewContentSize: CGSize {
        if let collectionView = self.collectionView {
            return CGSize(width: contentSizeWidth, height: collectionView.frame.height)
        }

        return CGSize.zero
    }
}
