//
//  TouchViewComponent.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/11/7.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

final public class TouchViewComponentProps: ASComponentProps {
    public var onTapped: (() -> Void)?
}

public final class TouchViewComponent<C: Context>: ASComponent<TouchViewComponentProps, EmptyState, TouchView, C> {
    public override func create(_ rect: CGRect) -> TouchView {
        return TouchView(frame: rect)
    }

    public override func update(view: TouchView) {
        super.update(view: view)

        if let tapped = self.props.onTapped {
            view.onTapped = { _ in
                tapped()
            }
        } else {
            view.onTapped = nil
        }
    }
}

// 基于touch的点击响应视图，如果有onTapped，则事件传递链不会传递到子视图
public final class TouchView: UIView {
    public var onTapped: ((TouchView) -> Void)?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTapped == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTapped == nil {
            super.touchesMoved(touches, with: event)
        }
    }

    // 按长一点时间会立即就执行Cancelled
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.onTapped == nil {
            super.touchesCancelled(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = self.onTapped {
            handler(self)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}
