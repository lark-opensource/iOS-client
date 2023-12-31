//
//  ImportExchangeControl.swift
//  Calendar
//
//  Created by tuwenbo on 2022/8/10.
//

import Foundation
import UniverseDesignIcon
import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit

// MARK: - NewInputTextField
final class NewInputTextField: BaseTextField {

    let disposeBag = DisposeBag()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override var placeholder: String? {
        get {
            super.placeholder
        }
        set {
            attributedPlaceholder = NSAttributedString(string: newValue ?? "", attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
        }
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var viewRect = super.rightViewRect(forBounds: bounds)
        viewRect.origin.x -= 16
        return viewRect
    }

}

// MARK: NewLoadingButton ， 跟 LoadingButton 的区别是 icon 和 文字 的颜色，大小，布局等，以后老页面下线后会替代 LoadingButton
final class NewLoadingButton: UIControl {

    enum State {
        case normal
        case disabled
        case loading
    }

    var buttonState: State {
        didSet {
            switch buttonState {
            case .normal:
                backgroundColor = UIColor.ud.primaryContentDefault
                titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
                icon.isHidden = true
                stopAnimation()
            case .disabled:
                backgroundColor = UIColor.ud.fillDisabled
                titleLabel.textColor = UIColor.ud.udtokenBtnPriTextDisabled
                icon.isHidden = true
                stopAnimation()
            case .loading:
                backgroundColor = UIColor.ud.primaryContentLoading
                titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
                icon.isHidden = false
                startAnimation()
            }
            let hasIcon = (buttonState == .loading)
            icon.snp.updateConstraints { (make) in
                make.width.equalTo(hasIcon ? 20 : 0)
            }
        }
    }

    override init(frame: CGRect) {
        buttonState = .normal
        super.init(frame: frame)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        let wrapperView = UIView()
        addSubview(wrapperView)
        wrapperView.addSubview(icon)
        wrapperView.addSubview(titleLabel)

        wrapperView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.width.equalTo(20)
            make.right.equalTo(titleLabel.snp.left).offset(-4)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    override var isEnabled: Bool {
        didSet {
            buttonState = isEnabled ? .normal : .disabled
        }
    }

    private func startAnimation() {
        self.isUserInteractionEnabled = false
        startZRotation()
    }

    private func stopAnimation() {
        self.icon.layer.removeAllAnimations()
        self.isUserInteractionEnabled = true
    }

    private func startZRotation(duration: CFTimeInterval = 1, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        if self.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: Double.pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        self.icon.layer.add(animation, forKey: "transform.rotation.z")
    }

    private let icon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.chatLoadingOutlined).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill))
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.cd.regularFont(ofSize: 17)
        return label
    }()

    var text: String = "" {
        didSet {
            titleLabel.text = text
        }
    }

    var textColor: UIColor = UIColor.ud.primaryOnPrimaryFill {
        didSet {
            titleLabel.textColor = textColor
        }
    }
}
