//
//  CertBaseViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import Lottie
import ByteViewCommon
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast

let kHProportion: CGFloat = 1

protocol BaseViewControllerLoadingProtocol {
    func showLoading()
    func stopLoading()
}

class CertBaseViewController: UIViewController {

    let certLogger = Logger.cert
    // 控制使用 HUD 的 Loading
    var useHUDLoading: Bool = false
    // 是否使用自定义Navi动画
    var useCustomNavAnimation: Bool = true

    let viewModel: CertBaseViewModel

    init(viewModel: CertBaseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    var horizontalSafeAeraTarget: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide
    }

    var viewTopConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.top
    }

    var viewBottomConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.bottom
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
        titleLabel.font = UIFont.systemFont(ofSize: 26 * kHProportion, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    /// 副标题
    lazy var detailLabel: UITextView = {
        let detailLabel = LinkClickableLabel.default(with: self)
        detailLabel.textContainer.maximumNumberOfLines = 3
        detailLabel.font = UIFont.systemFont(ofSize: 14 * kHProportion)
        detailLabel.textColor = UIColor.ud.textTitle
        detailLabel.textContainerInset = .zero
        detailLabel.textContainer.lineFragmentPadding = 0
        return detailLabel
    }()

    lazy private var loadingMaskView: UIView = {
        return CertBaseViewController.createLoadingMaskView(loadingView)
    }()

    lazy private var loadingView: LOTAnimationView = {
        return CertBaseViewController.createLoading()
    }()

    private var loadingHUD: UDToast?

    var isPad: Bool { Display.pad }

    // 根据页面层级 willAppear 阶段自动生成
    private lazy var backButton = { UIButton(type: .custom) }()

    /// 下一步按钮
    lazy var nextButton: NextButton = {
        let btn = NextButton(title: "")
        btn.isEnabled = false
        return btn
    }()

    /// 底部视图 默认只有下一步
    lazy var bottomView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.clear
        return v
    }()

    /// 输入调整避免键盘遮挡
    lazy var inputAdjustView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.isScrollEnabled = true
        v.addGestureRecognizer(inputTapGesture)
        return v
    }()

    lazy var inputTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(endEdit(gesture:)))

    /// 中间输入界面（不能被键盘弹起遮挡的部分）放置输入框等，配合下一步按钮布局
    var centerInputView: UIView = UIView()

    func needBottmBtnView() -> Bool {
        return onlyNavUI() ? false : true
    }

    var needSkipWhilePop: Bool { false }

    func needPanGesture() -> Bool { isPad }

    func pageName() -> String? { nil }

    private var beginOffset: CGPoint = .zero

    /// initial offset while keyboard show
    var keyboardShowBottomViewOffset: CGFloat {
        if let w = self.view.window {
            return w.safeAreaInsets.bottom + BaseLayout.itemSpace - BaseLayout.bottomMargin
        } else {
            return self.view.safeAreaInsets.bottom + BaseLayout.itemSpace - BaseLayout.bottomMargin
        }
    }

    func clickBack() {}

    func onlyNavUI() -> Bool { false }

    func setBackBtnHidden(_ hidden: Bool) {
        backButton.isHidden = hidden
    }

    func handle(_ error: Error) {
        stopLoading()
    }
}

// MARK: LifeCycle
extension CertBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.clipsToBounds = true

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

        moveBoddyView.snp.makeConstraints { (make) in
            if isPad {
                make.top.bottom.equalToSuperview()
                make.left.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.left)
                make.right.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.right)
                // will broken while use split screen with 320pt width on ipad
                make.width.equalTo(BaseLayout.padViewPrefferredWidth)
                make.centerX.equalToSuperview()
            } else {
                make.top.bottom.equalToSuperview()
                make.left.right.equalTo(horizontalSafeAeraTarget)
            }
        }

        inputAdjustView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }

        centerInputView.snp.makeConstraints { (make) in
            make.top.equalTo(detailLabel.snp.bottom).offset(BaseLayout.centerInputTop)
            make.left.right.equalTo(moveBoddyView)
            make.height.equalTo(0).priority(.low)   // 高度由内容撑 默认高度0
            make.bottom.lessThanOrEqualToSuperview().inset(BaseLayout.itemSpace)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(BaseLayout.titleLabelTop)
            make.left.equalTo(moveBoddyView).offset(BaseLayout.itemSpace)
            make.right.lessThanOrEqualTo(moveBoddyView).inset(BaseLayout.itemSpace)
            make.height.greaterThanOrEqualTo(BaseLayout.titleLabelHeight)
        }

        detailLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(moveBoddyView).inset(BaseLayout.itemSpace)
            make.top.equalTo(titleLabel.snp.bottom).offset(BaseLayout.detailLabelTop)
        }

        if needBottmBtnView() {
            setupBottomBtnView()
        }
    }

    /// 需要在 will appear 之后，不然 presentingViewController 的值可能不准确
    func addBackOrCloseButton() {
        guard backButton.superview == nil else { return }
        if let vcs = navigationController?.viewControllers, vcs.contains(self), vcs.first != self {
            backButton.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
            backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(BaseLayout.itemSpace)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.backButtonTopSpace)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        } else if presentingViewController != nil {
            backButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
            backButton.addTarget(self, action: #selector(didClickClose), for: .touchUpInside)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(BaseLayout.itemSpace)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.backButtonTopSpace)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        addBackOrCloseButton()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        return super.touchesEnded(touches, with: event)
    }

    @objc
    func endEdit(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
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

    @objc private func didClickBack() {
        self.clickBack()
        self.navigationController?.popViewController(animated: true)
    }

    @objc func didClickClose() {
        self.viewModel.clickClose()
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: set up
extension CertBaseViewController {

    func configTopInfo(_ title: String, detail: NSAttributedString) {
        titleLabel.text = title
        let text = NSMutableAttributedString(attributedString: detail)
        text.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle], range: NSRange(location: 0, length: detail.string.count))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        text.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.length))

        detailLabel.attributedText = text
    }

    private func setupBottomBtnView() {
        moveBoddyView.addSubview(bottomView)
        bottomView.addSubview(nextButton)
        nextButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview().inset(BaseLayout.itemSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight)
        }

        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(inputAdjustView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(viewBottomConstraint)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        func adjust(orignalHeight: CGFloat) {
            let keyboardHeight = self.calculateAdjustKeyboardHeight(original: orignalHeight, min: self.keyboardShowBottomViewOffset)
            self.bottomView.snp.updateConstraints({ (make) in
                // 只留下 nextButton.height + BaseLayout.bottomMargin
                make.bottom.equalTo(self.viewBottomConstraint).offset(-(keyboardHeight - self.keyboardShowBottomViewOffset))
            })
            self.view.layoutIfNeeded()
            if self.inputAdjustView.contentSize.height > self.inputAdjustView.frame.height {
                self.inputAdjustView.contentOffset = CGPoint(x: 0, y: self.inputAdjustView.contentSize.height - self.inputAdjustView.frame.height)
            }
        }

        if let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if Display.pad {
                /*
                 iPad modalPresentationStyle = formSheet，横屏下。
                 self.view会往上移动，但是要等动画设置完成才知道移动的目标位置，所以增加了Dispatch，获取移动的目标位置。
                 Dispatch之后，除了系统执行的动画作用域，会缺少位移动画，增加读取键盘动画配置进行动画。
                 */
                let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
                let animationOptions = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
                DispatchQueue.main.async {
                    UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationOptions << 16),
                                   animations: { adjust(orignalHeight: keyboardSize.height) }, completion: nil)
                }
            } else {
                adjust(orignalHeight: keyboardSize.height)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        self.bottomView.snp.updateConstraints { (make) in
            make.bottom.equalTo(self.viewBottomConstraint)
        }
        self.view.layoutIfNeeded()
    }

    /// 如果 iPad 模式下 界面会在屏幕中间 这时候 底部没有 safeArea 的距离 但约束是按照safeArea设置的，所以在计算时候要补偿下
    /// adjustedHeight < 0 不需要调节
    /// adjustedHeight > 0 调节 同时如果 window.frame.size.height > rect.maxY（飘起来了） 则需要补充safeAreaBottom
    func calculateAdjustKeyboardHeight(original: CGFloat, min: CGFloat) -> CGFloat {
        if Display.pad, let window = self.view.window {
            let rect = self.view.convert(self.view.frame, to: window)
            let adjustedHeight = original - (window.frame.size.height - rect.maxY)
            if adjustedHeight > 0 {
                return adjustedHeight + (window.frame.size.height > rect.maxY ? window.safeAreaInsets.bottom : 0)
            } else {
                return min
            }
        } else {
            return original
        }
    }
}

extension CertBaseViewController: BaseViewControllerLoadingProtocol {

    func showLoading() {
        DispatchQueue.main.async {
            // 目前用全局loading替换了
            self.view.endEditing(true)
            if self.useHUDLoading {
                self.loadingHUD = UDToast.showLoading(with: "", on: self.view)
            } else {
                self.loadingMaskView.isHidden = false
                self.view.bringSubviewToFront(self.loadingMaskView)
                self.loadingView.play()
            }
        }
    }

    func stopLoading() {
        DispatchQueue.main.async {
            if self.useHUDLoading {
                self.loadingHUD?.remove()
                self.loadingHUD = nil
            } else {
                self.loadingView.stop()
                self.loadingMaskView.isHidden = true
            }
        }
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
        mask.backgroundColor = UIColor.ud.bgMask
        let loadingView = UIView()
        loadingView.backgroundColor = .black
        let loadingBgColor: CGFloat = 199.0 / 255.0
        loadingView.layer.ud.setShadowColor(UIColor(red: loadingBgColor,
                                                green: loadingBgColor,
                                                blue: loadingBgColor, alpha: 0.5))
        loadingView.layer.opacity = 0.5
        loadingView.layer.cornerRadius = 9.0
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
        let loading = LOTAnimationView(name: "button_loading", bundle: BundleConfig.ByteViewLiveCertBundle)
        loading.backgroundColor = .clear
        loading.isUserInteractionEnabled = false
        loading.loopAnimation = true
        return loading
    }
}

extension CertBaseViewController {
    struct BaseLayout {
        static let loadingWidth: CGFloat = 30
        static let titleLabelTop: CGFloat = 82
        static let titleLabelHeight: CGFloat = 34
        static let loadingMaskWidth: CGFloat = 75
        static let detailLabelTop: CGFloat = 10
        static let centerInputTop: CGFloat = 32
        static let backHeight: CGFloat = 24

        static let bottomMargin: CGFloat = 10
        static let itemSpace: CGFloat = 16
        static let backButtonTopSpace: CGFloat = 10
        static let padViewPrefferredWidth: CGFloat = 480
    }
}

extension CertBaseViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let linkLabel = textView as? LinkClickableLabel {
            if linkLabel.tapPosition < characterRange.lowerBound ||
            linkLabel.tapPosition >= characterRange.upperBound {
                certLogger.debug("textView tapPosition out of response range")
                return false
            }
        }
        if interaction == .invokeDefaultAction {
            self.view.endEditing(true)
        }
        return false
    }
}
