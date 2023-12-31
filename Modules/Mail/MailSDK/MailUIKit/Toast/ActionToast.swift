//
//  BottomToast.swift
//  MailSDK
//
//  Created by majunxiao on 2020/8/21.
//
import Foundation
import UIKit
import SnapKit
import LarkActivityIndicatorView
import LarkExtensions
import EENavigator
import LarkContainer

private let ActionToastMaxWidth: CGFloat = 295
private let toastMargin: CGFloat = 128  // appropriate height of toast for generations below
private let screenHeight: CGFloat = 667 // for specific generations: iPhone 7,8,SE etc.
private let displayPosRate: CGFloat = toastMargin / screenHeight
// MARK: ActionToast
final class ActionToast {
    private let toastView: ActionToastView = ActionToastView()
    private var backgroundMaskView: UIControl?
    private var bottomConstraint: Constraint?
    private var dismissHandler: (() -> Void)?
    @discardableResult
    class func showLoadingToast(with text: String,
                                       on view: UIView,
                                       action: String?,
                                       dissmissOnTouch: Bool = false,
                                       handler: @escaping () -> Void,
                                       bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showLoading(with: text,
                        action: action,
                        on: view,
                        dissmissOnTouch: dissmissOnTouch,
                        bottomMargin: bottomMargin)
        hud.toastView.handler = handler
        return hud
    }

    @discardableResult
    class func showSuccessToast(with text: String, on view: UIView, bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showSuccess(with: text, action: nil, on: findCurrentWindow(on: view), dissmissOnTouch: false, bottomMargin: bottomMargin)
        hud.toastView.handler = nil
        return hud
    }
    
    @discardableResult
    class func showWarningToast(with text: String, on view: UIView, bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showWarning(with: text, action: nil, on: findCurrentWindow(on: view), dissmissOnTouch: false, bottomMargin: bottomMargin)
        hud.toastView.handler = nil
        return hud
    }

    @discardableResult
    class func showFailureToast(with text: String, on view: UIView, bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showFailure(with: text, action: nil, on: findCurrentWindow(on: view), dissmissOnTouch: false, bottomMargin: bottomMargin)
        hud.toastView.handler = nil
        return hud
    }

    @discardableResult
    class func showSuccessToast(with text: String,
                                on view: UIView,
                                action: String?,
                                autoDismiss: Bool = true,
                                dissmissOnTouch: Bool = false,
                                dissmissDuration: Double = timeIntvl.toastDismiss,
                                handler: @escaping () -> Void,
                                bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showSuccess(with: text,
                        action: action,
                        on: view,
                        autoDismiss: autoDismiss,
                        dissmissOnTouch: dissmissOnTouch,
                        dissmissDuration: dissmissDuration,
                        bottomMargin: bottomMargin)
        hud.toastView.handler = handler
        return hud
    }

    @discardableResult
    class func showFailureToast(with text: String,
                                       on view: UIView,
                                      action: String?,
                                      autoDismiss: Bool = true,
                                      dissmissOnTouch: Bool = false,
                                       handler: @escaping () -> Void,
                                       bottomMargin: CGFloat? = nil) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.showFailure(with: text, action: action, on: view, autoDismiss: autoDismiss, dissmissOnTouch: dissmissOnTouch, bottomMargin: bottomMargin)
        hud.toastView.handler = handler
        return hud
    }

    @discardableResult
    public class func updateText(on view: UIView, text: String, action: String?) -> ActionToast {
        let hud = existingToast(on: findCurrentWindow(on: view))
        hud.toastView.setText(text, action: action)
        return hud
    }

    public class func removeToast(on view: UIView) {
        let w = findCurrentWindow(on: view)
        for hud in w.subviews {
            if let roundHud = hud as? ActionToastView {
                roundHud.host?.dismiss()
                roundHud.handler = nil
            }
        }
    }

    private class func existingToast(on view: UIView) -> ActionToast {
       if let existingToast = (view.subviews.last(where: { $0 is ActionToastView }) as? ActionToastView)?.host {
           if existingToast.toastView.isRemoving || existingToast.toastView.styleChanged() {
               existingToast.remove()
               return ActionToast()
           }
           return existingToast
       }
       return ActionToast()
    }

    private func showLoading(with text: String,
                             action: String?,
                             on view: UIView,
                             dissmissOnTouch: Bool = false,
                             bottomMargin: CGFloat? = nil) {
        toastView.iconWrapper.isHidden = false
        toastView.iconView.isHidden = true
        toastView.indicator.isHidden = false
        toastView.indicator.startAnimating()
        toastView.setText(text, action: action)
        display(on: ActionToast.findCurrentWindow(on: view),
                dissmissOnTouch: dissmissOnTouch,
                bottomMargin: bottomMargin)
    }

    private func showSuccess(with text: String,
                             action: String?,
                             on view: UIView,
                             autoDismiss: Bool = true,
                             dissmissOnTouch: Bool = false,
                             dissmissDuration: Double = timeIntvl.toastDismiss,
                             bottomMargin: CGFloat? = nil) {
        self.showResult(with: text,
                        action: action,
                        image: Resources.toast_icon_success,
                        on: ActionToast.findCurrentWindow(on: view),
                        autoDismiss: autoDismiss,
                        dissmissOnTouch: dissmissOnTouch,
                        dissmissDuration: dissmissDuration,
                        bottomMargin: bottomMargin)
    }
    
    private func showWarning(with text: String,
                             action: String?,
                             on view: UIView,
                             autoDismiss: Bool = true,
                             dissmissOnTouch: Bool = false,
                             bottomMargin: CGFloat? = nil) {
        self.showResult(with: text,
                        action: action,
                        image: Resources.toast_icon_warning,
                        on: ActionToast.findCurrentWindow(on: view),
                        autoDismiss: autoDismiss,
                        dissmissOnTouch: dissmissOnTouch,
                        bottomMargin: bottomMargin)
    }

    private func showFailure(with text: String,
                             action: String?,
                             on view: UIView,
                             autoDismiss: Bool = true,
                             dissmissOnTouch: Bool = false,
                             bottomMargin: CGFloat? = nil) {
        self.showResult(with: text, action: action,
                        image: Resources.toast_icon_fail,
                        on: ActionToast.findCurrentWindow(on: view),
                        autoDismiss: autoDismiss,
                        dissmissOnTouch: dissmissOnTouch,
                        bottomMargin: bottomMargin)
    }

    private func showResult(with text: String,
                            action: String?,
                            image: UIImage,
                            on view: UIView,
                            autoDismiss: Bool,
                            dissmissOnTouch: Bool,
                            dissmissDuration: Double = timeIntvl.toastDismiss,
                            bottomMargin: CGFloat? = nil) {
        toastView.iconView.isHidden = false
        toastView.indicator.isHidden = true
        toastView.indicator.stopAnimating()
        toastView.iconView.image = image
        toastView.setText(text, action: action)
        let superView = toastView.superview ?? view
        display(on: superView, dissmissOnTouch: dissmissOnTouch, bottomMargin: bottomMargin)
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + dissmissDuration) {
                self.dismiss()
            }
        }
    }

    func remove() {
        self.removeSafity(view: backgroundMaskView)
        self.removeSafity(view: toastView)
    }

    private func removeSafity(view: UIView?) {
        let task = {
            guard let view = view else { return }
            if view.superview == nil { return }
            view.removeFromSuperview()
        }

        if Thread.isMainThread {
            task()
            return
        }
        DispatchQueue.main.async {
            task()
        }
    }

    private func display(on view: UIView, dissmissOnTouch: Bool, bottomMargin: CGFloat? = nil) {
        if toastView.superview != nil {
            return
        }
        let window = ActionToast.findCurrentWindow(on: view)
        toastView.alpha = 0.0
        view.addSubview(toastView)
        toastView.host = self
        var caculateBottomMargin = window.bounds.size.height * displayPosRate
        if let bottomMargin = bottomMargin {
            caculateBottomMargin = bottomMargin
        }
        toastView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-caculateBottomMargin).priority(.high)
            make.width.lessThanOrEqualTo(ActionToastMaxWidth)
        }

        /// toast will dismiss when touch  bgMask
        if dissmissOnTouch {
            if backgroundMaskView == nil {
                let mask = UIControl()
                view.insertSubview(mask, belowSubview: toastView)
                mask.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                mask.addTarget(self, action: #selector(onMaskClick), for: .touchDown)
                backgroundMaskView = mask
            }
            backgroundMaskView?.isHidden = false
        } else {
            backgroundMaskView?.isHidden = true
        }

        UIView.animate(withDuration: timeIntvl.ultraShort, delay: 0, options: .curveLinear, animations: {
            self.toastView.alpha = 1.0
        }, completion: nil)
    }

    private func dismiss() {
        toastView.isRemoving = true
        UIView.animate(withDuration: timeIntvl.ultraShort, delay: 0, options: .curveLinear, animations: {
            self.toastView.alpha = 0.0
        }, completion: { _ in
            self.remove()
        })
        dismissHandler?()
    }

    @objc
    private func onMaskClick() {
        dismiss()
    }

    private class func findCurrentWindow(on view: UIView) -> UIWindow {
        if let w = view as? UIWindow {
            return w
        }
        if let w = view.window, rightWindow(w: w) {
            return w
        } else if let w = Container.shared.getCurrentUserResolver().navigator.mainSceneWindow,
                  rightWindow(w: w) {
            /// 这里用 fallback 的方法，先看看有没有走，如果没走后续可以移除改分支
            mailAssertionFailure("[UserContainer] Should not fallback to main scene window")
            return w
        } else {
            mailAssertionFailure("can't find window")
            return UIWindow()
        }
    }
    private class func rightWindow(w: UIWindow) -> Bool {
        return !w.isHidden && w.windowLevel == .normal && w.alpha > 0
    }
}

// MARK: - ActionToastView
private class ActionToastView: UIView {
    static let textFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let margin: CGFloat = 20.0
    static let spacing: CGFloat = 8.0
    static let iconWidth: CGFloat = 18.0
    static let defaultCornerRadius: CGFloat = 20.0
    static let minCornerRadius: CGFloat = 8.0

    let iconWrapper = UIView()
    let actionWrapper = UIView()
    var host: ActionToast?
    var isRemoving: Bool = false
    var handler: (() -> Void)?

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = ActionToastView.textFont
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.textAlignment = .left
        return label
    }()

    lazy var iconView: UIImageView = {
        return UIImageView()
    }()

    lazy var indicator: ActivityIndicatorView = {
        return ActivityIndicatorView(color: UIColor.ud.primaryOnPrimaryFill)
    }()

    lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        return separator
    }()

    lazy var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = ActionToastView.textFont
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.addTarget(self, action: #selector(onClickButton), for: .touchUpInside)
        let titleLabel = button.titleLabel

        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview == nil {
            self.host = nil
        }
    }

    let stackView = UIStackView()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        setupViews()
    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgTips
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 7.5
        layer.cornerRadius = ActionToastView.defaultCornerRadius

        stackView.axis = .horizontal
        stackView.spacing = ActionToastView.spacing
        addSubview(stackView)
        stackView.snp.makeConstraints({ (make) in
            make.height.greaterThanOrEqualTo(20)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalToSuperview().offset(ActionToastView.margin)
            make.right.equalToSuperview().offset(-ActionToastView.margin)
        })

        // icon wrapper
        stackView.addArrangedSubview(iconWrapper)
        iconWrapper.snp.makeConstraints({ (make) in
            make.width.equalTo(ActionToastView.iconWidth)
            make.height.equalTo(ActionToastView.iconWidth)
        })
        iconWrapper.addSubview(iconView)
        iconView.snp.makeConstraints({ (make) in
            make.width.equalTo(ActionToastView.iconWidth)
            make.height.equalTo(ActionToastView.iconWidth)
            make.centerX.equalToSuperview()
            make.top.equalTo(1)
        })
        iconWrapper.addSubview(indicator)
        indicator.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(ActionToastView.iconWidth)
        })

        // text
        stackView.addArrangedSubview(textLabel)

        // action
        stackView.addArrangedSubview(actionWrapper)
        actionWrapper.snp.makeConstraints { (make) in
        }
        actionWrapper.addSubview(separator)
        separator.snp.makeConstraints { (make) in
            make.width.equalTo(1 / UIScreen.main.scale)
            make.height.equalTo(16)
            make.leading.equalTo(6)
            make.centerY.equalToSuperview()
        }
        actionWrapper.addSubview(actionButton)
        actionButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.leading.equalTo(21)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func styleChanged() -> Bool {
        return layer.cornerRadius != ActionToastView.defaultCornerRadius
    }

    func maxTextWidth() -> CGFloat {
        actionWrapper.layoutIfNeeded()
        var actionTextWidth: CGFloat = 0
        if let actionText = actionButton.titleLabel?.text {
            actionTextWidth = textWidth(of: actionText)
        }
        let actionWrapperWidth: CGFloat = actionTextWidth + 21
        let toastSpaceWidth: CGFloat = ActionToastView.margin * 2 + ActionToastView.spacing * 2
        return ActionToastMaxWidth - actionWrapperWidth - ActionToastView.iconWidth - toastSpaceWidth
    }

    func textWidth(of text: String) -> CGFloat {
        let font = ActionToastView.textFont
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
    
    func setText(_ text: String, action: String?) {
        actionButton.setTitle(action, for: .normal)
        if action?.isEmpty ?? true {
            actionWrapper.isHidden = true
        } else {
            actionWrapper.isHidden = false
        }
        let maxWidth = maxTextWidth()
        var width = textWidth(of: text)
        var height = 20
        if width > maxWidth {
            width = maxWidth
            height = 40
            layer.cornerRadius = ActionToastView.minCornerRadius
            textLabel.numberOfLines = 2
            iconView.snp.remakeConstraints({ (make) in
                make.width.equalTo(ActionToastView.iconWidth)
                make.height.equalTo(ActionToastView.iconWidth)
                make.centerX.equalToSuperview()
                make.top.equalTo(2)
            })
        } else {
            textLabel.numberOfLines = 1
            height = 20
            layer.cornerRadius = ActionToastView.defaultCornerRadius
            iconView.snp.remakeConstraints({ (make) in
                make.width.equalTo(ActionToastView.iconWidth)
                make.height.equalTo(ActionToastView.iconWidth)
                make.centerX.equalToSuperview()
                make.top.equalTo(1)
            })
        }
        textLabel.snp.remakeConstraints { (make) in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
        stackView.snp.updateConstraints({ (make) in
            make.height.greaterThanOrEqualTo(height)
        })
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.05
        paragraphStyle.alignment = .left
        let attrString = NSMutableAttributedString(string: text)
        attrString.addAttribute(.paragraphStyle,
                                value: paragraphStyle,
                                range: NSRange(location: 0, length: attrString.length))
        textLabel.attributedText = attrString
    }

    @objc
    func onClickButton() {
        handler?()
    }
}
