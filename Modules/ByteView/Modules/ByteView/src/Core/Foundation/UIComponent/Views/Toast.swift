//
//  Toast.swift
//  ByteView
//
//  Created by kiri on 2020/6/15.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignSwitch
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

enum VCToastType: Int {
    case success
    case warning
    case error
}

final class Toast {

    static let iconSize: CGSize = CGSize(width: 20, height: 20)

    /// vc模块专用toast loading，显示在和vc窗口同scene的独立window上
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func showLoading(_ content: String = "", duration: TimeInterval? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return show(.loading(content), duration: duration ?? Double(INT_MAX), completion: completion)
    }

    @discardableResult
    static func showLoading(_ content: String = "", in view: UIView, duration: TimeInterval? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return show(.loading(content), in: view, duration: duration ?? Double(INT_MAX), completion: completion)
    }

    /// vc模块专用toast loading，显示在和vc窗口同scene的独立window上
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func show(_ text: String, type: VCToastType, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        var content: Content?
        switch type {
        case .success:
            content = .richText(successIcon(), iconSize, text)
        case .warning:
            content = .richText(warningIcon(), iconSize, text)
        case .error:
            content = .richText(failureIcon(), iconSize, text)
        }
        return show(content ?? .plain(text), duration: duration, style: style, completion: completion)
    }

    @RwAtomic
    private static var lastBlockedVCSceneRequest: ToastRequest?
    @RwAtomic
    private static var shouldBlockToastOnVCScene = false

    // 在进入onthecall的时候调用
    static func blockToastOnVCScene() {
        shouldBlockToastOnVCScene = true
        Logger.ui.info("blockToastOnVCScene")
    }

    static func unblockToastOnVCScene(showBlockedToast: Bool) {
        guard shouldBlockToastOnVCScene else { return }
        Logger.ui.info("unblockToastOnVCScene, showBlockedToast = \(showBlockedToast)")
        shouldBlockToastOnVCScene = false
        if let req = self.lastBlockedVCSceneRequest {
            self.lastBlockedVCSceneRequest = nil
            if showBlockedToast {
                showOnVCScene(req.text, in: req.view, duration: req.duration, style: req.style, completion: req.completion)
            }
        }
    }

    /// vc模块专用toast，优先显示在传入的view上；找不到的话，全屏时显示在VCScene.window上；否则就放到vc窗口同scene的独立window上
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func showOnVCScene(_ text: String, in view: UIView? = nil, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        if shouldBlockToastOnVCScene {
            self.lastBlockedVCSceneRequest = ToastRequest(text: text, view: view, duration: duration, style: style, completion: completion)
            return nil
        }
        if let targetView = view {
            return show(.plain(text), in: targetView, duration: duration, style: style, completion: completion)
        } else if let targetVCSceneWindow = FloatingWindow.current, !targetVCSceneWindow.isFloating {
            return show(.plain(text), in: targetVCSceneWindow, duration: duration, style: style, completion: completion)
        } else {
            return show(.plain(text), duration: duration, style: style, completion: completion)
        }
    }

    /// vc模块专用toast，显示在和vc窗口同scene的独立window上
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func show(_ text: String, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return show(.plain(text), duration: duration, style: style, completion: completion)
    }

    /// vc模块专用toast，显示在和vc窗口同scene的独立window上
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func show(_ content: Content, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return showInternal(content, in: nil, duration: duration, style: style, completion: completion)
    }

    /// 通用toast，需要提供容器view来显示
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func show(_ text: String, in view: UIView, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return show(.plain(text), in: view, duration: duration, style: style, completion: completion)
    }

    /// 通用toast，需要提供容器view来显示
    /// - note: 只有主线程show才会返回非空的ToastOperator
    @discardableResult
    static func show(_ content: Content, in view: UIView, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)? = nil) -> ToastOperator? {
        return showInternal(content, in: view, duration: duration, style: style, completion: completion)
    }

    static func update(customInsets: UIEdgeInsets) {
        Logger.ui.info("update customInsets \(customInsets)")
        Util.runInMainThread {
            ToastView.defaultToastView.customInsets = customInsets
        }
    }

    static func hideAllToasts(animated: Bool = false) {
        Util.runInMainThread {
            ToastView.findVisibleToastViews().forEach { (toast) in
                toast.hide(animated: animated, completion: nil)
            }
            cleanWindowAfterHideAll(animated: animated)
        }
    }

    static func hideToasts(in view: UIView, animated: Bool = false) {
        Util.runInMainThread {
            ToastView.findVisibleToastViews(in: view).forEach { (toast) in
                toast.hide(animated: animated, completion: nil)
            }
            if view === _window {
                cleanWindowAfterHideAll(animated: animated)
            }
        }
    }

    // MARK: - private
    private static var _window: UIWindow?
    private static var window: UIWindow {
        if let w = _window {
            return w
        }
        let window = VCScene.createWindow(UIWindow.self, tag: .toast)
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        window.isUserInteractionEnabled = false
        window.rootViewController = PuppetWindowRootViewController()
        _window = window
        return window
    }

    private static func showInternal(_ content: Content, in view: UIView?, duration: TimeInterval? = nil, style: Style? = nil, completion: (() -> Void)?) -> ToastOperator? {
        var result: ToastOperator?
        Util.runInMainThread {
            if content.text.isEmpty && content.image == nil && content.isLoading == false {
                return
            }
            let s = style ?? Context.defaultStyle
            guard let toast = ToastView.findToastByStyle(s, createIfNeeded: true) else {
                return
            }
            toast.prepare(content, style: s)
            let d = duration ?? Self.calculateDisplayTime(content.text)
            var isOnProtectedWindow = false
            let carrier = view ?? self.window
            // protect default window
            if carrier === _window {
                isOnProtectedWindow = true
                if #available(iOS 13.0, *), let ws = VCScene.windowScene, self.window.windowScene != ws {
                    self.window.windowScene = ws
                }
            }
            carrier.isHidden = false
            if content.isLoading {  // loading状态禁止屏幕点击
                window.isUserInteractionEnabled = true
            }
            if let routerWindow = FloatingWindow.current {
                // 清理 UDToast
                UDToast.removeToast(on: routerWindow)
            }
            toast.show(in: carrier, duration: d, animated: true) { (_) in
                if isOnProtectedWindow {
                    cleanWindowIfNeeded()  // 注意loading可能不走这里，也有可能走
                }
                completion?()
            }
            result = ToastOperator(toast)
        }
        return result
    }

    fileprivate static func cleanWindowAfterHideAll(animated: Bool) {
        if animated {
            // animation duration = 0.1s
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
                cleanWindowIfNeeded()
            }
        } else {
            cleanWindowIfNeeded()
        }
    }

    private static func cleanWindowIfNeeded() {
        guard let window = _window else {
            return
        }
        window.isUserInteractionEnabled = false
        if ToastView.findVisibleToastViews(in: window).isEmpty {
            window.isHidden = true
            ToastView.cleanUnusedReferences()
        }
    }

    private static func calculateDisplayTime(_ text: String) -> TimeInterval {
        let count = text.count
        if count <= 48 { return Context.defaultDuration }
        var time: TimeInterval = Context.defaultDuration
        time += TimeInterval(Int((count - 48) / 16))
        return time
    }

    private static func successIcon() -> UIImage? {
        UDIcon.getIconByKey(.yesOutlined, iconColor: .ud.primaryOnPrimaryFill, size: iconSize)
    }

    private static func warningIcon() -> UIImage? {
        UDIcon.getIconByKey(.warningOutlined, iconColor: .ud.primaryOnPrimaryFill, size: iconSize)
    }

    private static func failureIcon() -> UIImage? {
        UDIcon.getIconByKey(.moreCloseOutlined, iconColor: .ud.primaryOnPrimaryFill, size: iconSize)
    }
}

extension Toast {
    fileprivate static var additionalInsetsProviders: [ToastAdditionalInsetsProvider] = [] {
        didSet {
            ToastView.defaultToastView.updateLayout()
        }
    }

    static var additionalInsets: UIEdgeInsets {
        var edgeInsets: UIEdgeInsets = .zero
        for provider in additionalInsetsProviders {
            let i = provider.additionalInsets
            edgeInsets.left += i.left
            edgeInsets.right += i.right
            edgeInsets.top += i.top
            edgeInsets.bottom += i.bottom
        }
        return edgeInsets
    }

    static func requestAdditionalInsets(_ provider: ToastAdditionalInsetsProvider) -> ToastAdditionalInsetsToken {
        class Token: ToastAdditionalInsetsToken {
            let item: ToastAdditionalInsetsProvider
            init(item: ToastAdditionalInsetsProvider) {
                self.item = item
            }
            func cancel() {
                Util.runInMainThread {
                    Toast.additionalInsetsProviders.removeAll(where: { $0 === self.item })
                }
            }
        }
        Util.runInMainThread {
            self.additionalInsetsProviders.append(provider)
        }
        return Token(item: provider)
    }
}

extension Toast {
    /// 全局设置 Context
    struct Context {
        /// 默认样式
        static var defaultStyle: Style = .normal {
            didSet {
                if oldValue != defaultStyle {
                    ToastView.updateDefaultToast(style: defaultStyle)
                }
            }
        }
        /// 默认显示时间
        static var defaultDuration: TimeInterval = 3.0
    }

    // Content & Style
    enum Content {
        case plain(String)
        case richText(UIImage?, CGSize, String)
        case loading(String)

        var text: String {
            switch self {
            case let .plain(text):
                return text
            case let .richText(_, _, text):
                return text
            case let .loading(text):
                return text
            }
        }
        var image: UIImage? {
            switch self {
            case let .richText(image, _, _):
                return image
            default:
                return nil
            }
        }
        var imageSize: CGSize? {
            switch self {
            case let .richText(_, imageSize, _):
                return imageSize
            default:
                return nil
            }
        }
        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }
    }

    enum Style: Hashable {
        case normalPadding(CGFloat, keyboard: CGFloat, numberOfLines: Int)
        case emphasizePadding(CGFloat, keyboard: CGFloat, numberOfLines: Int)

        static let normal = Style.normalPadding(0, keyboard: 0, numberOfLines: 0)
        static let emphasize = Style.emphasizePadding(0, keyboard: 0, numberOfLines: 0)

        var textStyleConfig: VCFontConfig {
            switch self {
            case .emphasizePadding:
                return .h3
            default:
                return .boldBodyAssist
            }
        }

        fileprivate var cacheKey: ToastCacheKey {
            switch self {
            case .emphasizePadding:
                return .emphasize
            default:
                return .normal
            }
        }
    }

    /// 根据这个key来判断要新建一个ToastView还是复用旧的
    fileprivate enum ToastCacheKey: Int, Hashable {
        /// 大部分的toast，显示在底部
        case normal
        /// 显示在中间
        case emphasize
    }

    struct ToastOperator {
        private weak var toastView: ToastView?
        fileprivate init(_ toastView: ToastView) {
            self.toastView = toastView
        }

        func hide(animated: Bool, completion: ((Bool) -> Void)?) {
            guard let toast = toastView else {
                completion?(true)
                return
            }
            let wrappedCompletion: (Bool) -> Void = { b in
                Toast.cleanWindowIfNeeded()
                completion?(b)
            }
            toast.hide(animated: animated, completion: wrappedCompletion)
        }

        func update(customInsets: UIEdgeInsets) {
            toastView?.customInsets = customInsets
        }

        func hideLoading() {
            if case .loading = toastView?.content {
                hide(animated: true, completion: nil)
            }
        }
    }
}

private class ToastView: UIView {
    private(set) var style: Toast.Style
    private(set) var content: Toast.Content?

    private var isToastHidden = true
    private var contentView = UIView()
    private var imageView = UIImageView()
    private var textLabel = UILabel()

    private lazy var indicator: UDActivityIndicatorView = {
        return UDActivityIndicatorView(color: UIColor.ud.primaryOnPrimaryFill)
    }()

    private var visibleDeadline: DispatchTime?
    // remove warning: UIStackView 'UIView-Encapsulated-Layout-Width' = 0 vs H:|-[UIImageView]-(8)-[UILabel]-|
    private var stackView = UIStackView(frame: CGRect(origin: .zero, size: .init(width: 20, height: 20)))
    fileprivate var customInsets: UIEdgeInsets = .zero
    private var textGap: CGFloat = 0 // 仅文字部分的gap，显示toast前 需要额外考虑图片的宽度
    private var stackViewSpacing: CGFloat = 8.0

    init(style: Toast.Style) {
        self.style = style
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isUserInteractionEnabled = false
        //当被添加时防止被后添加的view覆盖掉
        layer.zPosition = 999
        alpha = 0.0
        isHidden = true
        indicator.isHidden = true
        contentView.backgroundColor = UIColor.ud.bgTips
        addSubview(contentView)

        indicator.setContentHuggingPriority(.defaultLow + 3, for: .horizontal)
        indicator.setContentHuggingPriority(.defaultLow + 3, for: .vertical)
        indicator.setContentCompressionResistancePriority(.defaultHigh + 3, for: .horizontal)
        indicator.setContentCompressionResistancePriority(.defaultHigh + 3, for: .vertical)

        imageView.clipsToBounds = false
        imageView.setContentHuggingPriority(.defaultLow + 2, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultHigh + 2, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultHigh + 2, for: .vertical)

        textLabel.font = .systemFont(ofSize: 14)
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        stackView.addArrangedSubview(indicator)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textLabel)
        stackView.spacing = stackViewSpacing
        stackView.alignment = .top

        contentView.addSubview(stackView)

        updateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateLayout()
        }
    }

    fileprivate func updateLayout() {
        let isCustomLeading: Bool = customInsets.left != 0
        let isCustomBottom: Bool = customInsets.bottom != 0

        var gap: CGFloat = 0
        let marginInset: CGFloat = 30
        let stackViewInset: CGFloat = content?.isLoading ?? false ? 24 : 20
        switch style {
        case .normalPadding(let padding, let keyboard, let numberOfLines):
            contentView.snp.remakeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide.snp.left).offset(isCustomLeading ? customInsets.left : marginInset)
                // 处理安全区域
                if isPhoneLandscape {
                    maker.bottom.lessThanOrEqualToSuperview().offset(isCustomBottom ? -customInsets.bottom : -100.0 - padding - Toast.additionalInsets.bottom)
                } else if VCScene.isLandscape {
                    maker.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide.snp.bottom).offset(isCustomBottom ? -customInsets.bottom : -100.0 - padding - Toast.additionalInsets.bottom)
                } else {
                    maker.bottom.lessThanOrEqualTo(self.safeAreaLayoutGuide.snp.bottom).offset(isCustomBottom ? -customInsets.bottom : -128.0 - padding - Toast.additionalInsets.bottom)
                }
                maker.bottom.lessThanOrEqualTo(self.vc.debounceKeyboardLayoutGuide.snp.top).offset(-20 - keyboard)
                maker.bottom.equalToSuperview().offset(isCustomBottom ? -customInsets.bottom : 0).priority(.high)
            }
            stackView.snp.remakeConstraints { (maker) in
                if let content = content, content.isLoading {
                    maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 11, left: stackViewInset, bottom: 11, right: stackViewInset))
                } else {
                    maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: stackViewInset, bottom: 10, right: stackViewInset))
                }
            }
            textLabel.numberOfLines = numberOfLines
            gap = stackViewInset * 2 + (isCustomLeading ? customInsets.left : CGFloat(marginInset)) * 2
        case .emphasizePadding(let padding, let keyboard, let numberOfLines):
            contentView.snp.remakeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide.snp.left).offset(40)
                // 处理安全区域
                maker.bottom.lessThanOrEqualTo(self.vc.debounceKeyboardLayoutGuide.snp.top).offset(-20 - keyboard)
                maker.centerY.equalToSuperview().offset(-padding).priority(.high)
            }
            stackView.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 22, bottom: 12, right: 22))
            }
            textLabel.numberOfLines = numberOfLines
            gap = 44 + 80
        }

        self.textGap = gap // gap without image
    }

    private var actionLabelTapAction: (() -> Void)?
    @objc private func didTapActionLabel() {
        self.actionLabelTapAction?()
    }

    func prepare(_ content: Toast.Content, style: Toast.Style) {
        self.style = style
        self.content = content

        updateLayout()
        let text = content.text
        let image = content.image
        let isLoading = content.isLoading
        self.textLabel.attributedText = .init(string: text, config: style.textStyleConfig, alignment: .center, textColor: UIColor.ud.primaryOnPrimaryFill)
        self.textLabel.isHidden = text.isEmpty
        self.imageView.image = image
        self.imageView.isHidden = (image == nil)
        self.accessibilityIdentifier = "Toast"
        if let imageSize = content.imageSize {
            imageView.snp.remakeConstraints { (make) in
                make.size.equalTo(imageSize)
            }
            textLabel.textAlignment = .left
        } else {
            textLabel.textAlignment = .center
        }
        self.indicator.isHidden = !isLoading
        if isLoading {
            self.indicator.startAnimating()
            indicator.snp.remakeConstraints { make in
                make.size.equalTo(17)
            }
        } else {
            self.indicator.stopAnimating()
            indicator.snp.remakeConstraints { make in
                make.size.equalTo(0)
            }
        }
        var realGap = self.textGap
        if let imageWidth = content.imageSize?.width {
            realGap += (imageWidth + stackViewSpacing)
        }
        var leftGap: CGFloat
        switch style {
        case .normal:
            leftGap = customInsets.left != 0 ? customInsets.left : 30
        default:
            leftGap = 40
        }
        // https://bytedance.feishu.cn/wiki/wikcnwfKed2okiugtpJCrgbo4hb#PBmEz6
        // toast width要小于295
        textLabel.preferredMaxLayoutWidth = min(295 - realGap + leftGap * 2, VCScene.bounds.width - realGap)
    }

    func show(in view: UIView, duration: TimeInterval?, animated: Bool, completion: ((Bool) -> Void)?) {
        isToastHidden = false
        if self.superview != view {
            view.addSubview(self)
            if self.frame != view.bounds {
                self.frame = view.bounds
            }
            self.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        } else {
            self.superview?.bringSubviewToFront(self)
        }
        view.layoutIfNeeded()

        // swiftlint:disable empty_count

        let maxSize = CGSize(width: textLabel.frame.size.width, height: .greatestFiniteMagnitude)
        let textHeight = textLabel.sizeThatFits(maxSize).height
        let lineHeight = textLabel.font.lineHeight
        let numberOfVisibleLines = lroundf(Float(textHeight / lineHeight))
        if numberOfVisibleLines == 1 || self.textLabel.text?.count == 0 {
            self.contentView.layer.cornerRadius = self.contentView.frame.size.height * 0.5
        } else {
            self.contentView.layer.cornerRadius = 8.0
        }
        // swiftlint:enable empty_count

        isHidden = false

        let animations = {
            self.alpha = 1.0
        }
        let wrappedCompletion: ((Bool) -> Void)?
        if duration == nil, let completion = completion {
            wrappedCompletion = completion
        } else {
            wrappedCompletion = nil
        }

        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: animations,
                           completion: { [weak self] b in
                wrappedCompletion?(b)
                if let self = self, let w = self.window {
                    let isLandscape = w.bounds.width > w.bounds.height
                    let statusLandscape = self.isLandscape
                    if isLandscape != statusLandscape {
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            })
        } else {
            animations()
            wrappedCompletion?(true)
        }

        if let duration = duration {
            let deadline: DispatchTime = .now() + .milliseconds(Int(duration * 1000))
            // - .milliseconds(100) for tolerance
            visibleDeadline = deadline - .milliseconds(100)
            DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
                if let time = self?.visibleDeadline, time < .now() {
                    self?.hide(animated: animated, completion: completion)
                } else {
                    completion?(false)
                }
            }
        } else {
            visibleDeadline = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.vc.updateKeyboardLayout()
    }

    func hide(animated: Bool, completion: ((Bool) -> Void)?) {
        isToastHidden = true
        visibleDeadline = .now()

        let animations = {
            self.alpha = 0.0
        }
        let wrappedCompletion: (Bool) -> Void = { [weak self] _ in
            guard let wself = self, wself.isToastHidden else {
                completion?(false)
                return
            }

            wself.indicator.stopAnimating()
            wself.removeFromSuperview()
            wself.isHidden = true
            completion?(true)
        }

        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: animations,
                           completion: wrappedCompletion)
        } else {
            animations()
            wrappedCompletion(true)
        }
    }
}

extension ToastView {
    static let normal = ToastView(style: .normal)
    private(set) static var defaultToastView: ToastView = normal
    private static var abnormalInstances: [WeakRef<ToastView>] = []

    static func findToastByStyle(_ style: Toast.Style, createIfNeeded: Bool = false) -> ToastView? {
        assertMain()
        // 找对应style的缓存
        let key = style.cacheKey
        if key == .normal {
            return normal
        } else if key == defaultToastView.style.cacheKey {
            return defaultToastView
        } else {
            /// 先清理一下垃圾
            self.abnormalInstances.removeAll(where: { $0.ref == nil })
            if let v = self.abnormalInstances.first(where: { $0.ref?.style.cacheKey == key })?.ref {
                return v
            } else if createIfNeeded {
                let v = ToastView(style: style)
                self.abnormalInstances.append(WeakRef(v))
                return v
            }
            return nil
        }
    }

    static func findVisibleToastViews() -> [ToastView] {
        return find { !$0.isToastHidden }
    }

    static func findVisibleToastViews(in view: UIView) -> [ToastView] {
        return find { !$0.isToastHidden && $0.isDescendant(of: view) }
    }

    private static func find(where shouldReturned: (ToastView) -> Bool) -> [ToastView] {
        assertMain()
        var result: [ToastView] = []
        if shouldReturned(normal) {
            result.append(normal)
        }
        abnormalInstances.forEach { (r) in
            if let v = r.ref, shouldReturned(v) {
                result.append(v)
            }
        }
        if shouldReturned(defaultToastView), !result.contains(defaultToastView) {
            result.append(defaultToastView)
        }
        return result
    }

    static func cleanUnusedReferences() {
        abnormalInstances.removeAll(where: { $0.ref == nil || $0.ref?.isHidden == true })
    }

    fileprivate static func updateDefaultToast(style: Toast.Style) {
        Util.runInMainThread {
            if defaultToastView.style != style, let toast = findToastByStyle(style, createIfNeeded: true) {
                defaultToastView = toast
            }
        }
    }
}

protocol ToastAdditionalInsetsProvider: AnyObject {
    var additionalInsets: UIEdgeInsets { get }
}

protocol ToastAdditionalInsetsToken {
    func cancel()
}

extension Toast {
    private struct ToastRequest {
        let text: String
        weak var view: UIView?
        let duration: TimeInterval?
        let style: Style?
        let completion: (() -> Void)?
    }
}
