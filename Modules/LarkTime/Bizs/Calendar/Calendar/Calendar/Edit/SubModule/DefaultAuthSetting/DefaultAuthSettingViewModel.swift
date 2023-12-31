//
//  DefaultAuthSettingViewModel.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/30/23.
//

import Foundation
import RxSwift
import RxRelay

typealias DefaultAuthSetting = Rust.CalendarShareOptions

class DefaultAuthSettingViewModel {

    private static let displayedOptions: [Rust.ShareOption] = [.shareOptPrivate, .shareOptFreeBusyReader, .shareOptReader, .shareOptWriter, .shareOptOwner]

    private(set) var rxInnerSelectedIndex: BehaviorRelay<Int>
    private(set) var rxExternalSelectedIndex: BehaviorRelay<Int>

    private(set) var rxShareAuthSettings: BehaviorRelay<DefaultAuthSetting>

    var externalTopAuthStr: String { rxShareAuthSettings.value.crossTopShareOption.cd.shareOptionInfo }

    init(authSettings: Rust.CalendarShareOptions) {
        rxShareAuthSettings = .init(value: authSettings)
        guard let innerSelectedIndex = Self.displayedOptions.firstIndex(of: authSettings.innerDefault),
        let externalSelectedIndex = Self.displayedOptions.firstIndex(of: authSettings.externalDefault) else {
            rxInnerSelectedIndex = .init(value: -1)
            rxExternalSelectedIndex = .init(value: -1)
            return
        }

        rxInnerSelectedIndex = .init(value: innerSelectedIndex)
        rxExternalSelectedIndex = .init(value: externalSelectedIndex)
    }

    /// 判断是否超过 reader 权限，calendar 兜底权限为 reader，区别于 admin 配置的最高权限（toast tip 不一样）
    /// - Parameter authIndex: 对应 auth 在 Self.displayedOptions 中的 index
    /// - Returns: predicate result
    func predicateAuthOverRuleFromCalendar(authIndex: Int) -> Bool? {
        guard let auth = Self.displayedOptions[safeIndex: authIndex] else {
            CalendarBiz.editLogger.error("Auth clicked has been out of range.")
            return nil
        }
        return auth > Rust.CalendarShareOptions().defaultTopOptionInCalendar
    }

    func contents(of type: DefaultAuthFrom) -> [SelectionCellData] {
        let topOption = type == .inner ? rxShareAuthSettings.value.innerDefaultTopOption : rxShareAuthSettings.value.externalDefaultTopOption
        return Self.displayedOptions.map {
            .init(canSelect: $0 <= topOption, title: $0.cd.shareOptionInfo, content: $0.cd.shareOptionDescription)
        }
    }

    func updateSetting(of type: DefaultAuthFrom, with optionIndex: Int) {
        var authSettings = rxShareAuthSettings.value
        guard let authOption = Self.displayedOptions[safeIndex: optionIndex] else {
            CalendarBiz.editLogger.error("Auth clicked has been out of range.")
            return
        }
        switch type {
        case .inner:
            authSettings.defaultShareOption = authOption
            rxInnerSelectedIndex.accept(optionIndex)
            rxShareAuthSettings.accept(authSettings)
        case .external:
            rxExternalSelectedIndex.accept(optionIndex)
            authSettings.crossDefaultShareOption = authOption
            rxShareAuthSettings.accept(authSettings)
        }
    }
}
