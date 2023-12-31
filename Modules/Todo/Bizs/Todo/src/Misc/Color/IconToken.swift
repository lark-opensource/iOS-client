//
//  IconToken.swift
//  Todo
//
//  Created by wangwanxin on 2021/9/6.
//

import UniverseDesignIcon

extension UDIconType {

    static func calendarDateOutlined(timeZone: TimeZone) -> UDIconType {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dateComponents = calendar.dateComponents([.day], from: Date())
        return UDIcon.getIconTypeByName("calendar\(dateComponents.day ?? 1)Outlined") ?? calendar1Outlined
    }
}
