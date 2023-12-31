//
//  EventEditRootScrollView.swift
//  Calendar
//
//  Created by pluto on 2023/10/23.
//

import Foundation

class EventEditRootScrollView: UIScrollView {
    
    var aiTaskStatusGetter: ((Bool) -> AiTaskStatus)?
    var tapBlockFrameGetter: ((AIGenerateEventInfoType) -> CGRect?)?
    var touchBeginPoint: CGPoint?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let isInAttendeeBlock: Bool = tapBlockFrameGetter?(.attendee)?.contains(point) ?? false
        /// 当浮窗完成态时，返回自己，不再传递到子view
        if aiTaskStatusGetter?(false) == .finish && !isInAttendeeBlock {
           return self
        }
        return super.hitTest(point, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        touchBeginPoint = point

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }

        if point == touchBeginPoint && aiTaskStatusGetter?(false) == .finish {
            aiTaskStatusGetter?(true)
        }
    }
}
