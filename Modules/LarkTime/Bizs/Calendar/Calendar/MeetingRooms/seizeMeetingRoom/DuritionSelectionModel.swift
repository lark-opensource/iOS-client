//
//  DuritionSelectionModel.swift
//  Calendar
//
//  Created by harry zou on 2019/4/18.
//

import Foundation
import CalendarFoundation

struct DurationSelectionModel {
    let interval = 15
    var endTimes: [TimeInterval] = []

    let startTime: Int
    let nextUnavailableTime: Int

    init(startTime: Int, nextUnavailableTime: Int) {
        self.startTime = startTime
        self.nextUnavailableTime = nextUnavailableTime
        reloadEndTimes()
    }

    @discardableResult
    mutating func reloadEndTimes() -> [TimeInterval] {
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTime))
        let calendar = Calendar.gregorianCalendar
        let nextDiff = interval - calendar.component(.minute, from: startDate) % interval
        var nextQuarterHour = (calendar.date(byAdding: .minute, value: nextDiff, to: startDate) ?? Date()).timeIntervalSince1970.floor2Minute()
        var result: [TimeInterval] = []
        let end = min(TimeInterval(nextUnavailableTime), startDate.dayEnd().timeIntervalSince1970 - 59)
        while nextQuarterHour < end {
            result.append(nextQuarterHour)
            nextQuarterHour += 900
        }
        result.append(end)
        if result.count > 1 {
            result.removeFirst()
        }
        self.endTimes = result
        return result
    }

    func getDurition(endTime: TimeInterval) -> Int {
        let diff = Int(endTime) - startTime
        let mins = diff / 60
        let n = mins / 5
        let a = mins % 5
        if a < 3 {
            return 5 * n
        } else {
            return 5 * (n + 1)
        }
    }
}

extension TimeInterval {
    func floor2Minute() -> TimeInterval {
        return floor(self / 60.0) * 60
    }
}
