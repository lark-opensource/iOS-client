//
//  ArrangementIntervalCoodinator.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/10.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift

final class ArrangementIntervalCoodinator: IntervalCoodinator {
    var timeChanged: ((Date, Date) -> Void)?
    var intervalStateChanged: ((_ isHidden: Bool) -> Void)?

    let intervalIndicator: IntervalIndicator
    let timeIndicator: TimeIndicator
    var startTime: Date
    var endTime: Date
    // 暂时取375作为屏幕宽度
    let width: CGFloat = 375
    lazy var containerWidth: CGFloat = width - timeIndicator.bounds.width
    init(startTime: Date, endTime: Date, is12HourStyle: Bool) {
        intervalIndicator = IntervalIndicator(minHeight: 25,
                                              draggable: false,
                                              borderType: .dottedLine)
        timeIndicator = TimeIndicator(frame: CGRect(x: 0, y: 0,
                                                    width: 0,
                                                    height: Style.wholeDayHeight),
                                      is12HourStyle: is12HourStyle)
        self.startTime = startTime
        self.endTime = endTime
        let frame = getTimeRangFrame(startTime: startTime, endTime: endTime, containerWidth: containerWidth)
        self.intervalIndicator.frame = frame
    }

    func changeTime(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        showStartEndTime(startTime: startTime, endTime: endTime)
        timeChanged?(startTime, endTime)
    }

    func changeFrameBy(point: CGPoint,
                       maxY: CGFloat,
                       animated: Bool,
                       completion: @escaping ((CGRect) -> Void)) {
        let frame = frameInHalfHourGrid(by: point,
                                        minute: endTime.minutesSince(date: startTime),
                                        maxY: maxY,
                                        containerWidth: containerWidth)
        setIntervalIndicatorFrame(frame, animated: animated, completion: completion)
    }

    func setIntervalIndicatorFrame(_ originFrame: CGRect,
                                   animated: Bool = false,
                                   completion: @escaping ((CGRect) -> Void)) {
        let (startTime, endTime) = getTimeBy(frame: originFrame)
        let frame = getTimeRangFrame(startTime: startTime, endTime: endTime, containerWidth: containerWidth)
        if animated && !isHidden() {
            UIView.animate(withDuration: 0.15, animations: {
                self.intervalIndicator.frame = frame
            }) { _ in
                self.changeTime(startTime: startTime, endTime: endTime)
                completion(frame)
            }
        } else {
            intervalIndicator.frame = frame
            self.changeTime(startTime: startTime, endTime: endTime)
            completion(frame)
        }
    }

}
