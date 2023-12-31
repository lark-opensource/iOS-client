//
//  FeedBackViewController.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/6/14.
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
import LarkSearchCore
import LKCommonsLogging
import ServerPB
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignInput
import LarkContainer
import LarkRustClient
import LarkSDKInterface

protocol SearchFeedBackViewControllerContext {
    // 填充环境参数信息, 返回false取消请求
    func willSend(feedback: inout Search_Feedback_V1_FeedbackRequest) -> Bool
    func didSendFeedback()
}

final class SearchFeedBackViewController: UIViewController, UIViewControllerTransitioningDelegate, UDMultilineTextFieldDelegate, UserResolverWrapper {

    enum UI {
        static var inset: CGFloat { 16 }
        static var vertSpacing: CGFloat { 16 }
    }
    @ScopedInjectedLazy var rustService: RustService?
    let context: SearchFeedBackViewControllerContext

    static let logger = Logger.log(SearchFeedBackViewController.self, category: "Module.IM.Search")
    let contentView: UIView = UIView() // 包含导航条的用户可见交互区域
    lazy var naviBar = buildNavibar()
    let containerView = UIView() // 内容containerView，成功后会替换成成功提示
    let _stackView = UIStackView()
    let contentScrollView = UIScrollView()
    let policyView = UITextView()

    let bag = DisposeBag()
    let userResolver: UserResolver
    init(userResolver: UserResolver, context: SearchFeedBackViewControllerContext) {
        self.userResolver = userResolver
        self.context = context
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

        buildBackgroundView()
        buildContentView()

        loadReasons()
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
    func buildContentView() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        if Display.pad {
            contentView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 16.0)
        } else {
            contentView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        }
        view.addSubview(contentView)
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
            $0.top.greaterThanOrEqualTo(44) // 顶部留一定的空白，模拟sheet的效果
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        // config content view
        buildStackViewInScrollView() // 用户输入的这一部分内容高度不够时可压缩滚动
        buildPolicyView()
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)

        contentView.addSubview(naviBar)
        contentView.addSubview(containerView)
        containerView.addSubview(contentScrollView)
        contentScrollView.addSubview(_stackView)
        contentScrollView.addSubview(policyView)
        contentScrollView.addSubview(sendButton)

        var frame = contentView.bounds
        frame.size.height = 48
        naviBar.frame = frame
        naviBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

        containerView.snp.makeConstraints {
            $0.top.equalTo(naviBar.snp.bottom).priority(990)
            $0.left.right.bottom.equalToSuperview()
        }

        contentScrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            // 高度自适应, 键盘弹起时可能需要压缩高度
            scrollViewHeight = $0.height.equalTo(0).priority(700).constraint
        }
        policyView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(UI.inset)
            $0.top.equalTo(_stackView.snp.bottom)
            policyViewHeight = $0.height.equalTo(0).constraint
        }
        sendButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(UI.inset)
            $0.top.equalTo(policyView.snp.bottom).offset(24)

            // contenView自适应高度
            $0.bottom.equalToSuperview().inset(8)
        }
        _stackView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview() // contentSize自适应, 高度自适应
            $0.width.equalToSuperview()
        }
    }
    func buildNavibar() -> UIView {
        let naviBar = UIView()

        let titleLabel = UILabel()
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkSearch.Lark_search_feedback_windowtitle

        let cancelButton = UIButton()
        cancelButton.hitTestEdgeInsets = .init(edges: 20)
        cancelButton.addTarget(self, action: #selector(cancelPage), for: .touchUpInside)
        cancelButton.setImage(Resources.chat_filter_close.withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.tintColor = UIColor.ud.iconN1

        naviBar.addSubview(titleLabel)
        naviBar.addSubview(cancelButton)

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        cancelButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.left.equalTo(UI.inset)
        }
        return naviBar
    }
    private lazy var sendButton = confirmButtonBlock(BundleI18n.LarkSearch.Lark_Legacy_Send)
    var reasonView = ReasonView()
    func buildStackViewInScrollView() {
        _stackView.axis = .vertical
        _stackView.spacing = 24
        _stackView.layoutMargins = .init(top: UI.vertSpacing, left: 0, bottom: 8, right: 0)
        _stackView.isLayoutMarginsRelativeArrangement = true

        buildQuickReason()
        buildFeedBack()
    }
    func buildQuickReason() {
        reasonView.selectedChange = { [weak self] in self?.updateSendButtonState() }
        _stackView.addArrangedSubview(reasonView)
        reasonView.snp.makeConstraints {
            reasonViewHeight = $0.height.equalTo(0).constraint
        }
    }
    var feedBackView = UDMultilineTextField()
    func buildFeedBack() {
        let container = UIView()
        let tip = Self.makeTipLabel(title: BundleI18n.LarkSearch.Lark_search_feedback_openquestiontitle)

        var config = UDMultilineTextFieldUIConfig()
        config.borderColor = .ud.textPlaceholder
        config.isShowBorder = true
        config.backgroundColor = .clear
        config.placeholderColor = .ud.textPlaceholder
        config.font = UIFont.systemFont(ofSize: 16)
        config.textColor = .ud.textTitle

        feedBackView.config = config
        feedBackView.delegate = self
        feedBackView.isEditable = true
        feedBackView.placeholder = BundleI18n.LarkSearch.Lark_search_feedback_openquestionguideline
        feedBackView.input.returnKeyType = .done
        feedBackView.layer.cornerRadius = 6.0

        _stackView.addArrangedSubview(container)
        container.addSubview(tip)
        container.addSubview(feedBackView)

        tip.sizeToFit()
        tip.frame.origin = .init(x: UI.inset, y: 0)
        feedBackView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(UI.inset)
            $0.top.equalTo(tip.snp.bottom).offset(8)
            $0.height.equalTo(108)
            $0.bottom.equalToSuperview() // container height
        }
        textViewDidChange(feedBackView.input)
    }
    static func makeTipLabel(title: String) -> UILabel {
        let tip = UILabel()
        tip.font = .boldSystemFont(ofSize: 16)
        tip.textColor = UIColor.ud.textTitle
        tip.text = title
        return tip
    }
    func buildPolicyView() {
        var tipString: NSAttributedString {
            let string: String = BundleI18n.LarkSearch.Lark_search_feedback_regulations(BundleI18n.LarkSearch.Lark_Guide_V3_PrivacyPolicy)
            let paraph = NSMutableParagraphStyle()
            paraph.lineSpacing = 3
            let stringAttribute: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paraph,
                .foregroundColor: UIColor.ud.textPlaceholder]
            let tipString = NSMutableAttributedString(string: string, attributes: stringAttribute)
            let linkAttr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textLinkNormal]

            if let privacyURL = getURL(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpPrivatePolicy) {
                let range = (string as NSString).range(of: BundleI18n.LarkSearch.Lark_Guide_V3_PrivacyPolicy)
                if range.location != NSNotFound {
                    tipString.addAttributes(linkAttr, range: range)
                    tipString.addAttribute(.link, value: privacyURL, range: range)
                }
            }
            return tipString
        }

        policyView.attributedText = tipString
        policyView.backgroundColor = .clear
        policyView.isEditable = false
        policyView.isSelectable = true
        // policyView.isScrollEnabled = false // this will disable auto contentSize set
        policyView.textContainer.lineFragmentPadding = 0
        policyView.textContainerInset = .zero
        policyView.delegate = self
    }
    func showSuccessView() {

        // MARK: makeSuccessView
        let successView = UIView()
        let icon = UIImageView(image: UDIcon.succeedColorful)
        icon.tintColor = UIColor.ud.colorfulGreen

        let title = UILabel()
        title.textColor = UIColor.ud.textTitle
        title.font = .boldSystemFont(ofSize: 20)
        title.text = BundleI18n.LarkSearch.Lark_Search_FeedbackSurveyThanksTitle

        let desc = UILabel()
        desc.textColor = UIColor.ud.textTitle
        desc.font = .systemFont(ofSize: 16)
        desc.text = BundleI18n.LarkSearch.Lark_Search_FeedbackSurveyThanksDesc
        desc.textAlignment = .center
        desc.numberOfLines = 0
        desc.lineBreakMode = .byWordWrapping
        desc.preferredMaxLayoutWidth = contentView.bounds.width - 2 * UI.inset

        let okButton = confirmButtonBlock(BundleI18n.LarkSearch.Lark_Search_FeedbackSurveyThanksButton)
        okButton.addTarget(self, action: #selector(cancelPage), for: .touchUpInside)

        successView.addSubview(icon)
        successView.addSubview(title)
        successView.addSubview(desc)
        successView.addSubview(okButton)

        icon.snp.makeConstraints {
            $0.top.equalTo(32)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(56)
        }
        title.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(icon.snp.bottom).offset(UI.vertSpacing * 2)
            $0.height.equalTo(title.intrinsicContentSize.height)
        }
        desc.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(title.snp.bottom).offset(UI.vertSpacing * 2)
            $0.height.equalTo(desc.intrinsicContentSize.height)
        }
        okButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(UI.inset)
            $0.top.equalTo(desc.snp.bottom).offset(32)
            $0.height.equalTo(48)

            // successView自适应高度
            $0.bottom.equalToSuperview().inset(8)
        }

        // MARK: success animation
        contentView.addSubview(successView)
        successView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview() // 高度自适应
        }

        // 切换动画，contentView的高度会产生变化，内容区域只alpha渐变
        successView.alpha = 0
        desc.alpha = 0
        okButton.alpha = 0
        view.layoutIfNeeded() // 先保证布局OK

        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [], animations: { [self] in
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                containerView.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                successView.snp.makeConstraints {
                    $0.top.equalTo(naviBar.snp.bottom).priority(999)
                }
                self.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                successView.alpha = 1
            }
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                desc.alpha = 1
                okButton.alpha = 1
            }
        }, completion: { (_) in
        })
    }
    var scrollViewHeight, policyViewHeight, reasonViewHeight: Constraint?
    var lastWidth: CGFloat = -1
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
    func updateReasonViewHeight() {
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
        scrollViewHeight?.update(offset: _stackView.frame.height + policyView.frame.height + sendButton.frame.height + 2 * UI.vertSpacing)
    }

    func loadReasons() {
        rustService?.sendPassThroughAsyncRequest(ServerPB_As_feedback_FeedbackReasonRequest(), serCommand: .getFeedbackReasonItems)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self](response: ServerPB_As_feedback_FeedbackReasonResponse) in
            guard let self = self else { return }
            Self.logger.debug("feedback load \(response.reasonItems.count) reasons")
            self.reasonView.reasons = response.reasonItems
            self.view.setNeedsLayout()
            self.lastWidth = -1
            self.view.layoutIfNeeded()
        }, onError: { (error) in
            Self.logger.debug("feedback load reasons error", error: error)
        }).disposed(by: bag)

    }
    // MARK: - Delegate & Event
    @objc
    func send() {
        weak var ws = self
        var request = Search_Feedback_V1_FeedbackRequest()
        request.feedbackContent = feedBackView.text ?? ""
        request.reasonItems = reasonView.selected.map {
            var item = Search_Feedback_V1_FeedbackReasonItem()
            item.id = $0.id
            item.content = $0.content
            return item
        }
        if !context.willSend(feedback: &request) { return }

        isSending = true
        view.endEditing(true) // 给出空间，防止之后展示不全

        rustService?.async(message: request)
        .timeout(.seconds(10), scheduler: MainScheduler.instance)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (_: Search_Feedback_V1_FeedbackResponse) in
            Self.logger.info("feedback success")
            ws?.context.didSendFeedback()
            ws?.showSuccessView()
        }, onError: { (error) in
            guard let self = ws else { return }
            Self.logger.warn("feedback error", error: error)
            UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Search_FailedToSubmitFeedback, on: self.view)
        }, onDisposed: {
            ws?.isSending = false
        }).disposed(by: bag)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 点击textView外，直接resign
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    @objc
    func keyboardChange(notification: NSNotification) {
        guard let kbFrame = notification.userInfo?[Self.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notification.userInfo?[Self.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { [self] in
            let originBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY + self.additionalSafeAreaInsets.bottom
            let kbFrame = self.view.convert(kbFrame, from: nil)
            self.additionalSafeAreaInsets.bottom = max(originBottom - kbFrame.minY, 0)
            self.view.layoutIfNeeded()
            contentScrollView.scrollRectToVisible(feedBackView.convert(feedBackView.bounds, to: contentScrollView), animated: false)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    @objc
    private func cancelPage() {
        dismiss(animated: true, completion: nil)
    }
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        Presentation(presentedViewController: presented, presenting: presenting ?? source)
    }
    // MARK: - UITextView
    private func getURL(key: String) -> URL? {
        guard
            let userAppConfig = try? userResolver.resolve(assert: UserAppConfig.self),
            let str = userAppConfig.resourceAddrWithLanguage(key: key)
        else { return nil }

        return URL(string: str)
    }
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        Self.logger.info("search feedback: click \(url)")
        navigator.push(url, context: ["from": "search_feedback"], from: self)
        return false
    }
    func textViewDidChange(_ textView: UITextView) {
        updateSendButtonState()
    }

    func calculateText(_ text: String) -> NSAttributedString? {
        return nil
    }

    var isSending = false {
        didSet { updateSendButtonState() }
    }
    func updateSendButtonState() {
        // configure state
        sendButton.isEnabled = !isSending && (feedBackView.input.hasText || !reasonView.selected.isEmpty)
    }
    /// 用于存放用户选项
    final class ReasonView: UIView {
        typealias ReasonType = ServerPB_As_feedback_FeedbackReasonItem
        static var itemStartY: CGFloat { 34 } // 在tipLabel下面，目前写的绝对值
        static var itemHeight: CGFloat { 28 }
        static var itemSpaceing: CGFloat { 12 }
        var reasons: [ReasonType] = [] {
            didSet {
                invalidLayout()
            }
        }
        var selected: Set<ReasonType> = []
        var selectedChange: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            let tip = SearchFeedBackViewController.makeTipLabel(title: BundleI18n.LarkSearch.Lark_Search_FeedbackSurveyTitle)
            addSubview(tip)
            tip.snp.makeConstraints {
                $0.left.equalTo(UI.inset)
                $0.top.equalToSuperview()
            }
            self.clipsToBounds = true // 高度不够是需要隐藏对应的视图
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        private var _reasonBtns: [UIButton] = [] {
            didSet {
                assert(Thread.isMainThread, "should occur on main thread!")
                if !oldValue.isEmpty {
                    for btn in oldValue {
                        btn.removeFromSuperview()
                    }
                }
                if !_reasonBtns.isEmpty {
                    for btn in _reasonBtns {
                        self.addSubview(btn) // frame在布局的时候设置
                    }
                }
            }
        }
        func makeReaonsButton() -> UIButton {
            let btn = ReasonButton(frame: .zero)
            btn.addTarget(self, action: #selector(touch(button:)), for: .touchUpInside)
            return btn
        }
        final class ReasonButton: UIButton {
            static var padding: CGFloat { 12 }
            override init(frame: CGRect) {
                super.init(frame: frame)
                self.titleLabel?.font = .systemFont(ofSize: 16)
                self.setTitleColor(UIColor.ud.textTitle, for: .normal)
                self.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
                self.contentEdgeInsets = UIEdgeInsets(horizontal: Self.padding, vertical: 0)
                self.layer.cornerRadius = Self.padding
                self.layer.borderWidth = 1
                self.clipsToBounds = true
                configByState()
            }
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            override var isSelected: Bool {
                didSet { configByState() }
            }
            func configByState() {
                if isSelected {
                    self.backgroundColor = UIColor.ud.udtokenBtnSeBgPriHover
                    self.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
                } else {
                    self.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
                    self.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
                }
            }
        }

        func invalidLayout() {
            lastWidth = -1
            self.setNeedsLayout()
        }
        var lastWidth: CGFloat = -1
        override func layoutSubviews() {
            super.layoutSubviews()
            doLayout(width: self.bounds.width)
        }
        /// valid after doLayout
        var preferHeight: CGFloat = 0
        @discardableResult
        func doLayout(width boundsWidth: CGFloat) -> CGFloat {
            if lastWidth == boundsWidth { return preferHeight }
            defer { lastWidth = boundsWidth }

            func dequeBtn(i: Int) -> UIButton {
                let btn: UIButton
                if i < _reasonBtns.count {
                    btn = _reasonBtns[i]
                } else {
                    btn = makeReaonsButton()
                }
                btn.tag = i // use to check which one is selected
                return btn
            }

            var buttons: [UIButton] = [] // add into this array to replace into view
            defer { _reasonBtns = buttons }

            // create and layout reasons
            var x = UI.inset
            let maxX = boundsWidth - UI.inset
            var y = Self.itemStartY
            var row = 0

            func nextFrame(width: CGFloat) -> CGRect {
                if x + width <= maxX {
                    // 正常能放下
                    defer { x += width + Self.itemSpaceing }
                    return .init(x: x, y: y, width: width, height: Self.itemHeight)
                }
                // 放不下了
                do {
                    defer {
                        x = UI.inset
                        y += Self.itemHeight + 12
                        row += 1
                    }
                    let left = max(maxX - x, 0)
                    if x == UI.inset { // 第一个时, 进行压缩放置
                        return .init(x: x, y: y, width: left, height: Self.itemHeight)
                    }
                }
                // 压缩也放不了，下一行进行判断
                return nextFrame(width: width)
            }
            for (i, reason) in reasons.enumerated() {
                let btn = dequeBtn(i: i)
                btn.setTitle(reason.content, for: .normal)
                btn.sizeToFit()
                let frame = nextFrame(width: btn.frame.width)
                btn.frame = frame
                btn.isSelected = selected.contains(reason)
                buttons.append(btn)
            }
            if let button = buttons.last {
                preferHeight = button.frame.maxY
            } else {
                preferHeight = 0 // 没有展示内容时不显示
            }
            return preferHeight
        }
        @objc
        func touch(button: UIButton) {
            button.isSelected = !button.isSelected
            let tag = button.tag
            if tag < reasons.count {
                if button.isSelected {
                    selected.insert(reasons[tag])
                } else {
                    selected.remove(reasons[tag])
                }
                selectedChange?()
            }
        }

    }
    private let confirmButtonBlock: (String) -> UIButton = { title in
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.functionInfoContentDefault,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        var config = UDButtonUIConifg(normalColor: normalColor)
        config.disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                          backgroundColor: UIColor.ud.fillDisabled,
                                                          textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        config.radiusStyle = .square
        config.type = .big
        let udButton = UDButton(config)
        udButton.setTitle(title, for: .normal)
        udButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        udButton.layer.masksToBounds = true
        return udButton
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
}

// MARK: Stat extension
extension SearchFeedBackViewController {

}
