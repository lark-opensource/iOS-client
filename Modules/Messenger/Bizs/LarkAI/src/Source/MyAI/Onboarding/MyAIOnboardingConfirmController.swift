//
//  MyAIOnboardingConfirmController.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/12.
//

import Lottie
import FigmaKit
import EENavigator
import LarkUIKit
import ByteWebImage
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast

class MyAIOnboardingConfirmController: BaseUIViewController {
    let viewModel: MyAIOnboardingViewModel

    // 使用 LayoutGuide 是为了做转场动画，确保两页的头像能够对齐
    /// `MyAIOnboardingInitController` 里顶部头像选择区域的布局
    private var avatarAreaLayoutGuide = UILayoutGuide()
    /// `MyAIOnboardingInitController` 上一页里底部头像与确认按钮区域的布局
    private var nameAreaLayoutGuide = UILayoutGuide()

    private var avatarAreaFinalLayoutGuide = UILayoutGuide()

    // 用来盛放 avatarView、shadowView、greetLabel 的容器
    // 容器整体居中防止
    private lazy var topContainer = UILayoutGuide()

    /// 用来给 avatarView 占位，并不实际展示
    private lazy var avatarPlaceholderView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    lazy var avatarView: AIAnimatedAvatarView = {
        let view = AIAnimatedAvatarView(avatarInfo: viewModel.currentAvatar,
                                        isDynamic: true,
                                        placeholder: viewModel.currentAvatarPlaceholderImage)
        return view
    }()

    /// 用来给 shadowView 占位，并不实际展示
    private lazy var shadowPlaceholderView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    lazy var shadowView: UIView = {
        let view = RadialGradientView()
        view.colors = shadowColors
        return view
    }()

    /// 用来给 greetLabel 占位，并不实际展示
    private lazy var greetPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = Cons.greetingLabelFont
        label.text = BundleI18n.LarkAI.MyAI_IM_Onboarding_Greeting_Text(name: viewModel.currentName)
        label.textColor = .clear
        label.backgroundColor = .systemGray.withAlphaComponent(0.1)
        label.isHidden = true
        return label
    }()

    lazy var greetLabel: TypingLabel = {
        let label = TypingLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = Cons.greetingLabelFont
        // 总动画时间设为 800ms
        label.totalTime = 0.8
        /* UX 又要按 Char 分词，这里暂时注掉
        // 自定义分词方法
        label.wordSeparator = { sentence in
            let words = sentence.components(separatedBy: " ")
            if words.count < 3 {
                let characters = Array(sentence).map { String($0) }
                return characters
            } else {
                var wordsWithSeparators: [String] = []
                for (index, element) in words.enumerated() {
                    wordsWithSeparators.append(element)
                    if index != words.count - 1 {
                        wordsWithSeparators.append(" ")
                    }
                }
                return wordsWithSeparators
            }
        }
         */
        return label
    }()

    lazy var agreeInfoLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    lazy var confirmButton: UIButton = {
        let button = AIUtils.makeAIButton()
        button.setTitle(BundleI18n.LarkAI.MyAI_IM_Onboarding_SaveActivateMyAI_Button, for: .normal)
        button.addTarget(self, action: #selector(onConfirmButtonClicked), for: .touchUpInside)
        // 支持多行显示
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        return button
    }()

    override var navigationBarStyle: NavigationBarStyle {
        if #available(iOS 16, *) {
            return .custom(UIColor.clear)
        } else {
            return .custom(UIColor.ud.bgBody)
        }
    }

    override func loadView() {
        view = AIUtils.makeAuroraBackgroundView()
    }

    init(viewModel: MyAIOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayoutGuide()
        setupSubviews()
        configAgreeLabel()
        view.backgroundColor = UIColor.ud.bgBody
        confirmButton.alpha = 0
        agreeInfoLabel.alpha = 0

        viewModel.reportOnboardingConfirmViewShown()
        closeCallback = { [weak self] in
            self?.viewModel.reportOnboardingConfirmCloseClicked()
        }
        backCallback = { [weak self] in
            self?.viewModel.reportOnboardingConfirmBackClicked()
        }
    }

    private func setupLayoutGuide() {
        view.addLayoutGuide(avatarAreaLayoutGuide)
        view.addLayoutGuide(nameAreaLayoutGuide)
        nameAreaLayoutGuide.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(MyAIOnboardingInitController.Cons.bottomAreaHeight)
        }
        avatarAreaLayoutGuide.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(nameAreaLayoutGuide.snp.top)
        }
    }

    private func setupSubviews() {
        view.addSubview(avatarView)
        view.addSubview(shadowView)
        view.addLayoutGuide(topContainer)
        view.addSubview(avatarPlaceholderView)
        view.addSubview(shadowPlaceholderView)
        view.addSubview(greetPlaceholderLabel)
        view.addSubview(greetLabel)
        view.addSubview(agreeInfoLabel)
        view.addSubview(confirmButton)
        view.addLayoutGuide(avatarAreaFinalLayoutGuide)
        // avatarView 起初先放置在和上一页同样的位置
        avatarView.snp.makeConstraints { make in
            make.center.equalTo(avatarAreaLayoutGuide)
            make.width.height.equalTo(AIAvatarPickerView.Cons.avatarMiddleSize)
        }
        shadowView.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(AIAvatarPickerView.Cons.shadowAvatarSpacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(AIAvatarPickerView.Cons.shadowMiddleWidth)
            make.height.equalTo(AIAvatarPickerView.Cons.shadowMiddleHeight)
        }
        avatarPlaceholderView.snp.makeConstraints { make in
            make.top.centerX.equalTo(topContainer)
            make.width.height.equalTo(AIAvatarPickerView.Cons.avatarLargeSize)
        }
        shadowPlaceholderView.snp.makeConstraints { make in
            make.top.equalTo(avatarPlaceholderView.snp.bottom).offset(AIAvatarPickerView.Cons.shadowAvatarSpacing)
            make.centerX.equalTo(avatarPlaceholderView)
            make.width.equalTo(AIAvatarPickerView.Cons.shadowLargeWidth)
            make.height.equalTo(AIAvatarPickerView.Cons.shadowLargeHeight)
        }
        greetPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalTo(shadowPlaceholderView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(MyAIOnboardingInitController.Config.leftRightMargin)
            make.right.lessThanOrEqualToSuperview().offset(-MyAIOnboardingInitController.Config.leftRightMargin)
            make.bottom.equalTo(topContainer)
        }
        greetLabel.snp.makeConstraints { make in
            make.top.left.right.equalTo(greetPlaceholderLabel)
        }
        topContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalTo(avatarAreaFinalLayoutGuide)
        }
        avatarAreaFinalLayoutGuide.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(agreeInfoLabel.snp.top).offset(-10)
        }
        agreeInfoLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(confirmButton)
            make.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        confirmButton.snp.makeConstraints { (make) in
            make.left.equalTo(MyAIOnboardingInitController.Config.leftRightMargin)
            make.right.equalTo(-MyAIOnboardingInitController.Config.leftRightMargin)
            make.height.greaterThanOrEqualTo(MyAIOnboardingInitController.Config.confimButtonHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MyAIOnboardingInitController.Config.bottomMargin)
        }
    }

    func animateToShow() {
        animateOfScaleAvatar { [weak self] in
            self?.playAvatarAnimation()
            self?.playGreetLabelAnimation { [weak self] in
                self?.animateOfShowConfirmButton()
            }
        }
    }

    //动画第一步：头像变大
    private func animateOfScaleAvatar(completion: (() -> Void)? = nil) {

        let avatarOffsetY = avatarView.frame.midY - avatarPlaceholderView.frame.midY
        let avatarScale = avatarPlaceholderView.frame.width / avatarView.frame.width

        let shadowOffsetY = shadowView.frame.midY - shadowPlaceholderView.frame.midY
        let shadowScaleX = AIAvatarPickerView.Cons.shadowLargeWidth / AIAvatarPickerView.Cons.shadowMiddleWidth
        let shadowScaleY = AIAvatarPickerView.Cons.shadowLargeHeight / AIAvatarPickerView.Cons.shadowMiddleHeight

        UIView.animate(withDuration: 0.6) { [weak self] in
            guard let self = self else { return }
            self.avatarView.transform = CGAffineTransform(translationX: 0, y: -avatarOffsetY)
                .scaledBy(x: avatarScale, y: avatarScale)
            self.shadowView.transform = CGAffineTransform(translationX: 0, y: -shadowOffsetY)
                .scaledBy(x: shadowScaleX, y: shadowScaleY)
        } completion: { _ in
            completion?()
        }
    }

    func playAvatarAnimation() {
        if viewModel.currentAvatar == .default {
            avatarView.playFinishDefault()
        } else {
            avatarView.playFinishAvatar()
        }
    }

    func playGreetLabelAnimation(completion: (() -> Void)? = nil) {
        let fullText = BundleI18n.LarkAI.MyAI_IM_Onboarding_Greeting_Text(name: viewModel.currentName)
        let availableWidth = view.bounds.width - MyAIOnboardingInitController.Config.leftRightMargin * 2
        let textOnelineWidth = fullText.getWidth(font: greetLabel.font)
        // 在 iOS13 上，用 textWidth 渲染的渐变色会差几像素，这里加个 buffer
        let textWidth = min(availableWidth, textOnelineWidth) + 6
        var textHeight = greetLabel.font.lineHeight
        if textOnelineWidth > availableWidth {
            textHeight = fullText.getHeight(withConstrainedWidth: availableWidth, font: greetLabel.font)
        }
        let textColor = UDColor.AIPrimaryContentDefault.toColor(withSize: CGSize(width: textWidth, height: textHeight * 1.2))
        greetLabel.text = fullText
        greetLabel.textColor = textColor
        greetLabel.textAlignment = .center
        greetLabel.onTypingAnimationFinished = completion
    }

    //动画第三步：
    func animateOfShowConfirmButton(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.agreeInfoLabel.alpha = 1
            self?.confirmButton.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    @objc
    private func onConfirmButtonClicked() {
        let toast = UDToast.showLoading(on: view, disableUserInteraction: true)
        viewModel.initMyAI(onSuccess: { [weak self] myAIID in
            guard let self = self else { return }
            toast.remove()
            self.navigationController?.dismiss(animated: true) { [weak self] in
                self?.viewModel.successCallback?(myAIID)
            }
        }, onFailure: { [weak self] error in
            guard let self = self else { return }
            toast.remove()
            if let apiError = error.underlyingError as? APIError, case .myAiAlreadyInitSuccess = apiError.type {
                // 重复 Onboarding，弹出错误提示，并关闭页面
                self.showError(apiError, shouldDismiss: true)
            } else {
                self.showError(error, shouldDismiss: false)
            }
            self.viewModel.failureCallback?(error)
        })
        viewModel.reportOnboardingConfirmFinishClicked()
    }

    private func showError(_ error: Error, fallbackMessage: String = "Onboarding failed", shouldDismiss: Bool) {
        UDToast.showFailure(with: fallbackMessage, on: view, error: error)
        if shouldDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.navigationController?.dismiss(animated: true)
            }
        }
    }

    private func configAgreeLabel() {
        var linkText = ""
        var fullText = ""
        let aiBrandName = MyAIResourceManager.getMyAIBrandNameFromSetting(userResolver: viewModel.userResolver)
        if let isFeishu = viewModel.passportService?.isFeishuBrand, isFeishu {
            // 租户是飞书品牌
            let tenant = BundleI18n.LarkAI.MyAI_Tenant_Feishu
            linkText = BundleI18n.LarkAI.MyAI_IM_FeishuOnboardingDisclaimer_Agreement_aiName_Text(tenant)
            fullText = BundleI18n.LarkAI.MyAI_IM_FeishuOnboardingDisclaimer_aiName_Text(aiBrandName, tenant, linkText)
        } else {
            // 租户是 Lark 品牌
            let tenant = BundleI18n.LarkAI.MyAI_Tenant_Lark
            linkText = BundleI18n.LarkAI.MyAI_Onboarding_UserActivationDisclaimerLinkAddress_aiName_Text(tenantName: tenant)
            fullText = BundleI18n.LarkAI.MyAI_Onboarding_UserActivationDisclaimerNoLink_aiName_Text(aiBrandName, linkText)
        }
        let font = Cons.agreementLabelFont
        let lineHeight: CGFloat = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        if let linkURL = MyAIResourceManager.serviceTermsURL {
            agreeInfoLabel.addTapGesture(
                text: fullText,
                textAttributes: [
                    .font: Cons.agreementLabelFont,
                    .foregroundColor: Cons.agreementTextColor,
                    .paragraphStyle: mutableParagraphStyle,
                    .baselineOffset: baselineOffset],
                tapOnText: linkText,
                tapOnTextAttributes: [
                    .font: Cons.agreementLabelFont,
                    .foregroundColor: Cons.agreementLinkColor,
                    .paragraphStyle: mutableParagraphStyle,
                    .baselineOffset: baselineOffset]
            ) { [weak self] in
                guard let `self` = self else { return }
                // 用浏览器打开 Service Terms 页面
                self.viewModel.userResolver.navigator.push(linkURL, from: self)
            }
        } else {
            agreeInfoLabel.font = Cons.agreementLabelFont
            agreeInfoLabel.textColor = Cons.agreementTextColor
            agreeInfoLabel.text = fullText
        }
    }
}

extension MyAIOnboardingConfirmController: CustomNaviAnimation {

    func selfPushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MyAIOnboardingTransition(type: .push)
    }

    func selfPopAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MyAIOnboardingTransition(type: .pop)
    }
}

extension MyAIOnboardingConfirmController {

    private enum Cons {
        static var greetingLabelFont: UIFont { UIFont.ud.title0(.fixed) }
        static var agreementLabelFont: UIFont { UIFont.ud.caption1(.fixed) }
        static var agreementTextColor: UIColor { UIColor.ud.textCaption }
        static var agreementLinkColor: UIColor { UIColor.ud.textLinkNormal }
    }
}
