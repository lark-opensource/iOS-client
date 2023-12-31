//
//  MagicShareOperationView.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/11/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Action
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

// 参考文档 https://bytedance.feishu.cn/wiki/wikcnwtlM4WecLLuDaR1wDodieg
class MagicShareOperationView: UIView {

    // MARK: - Layout Defines

    private enum Layout {

        // common
        static let commonLabelFontSize: CGFloat = 12.0
        static let commonLabelHeight: CGFloat = 18.0
        static let commonButtonCornerRadius: CGFloat = 6.0
        static let commonButtonBorderWidth: CGFloat = 1.0
        static let commonButtonTitleFontSize: CGFloat = Display.phone ? 14.0 : 12.0
        static let commonButtonMinWidth: CGFloat = Display.phone ? 60.0 : 48.0
        static let commonButtonHeight: CGFloat = Display.phone ? 28.0 : 24.0
        static let commonButtonContentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
        static let commonInteractionWidth: CGFloat = 24.0
        static let commonInteractionHeight: CGFloat = 10.0

        // specified
        static let contentViewHorizontalEdgeSpacing: CGFloat = Display.phone ? 12.0 : 16.0
        static let bottomSaperateLineHeight: CGFloat = 0.5
        static let stackViewSpacing: CGFloat = 12.0
        static let stackViewHeight: CGFloat = 28.0
        static let backToLastFileButtonDimension: CGFloat = Display.phone ? 28.0 : 24.0
        static let backToLastFileButtonImageSize = CGSize(width: 16, height: 16)
        static let copyAndRefreshButtonImageDimension: CGFloat = 18.0
        static let copyAndRefreshButtonDimension: CGFloat = 18.0
        static let placeholderViewMinWidth: CGFloat = 12.0
        static let saperateLineSize: CGSize = CGSize(width: 1.0, height: 16.0)
        static let moreButtonMinWidth: CGFloat = 48.0

        // stack view spacing
        static let spacingAfterFreeToBrowseLabel: CGFloat = 8.0
        static let maxPlaceholderViewWidth: CGFloat = 1000.0
    }

    /// 投屏转妙享中，p侧切换内容时，f侧提示动画相关时间
    private enum ContentChangeHintAnimationTime {
        /// Pad/Phone-L
        /// 阶段1，0s～0.5s，底色由中间向两侧扩散
        /// 阶段2，0.2s～0.35s，操作栏上的全部视图渐隐
        /// 阶段3，0.35s～0.5s，操作栏上的新视图渐显

        /// 阶段1动画时间
        static let regualrStyleSpreadAnimationTime: CGFloat = 0.5
        /// 阶段2前的时间
        static let timeBeforeDisappear: CGFloat = 0.2
        /// 阶段2动画时间
        static let regualrStyleDisappearAnimationTime: CGFloat = 0.15
        /// 阶段3动画时间
        static let regualrStyleAppearAnimationTime: CGFloat = 0.15

        /// Phone-P
        /// 阶段1，0s～0.3s，底色由左至右扩散
        /// 阶段2，0.1s～0.5s，“自由浏览中”和“文档标题”划出
        /// 阶段2，0.1s～0.3s，“自由浏览中”和“文档标题”渐隐
        /// 阶段3，0.15s～0.55s，“共享人已切换内容”划入+渐显

        /// 阶段1动画时间
        static let phonePortraitSpreadAnimationTime: CGFloat = 0.3
        /// 阶段2前的时间
        static let phonePortraitTimeBeforeFadeOut: CGFloat = 0.1
        /// 阶段2渐隐时间
        static let phonePortraitFadeOutAlphaAnimationTime: CGFloat = 0.2
        /// 阶段3前的时间
        static let phonePortraitTimeBeforeFadeIn: CGFloat = 0.15
        /// 阶段2、阶段3，划出or划入动画时间
        static let phonePortraitFadeAnimationTime: CGFloat = 0.4
    }

    // MARK: - Actions

    private var refreshAction: CocoaAction?
    private var copyLinkAction: CocoaAction?
    private var takeOverAction: CocoaAction?
    private var transferPresenterAction: CocoaAction?
    private var switchToOverlayAction: CocoaAction?
    private var backToMagicSharePresenterAction: CocoaAction?
    private var backToShareScreenAction: CocoaAction?

    @objc
    private func configShareControlAction() {
        if self.layoutParams.isSharing {
            transferPresenterAction?.execute()
        } else {
            takeOverAction?.execute()
        }
    }

    @objc
    private func backToPresenterAction() {
        if self.layoutParams.shareStatus == .shareScreenToFollow {
            backToShareScreenAction?.execute()
        } else {
            backToMagicSharePresenterAction?.execute()
        }
    }

    // MARK: - Params Defines

    private var disposeBag = DisposeBag()
    private weak var moreActionSheet: AlignPopoverViewController?
    /// 容纳需要在moreActionSheet上展示的项，展示
    private var moreActionSheetItemsSet = Set<MoreSheetAction>()

    // 手机竖屏
    private lazy var isPortrait: Bool = !VCScene.isLandscape {
        didSet {
            updateDisplayStyle()
            updateBottomSaperateLineHidden()
            // 如果横竖屏变化，收起“更多”面板
            if oldValue != isPortrait {
                dismissMoreActionSheetIfNeeded()
            }
        }
    }

    private lazy var isCompact: Bool = traitCollection.isCompact {
        didSet {
            updateDisplayStyle()
        }
    }

    private lazy var displayStyle: MSDisplayStyle = .iPhonePortrait {
        didSet {
            updateLayoutParams()
        }
    }

    /// 布局样式(沉浸态/堆叠态/平铺态)
    lazy var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var isMagicShare: Bool = true {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var shareStatus: MSShareStatus = .sharing {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var isRemoteEqualLocal: Bool = false {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var canShowPassOnSharing: Bool = false {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var hasMoreThanOneFile: Bool = false {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var isGuest: Bool = false {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var isContentChangeHintDisplaying: Bool = false {
        didSet {
            updateLayoutParams()
        }
    }

    private lazy var layoutParams: MSOperationViewDisplayStyleParams = .default {
        didSet {
            configHiddensAndUpdateLayout(from: oldValue, to: layoutParams)
        }
    }

    // MARK: - Views Defines

    /// 操作栏整体，控制高度
    private let contentView = UIView()

    /// 用一个UIStackView控制水平布局
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Layout.stackViewSpacing
        return stackView
    }()

    /// 回到上一篇文档
    lazy var backToLastFileButton: VisualButton = {
        let button = VisualButton()
        button.setImage(UDIcon.getIconByKey(.spaceLeftOutlined, iconColor: .ud.iconN1, size: Layout.backToLastFileButtonImageSize), for: .normal)
        button.setImage(UDIcon.getIconByKey(.spaceLeftOutlined, iconColor: .ud.iconN3, size: Layout.backToLastFileButtonImageSize), for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.layer.borderWidth = Layout.commonButtonBorderWidth
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.layer.masksToBounds = true
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }
        return button
    }()

    /// “自由浏览中”
    private let freeToBrowseLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_VieiwngOwnTag
        label.textColor = UIColor.ud.carmine
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    /// “共享人已切换内容”
    private let presenterChangedShareContentLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_SwitchContentWillReturn("")
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    /// 显示正在共享的内容
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        return label
    }()

    /// 复制按钮
    private lazy var copyButton: VisualButton = {
        let button = VisualButton()
        let size = CGSize(width: Layout.copyAndRefreshButtonImageDimension, height: Layout.copyAndRefreshButtonImageDimension)
        button.setImage(UDIcon.getIconByKey(.globalLinkOutlined, iconColor: .ud.iconN2, size: size),
                        for: .normal)
        button.vc.setBackgroundColor(UIColor.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1), for: .highlighted)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.addInteraction(type: .highlight,
                              shape: .roundedRect(CGSize(width: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionWidth,
                                                         height: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionHeight), 6.0))
        return button
    }()

    /// 刷新按钮
    private lazy var refreshButton: VisualButton = {
        let button = VisualButton()
        let size = CGSize(width: Layout.copyAndRefreshButtonImageDimension, height: Layout.copyAndRefreshButtonImageDimension)
        button.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: .ud.iconN2, size: size),
                        for: .normal)
        button.vc.setBackgroundColor(UIColor.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1), for: .highlighted)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.addInteraction(type: .highlight,
                              shape: .roundedRect(CGSize(width: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionWidth,
                                                         height: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionHeight), 6.0))
        return button
    }()

    /// 占位的View，sp4
    private let placeholderView = UIView()

    /// 更多其他操作
    private lazy var moreButton: VisualButton = {
        let button = VisualButton()
        button.contentEdgeInsets = Layout.commonButtonContentEdgeInsets
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setTitle(I18n.View_G_More, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonButtonTitleFontSize)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.layer.borderWidth = Layout.commonButtonBorderWidth
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.layer.masksToBounds = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        }
        return button
    }()

    /// 成为共享人 / 转移共享人权限，仅在横屏下显示
    private lazy var configShareControlButton: VisualButton = {
        let button = VisualButton()
        button.contentEdgeInsets = Layout.commonButtonContentEdgeInsets
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setTitle(I18n.View_VM_TakeOverSharingButton, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonButtonTitleFontSize)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.layer.borderWidth = Layout.commonButtonBorderWidth
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.layer.masksToBounds = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(configShareControlAction), for: .touchUpInside)
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        }
        return button
    }()

    /// 跟随共享人 / 回到共享屏幕
    lazy var backToPresenterButton: MagicShareGradientBackgroundButton = {
        let button = MagicShareGradientBackgroundButton()
        button.contentEdgeInsets = Layout.commonButtonContentEdgeInsets
        button.setTitle(I18n.View_VM_FollowPersonSharing, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonButtonTitleFontSize)
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.layer.masksToBounds = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        }
        button.addTarget(self, action: #selector(backToPresenterAction), for: .touchUpInside)
        return button
    }()

    /// iPad-C视图下的分割线
    private let saperateLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()

    /// 停止共享
    private lazy var stopSharingButton: VisualButton = {
        let button = VisualButton()
        button.contentEdgeInsets = Layout.commonButtonContentEdgeInsets
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgDangerPressed, for: .highlighted)
        button.setTitle(I18n.View_VM_StopSharing, for: .normal)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonButtonTitleFontSize)
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.layer.masksToBounds = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setBorderColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.layer.borderWidth = Layout.commonButtonBorderWidth
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        }
        return button
    }()

    /// 投屏转妙享中，共享人切换了内容时，显示的渐变背景色
    private lazy var shareContentChangeHintBackgroundView: UIImageView = {
        let imageView = UIImageView()
        let gradientImage = UIImage.vc.horizontalGradientImage(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 40),
            colors: [UIColor(red: 0.984, green: 0.922, blue: 0.984, alpha: 1.0),
                     UIColor(red: 1.0, green: 0.945, blue: 0.918, alpha: 1.0),
                     UIColor(red: 1, green: 0.965, blue: 0.875, alpha: 1.0)])
        imageView.image = gradientImage
        imageView.contentMode = .redraw
        return imageView
    }()

    // MARK: - 投屏转妙享“共享人已切换内容”提示显示时，用于动画的临时视图

    private let mockPresenterChangedShareContentLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_SwitchContentWillReturn("")
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.alpha = 0
        return label
    }()

    private let mockFreeToBrowseLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_VieiwngOwnTag
        label.textColor = UIColor.ud.carmine
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize, weight: .medium)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.alpha = 0
        return label
    }()

    private let mockFileNameLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        label.alpha = 0
        return label
    }()

    private lazy var mockShareContentChangeHintBackgroundView: UIImageView = {
        let imageView = UIImageView()
        let gradientImage = UIImage.vc.horizontalGradientImage(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 40),
            colors: [UIColor(red: 0.984, green: 0.922, blue: 0.984, alpha: 1.0),
                     UIColor(red: 1.0, green: 0.945, blue: 0.918, alpha: 1.0),
                     UIColor(red: 1, green: 0.965, blue: 0.875, alpha: 1.0)])
        imageView.image = gradientImage
        imageView.contentMode = .redraw
        return imageView
    }()

    /// 底线
    private let bottomSaperateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()

    // MARK: - Allocations

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupSubviews()
        setupSubviewsConstraints()

        isCompact = traitCollection.isCompact
        isPortrait = isPhonePortrait

        updateInterfaceStyleIfNeeded()
    }

    private func updateInterfaceStyleIfNeeded() {
        if #available(iOS 13.0, *) {
            let style = UITraitCollection.current.userInterfaceStyle
            if style == .dark {
                let darkGradientImage = UIImage.vc.horizontalGradientImage(
                    bounds: CGRect(x: 0, y: 0, width: 100, height: 40),
                    colors: [UIColor(red: 0.8, green: 0.278, blue: 0.573, alpha: 0.4),
                             UIColor(red: 0.8, green: 0.278, blue: 0.263, alpha: 0.4),
                             UIColor(red: 0.871, green: 0.51, blue: 0.094, alpha: 0.4)])
                shareContentChangeHintBackgroundView.image = darkGradientImage
                mockShareContentChangeHintBackgroundView.image = darkGradientImage
            } else {
                let lightGradientImage = UIImage.vc.horizontalGradientImage(
                    bounds: CGRect(x: 0, y: 0, width: 100, height: 40),
                    colors: [UIColor(red: 0.984, green: 0.922, blue: 0.984, alpha: 1.0),
                             UIColor(red: 1.0, green: 0.945, blue: 0.918, alpha: 1.0),
                             UIColor(red: 1, green: 0.965, blue: 0.875, alpha: 1.0)])
                shareContentChangeHintBackgroundView.image = lightGradientImage
                mockShareContentChangeHintBackgroundView.image = lightGradientImage
            }
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 小窗后可能会拿到空的backToPresenterButton.bounds，此时立刻layout
        if !backToPresenterButton.isHiddenInStackView && backToPresenterButton.frame.size.height == 0 {
            backToPresenterButton.layoutIfNeeded()
        }
        if !freeToBrowseLabel.isHiddenInStackView && freeToBrowseLabel.frame.size.height == 0 {
            freeToBrowseLabel.layoutIfNeeded()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        isPortrait = isPhonePortrait
        isCompact = !isRegular
        updateInterfaceStyleIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func switchToOverlay() {
        self.switchToOverlayAction?.execute()
    }

    // MARK: - Layout

    private func setupSubviews() {
        // set background
        backgroundColor = UIColor.ud.bgBody

        // add subviews
        addSubview(contentView)
        contentView.addSubview(shareContentChangeHintBackgroundView)
        contentView.addSubview(contentStackView)
        contentView.addSubview(bottomSaperateLine)

        contentStackView.addSubview(mockPresenterChangedShareContentLabel)
        contentStackView.addSubview(mockFileNameLabel)
        contentStackView.addSubview(mockFreeToBrowseLabel)

        contentStackView.addArrangedSubview(backToLastFileButton)
        contentStackView.addArrangedSubview(presenterChangedShareContentLabel)
        contentStackView.addArrangedSubview(freeToBrowseLabel)
        contentStackView.addArrangedSubview(fileNameLabel)
        contentStackView.addArrangedSubview(copyButton)
        contentStackView.addArrangedSubview(refreshButton)
        contentStackView.addArrangedSubview(placeholderView)
        contentStackView.addArrangedSubview(moreButton)
        contentStackView.addArrangedSubview(configShareControlButton)
        contentStackView.addArrangedSubview(backToPresenterButton)
        contentStackView.addArrangedSubview(saperateLineView)
        contentStackView.addArrangedSubview(stopSharingButton)

        // stack view static spacing
        contentStackView.setCustomSpacing(Layout.spacingAfterFreeToBrowseLabel, after: freeToBrowseLabel)
        contentStackView.setCustomSpacing(0, after: placeholderView)

        // stack view dynamic spacing
        updateStackViewSpacings()
    }

    private func updateStackViewSpacings() {
        // dynamic spacing
        let layoutParams = self.layoutParams
        contentStackView.setCustomSpacing(layoutParams.spacingAfterBackToLastFileButton,
                                          after: backToLastFileButton)
        contentStackView.setCustomSpacing(layoutParams.spacingAfterFileNameLabel,
                                          after: fileNameLabel)
        contentStackView.setCustomSpacing(layoutParams.spacingAfterSharerChangedContentLabel,
                                          after: presenterChangedShareContentLabel)
        contentStackView.setCustomSpacing(layoutParams.spacingAfterCopyButton,
                                          after: copyButton)
        contentStackView.setCustomSpacing(layoutParams.spacingAfterRefreshButton,
                                          after: refreshButton)
    }

    private func setupSubviewsConstraints() {
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(operationViewHeight)
        }
        shareContentChangeHintBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentStackView.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(safeAreaLayoutGuide)
            $0.left.greaterThanOrEqualToSuperview().inset(Layout.contentViewHorizontalEdgeSpacing)
            $0.right.lessThanOrEqualTo(safeAreaLayoutGuide)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.contentViewHorizontalEdgeSpacing)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(labelToTopOffset - 5.0)
            $0.height.equalTo(Layout.stackViewHeight)
        }
        bottomSaperateLine.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(Layout.bottomSaperateLineHeight)
        }
        backToLastFileButton.snp.makeConstraints {
            $0.size.equalTo(Layout.backToLastFileButtonDimension)
        }
        freeToBrowseLabel.snp.makeConstraints {
            $0.height.equalTo(Layout.commonLabelHeight)
        }
        fileNameLabel.snp.makeConstraints {
            $0.height.equalTo(Layout.commonLabelHeight)
        }
        copyButton.snp.makeConstraints {
            $0.size.equalTo(Layout.copyAndRefreshButtonDimension)
        }
        refreshButton.snp.makeConstraints {
            $0.size.equalTo(Layout.copyAndRefreshButtonDimension)
        }
        placeholderView.snp.makeConstraints {
            $0.width.equalTo(Layout.placeholderViewMinWidth)
        }
        moreButton.snp.makeConstraints {
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.width.greaterThanOrEqualTo(Layout.moreButtonMinWidth)
        }
        configShareControlButton.snp.makeConstraints {
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.width.greaterThanOrEqualTo(Layout.commonButtonMinWidth)
        }
        backToPresenterButton.snp.makeConstraints {
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.width.greaterThanOrEqualTo(Layout.commonButtonMinWidth)
        }
        saperateLineView.snp.makeConstraints {
            $0.size.equalTo(Layout.saperateLineSize)
        }
        stopSharingButton.snp.makeConstraints {
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.width.greaterThanOrEqualTo(Layout.commonButtonMinWidth)
        }
    }

    private func updateDisplayStyle() {
        let isPad: Bool = Display.pad
        let isCompact: Bool = self.isCompact
        let isPortrait: Bool = self.isPortrait
        switch (isPad, isCompact, isPortrait) {
        case (true, true, _):
            self.displayStyle = .iPadCompact
        case (true, false, _):
            self.displayStyle = .iPadRegular
        case (false, _, true):
            self.displayStyle = .iPhonePortrait
        case (false, _, false):
            self.displayStyle = .iPhoneLandscape
        }
    }

    private func updateLayoutParams() {
        layoutParams = .init(displayStyle: displayStyle,
                             shareStatus: shareStatus,
                             meetingLayoutStyle: meetingLayoutStyle,
                             hasMoreThanOneFile: hasMoreThanOneFile,
                             isRemoteEqualLocal: isRemoteEqualLocal,
                             canShowPassOnSharing: canShowPassOnSharing,
                             isGuest: isGuest,
                             isContentChangeHintDisplaying: isContentChangeHintDisplaying)
    }
}

extension MagicShareOperationView {

    func bindViewModel(_ viewModel: MagicShareOperationViewModel) {
        disposeBag = DisposeBag()

        // bind label content
        viewModel.sharingFileNameDriver
            .drive(fileNameLabel.rx.text)
            .disposed(by: disposeBag)

        // bind actions
        copyButton.rx.action = viewModel.copyFileURLAction
        refreshButton.rx.action = viewModel.reloadAction
        backToLastFileButton.rx.action = viewModel.backAction
        stopSharingButton.rx.action = viewModel.stopSharingAction

        let meeting = viewModel.meeting
        self.isGuest = viewModel.isGuest
        self.refreshAction = viewModel.reloadAction
        self.copyLinkAction = viewModel.copyFileURLAction
        self.takeOverAction = viewModel.takeControlAciton
        self.transferPresenterAction = viewModel.transferPresenterRoleAction
        self.switchToOverlayAction = viewModel.switchToOverlayAction
        self.backToMagicSharePresenterAction = viewModel.backToMagicSharePresenterAction
        self.backToShareScreenAction = viewModel.backToShareScreenAction

        let fullScreenDetector = viewModel.context.fullScreenDetector
        moreButton.rx.action = CocoaAction(workFactory: { [weak self, weak meeting, weak fullScreenDetector] _ in
            guard let self = self, let meeting = meeting else { return .empty() }

            MagicShareTracksV2.trackMagicShareClickOperation(action: .clickMore, isSharer: meeting.shareData.isSharingContent)

            // build action sheet
            let actionSheetVC = self.buildActionSheet(meeting: meeting)
            let anchor = AlignPopoverAnchor(sourceView: self.moreButton,
                                            arrowDirection: Display.phone ? .down : .up,
                                            contentWidth: .fixed(self.calcActionSheetMaxWidth()),
                                            contentHeight: CGFloat(self.moreActionSheetItemsSet.count * 50),
                                            contentInsets: UIEdgeInsets(top: 4.0, left: 0, bottom: 4.0, right: 0),
                                            positionOffset: CGPoint(x: 0, y: Display.phone ? -4 : 4),
                                            cornerRadius: 8.0,
                                            borderColor: UIColor.ud.lineBorderCard,
                                            dimmingColor: UIColor.clear,
                                            containerColor: UIColor.ud.bgFloat)

            self.moreActionSheet = AlignPopoverManager.shared.present(viewController: actionSheetVC, anchor: anchor)
            self.moreActionSheet?.fullScreenDetector = fullScreenDetector
            return .empty()
        })

        let tapGr = UITapGestureRecognizer(target: self, action: #selector(switchToOverlay))
        self.addGestureRecognizer(tapGr)

        // bind hidden
        viewModel.isInMagicShareObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isMagicShareOn: Bool) in
                self?.isHidden = !isMagicShareOn
                self?.moreActionSheet?.dismiss(animated: false)
            })
            .disposed(by: disposeBag)

        viewModel.showBackButtonObservable
            .subscribe(onNext: { [weak self] (hasMoreThanOneFile: Bool) in
                self?.hasMoreThanOneFile = hasMoreThanOneFile
            })
            .disposed(by: disposeBag)

        viewModel.shareStatusObservable
            .subscribe(onNext: { [weak self] (shareStatus: MSShareStatus) in
                self?.shareStatus = shareStatus
            })
            .disposed(by: disposeBag)

        viewModel.isRemoteEqualLocalObservable
            .subscribe(onNext: { [weak self] (isRemoteEqualLocal: Bool) in
                self?.isRemoteEqualLocal = isRemoteEqualLocal
            })
            .disposed(by: disposeBag)

        viewModel.showPassOnSharingObservable
            .subscribe(onNext: { [weak self] (canShowPassOnSharing: Bool) in
                self?.canShowPassOnSharing = canShowPassOnSharing
            })
            .disposed(by: disposeBag)

        viewModel.isContentChangeHintDisplayingObservable
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (isContentChangeHintDisplaying: Bool) in
                self?.isContentChangeHintDisplaying = isContentChangeHintDisplaying
            })
            .disposed(by: disposeBag)
    }

    private func configHiddensAndUpdateLayout(from oldLayoutParams: MSOperationViewDisplayStyleParams,
                                              to newLayoutParams: MSOperationViewDisplayStyleParams) {
        Util.runInMainThread { [weak self] in
            self?.configHiddensAndUpdateLayoutInMainThread(from: oldLayoutParams,
                                                           to: newLayoutParams)
        }
    }

    // disable-lint: long function
    private func configHiddensAndUpdateLayoutInMainThread(from oldLayoutParams: MSOperationViewDisplayStyleParams,
                                                          to newLayoutParams: MSOperationViewDisplayStyleParams) {
        switch (oldLayoutParams.isContentChangeHintDisplaying, newLayoutParams.isContentChangeHintDisplaying) {
        case (false, true):
            if [.iPadRegular, .iPadCompact, .iPhoneLandscape].contains(newLayoutParams.displayStyle) {
                contentView.insertSubview(mockShareContentChangeHintBackgroundView, belowSubview: contentStackView)
                mockShareContentChangeHintBackgroundView.frame = CGRect(x: contentView.frame.width / 2.0,
                                                                        y: 0,
                                                                        width: 0,
                                                                        height: contentView.frame.height)
                contentStackView.arrangedSubviews
                    .filter { !$0.isHiddenInStackView }
                    .forEach { $0.alpha = 1 }
                shareContentChangeHintBackgroundView.alpha = 0
                // 阶段1，底色扩张，从第0s开始，持续0.5s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.regualrStyleSpreadAnimationTime) { [weak self] in
                    guard let self = self else { return }
                    self.mockShareContentChangeHintBackgroundView.frame = CGRect(x: 0,
                                                                                 y: 0,
                                                                                 width: self.contentView.frame.width,
                                                                                 height: self.contentView.frame.height)
                }
                // 阶段2，旧布局渐隐，从第0.2s开始，持续0.15s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.regualrStyleDisappearAnimationTime,
                               delay: ContentChangeHintAnimationTime.timeBeforeDisappear) { [weak self] in
                    guard let self = self else { return }
                    self.contentStackView.arrangedSubviews
                        .filter { !$0.isHiddenInStackView }
                        .forEach { $0.alpha = 0 }
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    // 变化为新布局
                    self.refreshLayoutImmediately()
                    self.contentStackView.arrangedSubviews.forEach { $0.alpha = 0 }
                    // 阶段3，新布局渐显，从第0.35s开始，持续0.15s
                    UIView.animate(withDuration: ContentChangeHintAnimationTime.regualrStyleAppearAnimationTime) { [weak self] in
                        guard let self = self else { return }
                        self.contentStackView.arrangedSubviews
                            .filter { !$0.isHiddenInStackView }
                            .forEach { $0.alpha = 1 }
                    } completion: { [weak self] _ in
                        guard let self = self else { return }
                        self.mockShareContentChangeHintBackgroundView.removeFromSuperview()
                        self.shareContentChangeHintBackgroundView.alpha = 1.0
                    }
                }
            } else {
                let oldFreeToBrowseLabelFrame = freeToBrowseLabel.frame
                let oldFileNameLabelFrame = fileNameLabel.frame

                mockFreeToBrowseLabel.frame = oldFreeToBrowseLabelFrame
                mockFreeToBrowseLabel.alpha = 1
                mockFileNameLabel.frame = oldFileNameLabelFrame
                mockFileNameLabel.alpha = 1
                mockFileNameLabel.text = fileNameLabel.text
                shareContentChangeHintBackgroundView.alpha = 0

                refreshLayoutImmediately()
                layoutIfNeeded()

                let newPresenterChangedContentLabelFrame = presenterChangedShareContentLabel.frame

                mockPresenterChangedShareContentLabel.frame = CGRect(x: newPresenterChangedContentLabelFrame.minX - newPresenterChangedContentLabelFrame.width,
                                                                     y: newPresenterChangedContentLabelFrame.minY,
                                                                     width: newPresenterChangedContentLabelFrame.width,
                                                                     height: newPresenterChangedContentLabelFrame.height)
                mockPresenterChangedShareContentLabel.alpha = 0
                presenterChangedShareContentLabel.alpha = 0

                contentView.insertSubview(mockShareContentChangeHintBackgroundView, belowSubview: contentStackView)
                mockShareContentChangeHintBackgroundView.frame = CGRect(x: 0,
                                                                        y: 0,
                                                                        width: 0,
                                                                        height: contentView.frame.height)
                // 阶段1，底色扩张，从第0s开始，持续0.3s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.phonePortraitSpreadAnimationTime) { [weak self] in
                    guard let self = self else { return }
                    self.mockShareContentChangeHintBackgroundView.frame = CGRect(x: 0,
                                                                                 y: 0,
                                                                                 width: self.contentView.frame.width,
                                                                                 height: self.contentView.frame.height)
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.mockShareContentChangeHintBackgroundView.removeFromSuperview()
                    self.shareContentChangeHintBackgroundView.alpha = 1.0
                }
                // 阶段2，“共享人已变更内容”渐显且弹簧效果变更位置，从第0.1s开始，持续0.4s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.phonePortraitFadeAnimationTime,
                               delay: ContentChangeHintAnimationTime.phonePortraitTimeBeforeFadeIn,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 1.5) { [weak self] in
                    guard let self = self else { return }
                    self.mockPresenterChangedShareContentLabel.frame = newPresenterChangedContentLabelFrame
                    self.mockPresenterChangedShareContentLabel.alpha = 1
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    // 移除复制的视图
                    self.mockPresenterChangedShareContentLabel.alpha = 0
                    self.presenterChangedShareContentLabel.alpha = 1
                }
                // 阶段2，“自由浏览中”和“文件名”渐隐且变更位置，从第0.1s开始，持续0.4s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.phonePortraitFadeAnimationTime,
                               delay: ContentChangeHintAnimationTime.phonePortraitTimeBeforeFadeOut) { [weak self] in
                    guard let self = self else { return }
                    self.mockFreeToBrowseLabel.frame = CGRect(x: oldFreeToBrowseLabelFrame.maxX + newPresenterChangedContentLabelFrame.width,
                                                              y: oldFreeToBrowseLabelFrame.minY,
                                                              width: oldFreeToBrowseLabelFrame.width,
                                                              height: oldFreeToBrowseLabelFrame.height)
                    self.mockFileNameLabel.frame = CGRect(x: oldFileNameLabelFrame.maxX + newPresenterChangedContentLabelFrame.width,
                                                          y: oldFileNameLabelFrame.minY,
                                                          width: oldFileNameLabelFrame.width,
                                                          height: oldFileNameLabelFrame.height)
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    // 移除复制的视图
                    self.mockFreeToBrowseLabel.alpha = 0
                    self.mockFileNameLabel.alpha = 0
                }

                // 阶段2，“自由浏览中”和“文件名”渐隐变更位置，从第0.1s开始，持续0.2s
                UIView.animate(withDuration: ContentChangeHintAnimationTime.phonePortraitFadeOutAlphaAnimationTime,
                               delay: ContentChangeHintAnimationTime.phonePortraitTimeBeforeFadeOut) { [weak self] in
                    guard let self = self else { return }
                    self.mockFreeToBrowseLabel.alpha = 0
                    self.mockFileNameLabel.alpha = 0
                } completion: { [weak self] _ in
                    guard let self = self else { return }
                    // 移除复制的视图
                    self.mockFreeToBrowseLabel.alpha = 0
                    self.mockFileNameLabel.alpha = 0
                }
            }
        default:
            refreshLayoutImmediately()
        }
    }
    // enable-lint: long function

    /// 立刻刷新布局
    private func refreshLayoutImmediately() {
        // defines
        let layoutParams = self.layoutParams

        // config hiddens
        self.updateHiddens(with: layoutParams)

        // update stack view spacings
        self.updateStackViewSpacings()

        // config "more" aciton sheet
        self.configMoreActionSheet()

        // update layout
        self.updateLayout(centralizedLayout: layoutParams.isCentralizedLayout,
                          onlyShowTitle: layoutParams.meetingLayoutStyle.onlyShowTitle)

        // recover alpha
        self.contentStackView.arrangedSubviews.forEach { $0.alpha = 1 }

        // differ border color
        self.configBorders()
    }

    private func configBorders() {
        if self.layoutParams.showShareContentChangeHintBackgroundView {
            backToLastFileButton.setBorderColor(UIColor.ud.N900.withAlphaComponent(0.2), for: .normal)
            moreButton.setBorderColor(UIColor.ud.N900.withAlphaComponent(0.2), for: .normal)
        } else {
            backToLastFileButton.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
            moreButton.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        }
    }

    private func updateHiddens(with layoutParams: MSOperationViewDisplayStyleParams) {
        self.backToLastFileButton.isHiddenInStackView = !layoutParams.showBackToLastFileButton
        self.freeToBrowseLabel.isHiddenInStackView = !layoutParams.showFreeToBrowseLabel
        self.fileNameLabel.isHiddenInStackView = !layoutParams.showFileNameLabel
        self.presenterChangedShareContentLabel.isHiddenInStackView = !layoutParams.showPresenterChangedShareContentLabel
        self.shareContentChangeHintBackgroundView.isHidden = !layoutParams.showShareContentChangeHintBackgroundView
        self.copyButton.isHiddenInStackView = !layoutParams.showCopyAndRefreshButton
        self.refreshButton.isHiddenInStackView = !layoutParams.showCopyAndRefreshButton
        self.placeholderView.isHiddenInStackView = !layoutParams.showPlaceholderView
        self.moreButton.isHiddenInStackView = !layoutParams.showMoreButton
        self.configShareControlButton.isHiddenInStackView = !layoutParams.showConfigShareControlButton
        self.configShareControlButton.setTitle(layoutParams.configShareControlButtonText, for: .normal)
        self.backToPresenterButton.isHiddenInStackView = !layoutParams.showBackToPresenterButton
        self.backToPresenterButton.setTitle(layoutParams.backToPresenterButtonText, for: .normal)
        self.saperateLineView.isHiddenInStackView = !layoutParams.showSaperateLineView
        self.stopSharingButton.isHiddenInStackView = !layoutParams.showStopSharingButton
    }

    private func updateBottomSaperateLineHidden() {
        self.bottomSaperateLine.isHidden = !isPhonePortrait
    }

    private func updateLayout(centralizedLayout: Bool, onlyShowTitle: Bool) {
        contentView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(operationViewHeight)
        }
        contentStackView.snp.remakeConstraints {
            $0.left.greaterThanOrEqualTo(safeAreaLayoutGuide)
            $0.left.greaterThanOrEqualToSuperview().inset(Layout.contentViewHorizontalEdgeSpacing)
            $0.right.lessThanOrEqualTo(safeAreaLayoutGuide)
            $0.right.lessThanOrEqualToSuperview().inset(Layout.contentViewHorizontalEdgeSpacing)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(labelToTopOffset - 5.0)
            $0.height.equalTo(Layout.stackViewHeight)
        }
        placeholderView.snp.remakeConstraints {
            if centralizedLayout {
                $0.width.equalTo(12.0)
            } else {
                $0.width.greaterThanOrEqualTo(Layout.maxPlaceholderViewWidth).priority(998) // 不挤压Label的前提下，尽可能撑开
                $0.width.greaterThanOrEqualTo(onlyShowTitle ? 0 : Layout.placeholderViewMinWidth)
            }
        }
        setNeedsLayout()
    }

    private func configMoreActionSheet() {
        let shareStatus = self.layoutParams.shareStatus
        let layoutStyle = self.layoutParams.meetingLayoutStyle
        let displayStyle = self.layoutParams.displayStyle

        if layoutStyle.onlyShowTitle {
            self.moreActionSheetItemsSet = Set<MoreSheetAction>()
            self.moreActionSheet?.dismiss(animated: false)
        } else {
            switch displayStyle {
            case .iPadRegular:
                self.moreActionSheetItemsSet = Set<MoreSheetAction>()
                self.moreActionSheet?.dismiss(animated: false)
            case .iPadCompact, .iPhonePortrait:
                var thirdOption: MoreSheetAction?
                switch shareStatus {
                case .sharing:
                    thirdOption = canShowPassOnSharing ? .passOnSharing : nil
                case .following, .free:
                    thirdOption = .takeControl
                default:
                    break
                }
                self.moreActionSheetItemsSet = Set<MoreSheetAction>([.refresh, .copyLink])
                if let validThirdOption = thirdOption {
                    self.moreActionSheetItemsSet.insert(validThirdOption)
                }
            case .iPhoneLandscape:
                self.moreActionSheetItemsSet = Set<MoreSheetAction>([.refresh, .copyLink])
            }
        }
    }
}

// MARK: - More Action Sheet

extension MagicShareOperationView {

    private func buildActionSheet(meeting: InMeetMeeting) -> ActionSheetController {
        let appearance = ActionSheetAppearance(backgroundColor: UIColor.ud.bgFloat,
                                               contentViewColor: UIColor.ud.bgFloat,
                                               separatorColor: UIColor.clear,
                                               modalBackgroundColor: UIColor.ud.bgMask,
                                               customTextHeight: 50.0)
        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover
        for item in Array(self.moreActionSheetItemsSet).sorted(by: { $0.rawValue < $1.rawValue }) {
            switch item {
            case .refresh:
                actionSheetVC.addAction(buildRefreshSheetAction())
            case .copyLink:
                actionSheetVC.addAction(buildCopySheetAction())
            case .passOnSharing:
                actionSheetVC.addAction(buildPassOnSharingActionSheetAction())
            case .takeControl:
                actionSheetVC.addAction(buildTakeOverAction())
            }
        }
        return actionSheetVC
    }

    private func buildRefreshSheetAction() -> SheetAction {
        let refreshAction = self.refreshAction
        return SheetAction(title: I18n.View_VM_Refresh,
                           titleFontConfig: VCFontConfig.bodyAssist,
                           icon: UDIcon.getIconByKey(.refreshOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)),
                           showBottomSeparator: false,
                           sheetStyle: .iconAndLabel,
                           handler: { _ in
                            refreshAction?.execute()
                           })
    }

    private func buildCopySheetAction() -> SheetAction {
        let copyAction = self.copyLinkAction
        let image = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20))
        return SheetAction(title: I18n.View_VM_CopyFileLink,
                           titleFontConfig: VCFontConfig.bodyAssist,
                           icon: image,
                           showBottomSeparator: false,
                           sheetStyle: .iconAndLabel,
                           handler: { _ in
                            copyAction?.execute()
                           })
    }

    private func buildPassOnSharingActionSheetAction() -> SheetAction {
        let transferPresenterAction = self.transferPresenterAction
        return SheetAction(title: I18n.View_VM_PassOnSharing,
                           titleFontConfig: VCFontConfig.bodyAssist,
                           icon: UDIcon.getIconByKey(.assignedOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)),
                           showBottomSeparator: false,
                           sheetStyle: .iconAndLabel,
                           handler: { _ in
                            transferPresenterAction?.execute()
                           })
    }

    /// 收起“更多”面板
    private func dismissMoreActionSheetIfNeeded() {
        self.moreActionSheet?.dismiss(animated: false)
    }

    private func buildTakeOverAction() -> SheetAction {
        let takeOverAction = self.takeOverAction
        return SheetAction(title: I18n.View_VM_TakeOverSharingButton,
                           titleFontConfig: VCFontConfig.bodyAssist,
                           icon: UDIcon.getIconByKey(.shareScreenOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)),
                           showBottomSeparator: false,
                           sheetStyle: .iconAndLabel,
                           handler: { _ in
                            takeOverAction?.execute()
                           })
    }

    /// 计算MoreActionSheet中各项的最大宽度
    /// - Returns: 16(左边距) + 20(icon宽度) + 12(icon和label间隔) + label.maxWidth + 16(右边距)
    private func calcActionSheetMaxWidth() -> CGFloat {
        let textStyleConfig: VCFontConfig = .bodyAssist
        let lineHeight = textStyleConfig.lineHeight
        var maxWidth: CGFloat = 0
        for item in self.moreActionSheetItemsSet {
            let text: String
            switch item {
            case .refresh:
                text = I18n.View_VM_Refresh
            case .copyLink:
                text = I18n.View_VM_CopyFileLink
            case .passOnSharing:
                text = I18n.View_VM_PassOnSharing
            case .takeControl:
                text = I18n.View_VM_TakeOverSharingButton
            }
            let w = text.vc.boundingWidth(height: lineHeight, config: textStyleConfig)
            maxWidth = maxWidth > w ? maxWidth : w
        }
        return 16 + 20 + 12 + maxWidth + 16
    }
}
