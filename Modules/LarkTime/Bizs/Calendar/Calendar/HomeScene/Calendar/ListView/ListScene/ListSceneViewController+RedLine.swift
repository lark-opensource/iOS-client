//
//  ListSceneViewController+RedLine.swift
//  Calendar
//
//  Created by huoyunjie on 2022/8/17.
//

import UIKit
import Foundation
import RxSwift
import CalendarFoundation

// MARK: RedLine

extension ListSceneViewController {

    func bindRedLine() {
        localRefreshService?.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.updateRedline()
            })
            .disposed(by: disposeBag)
    }

    private func clearRedLine() {
        self.redLine.removeFromSuperview()
    }

    func updateRedline() {
        guard let position = self.redlinePosition() else {
            self.redLine.redlinePosition = nil
            self.clearRedLine()
            return
        }
        self.redLine.redlinePosition = position
        self.updateRedlinePosition(redline: self.redLine,
                                   position: position,
                                   tableView: self.tableView)
    }

    func redlinePosition() -> RedlinePositionInfo? {
        let currentTime = Date()
        let dayEnd = currentTime.dayEnd()
        var result: RedlinePositionInfo?
        var redPostionStartDate: Date?
        var firstIndexOfToday: Int?
        let cellItems = self.cellItems
        for i in 0..<cellItems.count {
            guard let item = cellItems[safeIndex: i] else {
                assertionFailure("cellItems error \(i)")
                continue
            }
            guard item.isEvent() else { continue }
            guard item.date.isInSameDay(currentTime) else { continue }
            if item.date > dayEnd { break }
            if firstIndexOfToday == nil {
                firstIndexOfToday = i
            }

            guard let content = item.event?.content else {// 今天为空的cell
                return RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                           isUpSide: false,
                                           isFirst: true,
                                           isEvent: false)
            }

            if content.isAllDay {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: false,
                                             isFirst: i == firstIndexOfToday,
                                             isEvent: true)
            } else if currentTime >= content.endDate {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: false,
                                             isFirst: i == firstIndexOfToday,
                                             isEvent: true)
                redPostionStartDate = nil
            } else if currentTime >= content.startDate {
                if redPostionStartDate != content.startDate {
                    result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                                 isUpSide: true,
                                                 isFirst: i == firstIndexOfToday,
                                                 isEvent: true)
                    redPostionStartDate = content.startDate
                }
            } else if result == nil {
                result = RedlinePositionInfo(indexPath: IndexPath(row: i, section: 0),
                                             isUpSide: true,
                                             isFirst: i == firstIndexOfToday,
                                             isEvent: true)
            }
        }
        return result
    }

    private func updateRedlinePosition(redline: EventListRedLine,
                                       position: RedlinePositionInfo,
                                       tableView: UITableView) {
        let cellItems = self.cellItems
        guard let item = cellItems[safeIndex: position.indexPath.row] else {
            assertionFailure("cellItem error \(cellItems.count) \(position.indexPath.row)")
            return
        }
        let spaceBetweenEventCell: CGFloat = 10.0
        let cellRect = tableView.rectForRow(at: position.indexPath)
        var eventRect: CGRect = .zero

        if item.cellIdentifer == ListCell.identifier {
            eventRect = ListCell.eventViewFrame()
        } else if item.cellIdentifer == ListSubCell.identifier {
            eventRect = ListSubCell.eventViewFrame()
        } else {
            assertionFailureLog("red line should only around event cell")
        }
        if eventRect != .zero {
            var y: CGFloat = 0.0
            if position.isUpSide {
                y = cellRect.origin.y + eventRect.origin.y - (spaceBetweenEventCell / 2.0)
            } else {
                y = cellRect.origin.y + eventRect.origin.y
                    + eventRect.size.height + (spaceBetweenEventCell / 2.0)
            }
            redline.updateOriginY(y - redline.bounds.size.height / 2.0, tableView: tableView)
        } else {
            redline.removeFromSuperview()
        }
    }
}
