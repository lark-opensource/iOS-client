//
//  ToolBarPhoneViewController.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit
import ByteViewTracker
import UniverseDesignIcon
import ByteViewUI

class ToolBarPhoneViewController: ToolBarViewController {
    /// 是否已经展开，动画结束后才更新成最新值
    private var isExpanded = false {
        didSet {
            Self.logger.info("Toolbar set isExpanded to \(isExpanded)")
            viewModel.isExpanded = isExpanded
        }
    }
    private var isAnimating = false {
        didSet {
            Self.logger.info("Toolbar set isAnimating to \(isAnimating)")
            viewModel.isAnimating = isAnimating
        }
    }

    /// 是否是展开后的样式，展开或收起的过程中就会更新
    private var isExpandedLayout = false
    private let toolbar = PhoneToolBar()
    private let contentView = UIView()
    private var expandedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgActionPanel
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    private var contentOriginInPan: CGPoint = .zero
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

    private enum Layout {
        static let toolbarHeight = TiledLayoutGuideHelper.bottomBarHeight
        // 超过50pt开始替换布局
        static let distanceThreshold: CGFloat = 50
    }
    private static let fullAnimationDuration: TimeInterval = 0.3
    private static let halfAnimationDuration: TimeInterval = 0.25

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }
    private var panBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard panBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingFillMask
        view.isHidden = true
        return view
    }()

    private let collectionView = ToolBarCollectionView(frame: .zero, isLandscape: false)
    private lazy var collectionBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private var buttonGroupView: UIStackView = {
        let stack = UIStackView(frame: .zero)
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.distribution = .fillEqually
        stack.spacing = 16
        return stack
    }()

    private lazy var hostControlButton = button(with: I18n.View_MV_Security_IconButton,
                                                image: UDIcon.getIconByKey(.safeVcFilled,
                                                                           iconColor: UIColor.ud.iconN1,
                                                                           size: CGSize(width: 18, height: 18)))
    private lazy var muteAllButton = button(with: I18n.View_M_MuteAll,
                                            image: UDIcon.getIconByKey(.micOffFilled,
                                                                       iconColor: UIColor.ud.iconN1,
                                                                       size: CGSize(width: 18, height: 18)))

    private var items: [ToolBarItem] = []
    private var moreItems: [ToolBarItem] = []
    var factory: ToolBarFactory { viewModel.factory }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
    }

    private var expandedFullHeight: CGFloat {
        // 展开页面的高度在是否是主持人、是否是刘海屏这两种条件组合下的高度均不相同，共 2 * 2 = 4 中情况。
        var height = collectionView.itemsHeight
        switch (Display.iPhoneXSeries, viewModel.hostControlShouldShowOnPhone) {
        case (true, true): height += 68
        case (true, false): height -= 13
        case (false, true): height += 84
        case (false, false): height += 8
        }
        return height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let superView = view.superview else { return }
        backgroundView.snp.remakeConstraints { (make) in
            make.edges.equalTo(superView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MeetingTracksV2.trackToolBarDisplay()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var shouldAutorotate: Bool { false }

    override func setupViews() {
        super.setupViews()
        Self.logger.info("Toolbar phone VC setupSubviews. Reset initial isExpanded state to false")

        view.backgroundColor = .clear

        view.addSubview(backgroundView)

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        toolbar.backgroundColor = .clear
        contentView.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
//            make.bottom.equalToSuperview().(view.safeAreaLayoutGuide)
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(44)
        }

        contentView.addSubview(expandedView)
        expandedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        expandedView.addSubview(collectionView)
        expandedView.addSubview(collectionBottomLine)
        collectionBottomLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(collectionView.snp.bottom).offset(9)
            make.height.equalTo(0.5)
        }

        expandedView.addSubview(buttonGroupView)
        buttonGroupView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(collectionBottomLine.snp.bottom)
            make.height.equalTo(58)
        }

        hostControlButton.addTarget(self, action: #selector(handleHostControl), for: .touchUpInside)
        muteAllButton.addTarget(self, action: #selector(handleMuteAll), for: .touchUpInside)
        buttonGroupView.addArrangedSubview(hostControlButton)
        buttonGroupView.addArrangedSubview(muteAllButton)
        [hostControlButton, muteAllButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(44)
            }
        }

        toggleExpandLayout(to: false)
        resetToolbarItems()
        updateHostControl()

        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: panGesture)
        backgroundView.addGestureRecognizer(tap)
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.setBridge(self, for: .toolbar)
        viewModel.addListener(self)
        viewModel.context.addListener(self, for: .contentScene)
    }

    override func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        updateBackgroundColor()
    }

    // MARK: - Private

    private func resetToolbarItems() {
        viewModel.phoneMainItems
            .map(factory.item(for:))
            .filter { $0.phoneLocation == .toolbar }
            .forEach(updateBarItem(_:))

        let collectionItems = viewModel.phoneMoreItems
            .map(factory.item(for:))
            .filter { $0.phoneLocation == .more }
        if collectionItems.map(\.itemType) != moreItems.map(\.itemType) {
            moreItems = collectionItems
            collectionView.initCollectionItems(collectionItems)
            updateMoreBadge()
            collectionView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(collectionView.itemsHeight)
            }
        }
    }

    private func updateBackgroundColor() {
        let isTiled = viewModel.meetingLayoutStyle == .tiled
        var shouldShowShadow = false
        switch (isExpandedLayout, isTiled) {
        case (true, _):
            // 展开
            contentView.backgroundColor = .clear
        case (false, true):
            // 收起 + 非沉浸
            contentView.backgroundColor = UIColor.ud.bgBody
        case (false, false):
            // 收起 + 沉浸
            contentView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.92)
            // 如果存在shareBar，则在shareBar上加阴影；否则，在toolbar上加
            if viewModel.meetingLayoutStyle == .overlay && !viewModel.context.hasShareBar {
                shouldShowShadow = true
            }
        }
        self.view.alpha = 1.0
        if shouldShowShadow {
            contentView.vc.addOverlayShadow(isTop: false)
        } else {
            contentView.vc.removeOverlayShadow()
        }
    }

    // 更新self.view的高度，在展开时使self.view达到父视图的高度，用来支持整个区域的手势操作
    private func updateViewHeight(isExpanded: Bool) {
        Self.logger.info("Update toolbar view height, isExpanded = \(isExpanded)")
        guard let layoutGuide = self.bottomBarGuide, layoutGuide.canUse(on: view) else { return }
        view.snp.remakeConstraints { (make) in
            make.left.right.equalTo(layoutGuide)
            make.bottom.equalToSuperview()
            if isExpanded {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(layoutGuide)
            }
        }
    }

    // 更新可视区域高度，收缩时顶部对齐外部传入的bottomLayoutGuide
    private func updateHeight(_ height: CGFloat, isExpanded: Bool) {
        guard contentView.superview != nil else { return }
        contentView.snp.remakeConstraints { (make) in
            guard let layoutGuide = self.bottomBarGuide, layoutGuide.canUse(on: view) else {
                return
            }
            make.left.right.bottom.equalToSuperview()
            if isExpanded {
                make.height.equalTo(height + safeAreaBottom)
            } else {
                make.top.equalTo(layoutGuide)
            }
        }
    }

    private func toggleExpandLayout(to isExpand: Bool) {
        Self.logger.info("Toggle toolbar layout. isExpand = \(isExpand)")
        isExpandedLayout = isExpand
        updateBackgroundColor()
        toolbar.alpha = isExpand ? 0 : 1
        expandedView.alpha = isExpand ? 1 : 0
    }

    private func updateContentAlpha(_ alpha: CGFloat) {
        if isExpandedLayout {
            expandedView.alpha = alpha
        } else {
            toolbar.alpha = alpha
        }
    }

    /* 动画说明
     view上拉时，从收起状态到高度增加到distanceThreshold时，隐藏toolbar，alpha从1-0
     高度增加从distanceThreshold到展开高度时，显示其他视图，如more、主持人操作选项等，alpha从0-1
     下滑时同样参考distanceThreshold
     */

    private func expand(from f: String = #function) {
        self.blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
        Self.logger.info("Toolbar will expand from \(f). Current isExpanded = \(isExpanded), isAnimating = \(isAnimating)")
        VCTracker.post(name: viewModel.meetingTrackName, params: [.action_name: "addition"])
        backgroundView.isHidden = false


        if !isAnimating {
            // 如果不在动画或手势中, 并且状态是 expanded，那就是重复调用，直接忽略
            if isExpanded {
                return
            }

            // 如果是在动画或手势中调用该方法（isAnimating == true)，说明手势到一半中断，回到 expand 态，此时 background.alpha 不用变，
            // 否则先将 background 的 alpha 置为 0
            backgroundView.alpha = 0
        }

        isAnimating = true

        let expandAnimationBlock = {
            Self.logger.info("Toolbar expand animation in progress...")
            self.toggleExpandLayout(to: true)
            self.backgroundView.alpha = 1
            self.updateHeight(self.expandedFullHeight, isExpanded: true)
            self.view.layoutIfNeeded()
        }

        let completionBlock = {
            self.isAnimating = false
            self.isExpanded = true
            Self.logger.info("Toolbar finished expanding")
            self.updateViewHeight(isExpanded: true) // 更新self.view的高度
            // 由于数据更新时 updateMoreItem 里对 isAnimating 做了过滤，动画期间不刷新 UI，防止引入状态不一致的 bug
            // 因此以防万一展开过程中主持人身份变更导致 toolbar 最终高度变更，这里最终调整一次正确高度
            self.updateHeight(self.expandedFullHeight, isExpanded: true)
        }

        let currentHeightOffset = contentView.frame.height - safeAreaBottom - Layout.toolbarHeight
        if currentHeightOffset > Layout.distanceThreshold {
            UIView.animate(withDuration: Self.halfAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
                expandAnimationBlock()
            }, completion: { _ in
                completionBlock()
            })
            return
        }

        let ratio = Double(Layout.distanceThreshold / (expandedFullHeight - Layout.toolbarHeight))
        Self.logger.info("Toolbar will start expand animation with expandedFullHeight \(expandedFullHeight), ratio \(ratio)")
        UIView.animateKeyframes(withDuration: Self.fullAnimationDuration, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: ratio) {
                self.backgroundView.alpha = 1 * CGFloat(ratio)
                self.updateContentAlpha(0)
                self.updateHeight(Layout.toolbarHeight + Layout.distanceThreshold, isExpanded: true)
                self.view.layoutIfNeeded()
            }

            UIView.addKeyframe(withRelativeStartTime: ratio, relativeDuration: 1 - ratio) {
                expandAnimationBlock()
            }
        }, completion: { _ in
            completionBlock()
        })
    }

    // 横竖屏切换时同步 toolbar 展开状态
    private func expandWithoutAnimation() {
        blockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
        isExpanded = true
        toggleExpandLayout(to: true)
        backgroundView.alpha = 1
        backgroundView.isHidden = false
        updateHeight(self.expandedFullHeight, isExpanded: true)
        updateViewHeight(isExpanded: true) // 更新self.view的高度
    }

    func shrink(from f: String = #function, completion: (() -> Void)? = nil) {
        Self.logger.info("Toolbar will shrink from \(f). Current isExpanded = \(isExpanded)")
        if !isExpanded {
            isAnimating = false
            completion?()
            return
        }

        isAnimating = true

        let shrinkAnimationBlock = {
            Self.logger.info("Toolbar shrink animation in progress...")
            self.toggleExpandLayout(to: false)
            self.backgroundView.alpha = 0
            self.updateHeight(Layout.toolbarHeight, isExpanded: false)
            self.view.layoutIfNeeded()
        }

        let completionBlock = {
            self.isAnimating = false
            self.blockFullScreenToken = nil
            self.isExpanded = false
            Self.logger.info("Toolbar finished shrinking")
            self.backgroundView.isHidden = true
            self.updateViewHeight(isExpanded: false)
            completion?()
        }

        let currentHeightOffset = contentView.frame.height - safeAreaBottom - Layout.toolbarHeight
        if currentHeightOffset < Layout.distanceThreshold {
            UIView.animate(withDuration: Self.halfAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
                shrinkAnimationBlock()
            }, completion: { _ in
                completionBlock()
            })
            return
        }

        let ratio = Double(Layout.distanceThreshold / (expandedFullHeight - Layout.toolbarHeight))
        Self.logger.info("Toolbar will start shrink animation with expandedFullHeight \(expandedFullHeight), ratio \(ratio)")
        UIView.animateKeyframes(withDuration: Self.fullAnimationDuration, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1 - ratio) {
                self.backgroundView.alpha = CGFloat(ratio)
                self.updateContentAlpha(0)
                self.updateHeight(Layout.toolbarHeight + Layout.distanceThreshold, isExpanded: true)
                self.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 1 - ratio, relativeDuration: ratio) {
                shrinkAnimationBlock()
            }
        }, completion: { _ in
            completionBlock()
        })
    }

    // 横竖屏切换时同步 toolbar 展开状态
    func shrinkWithoutAnimation() {
        guard isExpanded else { return }
        isExpanded = false
        blockFullScreenToken = nil
        toggleExpandLayout(to: false)
        backgroundView.alpha = 0
        backgroundView.isHidden = true
        updateHeight(Layout.toolbarHeight, isExpanded: false)
        updateViewHeight(isExpanded: false)
    }

    private func button(with title: String, image: UIImage?) -> UIButton {
        let button = VisualButton(type: .custom)
        button.edgeInsetStyle = .left
        button.space = 6
        button.setAttributedTitle(NSAttributedString(string: title, config: .bodyAssist, alignment: .center), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1), for: .highlighted)
        button.setImage(image, for: .normal)
        return button
    }

    private func updateBarItem(_ item: ToolBarItem) {
        let itemType = item.itemType
        let currentLocation = items.firstIndex { $0.itemType == itemType }
        let targetLocation = item.phoneLocation == .toolbar ? viewModel.phoneMainItems.firstIndex(of: itemType) : nil
        if currentLocation == nil && targetLocation != nil {
            // 从无到有
            let position = ToolBarFactory.insertPosition(of: itemType,
                                                         target: items.map(\.itemType),
                                                         order: viewModel.phoneMainItems)
            items.insert(item, at: position)
            toolbar.insertItemView(factory.phoneView(for: itemType), at: position)
        } else if let position = currentLocation, targetLocation == nil {
            // 从有到无
            items.remove(at: position)
            toolbar.removeItemView(at: position)
        }
    }

    private func updateMoreItem(_ item: ToolBarItem) {
        defer {
            // 只有动画完成后 isExpanded 才会置为相应的值，如果 isExpanded && isAnimating，说明当前正在 shrinkToolbar，此时不能走下面的方法。
            // 这样同时过滤掉了 "正在 expandToolbar" 的场景，所以极端场景下正在展开 toolbar 时发生主持人身份变更时，高度的处理见 expand 方法里注释
            if isExpanded && !isAnimating {
                Self.logger.info("Toolbar isExpanded. Manually update height to full height")
                updateHeight(expandedFullHeight, isExpanded: true)
            }
        }

        if item.itemType == .security {
            updateHostControl()
            return
        }

        moreItems = collectionView.update(item: item, collectionItems: viewModel.phoneMoreItems)
        updateMoreBadge()
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(collectionView.itemsHeight)
        }
    }

    private func updateMoreBadge() {
        (factory.item(for: .more) as? ToolBarMoreItem)?.updateMoreBadge()
    }

    private func updateHostControl() {
        guard let item = viewModel.hostControlItem else { return }
        let showHostControl = item.phoneLocation != .none
        collectionBottomLine.isHidden = !showHostControl
        buttonGroupView.isHidden = !showHostControl
    }

    // MARK: - Actions

    @objc
    private func handleTap(_ recognizer: UITapGestureRecognizer) {
        shrink()
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // 仅允许手势关闭，不允许手势打开
        guard isExpanded else { return }

        let point = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)

        switch recognizer.state {
        case .began:
            panBlockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
            isAnimating = true
            contentOriginInPan = contentView.frame.origin
        case .changed:
            var frame = contentView.frame
            frame.origin.y = contentOriginInPan.y + point.y
            let maxY = VCScene.bounds.height - Layout.toolbarHeight - safeAreaBottom
            let minY = VCScene.bounds.height - expandedFullHeight - safeAreaBottom
            if frame.origin.y > maxY {
                frame.origin.y = maxY
            }
            if frame.origin.y < minY {
                frame.origin.y = minY
            }
            let height = VCScene.bounds.height - frame.origin.y - safeAreaBottom
            backgroundView.alpha = height / expandedFullHeight

            let heightOffset = height - Layout.toolbarHeight
            if heightOffset > Layout.distanceThreshold {
                toggleExpandLayout(to: true)
                let alpha = (height - Layout.toolbarHeight - Layout.distanceThreshold) / (expandedFullHeight - Layout.toolbarHeight - Layout.distanceThreshold)
                updateContentAlpha(alpha)
            } else {
                toggleExpandLayout(to: false)
                let alpha = 1 - (height - Layout.toolbarHeight) / Layout.distanceThreshold
                updateContentAlpha(alpha)
            }

            updateHeight(height, isExpanded: true)
        case .ended, .cancelled:
            panBlockFullScreenToken = nil
            let frame = contentView.frame
            // 移动距离小于高度的 1/4，并且加速度小于1000则保持原状
            let hasEnoughVelocity = velocity.y > 1000
            if abs(frame.origin.y - contentOriginInPan.y) < (expandedFullHeight - Layout.toolbarHeight) / 4.0 && !hasEnoughVelocity {
                expand()
                return
            }
            shrink()
        default:
            break
        }
    }

    @objc
    private func handleMuteAll() {
        viewModel.hostControlItem?.muteAll()
    }

    @objc
    private func handleHostControl() {
        viewModel.hostControlItem?.openHostControlPage()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        resetToolbarItems()
        view.isHidden = newContext.layoutType.isPhoneLandscape
        if newContext.layoutType.isPhoneLandscape {
            blockFullScreenToken = nil
        } else {
            if viewModel.isExpanded && !viewModel.isAnimating {
                expandWithoutAnimation()
            } else {
                shrinkWithoutAnimation()
            }
        }
    }
}

extension ToolBarPhoneViewController: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        Util.runInMainThread {
            self.updateBarItem(item)
            self.updateMoreItem(item)
        }
    }
}

extension ToolBarPhoneViewController: ToolBarViewModelBridge {
    func toggleToolBarStatus(expanded: Bool, completion: (() -> Void)?) {
        if self.currentLayoutContext.layoutType.isPhoneLandscape { return }
        if expanded {
            expand()
            completion?()
        } else {
            shrink(completion: completion)
        }
    }

    func itemView(with type: ToolBarItemType) -> UIView? {
        toolbar.view(for: type)
    }
}

extension ToolBarPhoneViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .contentScene {
            updateBackgroundColor()
        }
    }
}
