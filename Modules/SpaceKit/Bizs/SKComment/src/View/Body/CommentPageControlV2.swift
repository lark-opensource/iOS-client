//
//  CommentPageControl.swift
//  CommentPageControl
//
//  Created by bytedance on 2019/1/14.
//  Copyright © 2019 xurunkang. All rights reserved.
//

import UIKit

class CommentPageControlV2: UICollectionView {

    /// 单个page的宽度
    public var singlePageSize: CGSize = CGSize(width: 4, height: CommentPageControlLayoutV2.lengthOfItem)

    /// 每个page之间的padding
    public var pagePadding: CGFloat = CommentPageControlLayoutV2.padding

    /// 组件个数
    public var numberOfPages: Int = 0

    public var maxNormalCount: Int = 5

    /// 正常颜色
    public var normalColor: UIColor = UIColor.ud.fillDisable

    /// 高亮颜色
    public var highlightColor: UIColor = UIColor.ud.bgFloat

    public var currentPageProgress: CGFloat = 0

    /// 当前页面
    public var currentPage: Int = 0

    /// 低于 maxNormalCount 个的时候居中
    private var contentOffsetInMiddle: CGPoint {
        let totalPadding = CGFloat(numberOfPages - 1) * pagePadding
        let totalPageWidth = CGFloat(numberOfPages) * singlePageSize.height
        let totalWidth = totalPadding + totalPageWidth
        let offsetY = (frame.size.height - totalWidth) / -2.0

        return CGPoint(x: contentOffset.x, y: offsetY)
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.delegate = self
        self.dataSource = self
        self.isPagingEnabled = false

        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CommentPageControlCollectionViewCell")

        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func progressHandler(_ currentPage: Int) -> CGFloat {
        guard currentPage >= 0, currentPage < self.numberOfPages else {
            return 0
        }
        var y: CGFloat = 0.0

        let fixNum = 2
        let fixedPreCount: Int = fixNum // 固定前面两个
        let fixedLastCount: Int = self.numberOfPages - fixNum // 固定最后两个

        let singleItemHeight = singlePageSize.height + pagePadding
        if currentPage <= fixedPreCount {
            y = singleItemHeight * CGFloat(fixedPreCount)
        } else if currentPage >= fixedLastCount {
            y = singleItemHeight * CGFloat(fixedLastCount)
        } else {
            y = singleItemHeight * CGFloat(currentPage)
        }
        y -= CGFloat(fixNum) * 2.0 * singleItemHeight
        return y
    }

    /// 设置当前 page 位移的进度
    public func setCurrentPageProgress(_ progress: CGFloat) {
        currentPageProgress = progress
    }

    /// 设置进度条高亮颜色
    public func setHighLightColor(_ index: Int) {

        for cell in visibleCells {
            cell.backgroundColor = normalColor
        }

        let indexPath = IndexPath(row: index, section: 0)
        let cell = cellForItem(at: indexPath)

        cell?.backgroundColor = highlightColor

        currentPage = index
    }

    public func reloadDataWithPage(_ page: Int) {
        reloadData()

        UIView.animate(withDuration: 0, animations: {
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.updatePage(page)
        })
    }

    public func updatePage(_ page: Int) {
        var offset: CGPoint = .zero
        if numberOfPages <= maxNormalCount {
            offset = contentOffsetInMiddle
        } else {
            offset = CGPoint(x: contentOffset.x, y: progressHandler(page))
        }

        self.setContentOffset(offset, animated: true)
        UIView.animate(withDuration: 0, animations: {
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.currentPage = page
            self.setHighLightColor(page)
        })
    }

}

extension CommentPageControlV2: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return singlePageSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return pagePadding
    }
}

extension CommentPageControlV2: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPages
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CommentPageControlCollectionViewCell", for: indexPath)

        var color: UIColor = normalColor

        if indexPath.row == currentPage {
            color = highlightColor
        }

        cell.layer.cornerRadius = 2

        cell.backgroundColor = color

        return cell
    }
}
extension CommentPageControlV2: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}
