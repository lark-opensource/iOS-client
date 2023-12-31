//
//  UIViewComponent.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/20.
//

import UIKit
import Foundation
import TangramComponent

public final class UIViewComponentProps: Props {
    public var onTap: EquatableWrapper<(() -> Void)?> = .init(value: nil)

    public init() {}

    public func clone() -> UIViewComponentProps {
        let clone = UIViewComponentProps()
        clone.onTap = onTap
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? UIViewComponentProps else { return false }
        return old.onTap == onTap
    }
}

public final class UIViewComponent<C: Context>: RenderComponent<UIViewComponentProps, UIViewWrapper, C> {
    public override func update(_ view: UIViewWrapper) {
        super.update(view)
        if let onTap = props.onTap.value {
            view.onTap = { _ in onTap() }
        } else {
            view.onTap = nil
        }
    }
}

// 基于touch的点击响应视图，如果有onTapped，则事件传递链不会传递到子视图
public final class UIViewWrapper: UIView {
    public var onTap: ((UIViewWrapper) -> Void)?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTap == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTap == nil {
            super.touchesMoved(touches, with: event)
        }
    }

    // 按长一点时间会立即就执行Cancelled
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTap == nil {
            super.touchesCancelled(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = self.onTap {
            handler(self)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}
