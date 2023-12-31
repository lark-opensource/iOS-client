//
//  ListSceneViewController+LeftScrollView.swift
//  Calendar
//
//  Created by huoyunjie on 2022/8/17.
//

import UIKit
import Foundation

// MARK: Left Scroll View

extension ListSceneViewController {

    func updateHeadersLocations(isReload: Bool = false) {
        if isReload {
            for (date, view) in dateViewDic {
                view.removeFromSuperview()
                dateViewDic[date] = nil
            }
        }
        let headerSize = CGSize(width: 57, height: 17 + 31)
        let rectDic = generateRectDic()

        var needRemovedViewList = dateViewDic

        let alternateCalendar = self.viewModel.rxViewSetting.value.alternateCalendar ?? self.viewModel.rxViewSetting.value.defaultAlternateCalendar

        // 第二步: 针对各个“section“作出处理
        for (date, value) in rectDic {
            var height = value.maxY - value.minY
            if height > 0 {
                height -= 23
            }
            let fakeSectionRect = CGRect(x: 0, y: value.minY + 23, width: tableView.bounds.width, height: height)
            let rect = tableView.convert(fakeSectionRect, to: tableView.superview)
            let viewFrame = getViewFrame(headerSize: headerSize, rect: rect)

            var view = dateViewDic[date]
            needRemovedViewList[date] = nil
            if viewFrame.maxY <= tableView.frame.minY || viewFrame.minY >= tableView.frame.maxY {
                if view != nil {
                    view?.removeFromSuperview()
                    dateViewDic[date] = nil
                }
            } else if view == nil {
                let newView = EventListDateView(item: value.firstItem, alternateCalendar: alternateCalendar)
                tableView.superview?.addSubview(newView)
                dateViewDic[date] = newView
                view = newView
            }
            view?.frame = viewFrame
        }

        // 第三步: 清理没用的view
        for (date, view) in needRemovedViewList {
            view.removeFromSuperview()
            dateViewDic[date] = nil
        }
    }

    private func getViewFrame(headerSize: CGSize, rect: CGRect) -> CGRect {
        var viewFrame = CGRect.zero
        viewFrame.size = headerSize
        viewFrame.origin.x = 0

        let tableViewTop = tableView.frame.minY + 6

        if rect.minY >= tableViewTop {
            viewFrame.origin.y = rect.origin.y
        } else if rect.maxY >= tableViewTop {
            viewFrame.origin.y = tableViewTop
        } else if rect.maxY < tableViewTop {
            viewFrame.origin.y = rect.maxY
        }

        return viewFrame
    }

    func generateRectDic() -> [Date: EventListDateViewLocationInfo] {
        let cellItems = self.cellItems
        var rectDic: [Date: EventListDateViewLocationInfo] = [:]
        // 第一步：得到各个“section”的区间范围以及日期。
        let indexs = tableView.indexPathsForVisibleRows
        var minIndex = indexs?.first?.row ?? 10
        var maxIndex = indexs?.last?.row ?? cellItems.count - 11
        minIndex -= 10
        maxIndex += 10
        minIndex = max(minIndex, 0)
        maxIndex = min(maxIndex, cellItems.count)
        minIndex = min(minIndex, maxIndex) // 防止滑动过快导致outofrange
        for i in minIndex..<maxIndex {
            guard let content = cellItems[safeIndex: i] else {
                assertionFailure("cellItems error \(i)")
                continue
            }
            if content.isSeparator() {
                continue
            }
            let date = content.dateStart
            let cellRectTop = tableView.rectForRow(at: IndexPath(row: i, section: 0)).minY
            if var rect = rectDic[date] {
                if rect.minY > cellRectTop {
                    rect.minY = cellRectTop
                }
                if rect.maxY < cellRectTop {
                    rect.maxY = cellRectTop
                }
                rectDic[date] = rect
            } else if let event = content.event {
                rectDic[date] = EventListDateViewLocationInfo(minY: cellRectTop, maxY: cellRectTop, firstItem: event)
            }
        }
        return rectDic
    }
}
