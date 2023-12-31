//
//  OCRPanGesture.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/29.
//

import Foundation
import UIKit

final class PanGestureRecognizer: UIPanGestureRecognizer {

    var touchBeginPoint: CGPoint?

    var translation: CGPoint? {
        guard let startPoint = self.touchBeginPoint,
            let gestureView = self.view else {
            return nil
        }
        let location = self.location(in: gestureView)
        return CGPoint(
            x: location.x - startPoint.x,
            y: location.y - startPoint.y
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.touchBeginPoint = self.location(in: self.view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.touchBeginPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.touchBeginPoint = nil
    }

    @available(iOS 13.4, *)
    override func shouldReceive(_ event: UIEvent) -> Bool {
        // 事件开始前 重置 startPoint,兼容触控板
        self.touchBeginPoint = nil
        return super.shouldReceive(event)
    }
}
