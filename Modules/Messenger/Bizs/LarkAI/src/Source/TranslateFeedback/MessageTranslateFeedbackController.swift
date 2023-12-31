//
//  MessageTranslateFeedBackController.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/24.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import LarkModel
import LarkSDKInterface
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import RustPB
import LarkUIKit
import SnapKit
import UniverseDesignCheckBox
import UniverseDesignButton
import UniverseDesignEmpty
import LarkContainer

private enum UI {
    static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    static let feedbackCommonFont: CGFloat = 14
    static let headerHeight: CGFloat = 48
    static let scoreViewHeight: CGFloat = 80
    // 翻译建议输入视图
    static let translateSuggestionViewTop: CGFloat = 20
    // 发送按钮 和 隐私协议
    static let sendButtonHeight: CGFloat = 48
    static let sendButtonMargin: CGFloat = 16
}

let policyLink: String = "policyLink"
let seviceLink: String = "seviceLink"

final class MessageTranslateFeedbackController: UIViewController, UIViewControllerTransitioningDelegate, UserResolverWrapper {
    /// 翻译服务
    private let translateService: TranslateFeedbackService
    /// 用户相关配置
    private let userAppConfig: UserAppConfig
    /// 复制权限相关配置
    private let copyConfig: TranslateCopyConfig
    /// 发送反馈成功的回调
    private let successBlock: (() -> Void)?
    /// 发送反馈失败的回调
    private let failBlock: (() -> Void)?
    /// 点击×号、dismiss的回调
    private let cancelBlock: (() -> Void)?
    /// 用户是否编辑了译文建议
    @objc dynamic private var isEditTranslateSuggestion: Bool = false
    /// 翻译的评分 -1代表用户未评分
    @objc dynamic private var translateScore: Int = -1
    /// 判断键盘是否存在
    private var keyBoardShow: Bool = false
    private let disposeBag = DisposeBag()
    // 选择的文本
    private let selectText: String
    // 翻译的文本
    private let translateText: String
    // 源语言
    private let originLanguage: String
    // 目标语言
    private var targetLanguage: String
    // 是否划词翻译
    private var isSelectMode: Bool
    // 消息翻译时使用
    private var message: Message?

    /// 埋点需要的参数
    private var trackParam: [String: Any] = [:]
    let userResolver: UserResolver
    init(userResolver: UserResolver,
                translateService: TranslateFeedbackService,
                selectText: String = "",
                translateText: String = "",
                originLanguage: String = "",
                targetLanguage: String = "",
                isSelectTranslate: Bool = false,
                message: Message? = nil,
                userAppConfig: UserAppConfig,
                copyConfig: TranslateCopyConfig = TranslateCopyConfig(),
                successBlock: (() -> Void)? = nil,
                failBlock: (() -> Void)? = nil,
                cancelBlock: (() -> Void)? = nil,
                trackParam: [String: Any] = [:]) {
        self.userResolver = userResolver
        self.translateService = translateService
        self.selectText = selectText
        self.translateText = translateText
        self.originLanguage = originLanguage
        self.targetLanguage = targetLanguage
        self.isSelectMode = isSelectTranslate
        self.message = message
        self.userAppConfig = userAppConfig
        self.copyConfig = copyConfig
        self.successBlock = successBlock
        self.failBlock = failBlock
        self.cancelBlock = cancelBlock
        self.trackParam = trackParam
        super.init(nibName: nil, bundle: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(notification:)), name: Self.keyboardWillChangeFrameNotification, object: nil)
        /// 添加蒙层消失手势

        buildBackgroundView()

        tipTextView.attributedText = tipString
        tipTextView.backgroundColor = .clear
        tipTextView.isEditable = false
        tipTextView.isSelectable = true
        tipTextView.textContainer.lineFragmentPadding = 0
        tipTextView.textContainerInset = .zero
        tipTextView.delegate = self
        /// 布局子视图
        layoutSubViews()
        /// 注册事件
        registerEvent()
        addKeyboardEvent()
        //设置是否可防截图
        captureShieldUtil.setCaptureAllowed(copyConfig.canCopy)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 导航条隐藏需要放在这里，不然从隐私策略、用户协议回来之后，导航条会再次展示出来
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    var lastWidth: CGFloat = -1
    override func viewDidLayoutSubviews() {
        let width = view.bounds.width
        if lastWidth == width {
            super.viewDidLayoutSubviews()
            return
        }
        lastWidth = width
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 3
        let tipHeight = tipString.string.getTextViewHeight(textViewWidth: contentView.frame.width - 2 * UI.sendButtonMargin,
                                                           attributes: [.font: UIFont.systemFont(ofSize: UI.feedbackCommonFont), .paragraphStyle: paraph], textView: tipTextView)

        policyViewHeight?.update(offset: tipHeight)
        let translateSuggestionViewHeight = translateSuggestionView.calculateMessageContentHeight(width: contentView.frame.width)
        translateViewHeight?.update(offset: translateSuggestionViewHeight)
        scrollViewHeight?.update(offset: UI.scoreViewHeight + UI.translateSuggestionViewTop +
                                 translateSuggestionViewHeight + UI.sendButtonHeight + 2 * UI.sendButtonMargin + tipHeight)
        translateSuggestionView.originContentTextViewViewHeight?.update(offset: translateSuggestionView.originContentHeight)
        super.viewDidLayoutSubviews()
    }

    /// 点击蒙层的dismiss操作
    @objc
    func dismiss(_ gesture: UIGestureRecognizer) {
        dismiss(animated: true, completion: {
            self.cancelBlock?()
        })
    }

    /// 键盘监听
    @objc
    func keyboardChange(notification: Notification) {
        guard let kbFrame = notification.userInfo?[Self.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notification.userInfo?[Self.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { [self] in
            let originBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY + self.additionalSafeAreaInsets.bottom
            let kbFrame = self.view.convert(kbFrame, from: nil)
            self.additionalSafeAreaInsets.bottom = max(originBottom - kbFrame.minY, 0)
            self.view.layoutIfNeeded()
            bodyView.scrollToBottom()
        }
    }

    lazy var captureShieldUtil = CaptureShieldUtility()

    // MARK: LazyLoad
    /// 防截图container
    private lazy var basicContainerView: UIView = {
        return captureShieldUtil.contentView
    }()
    /// 内容视图
    private lazy var contentView: UIView = UIView()
    let containerView = UIView()
    var scrollViewHeight, policyViewHeight, translateViewHeight: Constraint?
    /// 头部视图 (标题 + 关闭按钮)
    private lazy var headerView: MessageTranslateFeedbackHeadView = {
        let headerView = MessageTranslateFeedbackHeadView(delegate: self)
        headerView.backgroundColor = UIColor.ud.bgBody
        return headerView
    }()
    /// 内容视图 （评分 + 翻译建议等）
    private lazy var bodyView: UIScrollView = {
        let bodyView = UIScrollView()
        bodyView.backgroundColor = UIColor.ud.bgBody
        return bodyView
    }()
    /// 评分视图
    private lazy var scoreView: MessageTranslateFeedbackScoreView = {
        let scoreView = MessageTranslateFeedbackScoreView(score: 0,
                                                          delegate: self,
                                                          isSelectMode: isSelectMode,
                                                          targetLanguage: targetLanguage,
                                                          trackParam: trackParam)
        return scoreView
    }()
    /// 翻译建议
    private lazy var translateSuggestionView: MessageTranslateFeedbackInputView = {
        let translateSuggestionView = MessageTranslateFeedbackInputView(userResolver: userResolver,
                                                                        selectText: selectText,
                                                                        translateText: translateText,
                                                                        delegate: self,
                                                                        message: message,
                                                                        copyConfig: copyConfig)
        return translateSuggestionView
    }()
    /// 提示文字内容
    private lazy var tipString: NSMutableAttributedString = {
        let string: String = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackPrivacyDesc
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 3
        let stringAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: UI.feedbackCommonFont),
            .paragraphStyle: paraph,
            .foregroundColor: UIColor.ud.textPlaceholder]
        var tipString: NSMutableAttributedString = NSMutableAttributedString(string: string, attributes: stringAttribute)
        return tipString
    }()
    /// 提示文字
    private var tipTextView = UITextView()
    /// 发送按钮
    private lazy var sendButton: UIButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.colorfulBlue,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        var config = UDButtonUIConifg(normalColor: normalColor)
        config.disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                          backgroundColor: UIColor.ud.fillDisabled,
                                                          textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        config.radiusStyle = .square
        config.type = .big
        let sendButton = UDButton(config)
        sendButton.setTitle(BundleI18n.LarkAI.Lark_Legacy_Send, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        sendButton.layer.masksToBounds = true
        sendButton.isEnabled = false
        return sendButton
    }()

    func addKeyboardEvent() {
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(stopEditing))
        self.contentView.addGestureRecognizer(exitGesture)
    }

    func buildBackgroundView() {
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(cancelPage))
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        backgroundView.addGestureRecognizer(exitGesture)

        if !Display.pad {
            let safeAreaMaskBG = UIView()
            safeAreaMaskBG.backgroundColor = UIColor.ud.bgFloat
            view.addSubview(safeAreaMaskBG)
            safeAreaMaskBG.snp.makeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                $0.bottom.equalToSuperview()
            }
        }
    }

    @objc
    private func stopEditing() {
        view.endEditing(true)
        MessageTranslateFeedbackTracker.translateFeedbackClick(messageID: trackParam["messageID"],
                                                               messageType: trackParam["messageType"],
                                                               srcLanguage: trackParam["srcLanguage"],
                                                               trgLanguage: trackParam["trgLanguage"],
                                                               cardSource: trackParam["cardSource"],
                                                               fromType: trackParam["fromType"],
                                                               clickType: "input",
                                                               extraParam: ["target": "translation"])
    }

    @objc
    private func cancelPage() {
        dismiss(animated: true, completion: nil)
    }
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        Presentation(presentedViewController: presented, presenting: presenting ?? source)
    }
}

extension MessageTranslateFeedbackController: MessageTranslateFeedbackHeadViewDelegate, MessageTranslateFeedbackScoreViewDelegate, MessageTranslateFeedbackInputViewDelegate, UITextViewDelegate {
    // MARK: MessageTranslateFeedBackHeadViewDelegate
    func cancelFeedback() {
        MessageTranslateFeedbackTracker.translateFeedbackClick(messageID: trackParam["messageID"],
                                                               messageType: trackParam["messageType"],
                                                               srcLanguage: trackParam["srcLanguage"],
                                                               trgLanguage: trackParam["trgLanguage"],
                                                               cardSource: trackParam["cardSource"],
                                                               fromType: trackParam["fromType"],
                                                               clickType: "cancel",
                                                               extraParam: ["target": "none"])
        dismiss(animated: true, completion: { [weak self] in
            self?.cancelBlock?()
        })
    }

    // MARK: MessageTranslateFeedBackScoreViewDelegate
    func userChooseScore(score: Int) {
        translateScore = score
    }

    // MARK: MessageTranslateFeedBackInputViewDelegate
    func translateContentBeginInput(contentView: UITextView) {
        guard !isEditTranslateSuggestion else { return }
        isEditTranslateSuggestion = true
    }
    //结束输入
    func translateContentEndInput(contentView: UITextView) {
    }

    // MARK: UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == policyLink {
            if let url = getUrl(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpPrivatePolicy) {
                navigator.push(url,
                               context: ["from": "translate_feedback"],
                               from: self)
            }
        } else if URL.absoluteString == seviceLink {
            if let url = getUrl(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpUserAgreement) {
                navigator.push(url,
                               context: ["from": "translate_feedback"],
                               from: self)
            }
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

}

private extension MessageTranslateFeedbackController {

    /// 布局子视图
    private func layoutSubViews() {
        view.addSubview(basicContainerView)
        basicContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.backgroundColor = UIColor.ud.bgBody
        if Display.pad {
            contentView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 16.0)
        } else {
            contentView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        }
        basicContainerView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview().priority(900)
            // iphone上全屏，ipad上居中展示
            if Display.pad {
                $0.width.lessThanOrEqualTo(540) // 默认的formsheet的宽度
                $0.centerYWithinMargins.equalToSuperview().priority(600) // FIXME: 分屏时，可能要换成iphone那种样式的
            } else {
                $0.bottom.equalToSuperview().priority(800)
            }
            // 高度自适应，iPhone上自底向上，ipad上居中
            if Display.pad {
                $0.top.greaterThanOrEqualTo(44) // 顶部留一定的空白，模拟sheet的效果
            } else {
                $0.top.greaterThanOrEqualTo(UI.screenHeight * 0.2)
            }
            $0.bottom.lessThanOrEqualTo(basicContainerView.safeAreaLayoutGuide)
        }

        contentView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(UI.headerHeight)
        }

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).priority(990)
            $0.left.right.bottom.equalToSuperview()
        }

        containerView.addSubview(bodyView)
        bodyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            // 高度自适应, 键盘弹起时可能需要压缩高度
            scrollViewHeight = $0.height.equalTo(0).priority(700).constraint
        }

        bodyView.addSubview(scoreView)
        scoreView.snp.makeConstraints { (make) in
            make.top.centerX.width.equalToSuperview()
            make.height.equalTo(UI.scoreViewHeight)
        }

        bodyView.addSubview(translateSuggestionView)
        translateSuggestionView.snp.makeConstraints { (make) in
            make.top.equalTo(scoreView.snp.bottom).offset(UI.translateSuggestionViewTop)
            make.left.width.equalToSuperview()
            translateViewHeight = make.height.equalTo(0).priority(translateSuggestionView.viewHeight).constraint
        }

        bodyView.addSubview(tipTextView)
        tipTextView.snp.makeConstraints { (make) in
            make.right.equalTo(translateSuggestionView.snp.right).inset(UI.sendButtonMargin)
            make.left.equalTo(translateSuggestionView.snp.left).inset(UI.sendButtonMargin)
            make.top.equalTo(translateSuggestionView.snp.bottom)
            policyViewHeight = make.height.equalTo(44).constraint
        }

        bodyView.addSubview(sendButton)
        sendButton.snp.makeConstraints { (make) in
            make.right.equalTo(translateSuggestionView.snp.right).inset(UI.sendButtonMargin)
            make.left.equalTo(translateSuggestionView.snp.left).inset(UI.sendButtonMargin)
            make.top.equalTo(tipTextView.snp.bottom).offset(UI.sendButtonMargin)
            make.bottom.equalToSuperview().offset(-UI.sendButtonMargin)
            make.height.equalTo(UI.sendButtonHeight)
        }
        if !Display.pad {
            var bottomView: UIView = UIView()
            bottomView.backgroundColor = .ud.bgBody
            view.addSubview(bottomView)
            bottomView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(contentView.snp.bottom)
            }
        }
    }

    func showSuccessView() {
        // MARK: makeSuccessView
        view.endEditing(true)
        let successView = UIView()
        successView.backgroundColor = .ud.bgBody
        headerView.titleLabel.text = ""
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFill
        icon.image = UDEmptyType.done.defaultImage().ud.resized(to: CGSize(width: 120, height: 120))
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .center
        title.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackSuccess
        successView.addSubview(icon)
        successView.addSubview(title)

        title.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        icon.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(title.snp.bottom).offset(24)
            $0.height.width.equalTo(120)
            $0.bottom.equalToSuperview().inset(24)
        }

        // MARK: success animation
        contentView.addSubview(successView)
        successView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview() // 高度自适应
        }

        // 切换动画，contentView的高度会产生变化，内容区域只alpha渐变
        successView.alpha = 0
        title.alpha = 0
        view.layoutIfNeeded() // 先保证布局OK

        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [], animations: { [self] in
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                containerView.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                successView.snp.makeConstraints {
                    $0.top.equalTo(headerView.snp.bottom).priority(999)
                }
                self.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                successView.alpha = 1
                title.alpha = 1
            }
        }, completion: { (_) in
        })
        autoQuit()
    }

    /// 两秒后自动退出
    private func autoQuit() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    /// 注册事件
    private func registerEvent() {
        rx.observeWeakly(Bool.self, "isEditTranslateSuggestion")
            .subscribe(onNext: { (isEditTranslateSuggestion) in
                if let editTranslateSuggestion = isEditTranslateSuggestion {
                    guard editTranslateSuggestion else { return }
                }
            })
            .disposed(by: disposeBag)

        rx.observeWeakly(Int.self, "translateScore")
            .subscribe(onNext: { [weak self] (translateScore) in
                guard self != nil else { return }
                if let translateScore = translateScore {
                    self?.sendButton.isEnabled = (translateScore > 0)
                }
            })
            .disposed(by: disposeBag)

        sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let suggestText = self.translateSuggestionView.translateContentTextView.text ?? ""
                var objectID: String?
                if !self.isSelectMode {
                    objectID = self.message?.id
                }

                self.translateService
                    .sendTranslateFeedback(scene: self.isSelectMode ? .hyper : .message,
                                           score: self.translateScore,
                                           originText: self.translateSuggestionView.originContentString,
                                           targetText: self.translateSuggestionView.translateContentString,
                                           hasSuggestText: !suggestText.isEmpty,
                                           suggestText: suggestText,
                                           editSuggestText: self.isEditTranslateSuggestion,
                                           originLanguage: self.originLanguage,
                                           targetLanguage: self.targetLanguage,
                                           objectID: objectID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] ( _ ) in
                        guard let self = self else { return }
                        self.showSuccessView()
                    }, onError: { [weak self] (_) in
                        guard let self = self else { return }
                        self.showSuccessView()
                    })
                    .disposed(by: self.disposeBag)
                /// 失败也dissmiss，产品策略：为了防止极端情况下，一直提交不成功，打击用户反馈的积极性
                // self.dismiss(animated: true, completion: nil)

                MessageTranslateFeedbackTracker.translateFeedbackClick(
                    messageID: self.trackParam["messageID"],
                    messageType: self.trackParam["messageType"],
                    srcLanguage: self.trackParam["srcLanguage"],
                    trgLanguage: self.trackParam["trgLanguage"],
                    cardSource: self.trackParam["cardSource"],
                    fromType: self.trackParam["fromType"],
                    clickType: "submit",
                    extraParam: ["target": "asl_message_translation_feedback_succeed_view"]
                )
            })
            .disposed(by: disposeBag)

    }

    /// 获取指定key对于的地址
    private func getUrl(key: String) -> URL? {
        guard let str = self.userAppConfig.resourceAddrWithLanguage(key: key) else { return nil }

        return URL(string: str)
    }

    /// 根据颜色生成图片
    private func imageFrom(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func scrollViewScrollToEnd(scrollView: UIScrollView) {
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.frame.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
    }

}

/// 公共方法目前还不知道放在哪个仓库，暂时放在这里，后续抽离
extension String {
    /// 计算textView的内容高度
    public func getTextViewHeight(textViewWidth: CGFloat,
                                  attributes: [NSAttributedString.Key: Any],
                                  textView: UITextView) -> CGFloat {
        let lineFragmentPading = textView.textContainer.lineFragmentPadding
        let textContainerInset = textView.textContainerInset
        let topOffset = textContainerInset.top
        let bottomOffset = textContainerInset.bottom
        let leadingOffset = textContainerInset.left
        let trailingOffset = textContainerInset.right
        let textContentWidth = textViewWidth - leadingOffset - trailingOffset - lineFragmentPading * 2
        let normalText: NSString = textView.text as NSString
        let size = CGSize(width: textContentWidth, height: CGFloat(MAXFLOAT))
        let stringSize = normalText.boundingRect(with: size,
                                                 options: .usesLineFragmentOrigin,
                                                 attributes: attributes,
                                                 context: nil).size

        return CGFloat(ceilf(Float(stringSize.height))) + topOffset + bottomOffset
    }
}

extension UIView {

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}

extension UIScrollView {

    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + contentInset.bottom)
        setContentOffset(bottomOffset, animated: false)
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
