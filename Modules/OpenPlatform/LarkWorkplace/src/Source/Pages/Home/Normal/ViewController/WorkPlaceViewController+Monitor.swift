//
//  WorkPlaceViewController+Monitor.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/6/21.
//

import Foundation

extension WorkPlaceViewController: UIScrollViewDelegate {
    /// 用户手指离开屏幕，scrollView 继续滚动的情况
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didStopScrolling(scrollView: scrollView)
    }

    /// 用户手指离开屏幕，scrollView 停止滚动的情况
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        didStopScrolling(scrollView: scrollView)
    }

    /// ScrollView 停止滚动，上报产品埋点
    func didStopScrolling(scrollView: UIScrollView) {
        guard let collectionView = scrollView as? WorkPlaceCollectionView else { return }
        reportBlockExpose(collectionView: collectionView)
    }

    /// 上报 Block 曝光产品埋点，由小于 70% 到大于 >70% 曝光
    func reportBlockExpose(collectionView: WorkPlaceCollectionView) {
        let tabbarHeight: CGFloat = 65
        let exposeRatio = 0.7

        let visibleCellArray = collectionView.visibleCells
        let shouldExposeCellArray: [WorkPlaceCellExposeProtocol] = visibleCellArray.compactMap { cell in
            let containerFrame = CGRect(x: collectionView.frame.origin.x,
                                        y: collectionView.frame.origin.y,
                                        width: collectionView.frame.size.width,
                                        height: collectionView.frame.size.height - tabbarHeight)
            let cellFrame = view.convert(cell.frame, from: collectionView)
            let interRect = cellFrame.intersection(containerFrame)
            if let cell = cell as? WorkPlaceCellExposeProtocol,
               cellFrame.height != 0,
               interRect.height / cellFrame.height > exposeRatio {
                return cell
            }
            return nil
        }

        shouldExposeCellArray.forEach { cell in
            let exposeId = cell.exposeId
            guard !exposeId.isEmpty, !(blockExposeState[exposeId] ?? false) else {
                return
            }
            blockExposeState[exposeId] = true
            cell.didExpose()
        }
    }

    /// 重置曝光 Block 字典
    func resetExposeBlockMap(with viewModel: WorkPlaceViewModel?) {
        blockExposeState = [:]
        viewModel?.sectionsList.forEach({ section in
            let items = section.getDisplayItems()
            items.forEach { item in
                guard item.itemType == .block, let itemId = item.getItemId() else { return }
                blockExposeState[itemId] = false
            }
        })
    }
}
