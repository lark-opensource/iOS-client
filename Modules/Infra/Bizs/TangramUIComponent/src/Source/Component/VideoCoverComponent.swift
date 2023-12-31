//
//  VideoCoverComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/8/17.
//

import Foundation
import TangramComponent
import LarkInteraction

public final class VideoCoverComponentProps: Props {
    public var setImageTask: EquatableWrapper<VideoCoverView.SetImageTask?> = .init(value: nil)
    public var onTap: EquatableWrapper<VideoCoverView.OnTap?> = .init(value: nil)
    public var duration: Int64 = 0

    public init() {}

    public func clone() -> VideoCoverComponentProps {
        let clone = VideoCoverComponentProps()
        clone.setImageTask = setImageTask
        clone.onTap = onTap
        clone.duration = duration
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? VideoCoverComponentProps else { return false }
        return old.setImageTask == setImageTask &&
            old.onTap == onTap &&
            old.duration == duration
    }
}

public final class VideoCoverComponent<C: Context>: RenderComponent<VideoCoverComponentProps, VideoCoverView, C> {
    public override func update(_ view: VideoCoverView) {
        super.update(view)
        view.setImageTask = props.setImageTask.value
        view.onTap = props.onTap.value
        view.duration = props.duration
    }
}
