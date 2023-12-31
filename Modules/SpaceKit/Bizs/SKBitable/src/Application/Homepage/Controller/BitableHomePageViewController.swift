//
//  BitableHomePageViewController.swift
//  SKSpace
//
//  Created by ByteDance on 2023/10/27.
//

import UIKit
import LarkSetting
import LarkFontAssembly
import SwiftyJSON
import SpaceInterface
import LarkUIKit
import LarkSplitViewController
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import RxRelay
import SKInfra
import LarkContainer
import EENavigator
import LarkNavigator
import LKCommonsLogging
import RxCocoa
import UniverseDesignIcon
import UniverseDesignColor
import LarkModel

public enum BitableHomePageChartState: Int {
    case initial
    case loading
    case cacheSuccess
    case dataSuccess
    case dataEmpty
    case requestFail
}

protocol BitableHomePageViewControllerDelegate: AnyObject {
    func createBitableFileIfNeeded(isEmpty: Bool)
    func allowRightSlidingForBack()
    func forbiddenRightSlidingForBack()
}

final class BitableHomePageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    //记录是否上报过首页的成功/失败事件，一次homepage周期只report一次
    private var hasReportedSuccess: Bool = false
    private var hasReportFail: Bool = false

    //MARK: 框架层属性
    var context: BaseHomeContext

    weak var tabBarDelegate: BitableHomePageTabBarDelegate?
    
    weak var delegate: BitableHomePageViewControllerDelegate?
    
    private var hasDisappear = true

    var isFileListEmbeded = true

    lazy var header: BitableHomePageHeader = {
       let header =  BitableHomePageHeader.init { [weak self] in
            self?.jumpToSearchController()
        } zoomHomePageBlock: { [weak self] in
            self?.showMultiListViewInEmbededStyle()
        } exitHomePageBlock: { [weak self] in
            self?.closeHomePageViewController()
        }
        return header
    }()

    var headerBgViewAlphaBeforeAnimation: CGFloat?
    lazy var headerBgView = {
        let view = UIView.init()
        view.backgroundColor = BitableHomeLayoutConfig.headerBgColor()
        view.alpha = 0
        return view
    }()
    
    private var isPullingToRefresh: Bool = false
    private var isFirstRefresh: Bool = true

    private lazy var headerGradientLayer = {
         let layer = CAGradientLayer()
         layer.locations = [0.0,0.5]
         layer.startPoint = CGPoint(x: 0.0, y: 0.0)
         layer.endPoint = CGPoint(x: 0.0, y: 1.0)
         return layer
    }()
        
    lazy var collectionView: UICollectionView = {
        let layout = HomePageCollectionViewLayout.init()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        
        var collectionView = BTMonitoringFPSCollectionView(frame: .zero, collectionViewLayout: layout, scene: .native_home_personal)
        collectionView.register(BitableHomePageMultiListContainerCell.self, forCellWithReuseIdentifier: BitableHomePageMultiListContainerCell.reuseIdentifier)
        collectionView.register(BitableHomePageChartCell.self, forCellWithReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: .reuseForNormal))
        collectionView.register(BitableHomePageChartCell.self, forCellWithReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: .reuseForStatics))
        collectionView.register(BitableHomePageChartEmptyCell.self, forCellWithReuseIdentifier: BitableHomePageChartEmptyCell.cellWithReuseIdentifier())
        collectionView.register(BitableHomePageChartErrorCell.self, forCellWithReuseIdentifier: BitableHomePageChartErrorCell.cellWithReuseIdentifier())
        collectionView.register(BitableHomePageChartLoadingCell.self, forCellWithReuseIdentifier: BitableHomePageChartLoadingCell.cellWithReuseIdentifier())
        collectionView.register(BitableHomePageChartHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BitableHomePageChartHeader.reuseIdentifier)
        collectionView.register(BitableHomePageChartFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BitableHomePageChartFooter.reuseIdentifier)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        //collectionView.prefetchDataSource = self
           
        collectionView.isPagingEnabled = false
        collectionView.dragInteractionEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.setupFPSMonitoring()
        return collectionView
    }()
    
    //MARK: 多列属性
    var isInAnimation: Bool = false
    var multiListContainerCell : BitableHomePageMultiListContainerCell?
    var multiListController: BitableMultiListControllerProtocol?
    lazy var animationContainerView: UIView = {
       var container = UIView()
       return container
    }()
    
    lazy var animationBgView: UIView = {
       var container = UIView()
       return container
    }()
    
    //MARK: 仪表盘属性
    var chartHeader: UIView?
            
    private var chartState :BitableHomePageChartState = .initial {
        didSet{
            if let header = chartHeader as? BitableHomePageChartHeader  {
                if chartEditingMode {
                    header.showEditButton(true)
                } else {
                    header.showEditButton(chartState == .dataSuccess || chartState == .cacheSuccess)
                }
            }
        }
    }
    var chartDatasource: [Chart] = []
    let chartLynxDataProvider: BitableSliceDataProvider = BitableSliceManager()
    var chartEditingMode: Bool = false
    
    let addChartButton: UIButton = {
        let addChartButton = UIButton(frame: .zero)
        addChartButton.setImage(UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.primaryOnPrimaryFill,size: CGSize(width: 20, height: 20)), for: .normal)
        addChartButton.setImage(UDIcon.getIconByKey(.addOutlined, iconColor: UDColor.primaryOnPrimaryFill,size: CGSize(width: 20, height: 20)), for: .highlighted)
        addChartButton.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 17)
        addChartButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_AddCharts_Button, for: .normal)
        addChartButton.backgroundColor = UDColor.primaryFillDefault
        addChartButton.imageEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        addChartButton.titleEdgeInsets = UIEdgeInsets(top: 14, left: 2, bottom: 14, right: 0)
        addChartButton.contentMode = .scaleAspectFit
        addChartButton.layer.cornerRadius = 14
        addChartButton.isHidden = true
        addChartButton.isExclusiveTouch = true
        return addChartButton
    }()

    private var isDraging = false

    //MARK: lifeCycle
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
     init(multiListViewController: BitableMultiListControllerProtocol? = nil, context: BaseHomeContext){
        self.multiListController = multiListViewController
        self.context = context
        super.init(nibName: nil, bundle: nil)
   }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.view.backgroundColor = BitableHomeLayoutConfig.backgroundColor()
        setupUI()
        registerNotification()
        collectionView.es.startPullToRefresh()
        loadChartCache()
        addApplicationObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasDisappear {
            DocsTracker.reportBitableHomePageView(context: context, tab: .homepage)
            hasDisappear = false
        }
        if animationContainerView.superview != nil {
            forbiddenRightSlidingForBack()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hasDisappear = true
        allowRightSlidingForBack()
    }

    //MARK: UI
    private func setupUI() {
        setUpHeaderView()
        setCollectionView()
        setupHeaderRefreshView()
        addChartButton.addTarget(self, action: #selector(createChart), for: .touchUpInside)
        view.addSubview(addChartButton)
        addChartButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(BitableHomeLayoutConfig.colloctionViewHorizonMargin)
            make.right.equalToSuperview().offset(-BitableHomeLayoutConfig.colloctionViewHorizonMargin)
            make.height.equalTo(48)
            make.top.equalTo(self.collectionView.snp.bottom).offset(2)
        }
    }
    
    private func registerNotification() {
        _ = NotificationCenter.default.addObserver(forName: .init(SKBitableConst.triggerOpenFullscreenNoti), object: nil, queue: .main) {[weak self] noti in
            guard let `self` = self else {
                return
            }
            
            if let _ = view.window, let chartTokenToFullScreen = noti.userInfo?["chartToken"] as? String {
                if let tappedChart = self.chartDatasource.first(where: { chart in
                    return chart.token == chartTokenToFullScreen
                }) {
                    let copyChart = Chart(JSON(tappedChart.toMap()))
                    copyChart.updateScene(scene: .fullScreen)
                    let chartDetailVC = BitableChartDetailViewController(chart: copyChart, 
                                                                         context: context,
                                                                         chartLynxDataProvider: chartLynxDataProvider,
                                                                         safeAreaInsetsFrom: self.view.safeAreaInsets,
                                                                         userResolver: context.userResolver)
                    self.navigationController?.pushViewController(chartDetailVC, animated: true)
                }
            }
        }
    }
    
    private func setUpHeaderView() {
        view.layer.addSublayer(headerGradientLayer)
        headerGradientLayer.ud.setColors(BitableHomeLayoutConfig.headerGridentColors())
        headerGradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, 56 + view.safeAreaInsets.top)
        view.addSubview(headerBgView)
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(56)
        }
        headerBgView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(header.snp.bottom)
        }
    }
    
    private func setCollectionView() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.left.equalToSuperview().offset(BitableHomeLayoutConfig.colloctionViewHorizonMargin)
            make.right.equalToSuperview().offset(-BitableHomeLayoutConfig.colloctionViewHorizonMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-BitableHomeTabViewController.bottomTabBarHeight)
        }
    }
       
    //MARK: collection datasource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return chartEditingMode ? 0 : 1
        } else {
            switch chartState {
            case .loading:
                return 3
            case .dataEmpty, .requestFail:
                return 1
            case .cacheSuccess, .dataSuccess:
                return chartDatasource.count
            default:
                return 0
            }
        }
    }
       
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let section = indexPath.section
            if kind == UICollectionView.elementKindSectionHeader  {
               if section == 0 {
                   return UICollectionReusableView()
               } else {
                   let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: BitableHomePageChartHeader.reuseIdentifier, for: indexPath)
                   self.chartHeader = header
                   if let chartHeader = header as? BitableHomePageChartHeader {
                       chartHeader.editButton.addTarget(self, action: #selector(didEditClick), for: .touchUpInside)
                       chartHeader.showEditButton(chartState == .dataSuccess || chartState == .cacheSuccess)
                   }
                   
                   // 上报埋点
                   DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageDashboardSettingView, parameters: nil, context: context)
                   return header
               }
           } else if kind == UICollectionView.elementKindSectionFooter {
               if section == 0 {
                   return UICollectionReusableView()
               } else {
                   let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: BitableHomePageChartFooter.reuseIdentifier, for: indexPath)
                   return footer
               }
           } else {
               return UICollectionReusableView()
           }
       }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    //MARK: collection delegateFlowlayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            let cellW = collectionView.bounds.size.width
            let cellH = BitableHomeLayoutConfig.multiListContainerHeight
            return CGSize(width: cellW , height: cellH)
        } else {
            switch chartState {
            case .loading:
                return CGSize(width: collectionView.frame.width, height: 244)
            case .dataEmpty, .requestFail:
                return CGSize(width: collectionView.frame.width, height: 300)
            case .cacheSuccess, .dataSuccess:
                if indexPath.row < chartDatasource.count  {
                    let chart = chartDatasource[indexPath.item]
                    if chart.type == .statistics {
                        return CGSize(width: collectionView.frame.width, height: BitableHomeLayoutConfig.chartCardHeightStatistic + BitableHomeChartCellLayoutConfig.topBgViewHeight)
                    }
                }
                return CGSize(width: collectionView.frame.width, height: BitableHomeLayoutConfig.chartCardHeightNormal + BitableHomeChartCellLayoutConfig.topBgViewHeight)
            default:
                return CGSize(width: collectionView.frame.width, height: BitableHomeLayoutConfig.chartCardHeightNormal + BitableHomeChartCellLayoutConfig.topBgViewHeight)
            }
        }
    }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       if indexPath.section == 0 {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageMultiListContainerCell.reuseIdentifier, for: indexPath)
           if let containerCell = cell as? BitableHomePageMultiListContainerCell {
               containerCell.delegate = self
               if shouldMountMultiListVC(cell: containerCell) {
                   mountMultiListVC(cell: containerCell)
               }
           }
           return cell
       } else {
           switch chartState {
           case .loading:
               return collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartLoadingCell.cellWithReuseIdentifier(), for: indexPath)
           case .dataEmpty:
               let emptyCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartEmptyCell.cellWithReuseIdentifier(), for: indexPath)
               if let emptyCell = emptyCell as? BitableHomePageChartEmptyCell {
                   emptyCell.delegate = self
               }
               return emptyCell
           case .requestFail:
               let errorCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartErrorCell.cellWithReuseIdentifier(), for: indexPath)
               if let errorCell = errorCell as? BitableHomePageChartErrorCell {
                   errorCell.delegate = self
               }
               return errorCell
           case .cacheSuccess, .dataSuccess:
               let chart = chartDatasource[indexPath.item]
               let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: chart.type?.toReuseType()), for: indexPath)
               if let chartCell = cell as? BitableHomePageChartCell, indexPath.item < chartDatasource.count  {
                   chartCell.delegate = self
                   chartCell.renderCell(chart, dataProvider: chartLynxDataProvider,indexPath: indexPath,editMode: chartEditingMode)
               }
               return cell
           default:
               let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartLoadingCell.cellWithReuseIdentifier(), for: indexPath)
               return cell
           }
       }
   }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return .zero
        } else {
            return CGSize(width: collectionView.frame.width, height: BitableHomeLayoutConfig.chartHeaderHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 0 {
            return .zero
        } else {
            return CGSize(width: collectionView.frame.width, height: BitableHomeLayoutConfig.chartFooterHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath) as? BitableHomePageChartCell {
            let touchPoint = collectionView.panGestureRecognizer.location(in: cell)
            // 检查是否在重新排序按钮区域内
            if cell.reorderButton.frame.contains(touchPoint) {
                // 返回true开始拖拽
                return true
            }
            return false
        }
        return false
    }
    
    //MARK: collectionView 滑动监听
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHomepageHeader()
        updateChartHeader()
        checkFullyVisiableCellsForTracking()
    }
    
    func checkFullyVisiableCellsForTracking() {
        let collectionView = self.collectionView
        let totallyVisibleCells = collectionView.visibleCells.filter({ cell -> Bool in
            let cellRect = collectionView.convert(cell.frame, to: collectionView.superview)
            return collectionView.frame.contains(cellRect)
        })
        //过滤出 tag = 0 的cell，非 0的说明已经曝光过了，
        let shouldReportCells = totallyVisibleCells.filter { $0.tag == 0 }
        let invisibleCells = collectionView.visibleCells.filter { !totallyVisibleCells.contains($0) }
        //看不见了需要重置 tag 为 0。下次出来再重新曝光
        invisibleCells.forEach { $0.tag = 0 }
        shouldReportCells.forEach {
            if let indexPath = collectionView.indexPath(for:$0),
               self.chartDatasource.count > indexPath.row {
                let chart = self.chartDatasource[indexPath.row]
                if let dashboardToken = chart.dashboardToken,
                   let chartToken = chart.token,
                   let baseToken = chart.baseToken {
                    let params  = ["block_token": dashboardToken,
                                   "chart_id": chartToken,
                                   "is_template": chart.isTemplate ? "true" : "false",
                                   "file_id": baseToken.encryptToShort]
                    //曝光过了，需要设置为 1。避免重复曝光
                    collectionView.cellForItem(at: indexPath)?.tag = 1
                    DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageDashboardView, parameters: params, context: context)
                }
            }
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .user_scroll)
    }

    private func updateChartHeader() {
        // 图表吸顶
        if let header = self.chartHeader as? BitableHomePageChartHeader {
            if let firstChartFrame = collectionView.layoutAttributesForItem(at: IndexPath(row: 0, section: 1)) {
                header.stickTop(collectionView.contentOffset.y > firstChartFrame.frame.origin.y - BitableHomeLayoutConfig.chartHeaderHeight)
            }
        }
    }
        
    private func updateHomepageHeader() {
        guard chartEditingMode == false else {
            return
        }
        let offset = collectionView.contentOffset.y
        let height = self.headerGradientLayer.bounds.size.height
        if offset > height {
            headerBgView.alpha = 1.0
            return
        }
        if offset <= 0 {
            headerBgView.alpha = 0
            return
        }
        let ratio = offset / height
        headerBgView.alpha = ratio
    }
    
    private func updateHomepageHeaderForEdit() {
        let alpha = chartEditingMode ? 1.0 : 0.0
        UIView.animate(withDuration: 0.3) {
            self.headerBgView.alpha = alpha
        }
    }
    
    //MARK: 仪表盘数据相关
    func requestChartData(completion: (() -> Void)? = nil) {
        ChartRequest.requestHomePageChartData { [weak self] resp, err in
            completion?()
            guard let `self` = self else {
                return
            }
            BTOpenHomeReportMonitor.reportDashboardLoadDataEnd(context: context, isCache: false)
            if err == nil, let charts = resp?.charts {
                if charts.isEmpty {
                    self.chartState = .dataEmpty
                } else {
                    self.chartState = .dataSuccess
                    let colorConfig: [ChartGradientSTyle] = [.green, .blue]
                    for (idx, chart) in charts.enumerated() {
                        chart.gradientStyle = colorConfig[idx % 2]
                        chart.updateScene(scene: chartEditingMode ? .homeEdit : .home)
                    }
                    self.chartDatasource = charts
                }
            } else {
                self.chartState = .requestFail
            }
            self.collectionView.reloadData()
        }
    }
    
    func loadChartCache() {
        self.chartState = .loading
        self.collectionView.reloadData()
        
        //缓存有效时间，，默认取不到 settings 时是三天 (259200 秒)
        let bitableHomeChartConfig = try? context.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_homepage_chart"))
        let maxAge = bitableHomeChartConfig?["chart_list_cache_timeout_seconds"] as? TimeInterval ?? 259200
        ChartRequestCache.shared.loadCache(maxAge) {[weak self] chartCache, err in
            guard let `self` = self else {
                return
            }
            BTOpenHomeReportMonitor.reportDashboardLoadDataEnd(context: context, isCache: true)
            if err == nil, let charts = chartCache?.charts {
                if charts.isEmpty {
                    self.chartState = .dataEmpty
                } else {
                    self.chartState = .cacheSuccess
                    let colorConfig: [ChartGradientSTyle] = [.green, .blue]
                    for (idx, chart) in charts.enumerated() {
                        chart.gradientStyle = colorConfig[idx % 2]
                        chart.updateScene(scene: .home)
                    }
                    self.chartDatasource = charts
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    func updateChartData() {
        let editedOrderArray = self.chartDatasource.map { chart in
            return chart.token ?? ""
        }
        
        DispatchQueue.global().async {
            ChartRequestCache.shared.updateCache(self.chartDatasource)
        }
        
        ChartRequest.updateUserChartData(UpdateChartRequestParam(chartTokens: editedOrderArray)) { success, err in
            if err == nil {
                // 数据更新请求成功
                DocsLogger.info("update charts data result:\(success)")
            } else {
                DocsLogger.error("failed to update charts \(err?.localizedDescription ?? "unknown reason")")
            }
        }
    }

    @objc
    private func didEditClick() {
        if isDraging {
            return
        }
        toggleEditMode()
    }

    func toggleEditMode() {
        guard !isPullingToRefresh else {
            DocsLogger.btInfo("[Action]: Can Not Enter Edit Mode, Is Pulling To Refresh Data")
            return
        }
        chartEditingMode = !chartEditingMode
        //如果当前是编辑模式，调用埋点
        if chartEditingMode {
            BTOpenHomeReportMonitor.reportCancel(context: context, type: .dashboard_edit)
        }

        // 编辑模式下关闭bounces
        collectionView.bounces = !chartEditingMode
        
        // 图表的header切换状态
        updateHomepageHeaderForEdit()
        if let chartHeader = chartHeader as? BitableHomePageChartHeader {
            chartHeader.toggleEditMode(chartEditingMode)
            
            if chartEditingMode {
                chartHeader.showEditButton(true)
            } else {
                chartHeader.showEditButton(chartState == .dataSuccess || chartState == .cacheSuccess)
            }
        }
        
        // 控制底部bar显示隐藏
        if let tabBarDelegate = tabBarDelegate {
            if chartEditingMode {
                tabBarDelegate.hideBottomTabBar(animated: true)
            } else {
                tabBarDelegate.showBottomTabBar(animated: true)
            }
            makeAddChartButtonVisible(chartEditingMode)
        }
        
        // 是否允许右滑返回
        if chartEditingMode {
            forbiddenRightSlidingForBack()
        } else {
            allowRightSlidingForBack()
        }
        
        // collectionView自身状态切换&滚动表现
        collectionView.dragInteractionEnabled = chartEditingMode
        
        // 更新数据源的scene
        for chart in chartDatasource {
            chart.updateScene(scene: chartEditingMode ? .homeEdit : .home)
        }
        
        // 设置cell的非编辑状态
        self.chartDatasource.indices.forEach { row in
            //筛选出是 select 是 true 的数据
            let indexPath = IndexPath(row: row, section: 1)
            if let chartCell = self.collectionView.cellForItem(at: indexPath) as? BitableHomePageChartCell {
                chartCell.toggleEditMode(chartEditingMode)
            }
        }
        
        if chartEditingMode {
            if let _ = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)),
               let layoutAttributes = collectionView.layoutAttributesForItem(at: IndexPath(row: 0, section: 0)) {
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: layoutAttributes.frame.origin.y + layoutAttributes.frame.height), animated: false)
                } completion: { _ in
                    if #available(iOS 13, *), self.collectionView.numberOfItems(inSection: 0) > 0 {
                        self.collectionView.deleteItems(at: [IndexPath(row: 0, section: 0)])
                    } else {
                        self.collectionView.reloadData()
                    }
                }
            } else {
                DocsLogger.btInfo("collection section 0 missed")
                if #available(iOS 13, *), self.collectionView.numberOfItems(inSection: 0) > 0 {
                    self.collectionView.deleteItems(at: [IndexPath(row: 0, section: 0)])
                } else {
                    self.collectionView.reloadData()
                }
            }
        } else {
            self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
        }
        
        // 上报埋点
        let params :[String: Any] = ["click": chartEditingMode ? "edit" : "save",
                                     "target": "ccm_bitable_homepage_dashboard_component_setting_view"]
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageDashboardSettingClick, parameters: params, context: context)
    }
    
    func makeAddChartButtonVisible(_ visible:Bool) {
        self.addChartButton.snp.updateConstraints { make in
            make.top.equalTo(self.collectionView.snp.bottom).offset(visible ? 2 : 200)
        }
        
        if visible {
            // 首先先显示出来才能动画
            self.addChartButton.isHidden = false
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.addChartButton.isHidden = !visible
        }
    }
    
    @objc func createChart() {
        jumpToBitableOnlySearchController()
        
        // 上报埋点
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartSettingClick, parameters: ["click": "add_component"], context: context)
    }

    //MARK: 下拉刷新
    func setupHeaderRefreshView() {
        let headerRefreshView = collectionView.es.addPullToRefresh(animator: RecommendAnimatorView(frame: .zero)) { [weak self] in
            guard let self = self else {
                return
            }
            DocsLogger.btInfo("[Action] pull to refresh Data")
            isPullingToRefresh = true
            self.refreshData(completion: {
                self.collectionView.es.stopPullToRefresh()
                self.isPullingToRefresh = false
            })
            if !isFirstRefresh {
                BTOpenHomeReportMonitor.reportCancel(context: self.context, type: .user_refresh)
            }
            isFirstRefresh = false
        }
        headerRefreshView.frame.origin.y -= collectionView.contentInset.top
    }
    
    // 通知数据刷新
    func refreshData(completion: @escaping () -> Void) {
        DocsLogger.btInfo("[Action] pull to refresh Data")
        multiListController?.collectionViewPullToRefresh()
        requestChartData(completion: completion)
    }
    
    //MARK: 多列相关
    private func shouldMountMultiListVC(cell: BitableHomePageMultiListContainerCell) -> Bool {
        guard isInAnimation == false else {
            return false
        }
        guard let controller = multiListController else {
            return false
        }
        guard controller.view.superview != cell.contentView else {
            return false
        }
        guard isFileListEmbeded else {
            return false
        }
        return true
    }
    
    private func mountMultiListVC(cell: BitableHomePageMultiListContainerCell) {
        guard let controller = multiListController else {
            return
        }
        let embededW = collectionView.bounds.size.width
        let embededH = BitableHomeLayoutConfig.multiListContainerHeight
        let fullScreenW = view.bounds.size.width
        let fullScreenH = collectionView.bounds.size.height + BitableHomeTabViewController.bottomTabBarHeight
        let config = BitableMultiListUIConfig(widthForEmbededStyle: embededW, heightForEmbededStyle: embededH, widthForFullScreenStyle: fullScreenW, heightForFullScreenStyle: fullScreenH, heightForSectionHeader: BitableHomeLayoutConfig.multiListSectionHeaderHeight)
        controller.update(config: config)
        controller.removeFromParent()
        addChild(controller)
        controller.didMove(toParent: self)
        cell.contentView.insertSubview(controller.view, at: 0)
        controller.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        controller.delegate = self
        multiListContainerCell = cell
        controller.update(style: .embeded)
        controller.multiListCollectionView.isScrollEnabled = false
    }
}

//MARK: collecitonView 拖动交互
extension BitableHomePageViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let cell = collectionView.cellForItem(at: indexPath) as? BitableHomePageChartCell {
            let touchPoint = collectionView.panGestureRecognizer.location(in: cell)
            
            // 检查是否在重新排序按钮区域内
            if cell.reorderButton.frame.contains(touchPoint) {
                let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                dragItem.localObject = chartDatasource[indexPath.row]

                isDraging = true
                DocsLogger.btInfo("[BitableHomePageViewController] itemsForBeginning \(indexPath)")
                let chart = chartDatasource[indexPath.row]
                var params :[String: Any] = [:]
                params["click"] = "drag_component"
                params["chart_id"] = chart.token ?? ""
                params["file_id"] = chart.baseToken ?? ""
                DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartSettingClick, parameters: params, context: context)
                return [dragItem]
            }
        }
        return []
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        isDraging = false
        collectionView.endInteractiveMovement()
        DocsLogger.btInfo("[BitableHomePageViewController] dragSessionDidEnd")
    }
}

extension BitableHomePageViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        DocsLogger.btInfo("[BitableHomePageViewController] dropSessionDidUpdate \(collectionView.hasActiveDrag)")
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .cancel)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        isDraging = false
        DocsLogger.btInfo("[BitableHomePageViewController] performDropWith begin")
        guard chartEditingMode else { return }
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        guard destinationIndexPath.section == 1 else { return }

        if coordinator.proposal.operation == .move {
            let items = coordinator.items
            if let item = items.first, let sourceIndexPath = item.sourceIndexPath {
                collectionView.performBatchUpdates({
                    let movedItem = chartDatasource[sourceIndexPath.item]
                    chartDatasource.remove(at: sourceIndexPath.item)
                    chartDatasource.insert(movedItem, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }) { _ in
                    // 处理拖拽编辑操后同步服务端数据
                    self.updateChartData()
                }

                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                DocsLogger.btInfo("[BitableHomePageViewController] performDropWith end")
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        DocsLogger.btInfo("[BitableHomePageViewController] dropSessionDidEnd")
        isDraging = false
    }
}

//MARK: 搜索
extension BitableHomePageViewController: BitableSearchFactorySelectProtocol {
    private func closeHomePageViewController() {
        if chartEditingMode {
            toggleEditMode()
            return
        }
        self.navigationController?.popViewController(animated: true)
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .user_back)
    }
    
    private func jumpToSearchController() {
        if chartEditingMode {
            toggleEditMode()
        }
        
        guard let factory = try? context.userResolver.resolve(assert: BitableSearchFactoryProtocol.self) else {
            DocsLogger.error("Error: can not get WorkspaceSearchFactory")
            return
        }
        factory.jumpToSearchController(fromVC: self)
        DocsTracker.reportBitableHomePageClick(context: context, click: .search)
    }
    
    private func jumpToBitableOnlySearchController() {
        guard let factory = try? context.userResolver.resolve(assert: BitableSearchFactoryProtocol.self) else {
            DocsLogger.error("Error: can not get WorkspaceSearchFactory")
            return
        }
        
        factory.jumpToPickerBaseSearchController(selectDelegate: self, fromVC: self)
    }
    
    func pushSearchResultVCWithSelectItem(_ selectItem: PickerItem, pickerVC: UIViewController) {        
        var title: String?
        var token: String?
        var iconInfo: String?
        var docUrl: String?
        switch selectItem.meta {
        case .doc(let docMeta):
            title = docMeta.title
            token = docMeta.meta?.id
            iconInfo = docMeta.meta?.iconInfo
            docUrl = docMeta.meta?.url
        case .wiki(let wikiMeta):
            title = wikiMeta.title
            token = wikiMeta.meta?.id
            iconInfo = wikiMeta.meta?.iconInfo
            docUrl = wikiMeta.meta?.url
            if let unwapperUrl = docUrl,
               unwapperUrl.isEmpty {
                docUrl = wikiMeta.meta?.docURL
            }
        default:
            DocsLogger.btError("pushSearchResultVCWithSelectItem select, type not support: \(selectItem.meta.type)")
            return
        }
        
        guard let title = title,
              let token = token,
              let iconInfo = iconInfo,
              let docUrl = docUrl else {
            DocsLogger.btError("pushSearchResultVCWithSelectItem select is not a doc type")
            return
        }
        
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartAddClick,
                                               parameters: ["click:": "file_detail", "file_id": token],
                                               context: context)
        
        let insertVC = BitableChartInsertViewController(initData: BitableChartInsertInitData(title: title,
                                                                                             token: token,
                                                                                             dashboardUrl: docUrl,
                                                                                             iconInfo: iconInfo,
                                                                                             existedCharts: self.chartDatasource),
                                                        context: context,
                                                        userResolver:context.userResolver)
        insertVC.delegate = self
        pickerVC.navigationController?.pushViewController(insertVC, animated: true)
        //上报埋点
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartAddView, parameters: ["click:": "file_detail", "file_id": token], context: context)
    }
}

//MARK: 仪表盘回调
extension BitableHomePageViewController: BitableChartInsertViewControllerDelegate {
    func addCharts(_ charts: [Chart]) {
        guard !charts.isEmpty else {
            DocsLogger.info("charts is empty")
            return
        }
        chartState = .dataSuccess
        let startIndex = chartDatasource.count
        chartDatasource.append(contentsOf: charts)
        let colorConfig: [ChartGradientSTyle] = [.green, .blue]
        for (idx, chart) in chartDatasource.enumerated() {
            chart.gradientStyle = colorConfig[idx % 2]
        }
        // insertIndexPaths
        let destinationIndexPaths = charts.enumerated().map { (index, _) in
            return IndexPath(row: index + startIndex, section: 1)
        }
        
        collectionView.performBatchUpdates({
            if startIndex == 0 {
                collectionView.deleteItems(at: [IndexPath(row: 0, section: 1)])
                collectionView.insertItems(at: destinationIndexPaths)
            } else {
                collectionView.insertItems(at: destinationIndexPaths)
            }
        }) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.collectionView.scrollToItem(at: IndexPath(row: startIndex, section: 1), at: .centeredVertically, animated: true)
            // 处理拖拽编辑操后同步服务端数据
            self.updateChartData()
        }
    }
}

extension BitableHomePageViewController: BitableHomePageChartCellDelegate {
    func toggleFullScreen(_ cell: BitableHomePageChartCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard indexPath.row < chartDatasource.count else { return }
        let chart = chartDatasource[indexPath.row]
        let copyChart = Chart(JSON(chart.toMap()))
        copyChart.updateScene(scene: .fullScreen)
        let chartDetailVC = BitableChartDetailViewController(chart: copyChart, 
                                                             context: context,
                                                             chartLynxDataProvider: chartLynxDataProvider,
                                                             safeAreaInsetsFrom: self.view.safeAreaInsets,
                                                             userResolver: context.userResolver)
        self.navigationController?.pushViewController(chartDetailVC, animated: true)
    }
    
    func deleteChart(_ cell: BitableHomePageChartCell) {
        if isDraging {
            return
        }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        //上报埋点
        if let chart = cell.chart {
            let params: [String:  AnyHashable] = ["click": "delete_component",
                                                  "chart_id": chart.token ?? "",
                                                  "file_id": chart.baseToken ?? "",
                                                  "block_token": chart.dashboardToken ?? ""]
            DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartSettingClick,
                                                   parameters: params,
                                                   context: context)
        }
        collectionView.performBatchUpdates({
            chartDatasource.remove(at: indexPath.row)
            collectionView.deleteItems(at: [indexPath])
            if chartDatasource.count == 0 {
                self.chartState = .dataEmpty
                collectionView.insertItems(at: [IndexPath(row: 0, section: 1)])
            }
        }) { _ in
            // 处理删除编辑操后同步服务端数据
            self.updateChartData()
        }
    }
    
    func reportChartStatus(_ isSuccess: Bool, detail: String? = "") {
        if isSuccess {
            if hasReportedSuccess == false {
                hasReportedSuccess = true
                BTOpenHomeReportMonitor.reportTTV(context: context, type: .dashboard)
            }
        } else {
            if hasReportFail == false {
                BTOpenHomeReportMonitor.reportFail(context: context,
                                                  type: .load_dashboard, detail: detail ?? "")
                hasReportFail = true
            }
        }
    }
}

extension BitableHomePageViewController: BitableHomePageChartErrorCellDelegate {
    func triggerRetry(_ cell: BitableHomePageChartErrorCell) {
        chartState = .loading
        collectionView.reloadData()
        requestChartData()
    }
}

extension BitableHomePageViewController: BitableHomePageChartEmptyCellDelegate {
    func addChart(_ cell: BitableHomePageChartEmptyCell) {
        jumpToBitableOnlySearchController()
    }
}

extension BitableHomePageViewController {
    private func addApplicationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }


    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        if view.superview == nil {
            return
        }
        if hasDisappear {
            return
        }
        DocsTracker.reportBitableHomePageView(context: context, tab: .homepage)
    }
}

//MARK: 多列列表VC回调
extension BitableHomePageViewController: BitableMultiListControllerDelegate {
    func multiListController(vc: UIViewController, startRefreshSection sectionType: SpaceInterface.BitableMultiListSectionType) {}

    func multiListController(
        vc: UIViewController,
        endRefreshSection sectionType: SpaceInterface.BitableMultiListSectionType,
        loadResult: SpaceInterface.BitableMultiListSectionLoadResult
    ) {
        if sectionType == .recent {
            switch loadResult {
            case .success:
                BTOpenHomeReportMonitor.reportTTV(context: context, type: .file)
            case .fail(reason: let reason):
                BTOpenHomeReportMonitor.reportFail(context: context, type: .load_file_list, detail: reason)
            @unknown default:
                break
            }
        }
    }

    func createBitableFileIfNeeded(isEmpty: Bool) {
        self.delegate?.createBitableFileIfNeeded(isEmpty: isEmpty)
    }
    
    func didRightSlidingTriggerEmbedStyle() {
        showMultiListViewInEmbededStyle()
    }
}
