//
//  TimerViewComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/4/22.
//

import UIKit
import Foundation
import TangramComponent

public final class TimerViewComponentProps: Props {
    // 是否倒计时
    public var countDown: Bool = false
    public var font: UIFont = TimerView.defaultFont
    public var textColor: UIColor = TimerView.defaultTextColor
    public var startTime: Int64 = 0
    public var endTime: Int64?
    public var isEnd: Bool = false
    // 默认左对齐
    public var textAlignment: NSTextAlignment = .left

    public init() {}

    public func clone() -> TimerViewComponentProps {
        let clone = TimerViewComponentProps()
        clone.countDown = countDown
        clone.font = font.copy() as? UIFont ?? TimerView.defaultFont
        clone.textColor = textColor.copy() as? UIColor ?? TimerView.defaultTextColor
        clone.startTime = startTime
        clone.endTime = endTime
        clone.isEnd = isEnd
        clone.textAlignment = textAlignment
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? TimerViewComponentProps else { return false }
        return countDown == old.countDown &&
            font == old.font &&
            textColor == old.textColor &&
            startTime == old.startTime &&
            endTime == old.endTime &&
            isEnd == old.isEnd &&
            textAlignment == old.textAlignment
    }
}

public final class TimerViewComponent<C: Context>: RenderComponent<TimerViewComponentProps, TimerView, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return TimerView.fitSize(size: size, font: props.font)
    }

    public override func create(_ rect: CGRect) -> TimerView {
        let view = TimerView(countDown: props.countDown,
                             font: props.font,
                             textColor: props.textColor,
                             startTime: props.startTime,
                             endTime: props.endTime,
                             isEnd: props.isEnd,
                             textAlignment: props.textAlignment)
        view.frame = rect
        view.start()
        return view
    }

    public override func update(_ view: TimerView) {
        super.update(view)
        view.start()
        view.countDown = props.countDown
        view.font = props.font
        view.textColor = props.textColor
        view.startTime = props.startTime
        view.endTime = props.endTime
        view.isEnd = props.isEnd
        view.textAlignment = props.textAlignment
    }
}
