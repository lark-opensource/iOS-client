//
//  ImageEditPanGuesture.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/15.
//

import Foundation

import UIKit

final class ImageEditPanGestureRecognizer: UIPanGestureRecognizer {
    var initialTouchLocation: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialTouchLocation = touches.first?.location(in: view)
    }
}
