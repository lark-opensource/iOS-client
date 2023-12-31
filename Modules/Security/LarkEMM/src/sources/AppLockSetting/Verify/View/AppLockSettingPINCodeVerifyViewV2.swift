//
//  AppLockSettingPINCodeVerifyViewV2.swift
//  LarkEMM
//
//  Created by chenjinglin on 2023/11/3.
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

extension AppLockSettingV2 {
    final class AppLockSettingPINCodeVerifyInputBoxView: UIView {
        var focusIndex = 0 {
            didSet { updateFocus() }
        }
        private var numberOfDigits = 4
        private lazy var stackView: UIStackView = {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            stackView.isUserInteractionEnabled = false
            stackView.spacing = CGFloat(12)
            return stackView
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
            drawPINCodeVerifyView()
            updateFocus()
        }

        private func drawPINCodeVerifyView() {
            stackView.arrangedSubviews.forEach { (view) in
                stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            for _ in 0 ..< numberOfDigits {
                let node = AppLockSettingPINCodeVerifyNode()
                self.stackView.addArrangedSubview(node)
            }
        }

        private func updateFocus() {
            nodes.enumerated().forEach { (i, node) in
                if i < focusIndex {
                    node.active = .activated
                } else if i == focusIndex {
                    node.active = .activating
                } else {
                    node.active = .inactive
                }
            }
        }
    }

    final class AppLockSettingPINCodeVerifyNode: UILabel {
        // swiftlint:disable:next nesting
        enum NodeStatus {
            case inactive
            case activating
            case activated
        }

        var active = NodeStatus.inactive {
            didSet { updateActive(oldValue: oldValue, newValue: active) }
        }
        
        private lazy var containerView: UIView = {
            let view = UIView()
            view.layer.masksToBounds = true
            view.layer.cornerRadius = 8
            view.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.5)
            return view
        }()

        private lazy var cursor = AppLockSettingPINCodeVerifyCursor()

        private lazy var dotView: UIView = {
            let dotView = UIView()
            dotView.layer.masksToBounds = true
            dotView.layer.cornerRadius = 7
            dotView.isHidden = true
            dotView.isUserInteractionEnabled = false
            dotView.backgroundColor = UIColor.ud.iconN2
            return dotView
        }()

        private var animator: UIViewPropertyAnimator?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            textColor = UIColor.ud.iconN2
            textAlignment = .center
            backgroundColor = .clear
            layer.cornerRadius = 10
            layer.masksToBounds = true
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 2
            addSubview(containerView)
            addSubview(cursor)
            addSubview(dotView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(2)
            }
            cursor.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(1.5)
                make.height.equalTo(30)
            }
            dotView.snp.makeConstraints { make in
                make.centerX.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        private func updateActive(oldValue: NodeStatus, newValue: NodeStatus) {
            switch (oldValue, newValue) {
            case (.inactive, .activating), (.activated, .activating):
                startFocusAnimation()
            case (.activating, .activated):
                startRemoveFocusAnimation(isDotViewHidden: false)
            case (.activating, .inactive), (.activated, .inactive):
                startRemoveFocusAnimation(isDotViewHidden: true)
            default:
                break
            }
        }

        private func startFocusAnimation() {
            animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.9, animations: { [weak self] in
                guard let self else { return }
                self.layer.borderColor = UIColor.ud.fillFocus.cgColor
                self.dotView.isHidden = true
            })
            cursor.update(shouldFlash: true)
            animator?.startAnimation()
        }

        private func startRemoveFocusAnimation(isDotViewHidden: Bool) {
            animator?.addAnimations { [weak self] in
                guard let self else { return }
                self.layer.borderColor = UIColor.clear.cgColor
                self.dotView.isHidden = isDotViewHidden
            }
            cursor.update(shouldFlash: false)
            animator?.startAnimation()
        }

        @objc
        private func onDidBecomeActive() {
            cursor.update(shouldFlash: active == .activating)
        }

        @objc
        private func onDidEnterBackground() {
            cursor.update(shouldFlash: false)
        }
    }

    fileprivate final class AppLockSettingPINCodeVerifyCursor: UIView {
        let animationKey = "appLockSettingCursorOpacityAnimation"
        let values = [1.0, 0.0, 0.0, 1.0]
        let keyTimes: [NSNumber] = [0.0, 0.45, 0.5, 0.95, 1]
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.iconN2
            isHidden = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func getCursorFlashAnimation() -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = values
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = true
            animation.duration = 1
            animation.calculationMode = .discrete
            animation.keyTimes = keyTimes
            return animation
        }

        func update(shouldFlash: Bool) {
            if shouldFlash {
                let opacity = getCursorFlashAnimation()
                layer.add(opacity, forKey: animationKey)
            } else {
                layer.removeAnimation(forKey: animationKey)
            }
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                guard let self else { return }
                self.isHidden = !shouldFlash
            })
        }
    }
}
