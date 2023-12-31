//
//  CommentPageControl.swift
//  CommentPageControl
//
//  Created by bytedance on 2019/1/14.
//  Copyright © 2019 xurunkang. All rights reserved.
//

import UIKit

class CommentPageControl: UICollectionView {

    /// 单个page的宽度
    public var singlePageSize: CGSize = CGSize(width: 10, height: 2)

    /// 每个page之间的padding
    public var pagePadding: CGFloat = 6

    /// 组件个数
    public var numberOfPages: Int = 0

    public var maxNormalCount: Int = 5

    /// 正常颜色
    public var normalColor: UIColor = UIColor.ud.N300

    /// 高亮颜色
    public var highlightColor: UIColor = UIColor.ud.N900

    public var currentPageProgress: CGFloat = 0

    /// 当前页面
    public var currentPage: Int = 0

    /// 低于 maxNormalCount 个的时候居中
    private var contentOffsetInMiddle: CGPoint {
        let totalPadding = CGFloat(numberOfPages - 1) * pagePadding
        let totalPageWidth = CGFloat(numberOfPages) * singlePageSize.width
        let totalWidth = totalPadding + totalPageWidth
        let offsetX = (frame.size.width - totalWidth) / -2.0

        return CGPoint(x: offsetX, y: contentOffset.y)
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.delegate = self
        self.dataSource = self
        self.isPagingEnabled = false

        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CommentPageControlCollectionViewCell")

        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置 contentOffset.x 的函数
    // 默认实现
    typealias ProgressHandler = (_ x: CGFloat) -> CGFloat
    public var progressHandler: ProgressHandler = { x in

        var y: CGFloat = 0.0

        let fixedCount: CGFloat = 2.0 // 固定前面两个

        if x <= fixedCount * 414.0 {
            y = 16.0 * fixedCount - 64.0
        } else {
            y = ( 16.0 * x ) / 414.0 - 64.0
        }

        return y
    }

    /// 设置进度条的进度
    public func setProgress(_ progress: CGFloat) {

        if numberOfPages <= maxNormalCount {
            updateLayout()
            return
        }

        contentOffset.x = progressHandler(progress)
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

    public func reloadPage() {

        let offset = contentOffset

        reloadData()

        UIView.animate(withDuration: 0, animations: {
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }, completion: { _ in
            if self.numberOfPages > self.maxNormalCount {
                if self.contentOffset != offset {
                    self.setContentOffset(offset, animated: false)
                }
            } else {
                self.updateLayout()
            }

            self.setHighLightColor(self.currentPage)
        })
    }

    /*
    /// 插入 page
    public func insertPage(beforeCurrentIndex: Bool) {

        numberOfPages += 1

        if beforeCurrentIndex {
            currentPage += 1
        }

        let offset = contentOffset

        performBatchUpdates({
            if beforeCurrentIndex {
                insertItems(at: [IndexPath(row: 0, section: 0)])
            } else {
                insertItems(at: [IndexPath(row: numberOfPages - 1, section: 0)])
            }
        }, completion: { _ in
            self.setContentOffset(offset, animated: false)
            self.setHighLightColor(self.currentPage)
            self.updateLayout()
        })
    }

    /// 删除 page
    public func deletePage(beforeCurrentIndex: Bool) {
        numberOfPages -= 1

        if beforeCurrentIndex && currentPage > 0 {
            currentPage -= 1
        }

        let offset = contentOffset

        performBatchUpdates({
            if beforeCurrentIndex {
                deleteItems(at: [IndexPath(row: 0, section: 0)])
            } else {
                deleteItems(at: [IndexPath(row: numberOfPages - 1, section: 0)])
            }
        }, completion: { _ in
            self.setContentOffset(offset, animated: false)
            self.setHighLightColor(self.currentPage)
            self.updateLayout()
        })
    }
     */
}

extension CommentPageControl: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return singlePageSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return pagePadding
    }
}

extension CommentPageControl: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPages
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CommentPageControlCollectionViewCell", for: indexPath)

        var color: UIColor = normalColor

        if indexPath.row == currentPage {
            color = highlightColor
        }

        cell.layer.cornerRadius = 1

        cell.backgroundColor = color

        return cell
    }
}

// PRIVATE METHOD
extension CommentPageControl {
    private func updateLayout() {
        if numberOfPages <= maxNormalCount {
            contentOffset = contentOffsetInMiddle
        }
    }
}
