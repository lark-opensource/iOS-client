//
//  EMAHUD.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/21.
//

import UIKit
import SnapKit
import LarkActivityIndicatorView
import LKCommonsLogging
import LarkKeyboardKit
import UniverseDesignColor
import UniverseDesignTheme
import LarkSetting

private let screenMargin: CGFloat = 40.0
public let EMAHUDDefalutDelay: TimeInterval = 3.0

@objcMembers
public final class EMAHUD: NSObject {
    // TODOZJX
    @RealTimeFeatureGating(key: "openplatform.api.show_toast.adapt_webapp")
    public static var adaptWebApp: Bool

    @discardableResult
    public class func showLoading(window: UIWindow?) -> EMAHUD {
        return showLoading(nil, window: window)
    }

    @discardableResult
    public class func showLoading(_ text: String? = nil, window: UIWindow?) -> EMAHUD {
        return showLoading(text, on: window, window: window, delay: 0, disableUserInteraction: false)
    }

    @discardableResult
    public class func showTips(_ text: String, window: UIWindow?) -> EMAHUD {
        return showTips(text, on: window, window: window, delay: EMAHUDDefalutDelay, disableUserInteraction: false)
    }

    @discardableResult
    public class func showFailure(_ text: String, window: UIWindow?) -> EMAHUD {
        return showFailure(text, on: window, window: window, delay: EMAHUDDefalutDelay, disableUserInteraction: false)
    }

    @discardableResult
    public class func showFailure(_ text: String, on view: UIView?, window: UIWindow?) -> EMAHUD {
        return showFailure(text, on: view, window: window, delay: EMAHUDDefalutDelay, disableUserInteraction: false)
    }

    @discardableResult
    public class func showSuccess(_ text: String, window: UIWindow?) -> EMAHUD {
        return showSuccess(text, on: window, window: window, delay: EMAHUDDefalutDelay, disableUserInteraction: false)
    }

    @discardableResult
    public class func showSuccess(_ text: String, on view: UIView?, window: UIWindow?) -> EMAHUD {
        return showSuccess(text, on: view, window: window, delay: EMAHUDDefalutDelay, disableUserInteraction: false)
    }

    @discardableResult
    public class func showLoading(_ text: String? = nil, on view: UIView?, window: UIWindow?, delay: TimeInterval = 0, disableUserInteraction: Bool = true) -> EMAHUD {
        let text = text ?? BDPI18n.loading ?? ""
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        let hud = existingHUD(on: view, window: window)
        hud.showLoading(text, on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
        return hud
    }

    @discardableResult
    public class func showTips(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) -> EMAHUD {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        let hud = existingHUD(on: view, window: window)
        hud.showTips(text, on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
        return hud
    }

    @discardableResult
    public class func showFailure(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) -> EMAHUD {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        let hud = existingHUD(on: view, window: window)
        hud.showFailure(text, on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
        return hud
    }

    @discardableResult
    public class func showSuccess(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) -> EMAHUD {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        let hud = existingHUD(on: view, window: window)
        hud.showSuccess(text, on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
        return hud
    }

    public class func removeHUD(window: UIWindow?) {
        // UIWindow.lu.current 有可能是nil
        removeHUD(on: window, window: window)
    }

    public class func removeHUD(on view: UIView?, window: UIWindow?) {
        guard let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow() else {
            return
        }
        for hud in view.subviews {
            if let roundHud = hud as? RoundedView {
                roundHud.host?.disMissRoundView()
            }
        }
    }

    private class func existingHUD(on view: UIView?, window: UIWindow?) -> EMAHUD {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        if let view = view, let existingHUD = (view.subviews.last(where: { $0 is RoundedView }) as? RoundedView)?.host {
            if existingHUD.roundView.isRemoving || existingHUD.roundView.styleChanged() {
                existingHUD.remove()
                return EMAHUD()
            }
            return existingHUD
        }
        return EMAHUD()
    }

    public override init() {
        super.init()
        willShowObserver = EMAHUD.handelKeyboard(name: UIResponder.keyboardWillShowNotification, action: { [weak self] (keyBoardRect, _) in
            if self?.roundView.superview != nil {
                self?.bottomConstraint?.activate()
                self?.bottomConstraint?.update(offset: -keyBoardRect.height - 20 )
            }
        })
        willHideObserver = EMAHUD.handelKeyboard(name: UIResponder.keyboardWillHideNotification, action: { [weak self] (_, _) in
            if self?.roundView.superview != nil {
                self?.bottomConstraint?.deactivate()
            }
        })
    }

    public func showLoading(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = 0, disableUserInteraction: Bool = true) {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        self.roundView.iconWrapper.isHidden = false
        self.roundView.iconView.isHidden = true
        self.roundView.indicator.isHidden = false
        self.roundView.indicator.startAnimating()
        self.roundView.textLabel.text = text
        self.displayRoundView(on: view, window: window, disableUserInteraction: disableUserInteraction)
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.disMissRoundView()
            }
        }
    }

    public func showTips(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        self.roundView.iconWrapper.isHidden = true
        self.roundView.textLabel.text = text
        self.roundView.textLabel.numberOfLines = 2
        self.roundView.textLabel.textAlignment = .left
        if isTextShouldBreakLine(text, window: window) {
            roundView.layer.cornerRadius = 8
            roundView.stackView.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10).priority(.high)
                make.left.equalToSuperview().offset(20)
                make.right.equalToSuperview().offset(-20).priority(.high)
            })
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.05
            paragraphStyle.alignment = .center
            let attrString = NSMutableAttributedString(string: text)

            attrString.addAttribute(.paragraphStyle,
                                    value: paragraphStyle,
                                    range: NSRange(location: 0, length: attrString.length))
            roundView.textLabel.attributedText = attrString
        }

        self.displayRoundView(on: view, window: window, disableUserInteraction: disableUserInteraction)
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.disMissRoundView()
            }
        }
    }

    public func showFailure(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        self.showResult(text, image: UIImage.ema_imageNamed("roundToast_failure"), on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
    }

    public func showSuccess(_ text: String, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool = false) {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        self.showResult(text, image: UIImage.ema_imageNamed("roundToast_sucess"), on: view, window: window, delay: delay, disableUserInteraction: disableUserInteraction)
    }

    deinit {
        NotificationCenter.default.removeObserver(willShowObserver)
        NotificationCenter.default.removeObserver(willHideObserver)
        self.remove()
    }

    public func remove() {
        self.bgMask?.removeFromSuperview()
        self.roundView.removeFromSuperview()
    }

    public func showResult(_ text: String, image: UIImage, on view: UIView?, window: UIWindow?, delay: TimeInterval = EMAHUDDefalutDelay, disableUserInteraction: Bool) {
        let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow()
        self.roundView.iconView.isHidden = false
        self.roundView.indicator.isHidden = true
        self.roundView.indicator.stopAnimating()
        self.roundView.textLabel.text = text
        self.roundView.iconView.image = image
        let superView = self.roundView.superview ?? view
        self.displayRoundView(on: superView, window: window, disableUserInteraction: disableUserInteraction)
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.disMissRoundView()
            }
        }
    }

    public func showAfterDelay(_ delay: TimeInterval) {
        self.roundView.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.roundView.alpha = 1
        }
    }

    static let logger = Logger.oplog(EMAHUD.self)
    private let HUDWindowVerticalScale: CGFloat = 0.2   // HUD间隔屏幕底部占屏幕高度20%
    private let HUDKeyboardMargin: CGFloat = 20         // HUD距离键盘的间隔距离
    private var bgMask: UIView?                         // HUD背景样式
    private var bottomConstraint: Constraint?           // HUD底部约束
    private var bottomMarginWhenWindowNotFound: CGFloat = 50    // window不存在时的兜底间距
    private func displayRoundView(on view: UIView?, window: UIWindow?, disableUserInteraction: Bool) {
        guard let view = view ?? window ?? OPWindowHelper.fincMainSceneWindow() else {
            return  // UIWindow.lu.current 有可能是nil，会导致 make.centerX.equalToSuperview() crash
        }
        var realWindow: UIWindow? = nil
        if EMAHUD.adaptWebApp {
            realWindow = window ?? view.window ?? OPWindowHelper.fincMainSceneWindow()
        }
        if self.roundView.superview != nil {
            return
        }
        self.roundView.alpha = 0.0
        view.addSubview(self.roundView)
        self.roundView.host = self
        var bottomMargin: CGFloat
        if let window = EMAHUD.adaptWebApp ? realWindow : window {
            bottomMargin = window.bounds.size.height * HUDWindowVerticalScale
        } else {
            EMAHUD.logger.error("UIWindow not found")
            bottomMargin = bottomMarginWhenWindowNotFound
        }

        let bottomExceedWindowOffset = getBottomExceedWindowOffset(view: view, window: EMAHUD.adaptWebApp ? realWindow : window)
        bottomMargin += bottomExceedWindowOffset
        if EMAHUD.adaptWebApp {
            /*
             1. showToast 目前对异形容器的适配很有限，目前仅适配容器底部低于 window 和容器底部高于 window 底部的两种场景
             2. 并且当容器底部高于 window 过多时，会导致 bottomMargin 过小甚至为负导致超出 view，所以这里做个兜底 20 的距离，
                实际目前不会有命中兜底 20 的场景，因为目前容器底部最多高于 window 一个 tabbar 的高度
             */
            bottomMargin = bottomMargin >= 20 ? bottomMargin : 20
        }

        let keyboardHeight = KeyboardKit.shared.currentHeight
        let bottomOffset: CGFloat = keyboardHeight > 0 ? (-keyboardHeight - HUDKeyboardMargin) : 0
        self.roundView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomMargin).priority(.high)
            make.width.lessThanOrEqualToSuperview().offset(-screenMargin * 2)
            self.bottomConstraint = make.bottom.equalTo(bottomOffset).constraint
        }
        if keyboardHeight == 0 {
            self.bottomConstraint?.deactivate()
        }

        if disableUserInteraction {
            //挡住用户的操作
            let bg = UIView()
            view.insertSubview(bg, belowSubview: self.roundView)
            var isIntersects = false
            var naviHeight: CGFloat = 0
            if let naviBar = BDPResponderHelper.topNavigationController(for: view)?.navigationBar {
                naviHeight = naviBar.bounds.height
                let naviBarNewRect = naviBar.convert(naviBar.bounds, to: nil)
                let viewNewRect = view.convert(view.bounds, to: nil)
                if naviBarNewRect.intersects(viewNewRect) {
                    isIntersects = true
                } else {
                    isIntersects = false
                }
            } else {
                isIntersects = false
            }
            bg.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                let height = isIntersects ? UIApplication.shared.statusBarFrame.height + naviHeight : 0
                make.top.equalToSuperview().offset(height)
            }
            self.bgMask = bg
        }

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
            self.roundView.alpha = 1.0
        }, completion: nil)
    }

    /*
     https://meego.feishu.cn/larksuite/issue/detail/6150970
     小程序 view 在有 tabbar 的情况下可能超出 window，这块和容器沟通过是他们期望中的
     所以这里仅对小程序 view 底部超出 window 时，计算一下 offset 给 hud 的底部约束添加一个偏移
     */
    private func getBottomExceedWindowOffset(view: UIView, window: UIWindow?) -> CGFloat {
        guard let window = window else {
            return 0
        }
        let viewNewRect = view.convert(view.bounds, to: nil)
        let viewBottomOffset = viewNewRect.maxY - window.bounds.size.height
        if EMAHUD.adaptWebApp {
            return viewBottomOffset
        } else {
            return viewBottomOffset > 0 ? viewBottomOffset : 0
        }
    }

    private func disMissRoundView() {
        self.roundView.isRemoving = true
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear, animations: {
            self.roundView.alpha = 0.0
        }, completion: { _ in
            self.remove()
        })
    }

    private let roundView: RoundedView = RoundedView()

    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?
    private static func handelKeyboard(name: NSNotification.Name, action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return  NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration: TimeInterval = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration)
        }
    }
}

private class RoundedView: UIView {

    static let textFont = UIFont.ema_title(withSize: 14)
    static let margin: CGFloat = 20.0
    let defaultCornerRadius: CGFloat = 20.0
    let iconWrapper = UIView()

    var host: EMAHUD?

    var isRemoving: Bool = false

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = RoundedView.textFont
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var iconView: UIImageView = {
        return UIImageView()
    }()

    lazy var indicator: LarkActivityIndicatorView.ActivityIndicatorView = {
        return ActivityIndicatorView(color: UIColor.white)
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview == nil {
            self.host = nil
        }
    }

    let stackView = UIStackView()

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        isUserInteractionEnabled = false
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            UITraitCollection.current = correctTrait
        }
        layer.backgroundColor = UIColor.ud.bgTips.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 7.5
        layer.cornerRadius = defaultCornerRadius
        addSubview(self.textLabel)
        stackView.axis = .horizontal
        stackView.spacing = 8.0
        addSubview(stackView)
        stackView.snp.makeConstraints({ (make) in
            make.height.greaterThanOrEqualTo(20)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10).priority(.high)
            make.left.equalToSuperview().offset(RoundedView.margin)
            make.right.equalToSuperview().offset(-RoundedView.margin).priority(.high)
        })
        stackView.insertArrangedSubview(self.textLabel, at: 0)

        let iconWidth = 20.0
        stackView.insertArrangedSubview(iconWrapper, at: 0)
        iconWrapper.snp.makeConstraints({ (make) in
            make.width.equalTo(iconWidth).priority(.low)
            make.height.equalTo(iconWidth).priority(.low)
        })

        iconWrapper.addSubview(self.iconView)
        self.iconView.snp.makeConstraints({ (make) in
            make.width.equalTo(iconWidth)
            make.height.equalTo(iconWidth)
            make.center.equalToSuperview()
        })

        iconWrapper.addSubview(self.indicator)
        self.indicator.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(iconWidth)
        })
    }

    func styleChanged() -> Bool {
        return layer.cornerRadius != defaultCornerRadius
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func textWidth(of text: String) -> CGFloat {
    let font = RoundedView.textFont
    let rect = (text as NSString).boundingRect(
        with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
        options: .usesLineFragmentOrigin,
        attributes: [NSAttributedString.Key.font: font], context: nil)
    return ceil(rect.width)
}

private func isTextShouldBreakLine(_ text: String, window: UIWindow?) -> Bool {
    guard let window = window else {
        return false
    }
    let width = textWidth(of: text)
    let maxWidth = window.bounds.width - RoundedView.margin * 2 - screenMargin * 2
    return width > maxWidth
}
