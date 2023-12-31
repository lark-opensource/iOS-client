//
//  LinkClickableLabel.swift
//  SuiteLogin
//
//  Created by lixiaorui on 2019/9/28.
//

import UIKit

extension UITextView {
    func setupStyle(_ showLinkUnderLine: Bool = false) {
        self.isEditable = false
        self.textAlignment = .center
        self.backgroundColor = .clear
        self.font = UIFont.systemFont(ofSize: 14.0)
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .strikethroughColor: UIColor.clear
        ]
        if !showLinkUnderLine {
            attributes[.underlineColor] = UIColor.clear
        }
        self.linkTextAttributes = attributes
        self.textDragInteraction?.isEnabled = false
        self.isScrollEnabled = false
    }
}

typealias LinkClickableLabelDelegate = UITextViewDelegate

class LinkClickableLabel: UITextView {

    public static func `default`(with delegate: UITextViewDelegate, showLinkUnderLine: Bool = false) -> LinkClickableLabel {
        let label = LinkClickableLabel()
        label.setupStyle(showLinkUnderLine)
        label.delegate = delegate
        return label
    }

    // 禁用可以选取内容、以及其他菜单功能
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    // UITextView 的 selectable 会控制URL是否可以点击，为了让URL可交互，text不可选，所以模拟 selectabel = false
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tap = gestureRecognizer as? UITapGestureRecognizer, tap.numberOfTapsRequired == 2 {
            gestureRecognizer.isEnabled = false
            return false
        }
        if let ges = gestureRecognizer as? UILongPressGestureRecognizer,
            ges.minimumPressDuration >= 0.325 {
            // for more detail: https://stackoverflow.com/questions/46143868/xcode-9-uitextview-links-no-longer-clickable
            // allowing small delay long press for links (required for iOS 11.0-11.1)
            // average comparison value is used to distinguish between:
            // 0.12 (smallDelayRecognizer)
            // 0.5 (textSelectionForce and textLoupe)
            gestureRecognizer.isEnabled = false
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            var touchPoint = touch.location(in: self)
            touchPoint.x -= textContainerInset.left
            touchPoint.y -= textContainerInset.top
            tapPosition = layoutManager.characterIndex(for: touchPoint, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        } else {
            tapPosition = -1
        }
        super.touchesBegan(touches, with: event)
    }

    public private(set) var tapPosition: Int = -1
}
