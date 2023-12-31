//
//  SafeModeButton.swift
//  LarkSafeMode
//
//  Created by luyz on 2023/9/13.
//

import Foundation

final class SafeModeButton: UIButton {

    private let highlightBgColor = UIColor(red: 25.0/255.0, green: 66.0/255.0, blue: 148.0/255.0, alpha: 1.0)

    private let normalBgColor = UIColor(red: 51.0/255.0, green: 112.0/255.0, blue: 255.0/255.0, alpha: 1.0)

    private var iconImage: UIImage?

    private var isLoading = false

    private var loadingIcon: UIImage = BundleResources.LarkSafeMode.loadingIcon

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            if newValue || isLoading {
                backgroundColor = highlightBgColor
            } else {
                backgroundColor = normalBgColor
            }
            super.isHighlighted = newValue
        }
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(repaint(reSize: CGSize(width: 16, height: 14), image: image), for: state)

        self.iconImage = image

        if image != nil {
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        } else {
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    /// Button show loading
    func showLoading() {
        guard isEnabled,
            !isLoading,
            iconImage == nil else { return }

        self.isUserInteractionEnabled = false
        self.isLoading = true

        self.setImage(loadingIcon, for: .normal)
        if let imageView = self.imageView {
            addRotateAnimation(view: imageView)
        }

        self.backgroundColor = highlightBgColor
        self.setNeedsLayout()
    }

    /// Button hide loading
    func hideLoading() {
        guard isEnabled, isLoading else { return }

        self.isUserInteractionEnabled = true
        self.isLoading = false

        self.setImage(nil, for: .normal)
        if let imageView = self.imageView {
            removeRotateAnimation(view: imageView)
        }

        self.backgroundColor = normalBgColor
        self.setNeedsLayout()
    }

    private func addRotateAnimation(view: UIView, duration: CFTimeInterval = 1) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(CGFloat.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        view.layer.add(rotateAnimation, forKey: "rotateAnimation")
    }

    private func removeRotateAnimation(view: UIView) {
        view.layer.removeAllAnimations()
    }

    func repaint(reSize: CGSize, image: UIImage?) -> UIImage? {
        guard image != nil else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(reSize,
                                               false,
                                               UIScreen.main.scale)
        image?.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height))
        let reSizeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return reSizeImage
    }
}


