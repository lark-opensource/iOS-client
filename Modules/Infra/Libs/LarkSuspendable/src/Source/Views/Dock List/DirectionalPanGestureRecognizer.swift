//
//  DirectionalPanGestureRecognizer.swift
//  LarkSuspendable
//
//  Created by Hayden on 2021/5/31.
//

import Foundation
import UIKit

enum PanDirection: Int, CaseIterable {
    case right, down, left, up
}

final class DirectionalPanGestureRecognizer: UIPanGestureRecognizer {

    var allowedDirections: [PanDirection] = PanDirection.allCases
    var currentDirection: PanDirection?
    private var isDragging: Bool = false

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        if state == .failed { return }
        let velocity = self.velocity(in: self.view)
        if !isDragging && velocity != .zero {
            let velocities = [
                PanDirection.right: velocity.x,
                PanDirection.down: velocity.y,
                PanDirection.left: -velocity.x,
                PanDirection.up: -velocity.y
            ].sorted { $0.value < $1.value }
            let direction = velocities.last!.key
            currentDirection = direction
            if !allowedDirections.contains(direction) {
                self.state = .failed
            }
            isDragging = true
        }
    }

    override func reset() {
        super.reset()
        isDragging = false
    }

}
