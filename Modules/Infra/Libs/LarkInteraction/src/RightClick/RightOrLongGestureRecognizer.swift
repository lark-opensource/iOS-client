//
//  RightOrLongGestureRecognizer.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/18.
//

import UIKit
import Foundation

public final class RightOrLongGestureRecognizer: UILongPressGestureRecognizer {

    private var isRightClick: Bool = false

    public override func reset() {
        super.reset()
        self.isRightClick = false
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if #available(iOS 13.4, *) {
            if checkIsRightClick(touches: touches, event: event) {
                self.state = .began
                self.isRightClick = true
            }
        }
        if !self.isRightClick {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if !self.isRightClick {
            super.touchesMoved(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if !self.isRightClick {
            super.touchesEnded(touches, with: event)
        } else {
            self.state = .ended
        }
    }
}
