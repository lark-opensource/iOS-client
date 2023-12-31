//
//  AnimateCollectionView.swift
//  SKBrowser
//
//  Created by zoujie on 2020/12/6.
//  

import SKFoundation
import SKCommon

class SKDocsToolbarCollectionViewLayout: UICollectionViewFlowLayout {

    ///动画类型
    enum AnimationType {
        case fold //收起
        case unfold //展开
    }

    /// 需要刷新的时候indexPath
    private var reloadIndexPathArr = [IndexPath]()
    /// 删除的indexPath集合
    private var deleteIndexPathArr = [IndexPath]()
    /// 插入的indexPath集合
    private var insertIndexPathArr = [IndexPath]()
    ///需要插入的工具栏二级菜单对应的一级父菜单的Index
    public var insertParentIndexMap = [Int: Int]()
    ///需要删除的工具栏二级菜单对应的一级父菜单的Index
    public var deleteParentIndexMap = [Int: Int]()
    ///菜单的frame
    public var cellsFrame: [CGRect]?
    ///动画结束后新菜单项的frame
    public var newCellsFrame: [CGRect]?
    ///菜单动画类型
    public var animationType: AnimationType = .fold
    ///需要插入的菜单的x坐标
    public var firstInsertChildX: [Int: CGFloat] = [:]
    ///需要删除的菜单的x坐标
    public var firstDeleteChildX: [Int: CGFloat] = [:]
    ///新数据item index到旧数据item index的映射
    public var newIndexMapOld: [Int: Int] = [:]
    ///滚动的距离
    public var offsetX: CGFloat = 0

    func currentFrameWithIndexPath(_ index: Int) -> CGRect? {
        guard let frames = cellsFrame, index < frames.count, index >= 0 else { return nil }
        return frames[index]
    }

    // MARK: animation method
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        //数组重置
        self.reloadIndexPathArr.removeAll()
        self.deleteIndexPathArr.removeAll()
        self.insertIndexPathArr.removeAll()

        //保存更新的indexPath
        for item in updateItems {
            switch item.updateAction {
            case .insert:
                guard let indexPath = item.indexPathAfterUpdate else { return }
                self.insertIndexPathArr.append(indexPath)
            case .delete:
                guard let indexPath = item.indexPathBeforeUpdate else { return }
                self.deleteIndexPathArr.append(indexPath)
            default :
                break
            }
        }
        DocsLogger.info("iPad tool bar collectionview insertIndexPathArr:\(insertIndexPathArr)")
    }

    //刚出现时最初的布局属性，插入动画的初始状态
    //itemIndexPath为旧数据源
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        //此处需要用到copy，否则属性变量一次变化之后，会被保存，然后会出现移动那个动画
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        switch animationType {
        case .fold:
            if self.insertIndexPathArr.contains(itemIndexPath) {
                let parentIndex = insertParentIndexMap[itemIndexPath.row] ?? itemIndexPath.row
                guard var frame = self.currentFrameWithIndexPath(parentIndex) else { return attributes }
                frame.origin.y = 0
//                frame.origin.x -= offsetX
                if let x = firstInsertChildX[itemIndexPath.row] {
                    frame.origin.x = x
                }
                attributes?.frame = frame
                attributes?.alpha = 0.0
                DocsLogger.info("iPad tool bar fold collectionview insert for appering index:\(itemIndexPath.row) frame:\(frame)")
                return attributes
            }
        case .unfold:
            if self.insertIndexPathArr.contains(itemIndexPath) {
                let parentIndex = insertParentIndexMap[itemIndexPath.row] ?? itemIndexPath.row - 1
                guard var frame = self.currentFrameWithIndexPath(parentIndex) else { return attributes }
                DocsLogger.info("iPad tool bar unfold collectionview insert for appering index:\(itemIndexPath.row) frame:\(frame)")
                frame.origin.y = 0
//                frame.origin.x -= offsetX
                if insertParentIndexMap[itemIndexPath.row] != nil {
                    var width = frame.size.width
                    if frame.size.width == DocsMainToolBarV2.Const.separateWidth {
                        width += (DocsMainToolBarV2.Const.itemWidth - DocsMainToolBarV2.Const.imageWidth) / 2
                    }
                    frame.origin.x += width
                }
                attributes?.frame = frame
                attributes?.alpha = 0.0
                return attributes
            }
        }
        guard let oldIndex = newIndexMapOld[itemIndexPath.row],
              var frame = self.currentFrameWithIndexPath(oldIndex) else { return attributes }
        frame.origin.y = 0
        attributes?.frame = frame

        DocsLogger.info("iPad tool bar fold collectionview insert for appering index:\(itemIndexPath.row) attributes:\(attributes?.frame)")
        return attributes
    }

    //消失时最终的布局属性，删除动画的终止状态
    //itemIndexPath为旧数据源
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        if self.deleteIndexPathArr.contains(itemIndexPath) {
            guard var frame = self.currentFrameWithIndexPath(itemIndexPath.row) else { return attributes }
            DocsLogger.info("iPad tool bar collectionview delete for appering index:\(itemIndexPath.row) frame:\(frame)")
            //frame.origin.x -= offsetX
            frame.origin.y = 0
            if let x = firstDeleteChildX[itemIndexPath.row] {
                frame.origin.x = x
            } else {
                let parentIndex = deleteParentIndexMap[itemIndexPath.row] ?? itemIndexPath.row - 1
                guard let targetFrame = self.currentFrameWithIndexPath(parentIndex) else { return attributes }
                frame.origin.x = targetFrame.origin.x
            }
            attributes?.frame = frame
            attributes?.alpha = 0.0
            return attributes
        }

        guard var frame = self.currentFrameWithIndexPath(itemIndexPath.row) else { return attributes }
        frame.origin.y = 0
        attributes?.frame = frame
        DocsLogger.info("iPad tool bar fold collectionview delete for appering index:\(itemIndexPath.row) attributes:\(attributes?.frame)")
        return attributes
    }
}
