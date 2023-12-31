//
//  FocusDisplayView.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/14.
//

import Foundation
import UIKit
import LarkUIKit
import LarkEmotion
import LarkFoundation
import LarkInteraction
import UniverseDesignIcon
import LarkFocusInterface
import LarkContainer
import LarkSDKInterface

/// 用于展示自己、他人的个人状态
public final class FocusDisplayView: UIView, UserResolverWrapper {

    @ScopedInjectedLazy private var focusManager: FocusManager?
    @ScopedInjectedLazy
    var userSettings: UserGeneralSettings?
    /// 当前是否为 24 小时制
    var is24Hour: Bool {
        return userSettings?.is24HourTime.value ?? false
    }

    public var tapHandler: (() -> Void)?

    @objc
    public func refresh() {
        displayFocusStatus(currentStatusList ?? [], isEditable: isEditable)
    }

    public func configure(with focusList: [ChatterFocusStatus], isEditable: Bool) {
        FocusManager.logger.info("update focusDisplayView with \(focusList.simplifiedDescription) succeed.")
        guard focusList != currentStatusList else {
            FocusManager.logger.info("got same focus list, skip updating focusDisplayView.")
            return
        }
        self.currentStatusList = focusList
        self.isEditable = isEditable
        displayFocusStatus(focusList, isEditable: isEditable)
        if #available(iOS 13.4, *), Display.pad {
            for interaction in focusContainer.lkInteractions {
                focusContainer.removeLKInteraction(interaction)
            }
            guard isEditable else { return }
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            focusContainer.addLKInteraction(pointer)
        }
    }

    public func configure(with focus: ChatterFocusStatus?, isEditable: Bool) {
        var focusList: [ChatterFocusStatus] = []
        if let focus = focus { focusList.append(focus) }
        self.configure(with: focusList, isEditable: isEditable)
    }

    private var currentStatusList: [ChatterFocusStatus]?
    private var isEditable: Bool = false

    private func displayFocusStatus(_ focusList: [ChatterFocusStatus], isEditable: Bool) {
        if let focus = focusList.topActive {
            // Focus State
            focusContainer.isHidden = false
            buttonContainer.isHidden = true
            iconView.config(with: focus)
            titleLabel.text = focus.title
            titleLabel.isHidden = focus.tagInfo.isShowTag
            titleArrow.isHidden = !isEditable
            timeLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleContainer.snp.bottom).offset(1)
                make.trailing.equalTo(titleLabel.isHidden ? iconView : titleLabel)
                make.bottom.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview()
            }
            let isSystemStatus = focus.tagInfo.isShowTag
            let shouldDisplayTime = isEditable || isSystemStatus
            timeLabel.isHidden = !shouldDisplayTime
            if isSystemStatus {
                timeLabel.text = focus.timeFormat.format(startTimestamp: focus.effectiveInterval.startTime, endTimestamp: focus.effectiveInterval.endTime, is24Hour: is24Hour)
            } else {
                timeLabel.text = focus.effectiveInterval.untilTime(is24Hour: is24Hour)
            }
            FocusManager.logger.info("update focusDisplayView with \(focus.title.desensitized()).")
        } else {
            // Empty State
            focusContainer.isHidden = true
            buttonContainer.isHidden = !isEditable
            FocusManager.logger.info("update focusDisplayView, no active status.")
        }
    }

    private lazy var container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .trailing
        return stack
    }()

    private lazy var focusContainer: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var iconView: FocusTagView = {
        let view = FocusTagView(preferredSingleIconSize: 16)
        return view
    }()

    private lazy var titleContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 1
        return stack
    }()

    public private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private lazy var titleArrow: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.expandRightFilled
            .ud.withTintColor(UIColor.ud.iconN1)
        return imageView
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var buttonContainer: UIView = {
        let button = UIView()
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.backgroundColor = UIColor.ud.bgBody
        return button
    }()

    private lazy var emptyIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.addSheetOutlined.withRenderingMode(.alwaysTemplate)
        return imageView
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.LarkFocus.Lark_Profile_Status
        return label
    }()

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        setup()
        setupOnbardingAppearance(isNew: !(focusManager?.isOnboardingShown ?? false))
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(container)
        container.addArrangedSubview(focusContainer)
        focusContainer.addSubview(titleContainer)
        focusContainer.addSubview(timeLabel)
        titleContainer.addArrangedSubview(iconView)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(titleArrow)
        container.addArrangedSubview(buttonContainer)
        buttonContainer.addSubview(emptyIcon)
        buttonContainer.addSubview(emptyLabel)
        titleContainer.setCustomSpacing(3, after: iconView)
        titleContainer.setCustomSpacing(1, after: titleLabel)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Focus Container
        titleContainer.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview()
            make.height.equalTo(20)
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        titleArrow.snp.makeConstraints { make in
            make.width.height.equalTo(8)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleContainer.snp.bottom).offset(1)
            make.trailing.equalTo(titleContainer)
            make.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
        }
        // Empty Container
        buttonContainer.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
        emptyIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.width.height.equalTo(14)
            make.centerY.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(emptyIcon.snp.trailing).offset(2)
            make.trailing.equalToSuperview().offset(-8)
        }
        emptyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        emptyLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    private func setupAppearance() {
        focusContainer.isHidden = true
        buttonContainer.isHidden = false
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .lift))
            buttonContainer.addLKInteraction(action)
        }
    }

    /// 首次出现该入口时，显示 onboarding 蓝色状态
    private func setupOnbardingAppearance(isNew: Bool) {
        let iconColor = isNew ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN2
        let textColor = isNew ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption
        let borderColor = isNew ? UIColor.ud.primaryContentDefault : UIColor.ud.lineBorderCard
        emptyIcon.tintColor = iconColor
        emptyLabel.textColor = textColor
        buttonContainer.ud.setLayerBorderColor(borderColor)
        // 监听 Onboarding 通知，onboarding 展示后恢复正常状态
        if isNew {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(didShowOnboarding),
                name: FocusManager.onboardingShownNotification,
                object: nil
            )
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }

    @objc
    private func didShowOnboarding() {
        setupOnbardingAppearance(isNew: false)
    }
}

/// 用于在 LarkNaviBar 展示个人状态
public final class FocusNaviDisplayView: UIView {

    @objc
    public func refresh() {
        displayFocusStatus(currentStatusList ?? [])
    }

    public func configure(with focusList: [ChatterFocusStatus]) {
        FocusManager.logger.info("update focusNaviView with \(focusList.simplifiedDescription) succeed.")
        guard focusList != currentStatusList else {
            FocusManager.logger.info("got same focus list, skip updating focusNaviView.")
            return
        }
        currentStatusList = focusList
        displayFocusStatus(focusList)
    }

    public func configure(with focus: ChatterFocusStatus?) {
        var focusList: [ChatterFocusStatus] = []
        if let focus = focus { focusList.append(focus) }
        self.configure(with: focusList)
    }

    private var currentStatusList: [ChatterFocusStatus]?

    private func displayFocusStatus(_ focus: [ChatterFocusStatus]) {
        if let focus = focus.topActive {
            isHidden = false
            iconView.config(with: focus)
            titleLabel.text = focus.title
            // 显示 Tag 的情况下，文字包裹在标签里，由 iconView 显示
            titleLabel.isHidden = focus.tagInfo.isShowTag
            FocusManager.logger.info("update focusNaviView with \(focus.title.desensitized()).")
        } else {
            isHidden = true
            FocusManager.logger.info("update focusNaviView, no active status.")
        }
    }

    private lazy var iconView: FocusTagViewLegacy = {
        let view = FocusTagViewLegacy(preferredSingleIconSize: 16)
        return view
    }()

    private lazy var titleContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.rightOutlined
            .ud.withTintColor(UIColor.ud.iconN3)
        return imageView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func setupSubviews() {
        addSubview(iconView)
        addSubview(titleContainer)
        titleContainer.addArrangedSubview(titleLabel)
        titleContainer.addArrangedSubview(arrowView)
    }

    private func setupConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        titleContainer.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(3)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        arrowView.snp.makeConstraints { make in
            make.width.height.equalTo(10)
        }
    }

    private func setupAppearance() {
        isHidden = true
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            self.addLKInteraction(pointer)
        }
    }
}

/// 用于在 iPad MainTabbar 展示个人状态
public final class FocusTabbarDisplayView: UIView {

    public var didBecomeActiveRefreshCallBack: ((Bool) -> ())?

    @objc
    public func refresh() {
        displayFocusStatus(currentStatusList ?? []) { [weak self] (isShowFocus) in
            guard let self = self else { return }
            self.didBecomeActiveRefreshCallBack?(isShowFocus)
        }
    }

    public func configure(with focusList: [ChatterFocusStatus]) {
        FocusManager.logger.info("update focusTabbarView with \(focusList.simplifiedDescription) succeed.")
        guard focusList != currentStatusList else {
            FocusManager.logger.info("got same focus list, skip updating focusTabbarView.")
            return
        }
        currentStatusList = focusList
        displayFocusStatus(focusList)
    }

    public func configure(with focus: ChatterFocusStatus?) {
        var focusList: [ChatterFocusStatus] = []
        if let focus = focus { focusList.append(focus) }
        self.configure(with: focusList)
    }

    private var currentStatusList: [ChatterFocusStatus]?

    private func displayFocusStatus(_ focus: [ChatterFocusStatus], isShowFocusCallBack: ((Bool) -> Void)? = nil) {
        if let focus = focus.topActive {
            isHidden = false
            iconView.config(with: focus)
            isShowFocusCallBack?(true)
        } else {
            isHidden = true
            isShowFocusCallBack?(false)
            FocusManager.logger.info("update tabbar focusTabbarView, no active status.")
        }
    }

    private lazy var iconView: FocusImageView = {
        let view = FocusImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func setupSubviews() {
        addSubview(iconView)
    }

    private func setupConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(18)
        }

        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        isHidden = true
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            self.addLKInteraction(pointer)
        }
    }
}
