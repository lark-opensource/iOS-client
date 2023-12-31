//
//  PinListCell.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/25.
//

import UIKit
import Foundation
import LarkMessageBase

final class PinListCell: MessageCommonCell {
    private let duration: TimeInterval = 3

    lazy var hightView: UIView = {
        return self.getView(by: PinMessageCellComponent.hightViewKey) ?? UIView()
    }()

    public func highlight() {
        self.hightView.alpha = 1
        UIView.animateKeyframes(withDuration: duration, delay: 0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                self.hightView.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                self.hightView.alpha = 0
            })
        }, completion: { _ in
            self.hightView.alpha = 0
        })
    }
}
