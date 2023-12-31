//
//  BitableMultiListController+DataSource.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/30.
//

import Foundation


//MARK: dataSource
extension BitableMultiListController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        homeUI.numberOfSections
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        homeUI.numberOfItems(in: section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = homeUI.cell(for: indexPath, collectionView: collectionView)
        if let slideableCell = cell as? SlideableCell {
            slideableCell.enableSimultaneousGesture = self.enableSimultaneousGesture
            if self.enableSimultaneousGesture {
                slideableCell.simultaneousDelegate = self
            }
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        homeUI.supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
    }
}

//MARK: UICollectionViewDelegate
extension BitableMultiListController: UICollectionViewDelegate {
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        homeUI.contextMenuConfig(for: indexPath, sceneSourceID: self.currentSceneID(), collectionView: collectionView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        homeUI.didSelectItem(at: indexPath, collectionView: collectionView)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        homeUI.didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }

    public func forceScrollToTop() {
        scrollToTop()
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if homeUI.headerSection != nil {
            // 有 header 时，滚动到顶部的偏移量需要调整一下
            scrollToTop()
            return false
        } else {
            return true
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerSection = homeUI.headerSection else {
            return
        }
        let headerHeight = headerSection.headerViewHeight
        if scrollView.contentOffset.y < -headerHeight {
            return // 下拉刷新区间
        } else if scrollView.contentOffset.y < 0 {
            scrollView.contentInset.top = -scrollView.contentOffset.y
        } else {
            scrollView.contentInset.top = 0
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        homeUI.notifyDidEndDragging(willDecelerate: decelerate)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        homeUI.notifyDidEndDecelerating()
    }
    
    private func scrollToTop() {
        // 防止在手动刷新与推送的主动刷新事件冲突，导致刷新UI异常
        if refreshing { return }
        if let headerHeight = homeUI.headerSection?.headerViewHeight {
            collectionView.setContentOffset(CGPoint(x: 0, y: -headerHeight), animated: true)
        } else {
            collectionView.setContentOffset(.zero, animated: true)
        }
    }
}

//MARK: 拖动
extension BitableMultiListController: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        homeUI.dragItem(for: indexPath, sceneSourceID: self.currentSceneID(), collectionView: collectionView)
    }

    public func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let params = UIDragPreviewParameters()
        params.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 12)
        return params
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        self.collectionView.isScrollEnabled = true
    }
}

//MARK: layout
extension BitableMultiListController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if currentShowStyle == .embeded {
            let width = collectionViewConfig?.widthForEmbededStyle ?? collectionView.bounds.size.width
            return homeUI.itemSize(at: indexPath, containerWidth: width)
        } else if currentShowStyle == .fullScreen {
            let width = collectionViewConfig?.widthForFullScreenStyle ?? collectionView.bounds.size.width
            return homeUI.itemSize(at: indexPath, containerWidth: width)
        } else {
           return homeUI.itemSize(at: indexPath, containerWidth: collectionView.bounds.size.width)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        homeUI.insets(for: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        homeUI.minimumLineSpacing(at: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        homeUI.minimumInteritemSpacing(at: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height = homeUI.headerHeight(in: section, containerWidth: collectionView.frame.width)
        return CGSize(width: 0, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let height = homeUI.footerHeight(in: section, containerWidth: collectionView.frame.width)
        return CGSize(width: 0, height: height)
    }
}
