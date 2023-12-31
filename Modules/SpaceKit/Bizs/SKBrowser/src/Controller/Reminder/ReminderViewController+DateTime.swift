//
// Created by duanxiaochen.7 on 2020/10/30.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import LarkTimeFormatUtils
import UniverseDesignColor

protocol ReminderViewControllerDelegate: AnyObject {
    func reminderViewControllerDidSelectedTime(time: Date)
}

extension ReminderViewController {
    /// 设置时间选择列表是否显示
    func setTimeItemView(isHidden: Bool) {
        timeItemView.isHidden = isHidden
        timeItemView.snp.updateConstraints { (make) in
            make.height.equalTo(isHidden ? 0 : 60)
        }
        self.view.layoutIfNeeded()
    }

    /// 设置时间选择器是否隐藏，是否需要滚动到底部展开
    func setTimePicker(isHidden: Bool, scrollsToBottom: Bool) {
        guard timePicker.isHidden != isHidden else { return }
        timeItemView.setArrowState(to: isHidden ? .down : .up)
        timePicker.isHidden = isHidden
//        let offsetY = 731 - contentView.frame.height
//        contentView.setContentOffset(CGPoint(x: 0, y: isHidden ? 0 : offsetY > 0 ? offsetY : 0), animated: true)
//        contentView.isScrollEnabled = isHidden
        UIView.animate(withDuration: self.animateDuration) {
            self.timePicker.snp.updateConstraints { (make) in
                make.height.equalTo(isHidden ? 0 : 156)
            }
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.updateDisplayAreaContentSize()
            if scrollsToBottom {
                self.scrollsToBottomAnimated(true)
            }
        }
        if isHidden {
            timeItemView.rightView.textColor = UDColor.textCaption
        } else {
            timeItemView.rightView.textColor = UDColor.colorfulBlue
            updateTimePicker()
        }
        self.statisticsCallBack?(isHidden ? "select_reminder_time" : "select_time")
    }

    /// 更新时间选择器选项
    func updateTimePicker() {
        if let selectedTimeValue = selectedTime.value {
            let defaultMinute = context.docsInfo?.type == .sheet ? 0 : 59
            if selectedTimeValue.sk.minute == defaultMinute { // 如果为默认值
                let now = Date()
                timePicker.date = Date(year: selectedTimeValue.sk.year,
                                       month: selectedTimeValue.sk.month,
                                       day: selectedTimeValue.sk.day,
                                       hour: now.sk.hour,
                                       minute: (now.sk.minute / 5) * 5,
                                       second: 0)
            } else {
                timePicker.date = selectedTimeValue
            }
            selectedTime.accept(timePicker.date)
        } else {
            let now = Date()
            timePicker.date = Date(year: now.sk.year,
                                   month: now.sk.month,
                                   day: now.sk.day,
                                   hour: now.sk.hour,
                                   minute: (now.sk.minute / 5) * 5,
                                   second: 0)
            selectedTime.accept(timePicker.date)
        }
    }

    func resetTimePicker() {
        let now = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var currentDate = Date(year: now.sk.year,
                               month: now.sk.month,
                               day: now.sk.day,
                               hour: now.sk.hour,
                               minute: now.sk.minute % 5 == 0 ? (now.sk.minute / 5) * 5 : (now.sk.minute / 5 + 1) * 5,
                               second: 0)
        if currentDate.sk.minute == 60 { //分钟进位
            currentDate = Date(year: currentDate.sk.year,
                               month: currentDate.sk.month,
                               day: currentDate.sk.day,
                               hour: currentDate.sk.hour + 1,
                               minute: 0,
                               second: 0)
            if currentDate.sk.hour == 24 { //日期进位
                currentDate = Date(year: currentDate.sk.year,
                                   month: currentDate.sk.month,
                                   day: currentDate.sk.day + 1,
                                   hour: 0,
                                   minute: 0,
                                   second: 0)
            }
        }
        timePicker.date = currentDate
        selectedDay.accept(currentDate)
        selectedTime.accept(currentDate)
    }
    
    func checkExpireTime(_ expireTime: TimeInterval) -> Bool {
        let now = Date().timeIntervalSince1970
        return expireTime > now
    }
    
    /// 获取由date的yyMMdd 和 time的hhmmss组合起来的日期
    func getCombineDateTime(date: Date, time: Date?) -> Date {
        let now = Date()
        return Date(year: date.sk.year,
                    month: date.sk.month,
                    day: date.sk.day,
                    hour: time?.sk.hour ?? now.sk.hour,
                    minute: time?.sk.minute ?? (now.sk.minute / 5) * 5,
                    second: time?.sk.second ?? 0)
    }
    
    func tryAutoCorrectExpireTime(_ isManual: Bool) -> Bool {
        if isManual, let autoCorrectExpireTimeBlock = self.context.config.autoCorrectExpireTimeBlock {
            //自动修正过期时间
            let curDate = self.getCombineDateTime(date: self.selectedDay.value, time: self.selectedTime.value)
            if let newDate = autoCorrectExpireTimeBlock(curDate) {
                DocsLogger.info("autoCorrectExpireTime: \(curDate.toLocalTime) -> \(newDate.toLocalTime)", component: LogComponents.reminder)
                self.selectedTime.accept(newDate)
                return true
            }
        }
        return false
    }
    
}

// MARK: - date value manipulation
extension ReminderViewController {
    func addComponents(date: Date, components: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: components, to: date)
    }

    func subtract(date: Date, components: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: selfSubtract(components: components), to: date)
    }

    func selfSubtract(components: DateComponents) -> DateComponents {
        var dateComponents = DateComponents()
        if let year = components.year { dateComponents.year = -year }
        if let month = components.month { dateComponents.month = -month }
        if let day = components.day { dateComponents.day = -day }
        if let hour = components.hour { dateComponents.hour = -hour }
        if let minute = components.minute { dateComponents.minute = -minute }
        if let second = components.second { dateComponents.second = -second }
        if let nanosecond = components.nanosecond { dateComponents.nanosecond = -nanosecond }
        return dateComponents
    }

    func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return ""
        }
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: isEn,
                              timePrecisionType: .minute,
                              shouldRemoveTrailingZeros: false)
        return TimeFormatUtils.formatTime(from: date, with: options)
    }
}
