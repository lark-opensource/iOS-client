//
//  BaseViewController.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RoundedHUD
import LKCommonsLogging
import Lottie
import Homeric
import LarkAlertController
import LarkUIKit
import UniverseDesignTheme
import UniverseDesignToast
import LarkContainer
import LarkExtensions
import ECOProbeMeta
import EENavigator

struct Common {
    struct Layout {
        static let safeAreaLeft: CGFloat = 16
        static let bottomMargin: CGFloat = 10
        static let bottomHeight: CGFloat = 20
        static let itemSpace: CGFloat = 16
        static let backButtonTopSpace: CGFloat = 10
        static let tableBottom: CGFloat = 64
        static let navItemCenter: CGFloat = 22
        static let padViewPrefferredWidth: CGFloat = 480
        static let registerInfoFieldHeight: CGFloat = 40
        static let fieldHeight: CGFloat = 48
        static let fieldBottom: CGFloat = 40
        static let cardVerticalSpace: CGFloat = 6.0
        static let linkClickableLabelItemSpace = CL.itemSpace - 5
        static let checkBoxSize: CGSize = CGSize(width: 14, height: 14)
        static let checkBoxInsets: UIEdgeInsets = UIEdgeInsets(top: -40, left: -50, bottom: -50, right: -50)
        static let checkBoxYOffset: CGFloat = 2
        static let checkBoxRightPadding: CGFloat = 0
        static let underBackBtnTopSpace = backButtonTopSpace + BaseViewController.BaseLayout.backHeight
        static let passwordFieldHeight: CGFloat = 36
        static let processTipTopSpace: CGFloat = 5
    }
    struct Alert {
        static let contentWidth: CGFloat = 303
        static let contentPadding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)
    }
    struct Layer {
        static let commonTagRadius: CGFloat = 4
        static let commonButtonRadius: CGFloat = 6
        static let commonTextFieldRadius: CGFloat = 6
        static let commonHighlightCellRadius: CGFloat = 6
        static let commonAvatarImageRadius: CGFloat = 8
        static let commonPopPanelRadius: CGFloat = 8
        static let commonAppIconRadius: CGFloat = 8
        static let commonAlertViewRadius: CGFloat = 12
        static let commonCardContainerViewRadius: CGFloat = 10
        static let loginPageLogoRadius: CGFloat = 12
        static let loginQRCodeRadius: CGFloat = 10
    }
}

typealias CL = Common.Layout

typealias I18N = BundleI18n.suiteLogin
typealias Resource = BundleResources.LarkAccount
typealias DynamicResource = BundleResources.PassportDynamic

protocol V3ViewModelProtocol {
    var viewModel: V3ViewModel { get }
}

protocol NeedSkipWhilePopProtocol {
    var needSkipWhilePop: Bool { get }
}

protocol BaseViewControllerLoadingProtocol {
    func showLoading()
    func stopLoading()
}

class GradientCircleView: UIView {

    class RadialGradientLayer: CAGradientLayer {

        override init() {
            super.init()
            self.type = .radial
            startPoint = CGPoint(x: 0.5, y: 0.5)
            endPoint = CGPoint(x: 1, y: 1)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override init(layer: Any) {
            super.init(layer: layer)
        }

    }

    private lazy var gradientLayer = RadialGradientLayer()

    init() {
        super.init(frame: .zero)
        gradientLayer.locations = [0, 1]
        self.layer.addSublayer(gradientLayer)
    }

    func setColors(color: UIColor, opacity: CGFloat) {
        gradientLayer.colors = [color.withAlphaComponent(opacity).cgColor, UIColor.clear.cgColor]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
}


class BaseViewController: UIViewController, V3ViewModelProtocol, NeedSkipWhilePopProtocol {

    let logger = Logger.plog(BaseViewController.self, category: "SuiteLogin.BaseViewController")

    let disposeBag = DisposeBag()
    let viewModel: V3ViewModel
    // 控制使用 HUD 的 Loading，场景：端内加入团队的页面使用和端内统一的 Loading
    var useHUDLoading: Bool = false
    // 是否使用自定义Navi动画
    var useCustomNavAnimation: Bool = true
    // 避免View离开后 还响应后面页面的键盘弹出事件，引起 NextButton 飘逸和非预期键盘弹出
    var isInViewAppearTime: Bool = false
    // 是否可以显示session失效的弹窗, 默认为 false
    var showSessionInvalidAlert: Bool = false
    // 是否是以 formSheet 形式显示
    var isInFormSheet: Bool {
        guard presentingViewController != nil else { return false }

        var inFormSheet = modalPresentationStyle == .formSheet
        if !inFormSheet, let navi = self.navigationController {
            // 自己不是 fromSheet 但导航是
            inFormSheet = navi.modalPresentationStyle == .formSheet
        }
        return inFormSheet
    }

    // 是否强制iPad使用手机的布局
    var iPadUseCompactLayout: Bool {
        isPad && !isInFormSheet
    }

    deinit {
        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_page_run,
                              categoryValueMap: [ProbeConst.stepName: viewModel.step,
                                                 ProbeConst.stageName: "onDestroy"],
                              context: viewModel.context)
    }

    init(viewModel: V3ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var closeCallback: (() -> Void)?

    lazy var safeAreaTop: CGFloat = {
        if let window = UIApplication.shared.keyWindow {
            return window.safeAreaInsets.top
        }
        return 0
    }()

    lazy var safeAreaBottom: CGFloat = {
        if let window = UIApplication.shared.keyWindow {
            return window.safeAreaInsets.bottom
        }
        return 0
    }()

    var horizontalSafeAeraTarget: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide
    }

    var viewTopConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.top
    }

    var viewBottomConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.bottom
    }

    /// 默认和 viewBottomConstraint 相同，但部分页面会复写 用来调整键盘弹起操作
    var bottomViewBottomConstraint: ConstraintItem {
        return viewBottomConstraint
    }

    // 为转场动画使用，需要做转场动画的view添加在此view上
    lazy var moveBoddyView: UIView = {
        let moveBoddyView = UIView()
        moveBoddyView.backgroundColor = UIColor.clear
        moveBoddyView.autoresizingMask = .flexibleWidth
        return moveBoddyView
    }()

    /// 主标题
    lazy internal var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    /// 副标题
    lazy var detailLabel: UITextView = {
        let detailLabel = LinkClickableLabel.default(with: self)
        detailLabel.textContainer.maximumNumberOfLines = 10
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.textContainerInset = .zero
        detailLabel.textContainer.lineFragmentPadding = 0
        return detailLabel
    }()
    
    private lazy var backgroundImageView = UIImageView()

    lazy private var loadingMaskView: UIView = {
        return BaseViewController.createLoadingMaskView(loadingView)
    }()

    lazy private var loadingView: LOTAnimationView = {
        return BaseViewController.createLoading()
    }()

    private var loadingHUD: RoundedHUD?

    var isPad: Bool { Display.pad }

    // 根据页面层级 willAppear 阶段自动生成
    lazy var backButton = { UIButton(type: .custom) }()

    lazy var errorHandler: ErrorHandler = {
        return createErrorHandler()
    }()

    /// 切换验证方式
    lazy var switchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        return btn
    }()

    /// 下一步按钮
    lazy var nextButton: NextButton = {
        let btn = NextButton(title: "")
        btn.isEnabled = false
        btn.accessibilityIdentifier = "llNextStep"
        return btn
    }()

    /// 底部视图 默认只有下一步
    lazy var bottomView: UIView = {
        let v = UIView()
        return v
    }()

    /// 输入调整避免键盘遮挡
    lazy var inputAdjustView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never
        let gesture = UITapGestureRecognizer(target: self, action: #selector(endEdit))
        gesture.delegate = self
        v.addGestureRecognizer(gesture)
        return v
    }()
    
    lazy var topGradientMainCircle = GradientCircleView()
    lazy var topGradientSubCircle = GradientCircleView()
    lazy var topGradientRefCircle = GradientCircleView()
    lazy var blurEffectView = UIVisualEffectView()

    /// 中间输入界面（不能被键盘弹起遮挡的部分）放置输入框等，配合下一步按钮布局
    var centerInputView: UIView = UIView()

    var switchButtonContainer: UIView = UIView()

    /// 如果不使用 bottom 注意处理 inputAdjustView.snp.bottom 的约束
    /// 否则会显示不出来(ScrollView 需要底部锚定确认content size)
    /// 默认是 bottomView.snp.top
    func needBottmBtnView() -> Bool {
        return onlyNavUI() ? false : true
    }

    func needSwitchButton() -> Bool {
        return onlyNavUI() ? false : true
    }

    @Provider private var loginService: V3LoginService

    func needBackImage() -> Bool { !loginService.store.isLoggedIn }

    var needSkipWhilePop: Bool { false }

    func updateSwitchBtnTitle(_ title: String) {
        switchButton.setTitle(title, for: .normal)
    }

    func needPanGesture() -> Bool { iPadUseCompactLayout }

    @objc
    func switchAction(sender: UIButton) {}

    func pageName() -> String? { nil }

    private var beginOffset: CGPoint = .zero

    /// initial offset while keyboard show
    var keyboardShowBottomViewOffset: CGFloat {
        return self.safeAreaBottom + CL.itemSpace - CL.bottomMargin
    }

    func createErrorHandler() -> ErrorHandler {
        return V3ErrorHandler(vc: self, context: viewModel.context, contextExpiredPostEvent: true)
    }

    private func clickBack() {
        if let nc = navigationController,
           let index = nc.realViewControllers.firstIndex(of: self),
           index == 0 {
            clickClose()
            return
        }
        navigationController?.popViewController(animated: true)
        closeCallback?()
        closeCallback = nil
    }

    private func clickClose() {
        self.viewModel.clickClose()
        self.dismiss(animated: true) {
            self.closeCallback?()
            self.closeCallback = nil
        }
    }

    func clickBackOrClose(isBack: Bool) {
        if isBack {
            clickBack()
        } else {
            clickClose()
        }
    }

    func onlyNavUI() -> Bool { false }

    func setBackBtnHidden(_ hidden: Bool) {
        backButton.isHidden = hidden
    }

    func handleKeyboardWhenShow(_ noti: Notification) {
        func adjust(orignalHeight: CGFloat) {
            let keyboardHeight = self.calculateAdjustKeyboardHeight(original: orignalHeight, min: self.keyboardShowBottomViewOffset)
            self.bottomView.snp.updateConstraints({ (make) in
                // 只留下 nextButton.height + CL.bottomMargin
                make.bottom.equalTo(self.bottomViewBottomConstraint).offset(-(keyboardHeight - self.keyboardShowBottomViewOffset))
            })
            self.view.layoutIfNeeded()
            if self.inputAdjustView.contentSize.height > self.inputAdjustView.frame.height {
                self.inputAdjustView.setContentOffset(
                    CGPoint(x: 0, y: self.inputAdjustView.contentSize.height - self.inputAdjustView.frame.height),
                    animated: true
                )
            }
        }

        if let keyboardSize = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if Display.pad {
                /*
                     iPad modalPresentationStyle = formSheet，横屏下。
                     self.view会往上移动，但是要等动画设置完成才知道移动的目标位置，所以增加了Dispatch，获取移动的目标位置。
                     Dispatch之后，除了系统执行的动画作用域，会缺少位移动画，增加读取键盘动画配置进行动画。
                     */
                let animationDuration = (noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0
                let animationOptions = (noti.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
                DispatchQueue.main.async {
                    UIView.animate(
                        withDuration: TimeInterval(animationDuration),
                        delay: 0,
                        options: UIView.AnimationOptions(rawValue: animationOptions),
                        animations: {
                            if #available(iOS 16.0, *) {
                                adjust(orignalHeight: self.updateKeyboardHeightIfNeeded(keybaordToFrame: keyboardSize))
                            } else {
                                adjust(orignalHeight: keyboardSize.height)
                            }
                        },
                        completion: nil)
                }
            } else {
                adjust(orignalHeight: keyboardSize.height)
            }
        }
    }

    func handleKeyboardWhenHide(_ noti: Notification) {
        self.bottomView.snp.updateConstraints({ (make) in
            make.bottom.equalTo(self.bottomViewBottomConstraint)
        })
        self.view.layoutIfNeeded()
    }
}

// MARK: LifeCycle
extension BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgLogin
        self.view.clipsToBounds = true
        if needBackImage() {
            var isDarkModeTheme: Bool = false
            if #available(iOS 13.0, *) {
                isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
            }
            self.view.addSubview(topGradientMainCircle)
            self.view.addSubview(topGradientSubCircle)
            self.view.addSubview(topGradientRefCircle)
            topGradientMainCircle.snp.makeConstraints { (make) in
                make.left.equalTo(-40.0 / 375 * view.frame.width)
                make.top.equalTo(0.0)
                make.width.equalToSuperview().multipliedBy(120.0 / 375)
                make.height.equalToSuperview().multipliedBy(96.0 / 812)
            }
            topGradientSubCircle.snp.makeConstraints { (make) in
                make.left.equalTo(-16.0 / 375 * view.frame.width)
                make.top.equalTo(-112.0 / 812 * view.frame.height)
                make.width.equalToSuperview().multipliedBy(228.0 / 375)
                make.height.equalToSuperview().multipliedBy(220.0 / 812)
            }
            topGradientRefCircle.snp.makeConstraints { (make) in
                make.left.equalTo(150.0 / 375 * view.frame.width)
                make.top.equalTo(-22.0 / 812 * view.frame.height)
                make.width.equalToSuperview().multipliedBy(136.0 / 375)
                make.height.equalToSuperview().multipliedBy(131.0 / 812)
            }
            self.view.addSubview(blurEffectView)
            blurEffectView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            setGradientLayerColors(isDarkModeTheme: isDarkModeTheme)
        }

        if needPanGesture() {
            // 扩展滚动区域 横屏输入界面 title 会被遮挡 扩展两边滑动区域
            view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture)))
        }

        setupLoading()
        view.addSubview(moveBoddyView)
        moveBoddyView.addSubview(inputAdjustView)
        inputAdjustView.addSubview(titleLabel)
        inputAdjustView.addSubview(detailLabel)
        inputAdjustView.addSubview(centerInputView)
        inputAdjustView.addSubview(switchButtonContainer)

        moveBoddyView.snp.makeConstraints { (make) in
            if iPadUseCompactLayout {
                make.top.equalToSuperview()
                make.bottom.equalTo(viewBottomConstraint)
                make.left.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.left)
                make.right.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.right)
                // will broken while use split screen with 320pt width on ipad
                make.width.equalTo(CL.padViewPrefferredWidth)
                make.centerX.equalToSuperview()
            } else {
                make.top.equalToSuperview()
                make.bottom.equalTo(viewBottomConstraint)
                make.left.right.equalTo(horizontalSafeAeraTarget)
            }
        }

        inputAdjustView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.visualNaviBarHeight)
            make.left.right.equalToSuperview()
        }

        centerInputView.snp.makeConstraints { (make) in
            make.top.equalTo(detailLabel.snp.bottom).offset(BaseLayout.centerInputTop)
            make.left.right.equalTo(moveBoddyView)
            make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
        }

        switchButtonContainer.snp.makeConstraints { (make) in
            make.top.equalTo(centerInputView.snp.bottom)
            make.left.right.equalTo(moveBoddyView)
            make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
            make.bottom.lessThanOrEqualToSuperview().inset(CL.itemSpace)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(BaseLayout.titleLabelTop)
            make.leading.equalTo(moveBoddyView).offset(CL.itemSpace)
            make.trailing.lessThanOrEqualTo(moveBoddyView).inset(CL.itemSpace)
            make.height.greaterThanOrEqualTo(BaseLayout.titleLabelHeight)
        }

        detailLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(moveBoddyView).inset(CL.itemSpace)
            make.top.equalTo(titleLabel.snp.bottom).offset(BaseLayout.detailLabelTop)
        }

        if needSwitchButton() {
            setupSwitchButton()
        }

        if needBottmBtnView() {
            setupBottomBtnView()
        }

        PassportProbeHelper.shared.currentStep = viewModel.step
        
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }
        setGradientLayerColors(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FetchClientLogHelper.subscribeStatusBarInteraction()
        isInViewAppearTime = true
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        addBackOrCloseButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_step_page_run,
                              categoryValueMap: [ProbeConst.stepName: viewModel.step,
                                                 ProbeConst.stageName: "onCreate"],
                              context: viewModel.context)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        FetchClientLogHelper.unsubscribeStatusBarInteraction()
        isInViewAppearTime = false
    }

    private func setGradientLayerColors(isDarkModeTheme: Bool) {
        topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.16)
        topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.16)
        topGradientRefCircle.setColors(color: UIColor.ud.rgb("#2DBEAB"), opacity: 0.10)
        blurEffectView.effect = isDarkModeTheme ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }
    
    /// 需要在 will appear 之后，不然 presentingViewController 的值可能不准确
    func addBackOrCloseButton() {
        guard backButton.superview == nil else { return }

        if hasBackPage {
            backButton.setImage(BundleResources.UDIconResources.leftOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            backButton.rx.controlEvent(.touchUpInside).observeOn(MainScheduler.instance).subscribe { [unowned self] (_) in
                if let pn = self.pageName() {
                    SuiteLoginTracker.track(Homeric.CLICK_BACK, params: ["from": pn])
                }
                self.clickBackOrClose(isBack: true)
            }.disposed(by: self.disposeBag)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(CL.itemSpace)
                let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
                var offset = (navigationBarHeight - BaseLayout.backHeight) / 2
                if offset < 0 {
                    offset = CL.backButtonTopSpace
                }
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(isPad && self.isInFormSheet ? CL.itemSpace : offset)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        } else if presentingViewController != nil {
            backButton.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
            backButton.rx.controlEvent(.touchUpInside).observeOn(MainScheduler.instance).subscribe { [unowned self] (_) in
                self.clickBackOrClose(isBack: false)
            }.disposed(by: self.disposeBag)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(CL.itemSpace)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(isPad && self.isInFormSheet ? CL.itemSpace : CL.backButtonTopSpace)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
        return super.touchesEnded(touches, with: event)
    }

    @objc
    func endEdit(gesture: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }

    @objc
    func panGesture(gesture: UIPanGestureRecognizer) {
        let maxOffsetY: CGFloat = inputAdjustView.contentSize.height - inputAdjustView.frame.height
        guard maxOffsetY > 0  else {
            // 不需要滚动
            return
        }

        if gesture.state == .began {
            beginOffset = inputAdjustView.contentOffset
        } else {
            let translationY = gesture.translation(in: view).y
            var offsetY = beginOffset.y - translationY

            let minOffsetY: CGFloat = 0

            if offsetY < minOffsetY {
                offsetY = minOffsetY
            } else if offsetY > maxOffsetY {
                offsetY = maxOffsetY
            }

            inputAdjustView.contentOffset = CGPoint(x: beginOffset.x, y: offsetY)
        }
    }
}

// MARK: set up
extension BaseViewController {

    func configInfo(_ title: String, detail: String) {
        configTopInfo(title, detail: NSAttributedString.tip(str: detail))
    }

    func configTopInfo(_ title: String, detail: NSAttributedString) {
        titleLabel.text = title
        let text = NSMutableAttributedString(attributedString: detail)
        text.adjustLineHeight()
        detailLabel.attributedText = text
    }

    func resetTitleFont() {
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        detailLabel.font = UIFont.systemFont(ofSize: 14)
    }

    private func setupBottomBtnView() {
        moveBoddyView.addSubview(bottomView)
        bottomView.addSubview(nextButton)
        nextButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview().inset(CL.itemSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }

        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(inputAdjustView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomViewBottomConstraint)
        }

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind { [weak self] (noti) in
                guard let self = self, self.isInViewAppearTime else { return }
                self.handleKeyboardWhenShow(noti)
            }.disposed(by: self.disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .bind { [weak self] (noti) in
                guard let self = self, self.isInViewAppearTime else { return }
                self.handleKeyboardWhenHide(noti)
            }.disposed(by: self.disposeBag)
    }

    func setupSwitchButton() {
        switchButtonContainer.addSubview(switchButton)
        switchButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(moveBoddyView).offset(CL.itemSpace)
            make.bottom.equalToSuperview()
        }
        switchButton.addTarget(self, action: #selector(switchAction), for: .touchUpInside)
    }
    
    /// iPadOS 16.1 起支持的 stage manager 场景，使 iPad 上页面的高度会小于屏幕高度
    /// 这里的适配参照了主端的逻辑，补充键盘相对屏幕的偏移
    /// https://code.byted.org/lark/ios-infra/blob/develop/Libs/LarkKeyboardView/src/Source/KeyboardPanel.swift
    func updateKeyboardHeightIfNeeded(keybaordToFrame toFrame: CGRect) -> CGFloat {
        if let window = self.view.window {
            let convertRect = self.view.convert(self.view.bounds, to: window)
            var windowOffSetY: CGFloat = 0
            if window.frame.height < UIScreen.main.bounds.height,
               Display.pad {
                let point = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
                windowOffSetY = point.y
            }
            
            let bottomY = windowOffSetY + window.frame.minY + convertRect.minY + convertRect.height
            return max(0, min(toFrame.maxY, bottomY) - toFrame.minY)
        } else {
            return toFrame.height
        }
    }

    /// 如果 iPad 模式下 界面会在屏幕中间 这时候 底部没有 safeArea 的距离 但约束是按照safeArea设置的，所以在计算时候要补偿下
    /// adjustedHeight < 0 不需要调节
    /// adjustedHeight > 0 调节 同时如果 window.frame.size.height > rect.maxY（飘起来了） 则需要补充safeAreaBottom
    func calculateAdjustKeyboardHeight(original: CGFloat, min: CGFloat) -> CGFloat {
        if Display.pad, let window = self.view.window {
            let rect = self.view.convert(self.view.frame, to: window)
            let adjustedHeight = original - (window.frame.size.height - rect.maxY)
            if adjustedHeight > 0 {
                return adjustedHeight + (window.frame.size.height > rect.maxY ? self.safeAreaBottom : 0)
            } else {
                return min
            }
        } else {
            return original
        }
    }
}

extension BaseViewController: ErrorHandler, BaseViewControllerLoadingProtocol {

    func showLoading() {
        SuiteLoginUtil.runOnMain {
            // 目前用全局loading替换了
            self.view.endEditing(true)
            if self.useHUDLoading {
                self.loadingHUD = RoundedHUD.showLoading(on: self.view)
            } else {
//                self.loadingMaskView.isHidden = false
//                self.view.bringSubviewToFront(self.loadingMaskView)
//                self.loadingView.play()
                UDToast.showDefaultLoading(on: self.view)
            }
        }
    }

    func stopLoading() {
        SuiteLoginUtil.runOnMain {
            if self.useHUDLoading {
                self.loadingHUD?.remove()
                self.loadingHUD = nil
            } else {
//                self.loadingView.stop()
//                self.loadingMaskView.isHidden = true
                UDToast.removeToast(on: self.view)
            }
        }
    }

    @objc
    func handle(_ error: Error) {
        errorHandler.handle(error)
        stopLoading()
    }

    func setupLoading() {
        view.addSubview(loadingMaskView)
        loadingMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    static func createLoadingMaskView(_ loading: LOTAnimationView) -> UIView {
        let mask = UIView()
        mask.isHidden = true
        mask.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        let loadingView = UIView()
        loadingView.backgroundColor = .black
        let loadingBgColor: CGFloat = 199.0 / 255.0
        loadingView.layer.shadowColor = UIColor(red: loadingBgColor,
                                                green: loadingBgColor,
                                                blue: loadingBgColor, alpha: 0.5).cgColor
        loadingView.layer.opacity = 0.5
        loadingView.layer.cornerRadius = Common.Layer.commonAlertViewRadius
        mask.addSubview(loadingView)
        loadingView.addSubview(loading)
        loadingView.snp.makeConstraints({ (make) in
            make.size.equalTo(CGSize(width: BaseLayout.loadingMaskWidth,
                                     height: BaseLayout.loadingMaskWidth))
            make.center.equalToSuperview()
        })
        loading.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: BaseLayout.loadingWidth,
                                     height: BaseLayout.loadingWidth))
        })
        return mask
    }

    static func createLoading() -> LOTAnimationView {
        // swiftlint:disable ForceUnwrapping
        let loading = LOTAnimationView(filePath: BundleConfig.LarkAccountBundle.path(forResource: "data", ofType: "json", inDirectory: "Lottie/button_loading")!)
        // swiftlint:enable ForceUnwrapping

        loading.backgroundColor = .clear
        loading.isUserInteractionEnabled = false
        loading.loopAnimation = true
        return loading
    }
}

extension BaseViewController {
    struct BaseLayout {
        static let loadingWidth: CGFloat = 30
        static let adjustViewTop: CGFloat = 64
        static let titleLabelTop: CGFloat = 28
        static let titleLabelHeight: CGFloat = 34
        static let loadingMaskWidth: CGFloat = 75
        static let detailLabelTop: CGFloat = 8
        static let centerInputTop: CGFloat = 30
        static let centerInputTop2: CGFloat = 24
        static let deatailLabelbottom: CGFloat = 12
        static let backHeight: CGFloat = 24
        static let visualNaviBarHeight: CGFloat = 44
    }
}

extension BaseViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let linkLabel = textView as? LinkClickableLabel {
            if linkLabel.tapPosition < characterRange.lowerBound ||
            linkLabel.tapPosition >= characterRange.upperBound {
                logger.debug("textView tapPosition out of response range")
                return false
            }
        }
        if interaction == .invokeDefaultAction {
            handleClickLink(URL, textView: textView)
        }
        return false
    }

    @objc
    func handleClickLink(_ URL: URL, textView: UITextView) {
        BaseViewController.clickLink(
            URL,
            serverInfo: viewModel.stepInfo,
            vm: viewModel,
            vc: self,
            errorHandler: self
        )
    }

    static func clickLink(_ URL: URL, serverInfo: ServerInfo? = nil, vm: V3ViewModel, vc: UIViewController, errorHandler: ErrorHandler) {
        let absoluteUrl: String
        if var urlComponents = URLComponents(url: URL, resolvingAgainstBaseURL: false) {
            urlComponents.queryItems = nil
            absoluteUrl = urlComponents.url?.absoluteString ?? ""
        } else {
            absoluteUrl = URL.absoluteString
            V3ViewModel.logger.error("url: \(absoluteUrl) can not transform to components")
        }
        SuiteLoginTracker.track(
            Homeric.PASSPORT_CLICK_LINK,
            params: [
                "url": absoluteUrl,
                "from": vm.step
        ])
        vc.view.endEditing(true)
        if let stepRaw = URL.host,
           PassportStep(rawValue: stepRaw) != nil,
            let theServerInfo = serverInfo {
            let nextServerInfo = theServerInfo.nextServerInfo(for: stepRaw)
            vm.post(
                event: stepRaw,
                serverInfo: nextServerInfo,
                success: {},
                error: { err in
                    errorHandler.handle(err)
                })
        } else {
            func postWeb() {
                vm.post(
                    event: V3NativeStep.simpleWeb.rawValue,
                    serverInfo: nil,
                    additionalInfo: V3SimpleWebInfo(url: URL),
                    success: {},
                    error: { err in
                        errorHandler.handle(err)
                    })
            }
            if vc.presentedViewController != nil {
                vc.dismiss(animated: true, completion: {
                    postWeb()
                })
            } else {
                postWeb()
            }
        }
    }
}

extension LarkAlertController {

    func setFixedWidthContent(view: UIView) {
        let contentWidth = Common.Alert.contentWidth
        let contentPadding = Common.Alert.contentPadding
        let container = UIView()
        container.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.width.equalTo(contentWidth - contentPadding.left - contentPadding.right).priority(.high)
            make.edges.equalToSuperview()
        }
        setContent(view: container, padding: contentPadding)
    }

    func setFixedWidthContent(text: String,
                              color: UIColor = UIColor.ud.textTitle,
                            font: UIFont = UIFont.systemFont(ofSize: 16),
                            alignment: NSTextAlignment = .center,
                            lineSpacing: CGFloat = 4,
                            numberOfLines: Int = 0) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color
        ]
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: text, attributes: attributes)

        setFixedWidthContent(view: label)
    }
}

extension BaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

extension UIViewController {
    var isModal: Bool {
        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}

private var closeAllStartPointKey: Void?
extension UIViewController {
    var closeAllStartPoint: Bool {
        get {
            objc_getAssociatedObject(self, &closeAllStartPointKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &closeAllStartPointKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
