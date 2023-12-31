//
//  PhotoScrollPickerCollectionLayout.swift
//  LarkUIKit
//
//  Created by zc09v on 2018/7/4.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation

final class PhotoScrollPickerCollectionLayout: UICollectionViewFlowLayout {
    var imageSizeCache: [CGSize]

    private var layoutAttrs: [UICollectionViewLayoutAttributes] = []
    private var contentSizeWidth: CGFloat = 0

    init(itemCount: Int) {
        imageSizeCache = [CGSize](repeating: .zero, count: itemCount)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        layoutAttrs = []
        if let collectionView = self.collectionView {
            let cellCount = collectionView.numberOfItems(inSection: 0)
            for i in 0..<cellCount {
                let indexPath = IndexPath(item: i, section: 0)
                let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                let itemSize = imageSizeCache[i]
                var x = sectionInset.left
                if i > 0 {
                    let preAttr = layoutAttrs[i - 1]
                    x = preAttr.frame.origin.x + preAttr.frame.size.width + 3
                }
                attr.frame = CGRect(x: x, y: sectionInset.top, width: itemSize.width, height: itemSize.height)
                layoutAttrs.append(attr)
            }
        }
        if let attr = layoutAttrs.last {
            contentSizeWidth = attr.frame.origin.x + attr.frame.size.width + sectionInset.right
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttrs
    }

    override var collectionViewContentSize: CGSize {
        if let collectionView = self.collectionView {
            return CGSize(width: contentSizeWidth, height: collectionView.frame.height)
        }
        return CGSize.zero
    }
}
