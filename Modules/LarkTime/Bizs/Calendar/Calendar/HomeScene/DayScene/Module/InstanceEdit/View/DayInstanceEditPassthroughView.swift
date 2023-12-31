//
//  DayInstanceEditPassthroughView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/26.
//

import UIKit

/// DayScene - InstanceEdit - PassthroughView

final class DayInstanceEditPassthroughView: UIView {

    // 返回 true 则处理
    typealias EventFilter = (CGPoint, UIEvent?) -> Bool

    var eventFilter: EventFilter?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return eventFilter?(point, event) ?? false
    }
}
