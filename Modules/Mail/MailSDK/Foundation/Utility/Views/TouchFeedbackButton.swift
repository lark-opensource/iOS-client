//
//  TouchFeedbackButton.swift
//  MailSDK
//
//  Created by Quanze Gao on 2023/4/24.
//

import UIKit

/// 支持点击时改变按钮颜色
class TouchFeedbackButton: UIButton {
    var feedbackDuration = 0.1
    var normalBackgroundColor: UIColor = .clear
    var highlightedBackgroundColor: UIColor = .clear

    init(normalBackgroundColor: UIColor, highlightedBackgroundColor: UIColor) {
        self.normalBackgroundColor = normalBackgroundColor
        self.highlightedBackgroundColor = highlightedBackgroundColor
        super.init(frame: .zero)
        backgroundColor = normalBackgroundColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        backgroundColor = highlightedBackgroundColor
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        DispatchQueue.main.asyncAfter(deadline: .now() + feedbackDuration) {
            self.backgroundColor = self.normalBackgroundColor
        }
    }
}
