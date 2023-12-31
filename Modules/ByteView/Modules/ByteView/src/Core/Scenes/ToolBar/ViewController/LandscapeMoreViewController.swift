//
//  LandscapeMoreViewController.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/13.
//

import UIKit
import ByteViewTracker
import UniverseDesignIcon

class LandscapeMoreViewController: VMViewController<ToolBarViewModel> {
    enum Layout {
        static let containerWidth: CGFloat = 336
        static let bottomViewHeight: CGFloat = 56
        static let separateLineHeight: CGFloat = 0.5
    }

    // 只用于 iPhone 刘海屏
    private var bottomInset: CGFloat {
        viewModel.hostControlShouldShowOnPhone ? 21 : 33
    }

    private static let animationDuration: TimeInterval = 0.25
    private var isShowing = false {
        didSet {
            viewModel.isExpanded = isShowing
        }
    }
    private var isAnimating = false {
        didSet {
            viewModel.isAnimating = isAnimating
        }
    }

    private var collectionItems: [ToolBarItemType] = []

    private var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingFillMask
        return view
    }()

    // 整个横屏 toolbar 更多页面内容区最外层视图
    let containerView = UIView()
    // toolbar 内容区视图
    private let contentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }()

    private lazy var collectionView: ToolBarCollectionView = {
        let view = ToolBarCollectionView(frame: .zero, isLandscape: true)
        view.layout.isLandscape = true
        view.delegate = self
        return view
    }()

    private lazy var collectionBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var pageControl: FlexiblePageControl = {
        let config: FlexiblePageControl.Config = FlexiblePageControl.Config(dotSize: 5, dotSpace: 4, mediumDotSize: 5, smallDotSize: 5)
        let pageControl = FlexiblePageControl(config: config)
        pageControl.currentPageIndicatorTintColor = UIColor.ud.primaryContentDefault
        pageControl.pageIndicatorTintColor = UIColor.ud.iconN3
        pageControl.hidesForSinglePage = true
        return pageControl
    }()

    private var buttonGroupView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()

    private var items: [ToolBarItem] = []
    var factory: ToolBarFactory { viewModel.factory }

    private var bottomPaddingView = UIView()

    private lazy var hostControlButton = button(with: I18n.View_MV_Security_IconButton,
                                                image: UDIcon.getIconByKey(.safeVcFilled,
                                                                           iconColor: UIColor.ud.iconN1,
                                                                           size: CGSize(width: 18, height: 18)))
    private lazy var muteAllButton = button(with: I18n.View_M_MuteAll,
                                            image: UDIcon.getIconByKey(.micOffFilled,
                                                                       iconColor: UIColor.ud.iconN1,
                                                                       size: CGSize(width: 18, height: 18)))

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    override func setupViews() {
        super.setupViews()
        // 默认隐藏
        view.isHidden = true
        view.backgroundColor = .clear

        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 14
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.snp.bottom)
            make.width.equalTo(Layout.containerWidth)
        }

        let containerBackground = UIView()
        containerBackground.backgroundColor = UIColor.ud.vcTokenMeetingBgActionPanel
        containerView.addSubview(containerBackground)
        containerBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addArrangedSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(195)
        }

        contentView.addArrangedSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.height.equalTo(5)
        }

        // 不管 pageControl、主持人会控按钮隐藏与否，底部都有一个 8 的间距，因此用一个固定高度的视图代替
        let space = UIView()
        contentView.addArrangedSubview(space)
        space.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }

        contentView.addArrangedSubview(collectionBottomLine)
        collectionBottomLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        contentView.addArrangedSubview(buttonGroupView)
        buttonGroupView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.height.equalTo(Layout.bottomViewHeight)
        }

        hostControlButton.addTarget(self, action: #selector(handleHostControl), for: .touchUpInside)
        muteAllButton.addTarget(self, action: #selector(handleMuteAll), for: .touchUpInside)
        buttonGroupView.addArrangedSubview(hostControlButton)
        buttonGroupView.addArrangedSubview(muteAllButton)
        [hostControlButton, muteAllButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
        }

        if Display.iPhoneXSeries {
            contentView.addArrangedSubview(bottomPaddingView)
            bottomPaddingView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(bottomInset)
            }
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        backgroundView.addGestureRecognizer(tap)

        resetToolbarItems()
        updateHostControl()
        updateBottomView()
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.addListener(self)
    }

    // MARK: - Public

    func show(animated: Bool) {
        view.isHidden = false
        showContainerView(animated: animated)
    }

    func hide(animated: Bool, completion: (() -> Void)?) -> Bool {
        guard isShowing else {
            completion?()
            return true
        }
        hideContainerView(animated: animated, completion: {
            self.view.isHidden = true
            completion?()
        })
        return false
    }

    // MARK: - Private

    private func resetToolbarItems() {
        let items = viewModel.phoneMoreItems
            .map { factory.item(for: $0) }
            .filter { $0.phoneLocation == .more }
        if self.items.map(\.itemType) != items.map(\.itemType) {
            self.items = items
            collectionView.initCollectionItems(items)
            updateMoreBadge()
        }
    }

    private func updateMoreItem(_ item: ToolBarItem) {
        if item.itemType == .security {
            updateHostControl()
            return
        }

        items = collectionView.update(item: item, collectionItems: viewModel.phoneMoreItems)
        updateMoreBadge()
        updateBottomView()
    }

    private func updateHostControl() {
        guard let item = viewModel.hostControlItem else { return }
        let showHostControl = item.phoneLocation != .none
        // line, buttonGroup, pageControl 都是 stackView 的子视图，设置 isHidden 在某些系统有 bug，
        // 即使使用 isHiddenInStackView 也没有效。因此同时通过 alpha 控制显示隐藏
        // TODO: @chenyizhuo 从 stackView 里拿出来
        collectionBottomLine.isHiddenInStackView = !showHostControl
        collectionBottomLine.alpha = showHostControl ? 1 : 0
        buttonGroupView.isHiddenInStackView = !showHostControl
        buttonGroupView.alpha = showHostControl ? 1 : 0
    }

    private func updateMoreBadge() {
        (factory.item(for: .more) as? ToolBarMoreItem)?.updateMoreBadge()
    }

    private func updateBottomView() {
        pageControl.numberOfPages = collectionView.numberOfPages
        pageControl.isHiddenInStackView = pageControl.numberOfPages <= 1
        pageControl.alpha = pageControl.numberOfPages <= 1 ? 0 : 1
        if Display.iPhoneXSeries {
            bottomPaddingView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(self.bottomInset)
            }
        }
    }

    private func showContainerView(animated: Bool) {
        Self.logger.info("Landscape More VC show container view")
        self.blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()

        let animationBlock = { [weak self] in
            guard let self = self else { return }
            self.containerView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(Layout.containerWidth)
            }
            self.view.layoutIfNeeded()
        }

        if animated {
            // 定位起点
            containerView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(view.snp.bottom)
                make.width.equalTo(Layout.containerWidth)
            }
            view.layoutIfNeeded()

            isAnimating = true
            UIView.animate(withDuration: Self.animationDuration, animations: {
                animationBlock()
            }, completion: { _ in
                self.isShowing = true
                self.isAnimating = false
            })
        } else {
            UIView.performWithoutAnimation {
                animationBlock()
                self.isShowing = true
                self.isAnimating = false
            }
        }
    }

    private func hideContainerView(animated: Bool, completion: (() -> Void)?) {
        self.blockFullScreenToken = nil
        if animated {
            isAnimating = true
            UIView.animate(withDuration: Self.animationDuration, animations: {
                self.containerView.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(self.view.snp.bottom)
                    make.width.equalTo(Layout.containerWidth)
                }
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.isAnimating = false
                self.isShowing = false
                completion?()
            })
        } else {
            isAnimating = false
            isShowing = false
            completion?()
        }
    }

    private func button(with title: String, image: UIImage?) -> UIButton {
        let button = VisualButton(type: .custom)
        button.edgeInsetStyle = .left
        button.space = 6
        button.setAttributedTitle(NSAttributedString(string: title, config: .bodyAssist, alignment: .center), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1), for: .highlighted)
        button.setImage(image, for: .normal)
        return button
    }

    // MARK: - Actions

    @objc
    private func handleTap() {
        _ = hide(animated: true, completion: nil)
    }

    @objc
    private func handleHostControl() {
        viewModel.hostControlItem?.openHostControlPage()
    }

    @objc
    private func handleMuteAll() {
        viewModel.hostControlItem?.muteAll()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh{
            self.resetToolbarItems()
            if newContext.layoutType.isPhoneLandscape {
                if viewModel.isExpanded && !viewModel.isAnimating {
                    showContainerView(animated: false)
                    view.isHidden = false
                } else {
                    hideContainerView(animated: false, completion: nil)
                    view.isHidden = true
                }
            } else {
                blockFullScreenToken = nil
                view.isHidden = true
            }
        }
    }
}

extension LandscapeMoreViewController: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        Util.runInMainThread {
            self.updateMoreItem(item)
        }
    }
}

extension LandscapeMoreViewController: ToolBarCollectionViewDelegate {
    func toolbarCollectionViewDidScroll(_ collectionView: UICollectionView) {
        let pageWidth = collectionView.bounds.width
        let offsetX = collectionView.contentOffset.x
        guard pageWidth != 0, self.currentLayoutContext.layoutType.isPhoneLandscape else { return }
        pageControl.setProgress(contentOffsetX: offsetX, pageWidth: pageWidth)
    }
}
