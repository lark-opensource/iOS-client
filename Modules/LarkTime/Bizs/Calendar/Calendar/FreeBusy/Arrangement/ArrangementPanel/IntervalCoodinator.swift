//
//  IntervalControl.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/9.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift

protocol IntervalCoodinator {
    var startTime: Date { get set }
    var endTime: Date { get set }
    var intervalIndicator: IntervalIndicator { get }
    var timeIndicator: TimeIndicator { get }
    var containerWidth: CGFloat { get set }

    var timeChanged: ((_ startTime: Date, _ endTime: Date) -> Void)? { get set }
    var intervalStateChanged: ((_ isHidden: Bool) -> Void)? { get set }
    func changeTime(startTime: Date, endTime: Date)
    func changeFrameBy(point: CGPoint,
                       maxY: CGFloat,
                       animated: Bool,
                       completion: @escaping ((CGRect) -> Void))
}

extension IntervalCoodinator {

    typealias Style = ArrangementPanel.Style

    func isHidden() -> Bool {
        return intervalIndicator.isHidden
    }

    /// 拖拽
    mutating func setStartEndTimeBy(_ frame: CGRect, isMoveEnd: Bool, containerWidth: CGFloat) {
        let (startTime, endTime) = getTimeBy(frame: frame)
        changeTime(startTime: startTime, endTime: endTime)
        if isMoveEnd {
            let frame = getTimeRangFrame(startTime: startTime, endTime: endTime, containerWidth: containerWidth)
            intervalIndicator.frame = frame
        }
    }

    func getTimeRangFrame(startTime: Date, endTime: Date, containerWidth: CGFloat) -> CGRect {
        let oneHourMinute: CGFloat = 60.0
        let startMinuteInDay = startTime.minute + startTime.hour * Int(oneHourMinute)
        let originY = CGFloat(startMinuteInDay) * Style.hourGridHeight / oneHourMinute
        let diffMinute = endTime.minutesSince(date: startTime)
        let height = CGFloat(diffMinute) * Style.hourGridHeight / oneHourMinute
        return CGRect(x: 0, y: originY, width: containerWidth, height: height)
    }

    func showStartEndTime(_ changedFrame: CGRect?) {
        guard let changedFrame = changedFrame else {
            timeIndicator.showStartEndTime(nil)
            return
        }
        let (startTime, endTime) = getTimeBy(frame: changedFrame)
        showStartEndTime(startTime: startTime, endTime: endTime)
    }

    func showStartEndTime(startTime: Date, endTime: Date) {
        timeIndicator.showStartEndTime((startTime, endTime))
    }

    func getTimeBy(frame: CGRect) -> (Date, Date) {
        let totalHeight = Style.hourGridHeight * 24
        let minY = max(frame.minY, 0)
        let startTime = dateWithYOffset(minY,
                                        startTime: self.startTime,
                                        totalHeight: totalHeight,
                                        topIgnoreHeight: 0,
                                        bottomIgnoreHeight: 0)
        let maxY = min(frame.maxY, totalHeight)
        let endTime = dateWithYOffset(maxY,
                                      startTime: self.startTime,
                                      totalHeight: totalHeight,
                                      topIgnoreHeight: 0,
                                      bottomIgnoreHeight: 0)
        let startNor = normorlizeDate(startTime, minEventChangeMinutes: 15)
        let endNor = normorlizeDate(endTime, minEventChangeMinutes: 15)
        return (startNor, endNor)
    }

    func frameInHalfHourGrid(by point: CGPoint, minute: Int, maxY: CGFloat, containerWidth: CGFloat) -> CGRect {
        let gridIndexY = Int(point.y) / Int(Style.hourGridHeight)

        /// 偏移半小时 只能是 整点或半点
        let offset = (point.y - CGFloat(gridIndexY) * Style.hourGridHeight) < Style.hourGridHeight / 2 ? 0 : Style.hourGridHeight / 2
        var originY = CGFloat(gridIndexY) * Style.hourGridHeight + offset

        let oneHourMinute: CGFloat = 60.0
        let height = Style.hourGridHeight * CGFloat(minute) / oneHourMinute
        if originY + height > maxY {
            originY = maxY - height
        }

        let frame = CGRect(
            x: 0,
            y: originY,
            width: containerWidth,
            height: height)
        return frame
    }
}
