//
//  BaseInMeetStatusView.swift
//  ByteView
//
//  Created by bytedance on 2022/7/27.
//

import Foundation
import UIKit

class BaseInMeetStatusView: UIView {
    var shouldHiddenForOmit: Bool = false {
        didSet {
            guard oldValue != self.shouldHiddenForOmit else { return }
            updateLayout()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    func updateLayout() {}
}
