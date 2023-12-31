//
//  Date+Mail.swift
//  MailCommon
//
//  Created by weidong fu on 28/11/2017.
//

import Foundation
import LarkLocalizations

extension Date {
    var milliTimestamp: String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval * 1000))
        return "\(millisecond)"
    }

    /// 返回到 dueDate的天数，同一天返回0，在dueDate前，返回正数；在dueDate后，返回负数
    /// - Parameter dueDate: 结束日期
    /// - Returns: 距离天数
    func daysTo(dueDate: Date) -> Int? {
        let calendar = Calendar.current

        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: dueDate)

        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day
    }
}
