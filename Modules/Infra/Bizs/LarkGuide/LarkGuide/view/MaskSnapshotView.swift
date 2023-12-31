//
//  MaskSnapshotView.swift
//  LarkChat
//
//  Created by sniper on 2018/11/20.
//

import Foundation
import UIKit

final class MaskSnapshotView: UIView {
    var visualEffectView: UIVisualEffectView! {
        willSet {
            if visualEffectView == nil { return }
            visualEffectView.removeFromSuperview()
        }

        didSet {
            if visualEffectView != nil {
                self.addSubview(visualEffectView)
            }
        }
    }
    var backgroundView: UIView = .init() {
        willSet {
            if backgroundView == nil { return }
            backgroundView.removeFromSuperview()
        }

        didSet {
            if backgroundView != nil {
                self.addSubview(backgroundView)
            }
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}
