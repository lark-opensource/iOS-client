//
//  SuspendView.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/6.
//

import Foundation
import UIKit

final class SuspendView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        if hitView == self {
            return nil
        }
        return hitView
    }

}
