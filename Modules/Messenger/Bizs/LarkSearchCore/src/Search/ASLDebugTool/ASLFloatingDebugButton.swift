//
//  ASLFloatingDebugButton.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/7/15.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignToast
import UIKit
import LarkEMM
import LarkSensitivityControl

public final class ASLFloatingDebugButton: UIButton {
    // 后续改成通过监听来实现get的计算属性
    private var contextID: String

    public init() {
        self.contextID = "暂无搜索"
        super.init(frame: CGRect.zero)
        setupParam()
        setupAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupParam() {
        updateTitle(ContextID: self.contextID)
        self.titleLabel?.lineBreakMode = .byWordWrapping
        self.titleLabel?.textAlignment = .left
        self.titleLabel?.font = UDFont.body1
        self.frame = CGRect(x: 10, y: 200, width: 120, height: 50)
        self.backgroundColor = UDColor.bgTips
        self.layer.cornerRadius = 5.0
    }

    func setupAction() {
        self.addTarget(self, action: #selector(copyContextID(sender:)), for: .touchUpInside)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragAction(gesture:)))
        self.addGestureRecognizer(panGesture)
    }

    public func updateTitle(ContextID: String) {
        self.contextID = ContextID
        self.setTitle("ContextID: \n\(contextID)", for: .normal)
    }

    @objc
    func dragAction(gesture: UIPanGestureRecognizer) {
        let moveState = gesture.state
        guard let superview = self.superview else { return }
        switch moveState {
        case .began:
            break
        case .changed:
            let point = gesture.translation(in: superview)
            self.center = CGPoint(x: self.center.x + point.x, y: self.center.y + point.y)
            break
        case .ended:
            let point = gesture.translation(in: superview)
            var newPoint = CGPoint(x: self.center.x + point.x, y: self.center.y + point.y)
            if newPoint.x < superview.frame.width / 2.0 {
                newPoint.x = self.frame.width / 2.0
            } else {
                newPoint.x = superview.frame.width - self.frame.width / 2.0
            }
            if newPoint.y <= self.frame.height / 2.0 {
                newPoint.y = self.frame.height / 2.0
            } else if newPoint.y >= superview.frame.height - self.frame.height {
                let a = superview.frame.height
                newPoint.y = superview.frame.height - self.frame.height
            }
            UIView.animate(withDuration: 0.5) {
                self.center = newPoint
            }
            break
        default:
            break
        }
           gesture.setTranslation(.zero, in: self)
       }

    @objc
    func copyContextID(sender: UIButton) {
        guard let superview = self.superview else { return }
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = self.contextID
        UDToast.showSuccess(with: "复制成功", on: superview)
    }

}
