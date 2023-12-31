//
//  FreebusyIntervalCoodinator.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/10.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift

final class FreebusyIntervalCoodinator: IntervalCoodinator {
    var timeChanged: ((Date, Date) -> Void)?
    var getTimeZone: (() -> TimeZone)?

    private let disposeBag = DisposeBag()
    let intervalIndicator: IntervalIndicator
    var startTime: Date
    var endTime: Date
    let timeIndicator: TimeIndicator
    var addNewEvent: ((_ startTime: Date, _ endTime: Date) -> Void)? {
        didSet {
            intervalIndicator.clicked = { [weak self] in
                guard let `self` = self else { return }
                self.addNewEvent?(self.startTime, self.endTime)
            }
        }
    }
    var intervalStateChanged: ((_ isHidden: Bool) -> Void)?

    private let getNewEventMinute: () -> Int
    // 暂时取375作为屏幕宽度
    let width: CGFloat = 375
    lazy var containerWidth: CGFloat = width - timeIndicator.bounds.width
    init(startTime: Date,
         title: String,
         isHiddenPushlish: PublishSubject<Bool>,
         getNewEventMinute: @escaping () -> Int,
         is12HourStyle: Bool) {
        self.startTime = startTime
        self.endTime = (startTime + getNewEventMinute().minute)!
        self.getNewEventMinute = getNewEventMinute
        self.timeIndicator = TimeIndicator(frame: CGRect(x: 0, y: 0,
                                                        width: 0,
                                                        height: Style.wholeDayHeight),
                                           is12HourStyle: is12HourStyle)
        self.intervalIndicator = IntervalIndicator(
            minHeight: 25,
            title: title,
            draggable: true,
            borderType: .solidLine
        )
        let frame = getTimeRangFrame(startTime: startTime, endTime: endTime, containerWidth: containerWidth)
        intervalIndicator.frame = frame
        setIntervalIsHidden(true)

        isHiddenPushlish.subscribe(onNext: { [weak self] (isHidden) in
            self?.setIntervalIsHidden(isHidden)
        }).disposed(by: disposeBag)
    }

    func changeTime(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        if !isHidden() {
            showStartEndTime(startTime: startTime, endTime: endTime)
        }
        timeChanged?(startTime, endTime)
    }

    func changeFrameBy(point: CGPoint,
                       maxY: CGFloat,
                       animated: Bool,
                       completion: @escaping ((CGRect) -> Void)) {
        let frame = frameInHalfHourGrid(by: point,
                                        minute: self.getNewEventMinute(),
                                        maxY: maxY,
                                        containerWidth: containerWidth)
        setIntervalIndicatorFrame(frame, animated: animated, completion: completion)
    }

    func setIntervalIndicatorFrame(_ originFrame: CGRect,
                                   animated: Bool = false,
                                   completion: ((CGRect) -> Void)) {
        let (startTime, endTime) = getTimeBy(frame: originFrame)
        self.changeTime(startTime: startTime, endTime: endTime)
        let frame = getTimeRangFrame(startTime: startTime, endTime: endTime, containerWidth: containerWidth)
        intervalIndicator.frame = frame

        let isHidden = self.isHidden()
        setIntervalIsHidden(!isHidden)
        if isHidden {
            showStartEndTime(frame)
            completion(frame)
            return
        }
    }

    private func setIntervalIsHidden(_ isHidden: Bool) {
        if intervalIndicator.isHidden == isHidden {
            return
        }
        intervalIndicator.isHidden = isHidden
        if isHidden {
            /// 如果隐藏了 要把侧边时间轴的联动关闭
            showStartEndTime(nil)
            /// 如果隐藏了 把开始结束时间置等  这样不会计算忙闲冲突
            changeTime(startTime: getTodayTime(), endTime: getTodayTime())
        }
        intervalStateChanged?(isHidden)
    }

    /// 换成当前时间的小时和分钟
    private func getTodayTime() -> Date {
        let now = Date()
        return calibrationDate(date: startTime.changed(hour: now.hour, minute: now.minute) ?? startTime)
    }

    /// bugfix: https://meego.feishu.cn/larksuite/issue/detail/8361965?parentUrl=%2Fworkbench&tab=todo
    /// 忙闲页时间在时区间的转换逻辑混乱，改一处会动全身，这里打补丁修复，弥补时差问题；后续重构彻底处理
    private func calibrationDate(date: Date) -> Date {
        // 这里的date是设备时区的date，需要转成年月日时分秒后再转成设置时区的date
        guard let getTimeZone = getTimeZone,
              TimeZone.current.identifier != getTimeZone().identifier else {
            return date
        }
        return TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: getTimeZone().identifier, destTzId: TimeZone.current.identifier)
    }

}
