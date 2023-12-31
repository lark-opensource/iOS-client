//
//  BTCardListViewController.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/30.
//  

import SKFoundation
import SnapKit
import SKInfra
import SKBrowser
import UniverseDesignColor
import SKUIKit

fileprivate class GradientBackgroundView: UIView {
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0.05, 0.25, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = layer.bounds
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientLayer)
        // ud 的bug，得先加到superLayer再设置
        gradientLayer.ud.setColors([UDColor.bgBody, UDColor.bgBase, UDColor.bgBase])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BTCardListViewController: NativeRenderBaseController {
    private let TAG = "[BTCardListViewController]"
    private var viewModel: NativeCardViewModel {
        if let viewModel = viewModels[currentViewId] {
            return viewModel
        }
        
        let newViewModel = NativeCardViewModel(model: model, service: service)
        newViewModel.listener = self
        viewModels.updateValue(newViewModel, forKey: model.viewId)
        return newViewModel
    }
    
    private var _canPerformActions: [Selector: Bool] = [:]
    private var frameObserver: NSKeyValueObservation? // 监听size变化reload
    
    private var didAppear: Bool = false // flag
    
    private let backgroundView: GradientBackgroundView = GradientBackgroundView()
    
    private var disAppearOrientation: UIInterfaceOrientation = .unknown
    
    // 不同view对应不同的viewModel
    private var viewModels: [String: NativeCardViewModel] = [:]
    // 不同view列表滚动距离缓存
    private var viewContentOffsetCache: [String: CGPoint] = [:]
    // 当前视图ID
    private var currentViewId: String
    private var service: BTContainerService?
    private var model: CardPageModel
    
    // 埋点上报traceId
    private var viewLifecycleTraceId: String?
    private var viewLifecycleTraceComsumer: BTNativeViewLifecycleComsumer?
    
    lazy var groupHeaderFixedView = BTGroupHeaderFixedView().construct { it in
        it.isHidden = true
        it.backgroundColor = UDColor.bgBody
    }
    var keyboard = Keyboard()
    
    lazy var cardListView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.register(BTCardViewCell.self, forCellWithReuseIdentifier: BTCardViewCell.reuseIdentifier)
        view.register(BTCardGroupHeaderCell.self, forCellWithReuseIdentifier: BTCardGroupHeaderCell.reuseIdentifier)
        view.register(BTCardListFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BTCardListFooterView.reuseIdentifier)
        view.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UICollectionReusableView.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.bounces = false
        view.canCancelContentTouches = true
        view.contentInset = .zero
        view.contentInsetAdjustmentBehavior = .never
        view.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 0)
        view.bounces = false
        return view
    }()
    
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        return generator
    }()
    
    init(model: CardPageModel, service: BTContainerService?, context: BTNativeRenderContext) {
        self.model = model
        self.service = service
        self.currentViewId = model.viewId
        super.init(context: context)
        
        self.viewModels.updateValue(NativeCardViewModel(model: model, service: service), forKey: model.viewId)
        self.viewModel.listener = self
        handleViewLifecycleTrace()
        groupHeaderFixedView.resetModel(items: viewModel.groupItem,
                                        dataMap: viewModel.cachedGroupHeaderItems)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(context: BTNativeRenderContext) {
        fatalError("init(context:) has not been implemented")
    }
    
    deinit {
        keyboard.stop()
        viewModel.fpsTrace.forceStopAndReportAll()
        if let traceId = viewLifecycleTraceId, !view.isHidden {
            let point = BTStatisticNormalPoint(name: "ccm_bitable_mobile_view_lifecycle", extra: ["reportScene": "nativeDestroy"])
            BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppear {
            didAppear = true
            self.frameObserver = view.observe(\.bounds, options: [.new]) { [weak self] _, _  in
                guard let self = self else { return }
                self.shouldReloadWithoutDataChange()
            }
        } else {
            // 进入其他Controller，改变屏幕方向，回来需要reload
            if disAppearOrientation != UIApplication.shared.statusBarOrientation {
                self.shouldReloadWithoutDataChange()
            }
        }
    }
    
    override func setUpUI() {
        super.setUpUI()
        self.view.addSubview(backgroundView)
        self.view.addSubview(cardListView)
        self.view.addSubview(groupHeaderFixedView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        cardListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        groupHeaderFixedView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(CardViewConstant.LayoutConfig.groupHeaderHeight)
        }
        
        reloadCardList()
        DispatchQueue.main.async {
            self.cardListView.visibleCells.forEach { card in
                if let card = card as? BTNativeRenderCardStatisticProtocol {
                    BTNativeRenderReportMonitor.reportCardViewCellSetData(traceId: self.context.nativeRenderTraceId,
                                                                         costTime: card.setData)
                    BTNativeRenderReportMonitor.reportCardViewCellLayout(traceId: self.context.nativeRenderTraceId,
                                                                        costTime: card.layout)
                    BTNativeRenderReportMonitor.reportCardViewCellDraw(traceId: self.context.nativeRenderTraceId,
                                                                      costTime: card.draw)
                    if let card = card as? BTCardViewCell {
                        card.fieldList.visibleCells.forEach { field in
                            if let field = field as? BTNativeRenderFieldStatisticProtocol {
                                BTNativeRenderReportMonitor.reportCardViewFieldSetData(traceId: self.context.nativeRenderTraceId,
                                                                                      costTime: field.setData,
                                                                                      fieldUIType: field.type)
                                BTNativeRenderReportMonitor.reportCardViewFieldLayout(traceId: self.context.nativeRenderTraceId,
                                                                                     costTime: field.layout,
                                                                                     fieldUIType: field.type)
                                BTNativeRenderReportMonitor.reportCardViewFieldDraw(traceId: self.context.nativeRenderTraceId,
                                                                                   costTime: field.draw,
                                                                                   fieldUIType: field.type)
                            }
                        }
                    }
                }
            }
            // ttv和ttu 用openfile的traceid，其他的用自己的
            BTNativeRenderReportMonitor.reportCardViewGroup(traceId: self.context.nativeRenderTraceId)
            BTNativeRenderReportMonitor.reportOpenCardViewTTV(traceId: self.context.openBaseTraceId)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(shouldReloadWithoutDataChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
        groupHeaderFixedView.onClick = { [weak self] id in
            self?.handleGroupHeaderClick(id: id)
            
        }
        keyboard.on(event: .didShow, do: { [weak self] options in
            guard let self = self else { return }
            let bottom = options.endFrame.height + self.getBottomPlaceholderHeight()
            self.cardListView.contentInset.bottom = bottom
        })
        keyboard.on(event: .willHide, do: { [weak self] _ in
            guard let self = self else { return }
            // 搜索切换匹配内容时会下掉键盘
            let bottom = viewModel.isInSearchMode ? self.getBottomPlaceholderHeight() : 0
            self.cardListView.contentInset.bottom = bottom
        })
        keyboard.on(event: .didChangeFrame, do: {
            [weak self] options in
            guard let self = self else { return }
            if options.isShow {
                let bottom = options.endFrame.height + self.getBottomPlaceholderHeight()
                self.cardListView.contentInset.bottom = bottom
            }
        })
        keyboard.start()
        viewModel.fpsTrace.bindGridCardScrollView(self.cardListView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disAppearOrientation = UIApplication.shared.statusBarOrientation
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func updateModel(model: NativeRenderBaseModel?) {
        super.updateModel(model: model)
        guard let cardModel = model as? CardPageModel, model?.empty == nil else {
            return
        }
        
        self.model = cardModel
        if cardModel.updateStrategy?.switchView == true {
            handleViewLifecycleTrace()
        }
        
        if currentViewId != cardModel.viewId {
            // view切换, 整个reload列表
            currentViewId = cardModel.viewId
            cardListView.setContentOffset(viewContentOffsetCache[cardModel.viewId] ?? .zero, animated: false)
            reloadItems(viewId: currentViewId) { [weak self] in
                guard let self = self else { return }
                let maxContentOffset = max(self.cardListView.contentSize.height - self.cardListView.bounds.height, 0)
                if cardListView.contentOffset.y > maxContentOffset {
                    self.cardListView.contentOffset.y = maxContentOffset
                    self.cardListView.layoutIfNeeded()
                }
            }
            
            DocsLogger.btInfo("\(TAG) switch view")
        } else {
            // view 更新
            viewLifecycleTraceComsumer?.updateBridgeInfo(model: cardModel)
            viewModel.updateModel(model: cardModel)
        }
    }
    
    override func searchModeDidChange(searchMode: BrowserViewController.SearchMode?) {
        if case .search(_) = searchMode {
            viewModel.isInSearchMode = true
        } else {
            // 退出搜索态
            viewModel.isInSearchMode = false
            cardListView.contentInset.bottom = 0
        }
    }
    
    private func handleViewLifecycleTrace() {
        viewLifecycleTraceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: nil)
        if let traceId = viewLifecycleTraceId {
            let comsumer = BTNativeViewLifecycleComsumer()
            comsumer.updateBridgeInfo(model: model)
            if let lastTraceComsumer = self.viewLifecycleTraceComsumer {
                viewModel.fpsTrace.removeNativeViewLifecycleComsumer(consumer: lastTraceComsumer)
            }
            self.viewLifecycleTraceComsumer = comsumer
            viewModel.fpsTrace.addNativeViewLifecycleComsumer(consumer: comsumer)
            BTStatisticManager.shared?.addNormalConsumer(traceId: traceId, consumer: comsumer)
            viewModel.handleJSCallBack(params: ["id": traceId,
                                                "action": "BindViewLifecycleTraceId"])
        }
    }
    
    private func getBottomPlaceholderHeight() -> CGFloat {
        guard let browserVC = self.parent as? BrowserViewController else {
            return 0
        }
        
        return browserVC.bottomPlaceholder.bounds.height
    }
    
    private func getCardCellHeight(index: Int) -> CGFloat {
        let lineSpacing = viewModel.columnCount == 1 ? CardViewConstant.LayoutConfig.fieldSingleCloLineSpacing :
                                                        CardViewConstant.LayoutConfig.fieldLineSpacing
        
        var height: CGFloat = CardViewConstant.LayoutConfig.cardListViewPaddingTop * 2
        // 文本字段标题最多两行 48
        // 其它字段标题仅一行 24
        var fieldDataContainerWidth = self.cardListView.bounds.width
        if viewModel.hasCover {
            fieldDataContainerWidth -= CardViewConstant.LayoutConfig.coverViewSize.width + 10 + 28
        } else {
            fieldDataContainerWidth = self.cardListView.bounds.width - CardViewConstant.LayoutConfig.cardListViewPaddingTop * 2
            height += CardViewConstant.LayoutConfig.cardCellInset
        }
        
        if let model = viewModel.getCardItemData(index: index),
            let titleModel = model.title {
            var commentWidth: CGFloat = 0
            if let commentText = model.comment?.text {
                commentWidth = BTCardTitleTextCalculaor.caculateTextWidth(text: commentText,
                                                                          font: .systemFont(ofSize: BTCardCommentConst.commentFontSize),
                                                                          inset: BTCardCommentConst.textInset) + BTCardCommentConst.leftInset
            }
            let isSingleLine = BTCardTitleTextCalculaor.isSingleLine(titleModel,
                                                                     font: CardViewConstant.LayoutConfig.textTtileFont,
                                                                     containerWidth: fieldDataContainerWidth - commentWidth)
            height += isSingleLine ? CardViewConstant.LayoutConfig.textTitleSingleLineHeight : CardViewConstant.LayoutConfig.textTitleMutilLineHeight
        } else {
            height += CardViewConstant.LayoutConfig.textTitleSingleLineHeight
        }
        
        // 有副标题
        if viewModel.hasSubTitle {
            height += CardViewConstant.LayoutConfig.fieldHeightForRL
        }
        
        let fieldLineNum = ceil(CGFloat(viewModel.fieldCount) / CGFloat(viewModel.columnCount))
        if fieldLineNum > 0 {
            let sectionSpacing = viewModel.columnCount == 1 ?
            CardViewConstant.LayoutConfig.titleAndFieldSectionSpacingForSingleLine :
            CardViewConstant.LayoutConfig.titleAndFieldSectionSpacing
            height += sectionSpacing
        }
        
        var minHeight = CardViewConstant.LayoutConfig.cardListViewPaddingTop * 2
        if viewModel.columnCount == 1 {
            // 单列，字段名和值是左右排布，高度24，行间距12
            height += fieldLineNum * CardViewConstant.LayoutConfig.fieldHeightForRL + max((fieldLineNum - 1), 0) * lineSpacing
            
            if viewModel.hasCover {
                // 有封面，最小高度为 16 + 104 + 96
                minHeight += CardViewConstant.LayoutConfig.coverViewSingleCloSize.height
            }
        } else {
            // 多列，字段名和值是上下排布，高度42，行间距12
            height += fieldLineNum * CardViewConstant.LayoutConfig.fieldHeightForTB + max((fieldLineNum - 1), 0) * lineSpacing
            
            if viewModel.hasCover {
                // 有封面，最小高度为 16 + 96 + 96
                minHeight += CardViewConstant.LayoutConfig.coverViewSize.height
            }
        }
        
        if viewModel.hasGroup, let uiModel = viewModel.uiModel.safe(index: index) {
            let isGroupFirst = index != 0 && viewModel.isGroupFirstRecord(uiModel)
            let isGroupLast = viewModel.isGroupLastRecord(uiModel)
            if isGroupFirst {
                height += CardViewConstant.LayoutConfig.groupHeightAdjustHeight
            }
            if isGroupLast {
                height += CardViewConstant.LayoutConfig.groupHeightAdjustHeight
            }
        }
        
        return max(minHeight, height)
    }
    
    @objc
    private func clickCellPressMenu(menuId: String, index: Int) {
        guard let model = viewModel.getCardItemData(index: index) else {
            DocsLogger.btInfo("\(TAG) clickCellPressMenu failed no model")
            return
        }
        
        guard let menuItem = model.longPressMenu.first(where: { $0.text == menuId }) else {
            DocsLogger.btInfo("\(TAG) clickCellPressMenu failed no menu")
            return
        }
        
        guard let params = menuItem.clickActionPayload as? [String: Any] else {
            DocsLogger.btInfo("\(TAG) clickCellPressMenu failed no clickAction")
            return
        }
        
        DocsLogger.btInfo("\(TAG) clickCellPressMenu menuId: \(menuId)")
        viewModel.handleJSCallBack(params: params)
    }
    
    private func handleGroupHeaderClick(id: String) {
        viewModel.handleGroupHeaderClick(id: id)
        viewLifecycleTraceComsumer?.clickGroup += 1
    }
    
    private func handleItemLongPressTrace() {
        viewLifecycleTraceComsumer?.longPress += 1
    }
    
    private func handleViewScrollTrace() {
        let visitRow = getFirstVisibleItemIndex() ?? 0
        viewLifecycleTraceComsumer?.visitRow = max(visitRow, viewLifecycleTraceComsumer?.visitRow ?? 0)
        // 滑动到最底部
        let hasScrollEnd = cardListView.contentOffset.y + cardListView.bounds.height == cardListView.contentSize.height
        if hasScrollEnd, viewModel.footerText != nil {
            viewLifecycleTraceComsumer?.hasVisibleLimit = true
        }
    }
    
    @objc func shouldReloadWithoutDataChange() {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.updateVisibleItems(viewId: self.currentViewId)
            CATransaction.commit()
        }
    }
    
    // reload 都调这里统一收口
    private func reloadCardList() {
        self.cardListView.reloadData()
        // 立即刷新listView，避免初始reload还未完成时又触发了update，导致崩溃
        self.cardListView.layoutIfNeeded()
    }
}

extension BTCardListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < viewModel.uiModel.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: BTCardViewCell.reuseIdentifier, for: indexPath)
        }
        
        let uiModel = viewModel.uiModel[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: uiModel.type.reuseIdentifier, for: indexPath)
        
        if uiModel.type == .groupHeader {
            guard let groupHeaderCell = cell as? BTCardGroupHeaderCell else {
                return cell
            }
            
            updateHeaderCellModel(cell: groupHeaderCell, index: indexPath.row, uiModel: uiModel)
            return groupHeaderCell
        } else if uiModel.type == .record {
            guard let cardViewCell = cell as? BTCardViewCell else {
                return cell
            }
            
            updateRecordCellModel(cell: cardViewCell, index: indexPath.row, uiModel: uiModel)
            return cardViewCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height = getCardCellHeight(index: indexPath.row)
        guard indexPath.row < viewModel.uiModel.count else {
            return CGSize(width: self.view.bounds.width, height: height)
        }
        
        let uiModel = viewModel.uiModel[indexPath.row]
        if uiModel.type == .groupHeader {
            height = CardViewConstant.LayoutConfig.groupHeaderHeight
        }
        
        return CGSize(width: self.view.bounds.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.uiModel.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return false
        }
        
        guard indexPath.row < viewModel.uiModel.count else {
            return false
        }
        
        let uiModel = viewModel.uiModel[indexPath.row]
        
        guard uiModel.type == .record else {
            return false
        }
        
        guard let recordModel = viewModel.getCardItemData(index: indexPath.row) else {
            return false
        }
        
        self._canPerformActions.removeAll()
        var pressMenuItems: [UIMenuItem] = []
        recordModel.longPressMenu.forEach { item in
            guard let text = item.text else {
                return
            }
            
            let aSelector = selector(uid: text, classes: [ type(of: cell) ]) { [weak self] in
                self?.clickCellPressMenu(menuId: text, index: indexPath.row)
            }
            
            self._canPerformActions[aSelector] = true
            let menuItem = UIMenuItem(title: text, action: aSelector)
            pressMenuItems.append(menuItem)
        }
        UIMenuController.shared.menuItems = pressMenuItems
        impactGenerator.impactOccurred()
        handleItemLongPressTrace()
        DocsLogger.btInfo("\(TAG) showPressMenu")
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return self._canPerformActions[action] ?? false
    }
    
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        // 这个方法根本不会调用，但是如果不实现的话则无法呼出 menu
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let hasGroup = viewModel.hasGroup
        return CGSize(width: collectionView.bounds.width,
                      height: hasGroup ? CardViewConstant.LayoutConfig.groupHeightAdjustHeight : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let hasFooterText = model.footer != nil
        return CGSize(width: collectionView.bounds.width, height: hasFooterText ? CardViewConstant.LayoutConfig.footerHeightWithText : self.view.safeAreaInsets.bottom)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter,
           let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: BTCardListFooterView.reuseIdentifier, for: indexPath) as? BTCardListFooterView {
            // 无分组有封面需要背景色，其它情况都是透明色
            footerView.backgroundColor = (!viewModel.hasGroup && viewModel.hasCover) ? UDColor.bgBody : .clear
            footerView.setText(viewModel.footerText ?? "")
            return footerView
        } else if kind == UICollectionView.elementKindSectionHeader {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: UICollectionReusableView.reuseIdentifier, for: indexPath)
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: UICollectionReusableView.reuseIdentifier, for: indexPath)
    }
}

extension BTCardListViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var scrollOffsetY = scrollView.contentOffset.y
        if let lastContentOffset = viewContentOffsetCache[currentViewId] {
            scrollOffsetY -= lastContentOffset.y
        }
        
        handlePreload(scrollOffsetY)
        handleGroupFixed(scrollOffsetY)
        viewModel.didScroll(scrollView)
        let cacheContentOffset = CGPoint(x: max(scrollView.contentOffset.x, 0), y: max(scrollView.contentOffset.y, 0))
        viewContentOffsetCache.updateValue(cacheContentOffset, forKey: currentViewId)
        handleViewScrollTrace()
    }
    
    private func handlePreload(_ scrollOffsetY: CGFloat) {
        if scrollOffsetY > 0 {
            // 上滑
            // 预加载数据，提前拉上一页或者下一页的数据
            if let lastVisibleIndex = getLastVisibleItemIndex() {
                viewModel.preloadItems(itemIndex: lastVisibleIndex, direction: scrollOffsetY)
            }
        } else {
            // 下滑
            if let firstVisibleIndex = getFirstVisibleItemIndex() {
                viewModel.preloadItems(itemIndex: firstVisibleIndex, direction: scrollOffsetY)
            }
        }
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let stopScrolling = !scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating
        if stopScrolling {
            viewModel.didEndScroll()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewModel.didEndScroll()
        }
    }
    
    /// 处理滑动时分组吸顶
    private func handleGroupFixed(_ scrollOffsetY: CGFloat) {
        // 首个可见的需要吸顶的分组头，不一定是当前已经吸顶的分组头
        guard let firstVisibleHeader = getFirstVisibleNeedFixGroupHeader(),
              let firstVisibleHeaderId = firstVisibleHeader.model?.id else {
            return
        }
        
        guard let currentFixedId = groupHeaderFixedView.currentFixedHeaderId,
              cardListView.contentOffset != .zero else {
            // 无吸顶header or 列表在最顶部，吸顶view需要隐藏
            groupHeaderFixedView.isHidden = true
            return
        }
        
        // 首个可见的需要吸顶的分组头相对视图view的frame
        let firstVisibleGroupCellFrame = firstVisibleHeader.convert(firstVisibleHeader.bounds, to: self.view)
        DocsLogger.btInfo("\(TAG) handleGroupFixed firstVisibleHeaderId:\(firstVisibleHeaderId) currentFixedId:\(currentFixedId) firstVisibleGroupCellFrame:\(firstVisibleGroupCellFrame) scrollOffsetY:\(scrollOffsetY)")
        
        var nextFixedGroupCellFrame: CGRect?
        if let nextFixedGroupId = groupHeaderFixedView.getNextFixId(),
           let nextFixedGroupHeader = getVisibleGroupHeaderFor(nextFixedGroupId) {
            // 下一个需要吸顶的分组头相对视图view的frame
            nextFixedGroupCellFrame = nextFixedGroupHeader.convert(nextFixedGroupHeader.bounds, to: self.view)
        }
        
        if scrollOffsetY > 0 {
            if groupHeaderFixedView.isHidden {
                // 固定分组头隐藏了
                // 吸顶分组头从隐藏 -> 显示
                if firstVisibleGroupCellFrame.minY < 0 {
                    // 需要吸顶
                    groupHeaderFixedView.isHidden = false
                    groupHeaderFixedView.updateFixHeaderView(id: firstVisibleHeaderId)
                }
            } else {
                if firstVisibleHeaderId == groupHeaderFixedView.currentFixedHeaderId {
                    if let nextFixedGroupCellFrame = nextFixedGroupCellFrame,
                       nextFixedGroupCellFrame.minY <= groupHeaderFixedView.frame.maxY  {
                        // 下一个需要吸顶的分组头还未完成吸顶
                        let fixScrollOffsetY = groupHeaderFixedView.frame.maxY - nextFixedGroupCellFrame.minY
                        groupHeaderFixedView.updateOffset(-fixScrollOffsetY)
                    } else {
                        // 吸顶操作完成
                        groupHeaderFixedView.hasDoneFixed()
                    }
                } else if firstVisibleGroupCellFrame.minY <= groupHeaderFixedView.frame.maxY {
                    if firstVisibleGroupCellFrame.minY >= 0 {
                        let fixScrollOffsetY = groupHeaderFixedView.frame.maxY - firstVisibleGroupCellFrame.minY
                        // 首个可见需要吸顶的分组头还未完成吸顶
                        groupHeaderFixedView.updateOffset(-fixScrollOffsetY)
                    } else {
                        // 可见分组头已划出可视区，快速滑动场景
                        groupHeaderFixedView.updateFixHeaderView(id: firstVisibleHeaderId, scrollDirection: scrollOffsetY)
                    }
                } else {
                    // 修正偏移
                    groupHeaderFixedView.fixOffset()
                }
            }
        } else {
            // 下滑
            var currentFixedGroupCellFrame: CGRect?
            // 当前正在吸顶的分组头
            if let currentFixedGroupHeader = getVisibleGroupHeaderFor(currentFixedId) {
                // 当前正在吸顶的分组头相对视图view的frame，可能为空
                currentFixedGroupCellFrame = currentFixedGroupHeader.convert(currentFixedGroupHeader.bounds, to: self.view)
            }

            if let currentFixedGroupCellFrame = currentFixedGroupCellFrame {
                let hasPre = groupHeaderFixedView.hasPreFixHeaderView()
                if currentFixedGroupCellFrame.minY >= groupHeaderFixedView.frame.maxY {
                    // 当前正在吸顶的分组头完成取消吸顶
                    if hasPre {
                        groupHeaderFixedView.hasDoneCancleFixed()
                    } else {
                        // 无上一个吸顶header
                        // 吸顶分组头从显示 -> 隐藏
                        groupHeaderFixedView.isHidden = true
                    }
                } else if currentFixedGroupCellFrame.minY >= 0  {
                    // 当前正在吸顶的分组头正在取消吸顶
                    let fixScrollOffsetY = currentFixedGroupCellFrame.minY
                    groupHeaderFixedView.updateOffset(fixScrollOffsetY)
                    if !hasPre {
                        // 无上一个吸顶header
                        // 吸顶分组头从显示 -> 隐藏
                        groupHeaderFixedView.isHidden = true
                    }
                } else if let nextFixedGroupCellFrame = nextFixedGroupCellFrame,
                          nextFixedGroupCellFrame.minY <= groupHeaderFixedView.frame.maxY {
                    // 卡在中间态
                    let fixScrollOffsetY = nextFixedGroupCellFrame.minY - groupHeaderFixedView.frame.maxY
                    groupHeaderFixedView.updateOffset(fixScrollOffsetY)
                }
            } else if groupHeaderFixedView.currentFixedHeaderId != firstVisibleHeaderId,
                      firstVisibleGroupCellFrame.minY <= groupHeaderFixedView.frame.maxY {
                if firstVisibleGroupCellFrame.minY >= 0 {
                    // 当前正在吸顶的分组不在可视区
                    let fixScrollOffsetY = firstVisibleGroupCellFrame.minY - groupHeaderFixedView.frame.maxY
                    groupHeaderFixedView.updateOffset(fixScrollOffsetY)
                } else {
                    // 可见分组头已划出可视区，快速滑动场景
                    groupHeaderFixedView.updateFixHeaderView(id: firstVisibleHeaderId, scrollDirection: scrollOffsetY)
                }
            } else {
                // 修正偏移
                groupHeaderFixedView.fixOffset()
            }
        }
    }
    
    /// 更新吸顶的分组头
    private func updateFixHeaderIfNeed() {
        guard let fixedId = getNeedFixedGroupId() else {
            // 无吸顶header，需要隐藏
            groupHeaderFixedView.isHidden = true
            return
        }
        
        if let needFixedCell = getVisibleGroupHeaderFor(fixedId) {
            if needFixedCell.convert(needFixedCell.bounds, to: self.view).minY < 0 {
                // 需要吸顶的header cell可见，且y小于0，需要显示吸顶view
                groupHeaderFixedView.isHidden = false
                groupHeaderFixedView.updateFixHeaderView(id: fixedId)
            } else {
                groupHeaderFixedView.isHidden = true
            }
        } else {
            // 需要吸顶的header cell不在可视区，需要显示吸顶view
            groupHeaderFixedView.isHidden = false
            groupHeaderFixedView.updateFixHeaderView(id: fixedId)
        }
    }
    
    
    /// 根据header id获取cell
    private func getVisibleGroupHeaderFor(_ id: String) -> BTCardGroupHeaderCell? {
        guard let index = viewModel.uiModel.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        
        return cardListView.cellForItem(at: IndexPath(row: index, section: 0)) as? BTCardGroupHeaderCell
    }
    
    /// 获取视窗内首个需要吸顶的header
    private func getFirstVisibleNeedFixGroupHeader() -> BTCardGroupHeaderCell? {
        var firstVisibleHeaderIndex: Int = Int.max
        
        cardListView.indexPathsForVisibleItems.forEach({ indexPath in
            if indexPath.row >= 0,
               indexPath.row < viewModel.uiModel.count {
                let model = viewModel.uiModel[indexPath.row]
                if model.type == .groupHeader {
                    let data = viewModel.getGroupHeaderData(index: indexPath.row)
                    if data?.lastLevelGroup == true {
                        firstVisibleHeaderIndex = min(indexPath.row, firstVisibleHeaderIndex)
                    }
                }
            }
        })
        
        return cardListView.cellForItem(at: IndexPath(row: firstVisibleHeaderIndex, section: 0)) as? BTCardGroupHeaderCell
    }
    
    /// 获取最上方可见cell的index
    private func getFirstVisibleItemIndex() -> Int? {
        var firstVisibleItemIndex: Int = Int.max
        
        // indexPathsForVisibleItems是无序的
        cardListView.indexPathsForVisibleItems.forEach({ indexPath in
            firstVisibleItemIndex = min(indexPath.row, firstVisibleItemIndex)
        })
        
        guard firstVisibleItemIndex >= 0,
              firstVisibleItemIndex < viewModel.uiModel.count else {
            return nil
        }
        
        return firstVisibleItemIndex
    }
    
    /// 获取最下方可见celll的index
    private func getLastVisibleItemIndex() -> Int? {
        var lastVisibleItemIndex: Int = 0
        
        // indexPathsForVisibleItems是无序的
        cardListView.indexPathsForVisibleItems.forEach({ indexPath in
            lastVisibleItemIndex = max(indexPath.row, lastVisibleItemIndex)
        })
        
        guard lastVisibleItemIndex >= 0,
              lastVisibleItemIndex < viewModel.uiModel.count else {
            return nil
        }
        
        return lastVisibleItemIndex
    }
    
    /// 获取当前列表需要吸顶的groupHeaderID
    private func getNeedFixedGroupId() -> String? {
        // 获取当前可见的第一个item的Id，往上找需要fixed的headerId
        guard let firstVisibleItemIndex = getFirstVisibleItemIndex() else {
            return nil
        }
        
        var fixedId: String?
        // 当前可见cell的下一个是否是需要吸顶的分组头
        let nextFixedGroupId = viewModel.getLastFixedGroupId(from: firstVisibleItemIndex + 1,
                                                             to: firstVisibleItemIndex + 1)
        if let id = nextFixedGroupId,
           let cell = getVisibleGroupHeaderFor(id),
           cell.convert(cell.bounds, to: self.view).minY < groupHeaderFixedView.frame.maxY {
            // 当前第一个可见cell和下一个可见cell之间需要吸顶的header
            fixedId = id
        } else {
            // 从第0个找到当前的上一个
            fixedId = viewModel.getLastFixedGroupId(from: 0, to: firstVisibleItemIndex)
        }
        
        return fixedId
    }
    
    /// 列表结构发生变化时刷新吸顶header
    private func handleGroupHeaderReset() {
        groupHeaderFixedView.resetModel(items: viewModel.groupItem,
                                        dataMap: viewModel.cachedGroupHeaderItems)
        
        updateFixHeaderIfNeed()
    }
    
    private func updateRecordCellModel(cell: BTCardViewCell, index: Int, uiModel: RenderItem) {
        guard index >= 0, index < viewModel.uiModel.count else {
            return
        }
        
        let dataModel = viewModel.getCardItemData(index: index)
        cell.context = context
        cell.updateModel(index: index,
                         config: .init(isGroupFirst: index != 0 && viewModel.isGroupFirstRecord(uiModel),
                                       isGroupLast: viewModel.isGroupLastRecord(uiModel),
                                       hasGroup: viewModel.hasGroup),
                         model: dataModel,
                         cardSetting: viewModel.cardSetting)
        cell.delegate = self
    }
    
    private func updateHeaderCellModel(cell: BTCardGroupHeaderCell, index: Int, uiModel: RenderItem) {
        guard index >= 0, index < viewModel.uiModel.count else {
            return
        }
        
        let dataModel = viewModel.getGroupHeaderData(index: index)
        cell.updateModel(model: dataModel,
                         cardSetting: viewModel.cardSetting,
                         shouldShowTopLine: viewModel.preItemIsGroupHeader(uiModel),
                         shouldShowBottomLine: index == viewModel.uiModel.count - 1) { [weak self] id in
            
            self?.handleGroupHeaderClick(id: id)
        }
    }
}

extension BTCardListViewController: NativeCardViewModelListener {
    func batchUpdate(viewId: String, updateIndexs: [Int], deleteIndexs: [Int], insertIndexs: [Int], completion: (() -> Void)?) {
        guard viewId == currentViewId else {
            return
        }

        cardListView.performBatchUpdates({
            cardListView.deleteItems(at: deleteIndexs.map{ IndexPath(item: $0, section: 0) })
            cardListView.insertItems(at: insertIndexs.map{ IndexPath(item: $0, section: 0) })
            updateItems(viewId: viewId, indexs: updateIndexs, needInvalidateLayout: false)
        }) { [weak self] complete in
            guard let self = self, complete else {
                return
            }
            completion?()
            self.handleGroupHeaderReset()
            // 更新动画完成后再去刷新布局，不然会影响动画效果
            self.cardListView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func updateItems(viewId: String, indexs: [Int], needInvalidateLayout: Bool = true) {
        guard viewId == currentViewId else {
            return
        }

        var needReloadItemIndexs: [IndexPath] = []
        indexs.forEach { index in
            let indexPath = IndexPath(item: index, section: 0)
            let uiModel = viewModel.uiModel[index]
            if let cardCell = cardListView.cellForItem(at: indexPath) as? BTCardViewCell, uiModel.type == .record {
                updateRecordCellModel(cell: cardCell, index: index, uiModel: uiModel)
            } else if let groupHeaderCell = cardListView.cellForItem(at: indexPath) as? BTCardGroupHeaderCell, uiModel.type == .groupHeader {
                updateHeaderCellModel(cell: groupHeaderCell, index: index, uiModel: uiModel)
            } else {
                needReloadItemIndexs.append(indexPath)
            }
        }
        
        if needInvalidateLayout {
            cardListView.collectionViewLayout.invalidateLayout()
        }
        guard !needReloadItemIndexs.isEmpty else {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cardListView.performBatchUpdates({
            cardListView.reloadItems(at: needReloadItemIndexs)
        }) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.groupHeaderFixedView.updateItemsModel(self.viewModel.cachedGroupHeaderItems)
            self.updateFixHeaderIfNeed()
        }
        CATransaction.commit()
    }
    
    func diffUpdateModel(viewId: String, deleteIndexs: [Int], insertIndexs: [Int]) {
        guard viewId == currentViewId else {
            return
        }
        
        // 结构信息发生变更， 需要刷新整个列表
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cardListView.performBatchUpdates({
            cardListView.deleteItems(at: deleteIndexs.map{ IndexPath(item: $0, section: 0) })
            cardListView.insertItems(at: insertIndexs.map{ IndexPath(item: $0, section: 0) })
        }) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            // 刷新可视区cell
            self.updateVisibleItems(viewId: viewId)
            self.handleGroupHeaderReset()
        }
        CATransaction.commit()
    }
    
    func scrollToIndex(viewId: String, index: Int) {
        guard viewId == currentViewId else {
            return
        }
        
        guard index >= 0, index < cardListView.numberOfItems(inSection: 0) else {
            return
        }
        
        if let itemCell = cardListView.cellForItem(at: IndexPath(item: index, section: 0)) {
            let targetOffsetY = max(itemCell.frame.minY - groupHeaderFixedView.bounds.height, 0)
            guard targetOffsetY + cardListView.bounds.height <= cardListView.contentSize.height else {
                cardListView.docs.safeScrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: true)
                return
            }
            
            cardListView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: true)
        } else {
            cardListView.docs.safeScrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: true)
        }
    }
    
    func updateVisibleItems(viewId: String) {
        guard viewId == currentViewId else {
            return
        }
        let indexs = cardListView.indexPathsForVisibleItems.compactMap({ $0.row })
        viewModel.fetchVisibleItemDataIfNeed(index: indexs.first)
        updateItems(viewId: viewId, indexs: indexs)
    }
    
    func reloadItems(viewId: String, completion: (() -> Void)?) {
        guard viewId == currentViewId else {
            return
        }
        
        reloadCardList()
        cardListView.performBatchUpdates(nil) { [weak self] _ in
            completion?()
            self?.handleGroupHeaderReset()
        }
    }
    
    func updateGroupHeaderModel(viewId: String) {
        guard viewId == currentViewId else {
            return
        }
        
        handleGroupHeaderReset()
    }
}


extension BTCardListViewController: BTCardViewCellDelegate {
    func didClickItem(index: Int) {
        guard let model = viewModel.getCardItemData(index: index),
              let params = model.clickAction as? [String: Any] else {
            return
        }
        
        viewModel.handleJSCallBack(params: params)
    }
    
    func didClickCover(index: Int) {
        guard let model = viewModel.getCardItemData(index: index),
              let params = model.cardCover?.clickAction as? [String: Any] else {
            // 无封面时点击打开卡片
            didClickItem(index: index)
            DocsLogger.btInfo("\(TAG) didClickCover empty open card")
            return
        }
        
        viewModel.handleJSCallBack(params: params)
    }
    
    func didClickComment(params: [String: Any]) {
        viewModel.handleJSCallBack(params: params)
    }
}
