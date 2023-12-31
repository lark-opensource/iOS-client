//
//  RightClick.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/16.
//

import UIKit
import Foundation

// 项目是否启动了 UIApplicationSupportsIndirectInputEvents
let applicationSupportIndirect: Bool = {
    return (
        Bundle.main.infoDictionary?["UIApplicationSupportsIndirectInputEvents"] as? Bool
    ) ?? false
}()

@available(iOS 13.4, *)
func checkIsRightClick(touches: Set<UITouch>, event: UIEvent) -> Bool {
    guard touches.count == 1,
          event.type == .touches,
          let touch = touches.first else {
        return false
    }

    let isRightClick: Bool
    /// 需要判断系统是否支持 indirect
    if applicationSupportIndirect {
        isRightClick = touch.type == .indirectPointer &&
            event.buttonMask == .secondary
    } else {
        isRightClick = event.buttonMask == .secondary
    }
    return isRightClick
}

public final class RightClickRecognizer: UIGestureRecognizer {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if #available(iOS 13.4, *) {
            if checkIsRightClick(touches: touches, event: event) {
                self.state = .possible
                DispatchQueue.main.async {
                    if self.state == .possible {
                        self.state = .began
                    }
                }
            } else {
                self.state = .failed
            }
        } else {
            self.state = .failed
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        if self.state != .cancelled &&
            self.state != .failed {
            self.state = .ended
        }
    }
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.state = .cancelled
    }
}
