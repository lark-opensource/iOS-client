//
//  AppLockSettingPINCodeVerifyView.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/30.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkContainer
import EENavigator
import LarkActionSheet
import FigmaKit
import UIKit

final class AppLockSettingPINCodeVerifyView: UIView {

    var focusIndex = 0 {
        didSet { updateFocus() }
    }

    private var numberOfDigits = 4
    private lazy var stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.isUserInteractionEnabled = false
        s.spacing = CGFloat(32)
        return s
    }()
    private var nodes: [AppLockSettingPINCodeVerifyNode] {
        return stackView.arrangedSubviews.compactMap({ $0 as? AppLockSettingPINCodeVerifyNode })
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        redraw()
    }

    private func redraw() {
        stackView.arrangedSubviews.forEach { (v) in
            stackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for _ in 0 ..< numberOfDigits {
            let node = AppLockSettingPINCodeVerifyNode()
            node.isUserInteractionEnabled = false
            node.backgroundColor = backgroundColor
            let magicNum = 16.0
            node.layer.cornerRadius = magicNum / 2.0
            self.stackView.addArrangedSubview(node)
            node.snp.makeConstraints { make in
                make.height.width.equalTo(magicNum)
                make.centerY.equalToSuperview()
            }
        }
        layoutIfNeeded()
    }

    private func updateFocus() {
        nodes.enumerated().forEach { (i, node) in
            node.active = i < focusIndex
        }
    }

}

final class AppLockSettingPINCodeVerifyNode: UIView {
    var active = false {
        didSet { updateActive(oldValue: oldValue, newValue: active) }
    }

    private var animator = UIViewPropertyAnimator()
    private let activeBackgroundColor = UIColor.ud.primaryOnPrimaryFill

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        layer.borderColor = UIColor.ud.rgb(0xD5F6F2).cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateActive(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }
        if newValue {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    private func startAnimation() {
        animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9, animations: {
            self.backgroundColor = self.activeBackgroundColor
        })
        animator.startAnimation()
    }

    private func stopAnimation() {
        animator.addAnimations {
            self.backgroundColor = self.superview?.backgroundColor
        }
        animator.startAnimation()
    }
}
