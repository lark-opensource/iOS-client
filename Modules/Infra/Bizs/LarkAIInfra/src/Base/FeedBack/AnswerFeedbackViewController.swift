//
//  AnswerFeedbackViewController.swift
//  LarkAIInfra
//
//  Created by 李勇 on 2023/6/16.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import RxCocoa
import EditTextView
import EENavigator
import LarkUIKit
import RustPB
import LKCommonsLogging
import ServerPB
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignInput

final class AnswerFeedbackViewController: UIViewController {
    static let logger = Logger.log(AnswerFeedbackViewController.self, category: "Module.IM.LarkAI")

    /// naviBar + contentScrollView
    private let contentView = UIView()
    /// 导航栏
    private lazy var naviBar: UIView = {
        let naviBar = UIView()
        // 标题
        let titleLabel = UILabel()
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkAIInfra.MyAI_IM_SubmitFeedback_Title
        // 取消按钮
        let cancelButton = UIButton()
        cancelButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        cancelButton.addTarget(self, action: #selector(cancelPage), for: .touchUpInside)
        cancelButton.setImage(UDIcon.closeSmallOutlined, for: .normal)
        // 添加进导航栏
        naviBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        naviBar.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.height.width.equalTo(24)
            $0.left.equalTo(16)
        }
        return naviBar
    }()
    /// _stackView + policyView + sendButton
    private let contentScrollView = UIScrollView()
    /// reasonView + feedBackView
    private let _stackView = UIStackView()
    private let policyView = UITextView()
    private lazy var sendButton: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear, backgroundColor: UIColor.ud.primaryFillDefault, textColor: UIColor.ud.primaryOnPrimaryFill)
        var config = UDButtonUIConifg(normalColor: normalColor)
        config.pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear, backgroundColor: UIColor.ud.primaryFillPressed, textColor: UIColor.ud.primaryOnPrimaryFill)
        config.loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear, backgroundColor: UIColor.ud.primaryFillHover, textColor: UIColor.ud.primaryOnPrimaryFill)
        config.disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear, backgroundColor: UIColor.ud.fillDisabled, textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        config.loadingIconColor = UIColor.ud.staticWhite
        config.radiusStyle = .square
        config.type = .big
        let udButton = UDButton(config)
        udButton.setTitle(BundleI18n.LarkAIInfra.MyAI_IM_SubmitFeedback_Submit_Button, for: .normal)
        udButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        udButton.layer.masksToBounds = true
        return udButton
    }()

    private let viewModel: AnswerFeedbackViewModel

    // MARK: - Life Cycle
    init(viewModel: AnswerFeedbackViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(notification:)), name: Self.keyboardWillChangeFrameNotification, object: nil)
        // 添加黑色背景蒙层
        self.buildBackgroundView()
        // 构造内容区域
        self.buildContentView()
        // 从settings获取反馈原因
        self.viewModel.loadReasons { [weak self] reasons in
            guard let `self` = self else { return }
            self.reasonView.reasons = reasons
            // 主动触发一次viewDidLayoutSubviews
            self.view.setNeedsLayout()
            self.lastWidth = -1
            self.view.layoutIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    /// lastWidth用于首次布局、从远端拉取原因后，更新一次高度
    private var lastWidth: CGFloat = -1
    override func viewDidLayoutSubviews() {
        let width = view.bounds.width
        if lastWidth == width {
            super.viewDidLayoutSubviews()
            return
        }
        lastWidth = width
        policyViewHeight?.update(offset: policyView.contentSize.height)
        updateReasonViewHeight()
        super.viewDidLayoutSubviews()
    }

    // MARK: - UI
    /// 添加一个背景视图，点击后退出当前界面
    private func buildBackgroundView() {
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(cancelPage))
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(backgroundView)
        backgroundView.addGestureRecognizer(exitGesture)
        // iPhone上，底部安全区域会有一块系统的黑色视图，我们需要手动遮盖
        if !Display.pad {
            let safeAreaMaskBG = UIView()
            safeAreaMaskBG.backgroundColor = UIColor.ud.bgBody
            self.view.addSubview(safeAreaMaskBG)
            safeAreaMaskBG.snp.makeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                $0.bottom.equalToSuperview()
            }
        }
    }
    /// 构造内容区域
    private func buildContentView() {
        contentView.backgroundColor = UIColor.ud.bgBody
        if Display.pad {
            contentView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 12.0)
        } else {
            contentView.roundCorners(corners: [.topLeft, .topRight], radius: 12.0)
        }
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            // ipad上居中展示
            if Display.pad {
                $0.centerX.equalToSuperview()
                // 设置宽度小于等于540（默认的formsheet的宽度），设置lessThanOrEqualTo是因为有的iPad分屏宽度会小于540；需要配合设置left.right和父视图相等，否则宽度无法拉到540，只有内容的宽度
                // 测试发现如果width、left.right都不设置priority，默认priority为1000，那么width会不生效，所以这里把left.right的priority调低
                $0.width.lessThanOrEqualTo(540); $0.left.right.equalToSuperview().priority(900)
                // centerYWithinMargins是top和bottom的中心，因为bottom设置为了view.safeAreaLayoutGuide.bottom，所以view.safeAreaLayoutGuide.bottom如果变高了，那么视图整体会向上移动
                // 设置centerY.equalToSuperview()就是view的中心，并不会跟着view.safeAreaLayoutGuide.bottom调整
                $0.centerYWithinMargins.equalToSuperview()
                $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            } else {
                // 高度自适应，iPhone上自底向上
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            // 顶部留一定的空白，模拟sheet的效果，测试发现当top和bottom冲突时，会优先bottom
            $0.top.greaterThanOrEqualTo(44)
        }

        var frame = contentView.bounds
        frame.size.height = 48
        naviBar.frame = frame
        naviBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        contentView.addSubview(naviBar)

        contentView.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints {
            $0.top.equalTo(naviBar.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
            // 高度自适应, 键盘弹起时可能会被压缩高度；当高度被压缩时，scrollViewHeight这个值感觉和设置contentSize.height一样的效果，但本身的frame.height是被压缩的
            scrollViewHeight = $0.height.equalTo(0).priority(700).constraint
        }

        buildStackViewInScrollView()
        contentScrollView.addSubview(_stackView)
        _stackView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview() // contentSize自适应, 高度自适应
            $0.width.equalToSuperview()
        }
        buildPolicyView()
        contentScrollView.addSubview(policyView)
        policyView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalTo(_stackView.snp.bottom).offset(26)
            policyViewHeight = $0.height.equalTo(0).constraint
        }
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        contentScrollView.addSubview(sendButton)
        sendButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalTo(policyView.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().inset(8)
        }
    }
    /// 反馈原因
    private var reasonView = AnswerFeedbackReasonView()
    /// 用户输入内容
    private var feedBackView = UDMultilineTextField()
    private func buildStackViewInScrollView() {
        _stackView.axis = .vertical
        // 垂直方向上item间的间隔
        _stackView.spacing = 26
        _stackView.layoutMargins = .init(top: 16, left: 0, bottom: 0, right: 0)
        _stackView.isLayoutMarginsRelativeArrangement = true
        _stackView.addArrangedSubview(reasonView)
        reasonView.snp.makeConstraints {
            $0.left.right.equalToSuperview() // reasonView内部会左右间距16
            reasonViewHeight = $0.height.equalTo(0).constraint
        }

        // 用户输入内容
        var config = UDMultilineTextFieldUIConfig()
        config.borderColor = .ud.lineBorderComponent
        config.isShowBorder = true
        config.backgroundColor = .clear
        config.placeholderColor = .ud.textPlaceholder
        config.font = UIFont.systemFont(ofSize: 16)
        config.textColor = .ud.textTitle
        feedBackView.config = config
        feedBackView.delegate = self
        feedBackView.isEditable = true
        feedBackView.placeholder = BundleI18n.LarkAIInfra.MyAI_IM_SubmitFeedback_Placeholder
        feedBackView.input.returnKeyType = .done
        feedBackView.layer.cornerRadius = 10.0
        _stackView.addArrangedSubview(feedBackView)
        feedBackView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(122)
        }
    }

    private func buildPolicyView() {
        var tipString: NSAttributedString {
            let string: String = BundleI18n.LarkAIInfra.MyAI_IM_SubmitFeedback_PrivacyDisclaimer_Text
            let paraph = NSMutableParagraphStyle()
            paraph.minimumLineHeight = 18
            paraph.maximumLineHeight = 18
            let stringAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paraph,
                .foregroundColor: UIColor.ud.textTitle]
            let tipString = NSMutableAttributedString(string: string, attributes: stringAttribute)
            return tipString
        }

        policyView.attributedText = tipString
        policyView.backgroundColor = .clear
        policyView.isEditable = false
        policyView.isSelectable = false
        policyView.textContainer.lineFragmentPadding = 0
        policyView.textContainerInset = .zero
        policyView.delegate = self
    }

    private var scrollViewHeight, policyViewHeight, reasonViewHeight: Constraint?
    private func updateReasonViewHeight() {
        let offset = contentScrollView.contentOffset
        UIView.performWithoutAnimation { // reason item不要动画
            reasonViewHeight?.update(offset: reasonView.doLayout(width: contentView.bounds.width))
            let size = contentScrollView.contentSize
            contentScrollView.layoutIfNeeded() // update _stackView.frame
            // 期望当前的内容不动，只是新出现的往上移动, 避免scrollView内的直接替换闪烁
            let newSize = contentScrollView.contentSize
            contentScrollView.contentOffset.y += newSize.height - size.height
        }
        contentScrollView.contentOffset = offset
        scrollViewHeight?.update(offset: _stackView.frame.height + 26 + policyView.frame.height + 8 + sendButton.frame.height + 8)
    }

    // MARK: - Private Function
    @objc
    private func send() {
        // showLoading时如果有title则不会隐藏tilte，需要手动清除
        self.sendButton.showLoading() //; self.sendButton.setTitle("", for: .normal); self.sendButton.layoutIfNeeded()
        self.viewModel.sendFeedBack(reasonIds: self.reasonView.selected.map({ $0.id }), content: self.feedBackView.text) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            guard let window = self?.view.window else { return }
            UDToast.showTips(with: BundleI18n.LarkAIInfra.MyAI_IM_FeedbackSubmitted_Toast, on: window)
        } onError: { [weak self] in
            guard let window = self?.view.window else { return }
            // hideLoading时恢复显示tilte
            self?.sendButton.hideLoading() //; self?.sendButton.setTitle(BundleI18n.LarkAI.MyAI_IM_SubmitFeedback_Submit_Button, for: .normal); self?.sendButton.layoutIfNeeded()
            UDToast.showTips(with: BundleI18n.LarkAIInfra.Lark_Legacy_NetworkOrServiceError, on: window)
        }
    }

    @objc
    private func keyboardChange(notification: NSNotification) {
        guard let kbFrame = notification.userInfo?[Self.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notification.userInfo?[Self.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { [self] in
            let originBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY + self.additionalSafeAreaInsets.bottom
            let kbFrame = self.view.convert(kbFrame, from: nil)
            // 这句话是关键，用于调整底部安全区域的高度，这样就可以做到把整个contentView往上滚了
            self.additionalSafeAreaInsets.bottom = max(originBottom - kbFrame.minY, 0)
            self.view.layoutIfNeeded()
            contentScrollView.scrollRectToVisible(feedBackView.convert(feedBackView.bounds, to: contentScrollView), animated: false)
        }
    }

    @objc
    private func cancelPage() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension AnswerFeedbackViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        Presentation(presentedViewController: presented, presenting: presenting ?? source)
    }
}
/// 主要是考虑到动画时机不一样。dimmingView是渐变的。而contentController是present出来的
/// 所以使用Presentation来管理背景View
final class Presentation: UIPresentationController {
    private let dimmingView = UIView()

    init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?,
                  backgroundColor: UIColor = UIColor.ud.bgMask) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = backgroundColor
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        dimmingView.alpha = 0
        if let containerView = containerView {
            containerView.addSubview(dimmingView)
            dimmingView.frame = containerView.bounds
        }
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = containerView {
            dimmingView.frame = containerView.bounds
        }
    }
}

// MARK: - UDMultilineTextFieldDelegate
extension AnswerFeedbackViewController: UDMultilineTextFieldDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 点击完成，则收起输入框
        if text == "\n" {
            self.view.endEditing(true)
            return false
        }
        return true
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
