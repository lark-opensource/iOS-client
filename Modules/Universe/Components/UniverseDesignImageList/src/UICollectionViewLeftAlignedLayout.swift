//
//  UICollectionViewLeftAlignedLayout.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/10/8.
//

import Foundation
import UIKit

class UICollectionViewLeftAlignedLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrsArry = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        for i in 0..<attrsArry.count {
            guard i != attrsArry.count-1 else { continue }
            let curAttr = attrsArry[i] //当前attr
            let nextAttr = attrsArry[i+1]  //下一个attr

            //如果下一个在同一行则调整，不在同一行则跳过
            guard curAttr.frame.minY == nextAttr.frame.minY else { continue }
            guard nextAttr.frame.minX - curAttr.frame.maxX > minimumInteritemSpacing else { continue }

            var frame = nextAttr.frame
            let x = curAttr.frame.maxX + minimumInteritemSpacing
            frame = CGRect(x: x, y: frame.minY, width: frame.width, height: frame.height)
            nextAttr.frame = frame
        }
        return attrsArry
    }
}
