//
//  SKBitableRecommendNativeController.swift
//  SKBitable
//
//  Created by justin on 2023/8/30.
//

import Foundation
import UIKit
import SnapKit
import SKFoundation
import FigmaKit
import ESPullToRefresh
import SKUIKit
import LarkUIKit
import SKInfra
import SkeletonView
import EENavigator
import UniverseDesignColor
import Dispatch
import SKCommon
import Heimdallr
import UniverseDesignToast
import SKResource

enum RecommendRefreshType: Int {
    case firstEnter = 1
    case manulPull
    case loadMore
}

/// recommend card expose life cycle
protocol RecommendCardViewLifeCycle {
    func cardStartAppear(indexPath: IndexPath)
    func cardFullAppear(indexPath: IndexPath)
    func cardDidDisappear(indexPath: IndexPath)
    func cardDidClick(indexPath: IndexPath)
}

enum CardViewRenderState {
    case startAppear
    case fullAppear
    case didDisappear
}

struct RecommendFlowLayoutConfig {
    let columnSpacing: CGFloat
    let interitemSpacing: CGFloat
    let columnCount: Int
    let sectionInset: UIEdgeInsets

    static let doubleTabConfig = RecommendFlowLayoutConfig(
        columnSpacing: 14.0,
        interitemSpacing: 14.0,
        columnCount: 2,
        sectionInset: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
    )

    static let bottomTabConfig = RecommendFlowLayoutConfig(
        columnSpacing: 8,
        interitemSpacing: 14.0,
        columnCount: 2,
        sectionInset: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    )
}

struct RecommendCardConfig {
    let showCardShadow: Bool
    let cardCornerRadius: Float

    static let doubleTabConfig = RecommendCardConfig(showCardShadow: true, cardCornerRadius: 10)

    static let bottomTabConfig = RecommendCardConfig(showCardShadow: false, cardCornerRadius: 12)
}

public struct RecommendNativeConfig {
    let cardConfig: RecommendCardConfig
    let flowLayoutConfig: RecommendFlowLayoutConfig

    public static let doubleTabConfig = RecommendNativeConfig(
        cardConfig: RecommendCardConfig.doubleTabConfig,
        flowLayoutConfig: RecommendFlowLayoutConfig.doubleTabConfig
    )

    public static let bottomTabConfig = RecommendNativeConfig(
        cardConfig: RecommendCardConfig.bottomTabConfig,
        flowLayoutConfig: RecommendFlowLayoutConfig.bottomTabConfig
    )
}

public class SKBitableRecommendNativeController: UIViewController, UIScrollViewDelegate {
    
    static let FluencyCustomScene = "SKBitable.SKBitableRecommendNativeController"
    
    private let context: BaseHomeContext

    private var refreshing: Bool = false
    private var cacheLoaded: Bool = false
    private var finishFirstAppear: Bool = false
    
    private var respChangeExtra = ""
    // 用于埋点上报,用于记录当前的数据模型是来自于第几次请求,下拉刷新后会重置
    private var respChunkSeq = 0
    
    private var loadMoreFooter: RecommendLoadMoreView?
    
    private var exceptionView: UIView?
    
    private var columnCount: Int

    private var initStartTime: TimeInterval?
    private var appearStartTime: TimeInterval?
    public var isSelect: Bool = false
    public var requestIndex: Int = 0
    private var isAppear: Bool = false

    public var tabContainerLoadDurationForLog: Int64?

    private lazy var loadingView: RecommendLoadingView = {
        return RecommendLoadingView(frame: view.bounds)
    }()
    
    lazy var recommendCollectionView: UICollectionView = {
        let collectionLayout = RecommendFlowLayout()
        collectionLayout.delegate = self
        collectionLayout.minimumColumnSpacing = config.flowLayoutConfig.columnSpacing
        collectionLayout.minimumInteritemSpacing = config.flowLayoutConfig.interitemSpacing
        collectionLayout.columnCount = columnCount
        collectionLayout.sectionInset = config.flowLayoutConfig.sectionInset

        let collection = BTMonitoringFPSCollectionView(frame: view.bounds, collectionViewLayout: collectionLayout, scene: .native_home_recommend)
        collection.backgroundColor = UDColor.bgBody
        collection.delegate = self
        collection.alwaysBounceVertical = true
        collection.dataSource = self
        collection.register(BitableRecommendCell.self, forCellWithReuseIdentifier: BitableRecommendCell.cellWithReuseIdentifier())
        collection.setupFPSMonitoring()
        return collection
    }()
    
    // pre visiable indexPathItems
    var preVisibleItems: [IndexPath] = []
    
    // pre full appear items
    var preFullVisibleItems: [IndexPath] = []
    
    var datasource: [Recommend] = []
    
    private let config: RecommendNativeConfig

    public init(context: BaseHomeContext, config: RecommendNativeConfig = RecommendNativeConfig.doubleTabConfig) {
        self.context = context
        self.config = config
        columnCount = config.flowLayoutConfig.columnCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.initStartTime = Date().timeIntervalSince1970
        setupCollectionView()
        setupHeaderFooterView()
        
        if !UserScopeNoChangeFG.PXR.btHomepageRecommendDataCacheDisable {
            // 加载缓存
            RecommendRequestCache.shared.loadCache(context: context) {[weak self] cache, err in
                guard let `self` = self else {
                    return
                }
                BTOpenHomeReportMonitor.reportRecommendLoadDataEnd(context: context, isCache: true)
                if let recommends = cache?.recommends, err == nil {
                    self.respChunkSeq += 1
                    self.respChangeExtra = cache?.changeExtra ?? ""
                    
                    self.recommendCollectionView.isHidden = false
                    self.loadingView.isHidden = true
                    self.preVisibleItems = []
                    self.preFullVisibleItems = []
                    let currentWidth = self.rowCellItemWidth()
                    recommends.forEach { recModel in
                        recModel.computeLayout(currentWidth)
                    }
                    self.datasource = recommends
                    self.remarkAllPositionIndex()
                    self.recommendCollectionView.reloadData()
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        BTOpenHomeReportMonitor.reportTTV(context: self.context, type: .recommend)
                    }

                    self.cacheLoaded = true
                    self.preloadSSR(with: recommends.compactMap({ $0.contentUrl }))
                } else {
                    self.recommendCollectionView.isHidden = true
                    self.setupLoadingViewIfNeeded()
                }
            }
        } else {
            //未开启缓存功能,则直接加载骨架屏
            self.recommendCollectionView.isHidden = true
            self.setupLoadingViewIfNeeded()
        }
        
        // 网络请求
        requestData(refreshType: .firstEnter)
        
        self.addApplicationObserver()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppear = true
        appearViewTrigger()
        if !self.finishFirstAppear {
            self.finishFirstAppear = true
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disappearViewTrigger()
        isAppear = false
    }
    
    //MARK: setup Views
    func setupCollectionView() {
        view.addSubview(recommendCollectionView)
        recommendCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// add pullRefresh and loadmore view
    func setupHeaderFooterView() {
        // Header: Pull Refresh view
        let headerView = recommendCollectionView.es.addPullToRefresh(animator: RecommendAnimatorView(frame: .zero)) { [weak self] in
            guard let `self` = self, self.refreshing == false else {
                return
            }
            self.refreshing = true
            self.requestData(refreshType: .manulPull)
        }
        headerView.frame.origin.y -= recommendCollectionView.contentInset.top
        
        // Footer: load more view
        self.loadMoreFooter = recommendCollectionView.es.addRecommendLoadMore(animator: RecommendAnimatorView(frame: .zero)) { [weak self] in
            self?.requestData(refreshType: .loadMore)
        }
        
    }
    
    
    /// setup loading sketch view
    func setupLoadingViewIfNeeded() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView.showSkeleton()
    }
    
    public func forceScrollToTop() {
        scrollToTop()
    }
    
    private func scrollToTop() {
        // 防止在手动刷新与推送的主动刷新事件冲突，导致刷新UI异常
        if refreshing { return }
        recommendCollectionView.setContentOffset(.zero, animated: true)
    }
    
    func rowCellItemWidth() -> CGFloat {
        let collectionFrame = recommendCollectionView.frame
        let sectionInset = config.flowLayoutConfig.sectionInset
        let rowItemsSpace = sectionInset.left + sectionInset.right + config.flowLayoutConfig.columnSpacing * CGFloat(columnCount - 1)
        return (collectionFrame.width - rowItemsSpace)/CGFloat(columnCount)
    }
    
    func requestData(refreshType: RecommendRefreshType) {
        let isRefresh = refreshType == .manulPull ? true : false
        let chunkSize = RecommendConfig.shared.recommenChunkSize
        
        let requestStartTime = Date().timeIntervalSince1970
        let requestModel = RecommendRequestParam(chunkSize: chunkSize,
                                                 changeExtra: respChangeExtra,
                                                 isRefresh: isRefresh,
                                                 scene: 1,
                                                 needCache: !UserScopeNoChangeFG.PXR.btHomepageRecommendDataCacheDisable,
                                                 baseHPFrom: context.baseHpFrom ?? "")
        RecommendRequest.requestRecommendData(requestModel, context: context) {[weak self] resp, err in
            guard let `self` = self else {
                return
            }
            self.requestIndex += 1
            if let recommends = resp?.recommends, let changeExtra = resp?.changeExtra, err == nil {
                // 更新上下加载更多的数据请求标记
                self.respChangeExtra = changeExtra
                
                // 下拉刷新不重置
                self.respChunkSeq += 1
                
                // 这部分是否可以迁移到异步线程中
                if !recommends.isEmpty {
                    let currentWidth = self.rowCellItemWidth()
                    recommends.forEach { recModel in
                        recModel.computeLayout(currentWidth)
                        // 设置部分埋点数据
                        recModel.respChunkSeq = self.respChunkSeq
                    }
                }
                
                switch refreshType {
                case .firstEnter, .manulPull:
                    BTOpenHomeReportMonitor.reportRecommendLoadDataEnd(context: context, isCache: false)
                    let requestTime = Int64((Date().timeIntervalSince1970 - requestStartTime) * 1000)
                    let currentTime = Date().timeIntervalSince1970
                    
                    self.recommendCollectionView.isHidden = false
                    self.refreshing = false
                    self.loadingView.stopSkeleton()
                    self.loadingView.isHidden = true
                    self.recommendCollectionView.es.stopPullToRefresh()
                    
                    self.preVisibleItems = []
                    self.preFullVisibleItems = []
                    
                    if refreshType == .firstEnter && self.cacheLoaded && !self.datasource.isEmpty {
                        //  已经加载的缓存,新数据需要将与缓存数据中相同contentId的内容剔除
                        self.datasource += recommends.filter { recModel in
                            return !self.datasource.contains { addedModel in
                                return recModel.contentId == addedModel.contentId
                            }
                        }
                    } else {
                        self.datasource = recommends
                    }
                    self.remarkAllPositionIndex()
                    
                    if self.datasource.isEmpty {
                        self.setupFailView(state: .dataEmpty)
                        if refreshType == .firstEnter {
                            BTOpenHomeReportMonitor.reportFail(
                                context: self.context,
                                type: .load_recommend,
                                detail: "dataEmpty"
                            )
                        }
                    } else {
                        self.resetExceptionView()
                        self.recommendCollectionView.reloadData()
                        if refreshType == .firstEnter {
                            let renderTime = Int64((Date().timeIntervalSince1970 - currentTime) * 1000)
                            self.pageDidFinishLoadData(requestTime: requestTime, renderTime: renderTime)
                        }
                    }
                    self.refreshToExpose()
                    // 预加载ssr
                    preloadSSR(with: self.datasource.compactMap({ $0.contentUrl }))
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        BTOpenHomeReportMonitor.reportTTV(context: self.context, type: .recommend)
                    }
                case .loadMore:
                    self.resetExceptionView()
                    self.recommendCollectionView.isHidden = false
                    self.recommendCollectionView.es.stopLoadingMore()
                    if !recommends.isEmpty {
                        let startIndex = self.datasource.count
                        self.datasource.append(contentsOf: recommends)
                        self.remarkAllPositionIndex()
                        let insertItemIndexPaths = recommends.enumerated().map { element in
                            return IndexPath(item: startIndex + element.offset, section: 0)
                        }
                        // insert without animation for better performace
                        UIView.performWithoutAnimation {
                            self.recommendCollectionView.insertItems(at: insertItemIndexPaths)
                        }
                        DocsLogger.info("load more data, before cout: \(startIndex), after count:\(self.datasource.count)")
                        // 预加载ssr
                        preloadSSR(with: recommends.compactMap({ $0.contentUrl }))
                    }
                }
                // 接口成功也上报一次
                self.pageRequestState(type: refreshType, response: resp, empty: recommends.isEmpty)
            } else {
                switch refreshType {
                case .firstEnter, .manulPull:
                    self.refreshing = false
                    self.recommendCollectionView.es.stopPullToRefresh()
                    self.loadingView.stopSkeleton()
                    self.loadingView.isHidden = true
                    if self.datasource.isEmpty {
                        self.setupFailView(state: .requestFail)
                        if refreshType == .firstEnter {
                            BTOpenHomeReportMonitor.reportFail(
                                context: self.context,
                                type: .load_recommend,
                                detail: "\(err?.localizedDescription ?? "")"
                            )
                        }
                    }else {
                        UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Workspace_UnableToLoadData_Description, on: self.view)
                    }
                case .loadMore:
                    self.loadMoreFooter?.failStopLoadingMore()
                }
                self.pageLoadFail(error: err, type: refreshType)
            }
        }
    }
    
    
    /// expose when refresh with auto or manuel
    /// delay time for cell render finish after reloadData
    func refreshToExpose() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.checkNeedExpose(self.recommendCollectionView)
        }
    }
    
    /// caculate full appear cell and disappear cell for expose
    /// - Parameter scrollView: is collectionview
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // caculate full appear cell and disappear cell for expose
        checkNeedExpose(scrollView)
    }
    
    
    /// check  full appear cell and disappear cell for expose
    /// - Parameter scrollView: scorllview
    func checkNeedExpose(_ scrollView: UIScrollView) {
        let visiableItems = recommendCollectionView.indexPathsForVisibleItems
        if visiableItems != preVisibleItems {
            var curFullVisibleItems: [IndexPath] = []
            visiableItems.forEach { indexPath in
                guard let visiableCell = recommendCollectionView.cellForItem(at: indexPath) else {
                    return
                }
                let visiableRect = CGRect(x: recommendCollectionView.contentOffset.x, y: recommendCollectionView.contentOffset.y, width: recommendCollectionView.bounds.width, height: recommendCollectionView.bounds.height)
                if visiableRect.contains(visiableCell.frame) {
                    curFullVisibleItems.append(indexPath)
                }
            }
            
            // did disappear Items which current visible items not in previous appear items
            let disAppearItems = preVisibleItems.filter { indexPath in
                return !visiableItems.contains(indexPath)
            }
            
            if !disAppearItems.isEmpty {
//                DocsLogger.info("Cell Expose check, disappear items: \(disAppearItems)")
                preVisibleItems = visiableItems
                self.triggerCardRender(items: disAppearItems, renderState: .didDisappear)
            }
            
            // new appear items which current full visible items not in previous full appear items
            let newAppearItems = curFullVisibleItems.filter { indexPath in
                return !preFullVisibleItems.contains(indexPath)
            }
            
            if !newAppearItems.isEmpty {
//                DocsLogger.info("Cell Expose check, new appear items: \(newAppearItems)")
                self.triggerCardRender(items: newAppearItems, renderState: .fullAppear)
                preFullVisibleItems = curFullVisibleItems
            }
            
            if preVisibleItems.isEmpty {
                preVisibleItems = visiableItems
//                DocsLogger.info("Cell Expose check, first visible items: \(preVisibleItems)")
            }
            
            if preFullVisibleItems.isEmpty {
                preFullVisibleItems = curFullVisibleItems
//                DocsLogger.info("Cell Expose check, first full appear items: \(preFullVisibleItems)")
            }
        }
    }
}

// MARK: CollectionView Delegate
extension SKBitableRecommendNativeController: UICollectionViewDelegate, UICollectionViewDataSource, RecommendFlowLayoutDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableRecommendCell.cellWithReuseIdentifier(), for: indexPath)
        if let recommendCell = cell as? BitableRecommendCellDelegate, indexPath.item < datasource.count  {
            let modal = datasource[indexPath.item]
            recommendCell.renderCell(modal, indexPath: indexPath, config: config.cardConfig)
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item < datasource.count {
            let model = datasource[indexPath.item]
            let targetCellWidth = rowCellItemWidth()
            if abs(targetCellWidth - model.cellWidth) >= 0.1 {
                model.computeLayout(targetCellWidth)
            }
            let itemWidth = model.cellWidth
            let itemHeight = model.cellHeight
            return CGSize(width: itemWidth, height: itemHeight)
        }
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < datasource.count {
            let model = datasource[indexPath.item]
            if let pushUrl = model.contentUrl, let url = URL(string: pushUrl) {
                var context: [String: Any] = ["showTemporary": false]
                let fromParams = ["ccm_open_type": ccmOpenType,
                              "from": fromType]
                let urlAppended = url.docs.addOrChangeEncodeQuery(parameters: fromParams)
                Navigator.shared.docs.showDetailOrPush(urlAppended,context:context, from: self)
            }
            model.cardDidClick(indexPath: indexPath)
        }
    }

    private var ccmOpenType: String {
        if context.version == .hp_v2 {
            let type = context.containerEnv == .larkTab ? CCMOpenType.baseHomeLarkTabFeedV4 : CCMOpenType.baseHomeWorkbenchFeedV4
            return type.trackValue
        }
        return "homepage_feed"
    }

    private var fromType: String {
        if context.version == .hp_v2 {
            let type = context.containerEnv == .larkTab ? FromSource.baseHomeLarkTabFeedV4 : FromSource.baseHomeWorkbenchFeedV4
            return type.rawValue
        }
        return "homepage_feed"
    }
}

// MARK: - iPad Compatible
extension SKBitableRecommendNativeController {
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.resetColumCountIfNeed(containerWidth: self.recommendCollectionView.bounds.width)
            self.recommendCollectionView.reloadData()
        }
    }
    
    public func reloadHomeLayout() {
        view.layoutIfNeeded()
        resetColumCountIfNeed(containerWidth: self.recommendCollectionView.bounds.width)
        self.recommendCollectionView.reloadData()
    }
    
    @discardableResult
    public func resetColumCountIfNeed(containerWidth: CGFloat) -> Bool {
        let columnCount = caculateColumnCount(containerWidth: containerWidth)
        var isChanged = false
        if let flowLayout = self.recommendCollectionView.collectionViewLayout as? RecommendFlowLayout {
            if self.columnCount != flowLayout.columnCount || self.columnCount != columnCount {
                flowLayout.columnCount = columnCount
                self.columnCount = columnCount
                isChanged = true
            }
        }
        DocsLogger.info("***____,current colum count: \(columnCount)")
        return isChanged
    }
    
    public func caculateColumnCount(containerWidth: CGFloat) -> Int {
        if !SKDisplay.pad {
            return 2
        }
        let estimateWidth = CGFloat(150.0)
        let flowLayoutConfig = config.flowLayoutConfig
        let columnSpacing = flowLayoutConfig.columnSpacing
        let contentWidth = containerWidth - flowLayoutConfig.sectionInset.left - flowLayoutConfig.sectionInset.right + columnSpacing

        let columFloatValue = contentWidth / estimateWidth
        let minColumCount = floor(columFloatValue)
        
        DocsLogger.info("***____,current colum value: \(columFloatValue), minColumCount:\(minColumCount)")
        
        // 0.8 经验值
        let resultCount = (columFloatValue - minColumCount > 0.8) ? (Int(minColumCount) + 1) : Int(minColumCount)
        return max(2, resultCount)
    }
}

// MARK: - Data load/Request Exception
extension SKBitableRecommendNativeController: StateViewDelegate {
    
    func setupFailView(state: BitableHomePageState) {
        resetExceptionView()
        let stateView = BitableHomeStateView(frame: self.view.bounds, state: state, delegate:self)
        view.addSubview(stateView)
        stateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.exceptionView = stateView
    }
    
    public func tapStateView(state: BitableHomePageState) {
        switch state {
        case .loading: break
        case .dataEmpty, .requestFail:
            if !self.refreshing {
                self.refreshing = true
                self.requestData(refreshType: .firstEnter)
            }
        }
    }
    
    private func resetExceptionView() {
        guard let preExceptionView = self.exceptionView, preExceptionView.superview != nil else {
            return
        }
        preExceptionView.removeFromSuperview()
        self.exceptionView = nil
    }
    
}

// 数据埋点相关,数据埋点重多,全部由Controler集中控制,后续不必担心上下文缺失
extension SKBitableRecommendNativeController {
    // 全局重新排序
    func remarkAllPositionIndex() {
        var index = 0
        self.datasource.forEach { recommend in
            index += 1
            recommend.allPositionInex = index
        }
    }
}


public extension SKBitableRecommendNativeController {
    
    func addApplicationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        if isAppear {
            DispatchQueue.main.async { [weak self] in
                self?.appearViewTrigger()
            }
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        if isAppear {
            disappearViewTrigger()
        }
    }
    
    func enterContainerView(isFristLoad: Bool) {
        if !isFristLoad {
            isSelect = true
            appearViewTrigger()
        }
    }
    
    func leaveContainerView() {
        disappearViewTrigger()
        isSelect = false
    }
    
    /// 可能是切后台，跳转页面后，返回触发viewDidAppear
    func appearViewTrigger() {
        if !isSelect {
            return
        }
        appearStartTime = Date().timeIntervalSince1970
        HMDFPSMonitor.shared().enterFluencyCustomScene(withUniq: Self.FluencyCustomScene)
        // 第一次页面加载开始前不触发补偿曝光逻辑
        if self.finishFirstAppear {
            self.triggerCardRender(items: self.preVisibleItems, renderState: .startAppear)
            self.triggerCardRender(items: self.preFullVisibleItems, renderState: .fullAppear)
        }
    }
    
    /// 可能是切后台，跳转页面后，返回触发viewWillDisappear
    func disappearViewTrigger() {
        if !isSelect {
            return
        }
        HMDFPSMonitor.shared().leaveFluencyCustomScene(withUniq: Self.FluencyCustomScene)
        self.triggerCardRender(items: self.preVisibleItems, renderState: .didDisappear)
        guard let startTime = self.appearStartTime else {
            return
        }
        appearStartTime = nil
        
        let stayDuration = Int64((Date().timeIntervalSince1970 - startTime) * 1000)
        var dic: [String: Any] = pageCommonParams()
        dic.merge(other: ["stay_duration": stayDuration])
        DocsTracker.newLog(enumEvent: .baseHomepageFeedStayDuration, parameters: dic)
    }
    
    internal func triggerCardRender(items: [IndexPath], renderState: CardViewRenderState) {
        if items.isEmpty {
            return
        }
        items.forEach { indexPath in
            if indexPath.item < self.datasource.count {
                let itemModel = self.datasource[indexPath.item]
                switch renderState {
                case .startAppear:
                    itemModel.cardStartAppear(indexPath: indexPath)
                case .fullAppear:
                    itemModel.cardFullAppear(indexPath: indexPath)
                case .didDisappear:
                    itemModel.cardDidDisappear(indexPath: indexPath)
                }
            }
        }
    }
    
    func pageCommonParams() -> [String: Any] {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: self.context))
        var dic: [String: Any] = bizParams.params
        dic.merge(other: ["tab_name":"recommend"])
        return dic
    }
    
    
    func pageDidFinishLoadData(requestTime: Int64, renderTime: Int64) {
        if self.requestIndex == 1, let startTime = self.initStartTime {
            let duration = Int64((Date().timeIntervalSince1970 - startTime) * 1000)
            var dic: [String: Any] = pageCommonParams()
            dic.merge(other: ["duration": duration, "request_duration": requestTime, "render_duration": renderTime, "container_duration": tabContainerLoadDurationForLog ?? 0])
            DocsTracker.newLog(event: "ccm_base_homepage_recommend_load_view", parameters: dic)
        }
    }
    
    internal func pageLoadFail(error: Error?, type: RecommendRefreshType) {
        guard let resultError = error as? NSError else{
            return
        }
        var dic: [String: Any] = pageCommonParams()
        var errorParam: [String : Any] = [:]
        errorParam["error_code"] = resultError.code
        errorParam["error_msg"] = resultError.domain
        errorParam["request_id"] = resultError.userInfo["request_id"] ?? ""
        errorParam["request_index"] = self.requestIndex
        errorParam["request_type"] = type.rawValue
        dic.merge(other: errorParam)
        DocsTracker.newLog(event: "ccm_base_homepage_recommend_view", parameters: dic)
    }
    
    
    /// 推荐接口请求上报
    /// - Parameters:
    ///   - type: 请求类型
    ///   - response: response
    ///   - empty: 返回数据是否为空
    internal func pageRequestState(type: RecommendRefreshType, response: RecommendResponse?, empty: Bool) {
        let requestId: String = response?.requestId ?? ""
        let errorMsg: String = empty ? "Response Empty" : "Sucess"
        let errcode: Int = empty ? 400 : 0
        let resposneError = NSError(domain: errorMsg, code:errcode, userInfo: ["request_id": requestId])
        self.pageLoadFail(error: resposneError, type: type)
    }
}
