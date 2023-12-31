//
//  BasePreviewController.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/21.
//

import Foundation
import UIKit

class BasePreviewController: UIViewController {

    typealias TapHandler = (_ controller: UIViewController) -> Void

    var onTapBack: TapHandler?
    var onTapSure: TapHandler?
    var autoDisapper: Bool = true

    let buttonSize: Int = 70

    private lazy var backContent: UIView = UIView()
    private lazy var backBlurView: UIView = UIView()
    private lazy var backButton: UIButton = UIButton()
    private lazy var lastTapBackDate = Date.distantPast
    private lazy var sureButton: UIButton = UIButton()
    private lazy var lastTapSureDate = Date.distantPast

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        initControl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = view.bounds.width
        let height = view.bounds.height
        let bottomMargin: CGFloat = 70
        let centerY = height - bottomMargin - backContent.bounds.height / 2

        backContent.center = CGPoint(x: width / 3, y: centerY - view.safeAreaInsets.bottom )

        sureButton.center = CGPoint(x: width / 3 * 2, y: backContent.center.y)
        bringControlToFront()
    }

    func bringControlToFront() {
        view.bringSubviewToFront(backContent)
        view.bringSubviewToFront(sureButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        playButtonAnimation(true)
    }

    private func playButtonAnimation(_ isApper: Bool, _ completion: ((Bool) -> Void)? = nil) {
        switchControl(false)
        let duration: TimeInterval = 0.2

        var centerFrame = backContent.frame
        centerFrame.origin.x = (view.bounds.width - backContent.bounds.width) / 2

        let leftFrame = backContent.frame
        let rightFrame = sureButton.frame

        if isApper {
            backContent.frame = centerFrame
            sureButton.frame = centerFrame

            UIView.animate(withDuration: duration) {
                self.backContent.frame = leftFrame
                self.sureButton.frame = rightFrame
            }
        } else {
            backContent.frame = leftFrame
            sureButton.frame = rightFrame

            UIView.animate(withDuration: duration, animations: {
                self.backContent.frame = centerFrame
                self.sureButton.frame = centerFrame
            }, completion: completion)
        }

        let animationLeft: CABasicAnimation = CABasicAnimation(keyPath: "frame")
        animationLeft.fromValue = centerFrame
        animationLeft.toValue = backContent.frame
        animationLeft.duration = duration

        let animationRight: CABasicAnimation = CABasicAnimation(keyPath: "frame")
        animationRight.fromValue = centerFrame
        animationRight.toValue = sureButton.frame
        animationRight.duration = duration

        backContent.layer.add(animationLeft, forKey: nil)
        sureButton.layer.add(animationRight, forKey: nil)
    }

    private func switchControl(_ isHidden: Bool) {
        backContent.isHidden = isHidden
        sureButton.isHidden = isHidden
    }
}

fileprivate extension BasePreviewController {
    func initControl() {

        let frame: CGRect = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)

        backContent.frame = frame
        backBlurView.frame = frame
        backButton.frame = frame
        sureButton.frame = frame

        view.addSubview(backContent)
        backContent.addSubview(backBlurView)
        backContent.addSubview(backButton)
        view.addSubview(sureButton)

        switchControl(true)

        let buttonCornerRadius: CGFloat = CGFloat(buttonSize / 2)
        backBlurView.clipsToBounds = true
        backBlurView.layer.cornerRadius = buttonCornerRadius
        addBlurToView(backBlurView)

        backButton.setImage(Resources.back, for: .normal)
        backButton.clipsToBounds = true
        backButton.layer.cornerRadius = buttonCornerRadius
        backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)

        sureButton.setImage(Resources.sure, for: .normal)
        sureButton.clipsToBounds = true
        sureButton.layer.cornerRadius = buttonCornerRadius
        sureButton.backgroundColor = UIColor.white
        sureButton.addTarget(self, action: #selector(tapSure), for: .touchUpInside)
    }

    func addBlurToView(_ view: UIView) {
        let blurEffect = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = view.bounds
        effectView.isUserInteractionEnabled = false
        view.addSubview(effectView)
    }

    @objc
    func tapBack(_ button: UIButton) {
        guard Date().timeIntervalSince(lastTapBackDate) > 1.5 else { return }
        lastTapBackDate = Date()

        tryDisapper()
        playButtonAnimation(false) { [weak self] (finish) in
            guard finish, let `self` = self else { return }

            self.onTapBack?(self)
        }
    }

    @objc
    func tapSure(_ button: UIButton) {
        guard Date().timeIntervalSince(lastTapSureDate) > 1.5 else { return }
        lastTapSureDate = Date()

        tryDisapper()
        onTapSure?(self)
    }

    func tryDisapper() {
        if autoDisapper {
            self.dismiss(animated: false, completion: nil)
            if let controller = self.navigationController {
                controller.popToViewController(self, animated: false)
                controller.popViewController(animated: false)
            }
        }
    }
}
