//
//  PostView.swift
//  LarkThread
//
//  Created by qihongye on 2019/2/14.
//

import UIKit
import Foundation

public final class PostViewCore: UIView {
    public var tapHandler: (() -> Void)?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesMoved(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.tapHandler == nil {
            super.touchesCancelled(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let handler = self.tapHandler {
            handler()
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}
