//
//  AlternateCalendarFactory.swift
//  Calendar
//
//  Created by yantao on 2020/3/5.
//

import Foundation

final class AlternateCalendarUtil {
    static let chineseCalendar = ChineseCalendar()

    static func getDisplayElement(julianDay: Int, type: AlternateCalendarEnum) -> String {
        switch type {
        case .chineseLunarCalendar:
            return chineseCalendar.getDisplayElement(julianDay: julianDay)
        @unknown default:
            return ""
        }
    }

    static func getDisplayElement(date: Date, type: AlternateCalendarEnum) -> String {
        switch type {
        case .chineseLunarCalendar:
            return chineseCalendar.getDisplayElement(date: date)
        @unknown default:
            return ""
        }
    }

    static func getDisplayElementList(date: Date, appendCount: Int, type: AlternateCalendarEnum) -> [LunarComponents] {
        switch type {
        case .chineseLunarCalendar:
            return chineseCalendar.getDisplayElementList(date: date, appendCount: appendCount)
        @unknown default:
            return []
        }
    }

    // 这个方法本不应暴露，但做农历的批量接口的时候，24节气计算有问题，24节气是按照公历算的，和农历没关系
    // 一开始的做法是，拿到date以后和农历同步进行偏移，但总是和实际的date有差异
    // 只能先暴露这个方法给调用方计算24节气来规避，视图页重构后农历接口的参数会由date改为JulianDay，到时候可以解决这个问题
    static func getSolarTerm(date: Date) -> String? {
        let term = chineseCalendar.getTwentyFourSolarTerm(
            year: date.get(.year),
            month: date.get(.month),
            day: date.get(.day)
        )
        return term.isEmpty ? nil : term
    }
}

// 这个类同样不应该被暴露，因为24节气需要交给调用方来补充，所以暴露这个类和get()方法
public struct LunarComponents {
    // 节日，例如：春节、端午
    let festival: String?
    // 24节气，例如：清明、谷雨
    var solarTerm: String?
    // 月日的别名，例如：腊月、十五
    let dateText: String

    // 获取最终需要展示的元素，优先级：节日>24节气>别名
    func get() -> String {
        if let festival = self.festival {
            return festival
        }
        if let solarTerm = self.solarTerm {
            return solarTerm
        }
        return dateText
    }
}
