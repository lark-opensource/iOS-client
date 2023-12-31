//
//  SuspendBubbleView.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import Lottie
import FigmaKit

public final class SuspendBubbleView: UIView {

    enum Alignment {
        case left
        case right
        case center
    }

    enum State {
        case none
        case bubbleOnly
        case viewOnly
        case both

        var hasBorder: Bool {
            switch self {
            case .bubbleOnly, .both:
                return true
            case .none, .viewOnly:
                return true
            }
        }
    }

    /// 气泡的停靠方位
    var alignment: Alignment = .right {
        didSet { updateAlignment() }
    }

    /// 气泡的状态
    private var state: State = .none {
        didSet { updateBubbleState() }
    }

    var bubbleSize: CGSize {
        let customSize = getCustomViewSize()
        switch state {
        case .both:
            return CGSize(
                width: max(customSize.width, Cons.bubbleWidth),
                height: Cons.bubbleHeight + customSize.height
            )
        case .viewOnly:
            return customSize
        case .bubbleOnly:
            return CGSize(
                width: Cons.bubbleWidth,
                height: Cons.bubbleHeight
            )
        case .none:
            return .zero
        }
    }

    /// 记录当前的页面数量
    private var currentCount: Int = SuspendManager.shared.suspendItems.count

    private var customWrapperHolder: [String: CustomWrapper] = [:]

    func getCustomViewSize() -> CGSize {
        var res = CGSize.zero
        for wrapper in customWrapperHolder.values {
            let size = wrapper.size
            res.width = max(res.width, (size.width + 2 * Cons.margin))
            res.height += (size.height + 2 * Cons.margin)
        }
        return res
    }

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var backgroundView: UIView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = 8
        blurView.fillColor = UIColor.ud.bgFloat
        blurView.fillOpacity = 0.8
        return blurView
    }()

    private lazy var leftMaskLine: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var rightMaskLine: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var dividingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var customContainer: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.addSubview(dividingLine)
        dividingLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(Cons.borderWidth)
        }
        return view
    }()

    lazy var bubbleContainer = UIView()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var lottieView: LOTAnimationView = {
        let view = LOTAnimationView()
        view.alpha = 0
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(backgroundView)
        addSubview(leftMaskLine)
        addSubview(rightMaskLine)
        addSubview(stackView)
        stackView.addArrangedSubview(customContainer)
        stackView.addArrangedSubview(bubbleContainer)
        bubbleContainer.addSubview(iconView)
        bubbleContainer.addSubview(lottieView)
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        leftMaskLine.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.left.equalToSuperview().offset(-1)
            make.top.equalToSuperview().offset(Cons.borderWidth)
            make.bottom.equalToSuperview().offset(-Cons.borderWidth)
        }
        rightMaskLine.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.right.equalToSuperview().offset(1)
            make.top.equalToSuperview().offset(Cons.borderWidth)
            make.bottom.equalToSuperview().offset(-Cons.borderWidth)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().priority(999)
        }
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Cons.iconSize)
            make.center.equalToSuperview()
        }
        lottieView.snp.makeConstraints { make in
            make.edges.equalTo(iconView)
        }
    }

    private func setupAppearance() {
        // 阴影
        layer.shadowRadius = 4
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.ud.setShadowColor(Cons.shadowColor)
        // 边框与圆角
        backgroundView.layer.borderWidth = Cons.borderWidth
        backgroundView.layer.ud.setBorderColor(Cons.borderColor, bindTo: self)
        backgroundView.layer.cornerRadius = Cons.maxCornerRadius
        backgroundView.layer.masksToBounds = true
        dividingLine.backgroundColor = Cons.borderColor
        // 显示与隐藏
        state = .none
    }

    private func adjustCornerRadius() {
        switch state {
        case .bubbleOnly:
            backgroundView.layer.cornerRadius = Cons.maxCornerRadius
        default:
            backgroundView.layer.cornerRadius = Cons.minCornerRadius
        }
    }
}

// MARK: - Public API

extension SuspendBubbleView {
    /// 设置气泡显示数字
    func updateSuspendCount(_ newCount: Int, animated: Bool = true) {
//        lottieView.alpha = 0
//        iconView.alpha = 1
        if !animated {
            iconView.image = getSuspendIcon(forNum: newCount)
        } else if newCount > currentCount {
            // 增加时，播放动画
            if newCount <= 9 {
                // 9 个以下播放 lottie 动画
                let lottieName = getSuspendLottie(forNum: newCount)
                lottieView.setAnimation(named: lottieName, bundle: BundleConfig.LarkSuspendableBundle)
                lottieView.alpha = 1
                iconView.alpha = 0
                lottieView.play { _ in
                    self.iconView.image = self.getSuspendIcon(forNum: newCount)
                    self.iconView.alpha = 1
                    self.lottieView.alpha = 0
                }
            } else {
                // 9 个以上播放 iOS 动画
                UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .allowUserInteraction, animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                        self.iconView.transform = .init(scaleX: 0.7, y: 0.7)
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4) {
                        self.iconView.transform = .identity
                    }
                }, completion: { _ in

                })
                iconView.image = getSuspendIcon(forNum: newCount)
            }
        } else if newCount < currentCount {
            // 减少时，不播放动画
            iconView.image = getSuspendIcon(forNum: newCount)
        } else {
            // 相同，刷新图片
            iconView.image = getSuspendIcon(forNum: newCount)
        }
        // 更新当前项目数
        currentCount = newCount
        let isBubbleShown = newCount <= 0
        switch state {
        case .none:         state = isBubbleShown ? .none : .bubbleOnly
        case .bubbleOnly:   state = isBubbleShown ? .none : .bubbleOnly
        case .viewOnly:     state = isBubbleShown ? .viewOnly : .both
        case .both:         state = isBubbleShown ? .viewOnly : .both
        }
        updateAlignment()
    }

    /// 添加自定义视图
    func addCustomView(_ view: UIView,
                       size: CGSize,
                       level: UInt8,
                       forKey key: String,
                       isBackgroundOpaque: Bool,
                       tapHandler: (() -> Void)? = nil) {
        if customWrapperHolder[key] != nil {
            removeCustomView(forKey: key)
        }
        let wrapperView = CustomWrapper(
            contentView: view,
            size: size,
            key: key,
            level: level,
            tapHandler: tapHandler
        )
        wrapperView.isBackgroundOpaque = isBackgroundOpaque
        var insertIndex: Int?
        for (index, wrapper) in customContainer.arrangedSubviews.compactMap({ $0 as? CustomWrapper }).enumerated()
        where wrapper.level < level {
            insertIndex = index
            break
        }
        if let insertIndex = insertIndex {
            customContainer.insertArrangedSubview(wrapperView, at: insertIndex)
        } else {
            customContainer.addArrangedSubview(wrapperView)
        }
        hideLastDividingLine()
        self.customWrapperHolder[key] = wrapperView
        switch state {
        case .none:         state = .viewOnly
        case .bubbleOnly:   state = .both
        case .viewOnly:     state = .viewOnly
        case .both:         state = .both
        }
        updateAlignment()
    }

    /// 移除自定义视图
    @discardableResult
    func removeCustomView(forKey key: String) -> UIView? {
        guard let wrapper = customWrapperHolder[key] else { return nil }
        wrapper.removeFromSuperview()
        let customView = wrapper.unwrappedView()
        hideLastDividingLine()
        customWrapperHolder[key] = nil
        switch state {
        case .none:         state = .none
        case .bubbleOnly:   state = .bubbleOnly
        case .viewOnly:     state = customWrapperHolder.isEmpty ? .none : .viewOnly
        case .both:         state = customWrapperHolder.isEmpty ? .bubbleOnly : .both
        }
        updateAlignment()
        return customView
    }
}

// MARK: - Appearance

extension SuspendBubbleView {

    private func updateAlignment() {
        switch alignment {
        case .left:
            backgroundView.layer.maskedCorners = [
                .layerMaxXMaxYCorner,
                .layerMaxXMinYCorner
            ]
            leftMaskLine.isHidden = backgroundView.alpha == 0
            rightMaskLine.isHidden = true
        case .right:
            backgroundView.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMinXMinYCorner
            ]
            leftMaskLine.isHidden = true
            rightMaskLine.isHidden = backgroundView.alpha == 0
        case .center:
            backgroundView.layer.maskedCorners = [
                .layerMaxXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMinXMinYCorner
            ]
            leftMaskLine.isHidden = true
            rightMaskLine.isHidden = true
        }
    }

    private func updateBubbleState() {
        switch state {
        case .none:
            // 不展示气泡
            isHidden = true
            dividingLine.isHidden = true
            bubbleContainer.isHidden = true
            customContainer.isHidden = true
        case .bubbleOnly:
            // 只展示数字
            isHidden = false
            dividingLine.isHidden = true
            bubbleContainer.isHidden = false
            customContainer.isHidden = true
        case .viewOnly:
            // 只展示视图
            isHidden = false
            dividingLine.isHidden = true
            bubbleContainer.isHidden = true
            customContainer.isHidden = false
        case .both:
            // 展示视图+数字
            isHidden = false
            dividingLine.isHidden = false
            bubbleContainer.isHidden = false
            customContainer.isHidden = false
        }
        adjustBackgroundView()
        adjustCornerRadius()
    }

    private func getSuspendLottie(forNum num: Int) -> String {
        switch num {
        case ...1:  return "lottie_suspend_1"
        case 2:     return "lottie_suspend_2"
        case 3:     return "lottie_suspend_3"
        case 4:     return "lottie_suspend_4"
        case 5:     return "lottie_suspend_5"
        case 6:     return "lottie_suspend_6"
        case 7:     return "lottie_suspend_7"
        case 8:     return "lottie_suspend_8"
        case 9...:  return "lottie_suspend_9"
        default:    return "lottie_suspend_9"
        }
    }

    private func getSuspendIcon(forNum num: Int) -> UIImage {
        switch num {
        case ...1:  return BundleResources.LarkSuspendable.icon_suspend_1
        case 2:     return BundleResources.LarkSuspendable.icon_suspend_2
        case 3:     return BundleResources.LarkSuspendable.icon_suspend_3
        case 4:     return BundleResources.LarkSuspendable.icon_suspend_4
        case 5:     return BundleResources.LarkSuspendable.icon_suspend_5
        case 6:     return BundleResources.LarkSuspendable.icon_suspend_6
        case 7:     return BundleResources.LarkSuspendable.icon_suspend_7
        case 8:     return BundleResources.LarkSuspendable.icon_suspend_8
        case 9...:  return BundleResources.LarkSuspendable.icon_suspend_9
        default:    return BundleResources.LarkSuspendable.icon_suspend_9
        }
    }

    private func hideLastDividingLine() {
        for (index, wrapper) in customContainer.arrangedSubviews.compactMap({ $0 as? CustomWrapper }).enumerated() {
            wrapper.isDividingLineHidden = index == customContainer.arrangedSubviews.count - 1
        }
    }

    /// 调整背景视图的透明度
    private func adjustBackgroundView() {
        guard state == .viewOnly,
            customContainer.arrangedSubviews.count == 1,
              let customWrapper = customContainer.arrangedSubviews[0] as? CustomWrapper
        else {
            backgroundView.alpha = 1
            return
        }
        backgroundView.alpha = customWrapper.isBackgroundOpaque ? 1 : 0
    }
}

final class CustomWrapper: UIView {

    struct CustomProperties {
        var translatesAutoresizingMask: Bool

        init(from contentView: UIView) {
            self.translatesAutoresizingMask = contentView.translatesAutoresizingMaskIntoConstraints
        }
    }

    var key: String
    var size: CGSize
    var level: UInt8
    var contentView: UIView
    var tapHandler: (() -> Void)?
    var isBackgroundOpaque: Bool = true
    var contentProperties: CustomProperties

    var isDividingLineHidden: Bool {
        get { dividingLine.isHidden }
        set { dividingLine.isHidden = newValue }
    }

    private lazy var dividingLine: UIView = {
        let line = UIView()
        line.backgroundColor = Cons.borderColor
        return line
    }()

    private lazy var container = UIStackView()

    func setDividingLineHidden(_ isHidden: Bool) {
        dividingLine.isHidden = isHidden
    }

    func unwrappedView() -> UIView {
        contentView.removeFromSuperview()
        contentView.translatesAutoresizingMaskIntoConstraints =
            contentProperties.translatesAutoresizingMask
        return contentView
    }

    init(contentView: UIView, size: CGSize, key: String, level: UInt8, tapHandler: (() -> Void)? = nil) {
        self.key = key
        self.size = size
        self.level = level
        self.tapHandler = tapHandler
        self.contentView = contentView
        self.contentProperties = CustomProperties(from: contentView)
        super.init(frame: .zero)
        setupSubviews()
        if tapHandler != nil {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCustomView)))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(container)
        addSubview(dividingLine)
        container.addArrangedSubview(contentView)
        container.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Cons.margin)
        }
        dividingLine.snp.makeConstraints { make in
            make.height.equalTo(Cons.borderWidth)
            make.leading.trailing.bottom.equalToSuperview()
        }
        container.layer.masksToBounds = true
        container.layer.cornerRadius = Cons.minCornerRadius - Cons.margin
    }

    @objc
    private func didTapCustomView() {
        tapHandler?()
    }
}

// MARK: Constants

extension SuspendBubbleView {
    /// 多任务图标的标准大小
    static var iconSize: CGSize {
        return Cons.iconSize
    }
    /// 多任务图标 View 的占位大小
    static var customSize: CGSize {
        return CGSize(
            width: Cons.bubbleWidth - Cons.margin * 2,
            height: Cons.bubbleHeight - Cons.margin * 2
        )
    }
    /// 多任务图标 View 的占位大小
    static var customIconSize: CGSize {
        return CGSize(
            width: Cons.bubbleWidth - Cons.margin * 4,
            height: Cons.bubbleHeight - Cons.margin * 4
        )
    }
}

private enum Cons {
    static var bubbleWidth: CGFloat { SuspendConfig.bubbleSize.width }
    static var bubbleHeight: CGFloat { SuspendConfig.bubbleSize.height }
    static var margin: CGFloat { 8 }
    static var borderWidth: CGFloat { 0.5 }
    static var minCornerRadius: CGFloat { 12 }
    static var maxCornerRadius: CGFloat { bubbleWidth / 2 }
    static var bubbleContentWidth: CGFloat { bubbleWidth - margin * 2 }
    static var bubbleContentHeight: CGFloat { bubbleHeight - margin * 2 }
    static var iconSize: CGSize { SuspendConfig.bubbleSize }
    static var borderColor: UIColor { UIColor.ud.lineBorderCard }
    static var shadowColor: UIColor { UIColor.ud.shadowDefaultSm }
}
