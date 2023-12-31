//
//  MailPassthroughView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2023/8/14.
//

import UIKit

/// 不拦截点击事件的 View
final class MailPassthroughView: UIView {
    var shouldPassThrough = true
    var passThroughAction: (() -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)

        if shouldPassThrough, v === self {
            passThroughAction?()
            return nil
        }

        return v
    }
}
