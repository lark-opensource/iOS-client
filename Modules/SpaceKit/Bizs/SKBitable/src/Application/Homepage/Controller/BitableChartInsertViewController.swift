//
//  BitableChartInsertViewController.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/10.
//

import Foundation
import UniverseDesignTag
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignLoading
import SwiftyJSON
import LarkDocsIcon
import RustPB
import LarkContainer
import LarkSetting
import SKResource
import UniverseDesignToast
import SKCommon

protocol BitableChartInsertViewControllerDelegate: AnyObject {
    func addCharts(_ charts:[Chart])
}

struct BitableInsertHeaderLayoutConfig {
    static let chartHeaderHeight: CGFloat = 48.0
}

class ConfirmButton: UIButton {
    enum ButtonState {
        case normal
        case disabled
    }
    private var disabledBackgroundColor: UIColor?
    private var defaultBackgroundColor: UIColor? {
        didSet {
            backgroundColor = defaultBackgroundColor
        }
    }
    
    // change background color on isEnabled value changed
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                if let color = defaultBackgroundColor {
                    self.backgroundColor = color
                }
            }
            else {
                if let color = disabledBackgroundColor {
                    self.backgroundColor = color
                }
            }
        }
    }
    
    func setBackgroundColor(_ color: UIColor?, for state: ButtonState) {
        switch state {
        case .disabled:
            disabledBackgroundColor = color
        case .normal:
            defaultBackgroundColor = color
        }
    }
}

private final class BitableInsertNavigationBar: UIView {
    lazy var backButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.contentMode = .scaleToFill
        button.setBackgroundImage(UDIcon.getIconByKey(.leftSmallCcmOutlined, iconColor: UDColor.iconN1),
                                  for: .normal)
        return button
    }()
    lazy var titleImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.textAlignment = .center
        titleLabel.font =  UIFont(name: "PingFangSC-Regular", size: 16)
        titleLabel.textAlignment = .left
        titleLabel.textColor = UDColor.textTitle
        titleLabel.sizeToFit()
        return titleLabel
    }()
    
    lazy var confirmButton: UIButton = {
        let button = ConfirmButton(type: .custom)
        button.setBackgroundColor(UDColor.primaryFillDefault,
                                  for: .normal)
        button.setBackgroundColor(UDColor.fillDisabled,
                                  for: .disabled)
        button.titleLabel?.textColor = UDColor.primaryOnPrimaryFill
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 14)
        button.layer.cornerRadius = 10.0
        button.imageView?.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        addSubview(self.backButton)
        addSubview(self.titleImageView)
        addSubview(self.titleLabel)
        addSubview(self.confirmButton)
        
        backButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width:22, height:22))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        titleImageView.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleImageView.snp.right).offset(8)
            make.right.equalTo(confirmButton.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        confirmButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width:70, height:28))
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class BitableChartCenterStatusView: UIView {
    
    enum CenterStatus {
        case loading
        case empty
        case fail
    }
    
    private var udloadingView = UDLoading.loadingImageView()
    
    private lazy var statusTitle: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.textColor = UDColor.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.sizeToFit()
        return titleLabel
    }()
    
    private lazy var emptyView: UDEmptyView = {
        let config = UDEmptyConfig(type: .code404)
        let emptyView = UDEmptyView(config: config)
        emptyView.backgroundColor = .clear
        emptyView.useCenterConstraints = true
        return emptyView
    }()
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloatBase
        setupSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubview() {
        addSubview(udloadingView)
        addSubview(statusTitle)
        addSubview(emptyView)
        
        emptyView.isHidden = true
        udloadingView.isHidden = true
        
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }
        
        udloadingView.snp.makeConstraints { make in
            make.center.equalTo(emptyView.center)
        }
        
        statusTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.emptyView.snp.bottom).offset(16)
        }
    }
    
    func updateWithStatus(_ status: CenterStatus) {
        switch status {
        case .loading:
            self.emptyView.isHidden = true
            self.udloadingView.isHidden = false
            
            self.statusTitle.text = BundleI18n.SKResource.Bitable_Homepage_Loading_Desc
        case .empty:
            let config = UDEmptyConfig(type: .noData)
            emptyView.update(config: config)
            
            self.emptyView.isHidden = false
            self.udloadingView.isHidden = true
            self.statusTitle.text =  BundleI18n.SKResource.Bitable_HomeDashboard_NoDashboardInBase_Desc
        case .fail:
            let config = UDEmptyConfig(type: .code404)
            emptyView.update(config: config)
            
            self.emptyView.isHidden = false
            self.udloadingView.isHidden = true

            self.statusTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_FailedReopen_Desc
        }
    }
}

struct BitableChartInsertInitData {
    let title: String
    let token: String
    let dashboardUrl: String
    let iconInfo: String
    let existedCharts: [Chart]
}

public final class BitableChartInsertViewController: UIViewController {
    
    let chartLynxDataProvider: BitableSliceDataProvider = BitableSliceManager()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionHeadersPinToVisibleBounds = true
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        layout.headerReferenceSize = CGSize(width: screen_width - 16, height: BitableInsertHeaderLayoutConfig.chartHeaderHeight)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(BitableHomePageChartCell.self, forCellWithReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: .reuseForNormal))
        view.register(BitableHomePageChartCell.self, forCellWithReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: .reuseForStatics))
        view.register(BitableInsertChartHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "chartHeader")

        view.delegate = self
        view.dataSource = self

        view.isPagingEnabled = false
        view.dragInteractionEnabled = false
        view.showsVerticalScrollIndicator = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    //全局变量
    private var screen_width: CGFloat = 0
    private var screen_height: CGFloat = 0
    
    private var scrollDetectEnable = true
    
    weak var delegate: BitableChartInsertViewControllerDelegate?
    
    private lazy var topNaviBar: BitableInsertNavigationBar = {
        let topBar = BitableInsertNavigationBar(frame: .zero)
        return topBar
    }()
    
    private lazy var centerStatusView: BitableChartCenterStatusView = {
        let centerView = BitableChartCenterStatusView()
        return centerView
    }()

    private var dashboardResponse: DashboardResponse?
    private lazy var dashboards: [Dashboard] = []
    private var selectData: [[Bool]] = []
    
    private let initData: BitableChartInsertInitData
    private let userResolver: UserResolver
    private let checkMaxLimit: Int
    private let insertPageCheckLimit: Int
    private let context: BaseHomeContext
    
    init(initData: BitableChartInsertInitData, context: BaseHomeContext, userResolver: UserResolver) {
        self.context = context
        self.initData = initData
        self.userResolver = userResolver
        let bitableHomeChartConfig = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_homepage_chart")) 
        //允许添加的上限为配置上线减去已添加的图表数，不能小于 0（默认没拿到配置时最多添加 20 个图表）
        self.insertPageCheckLimit = bitableHomeChartConfig?["insert_page_check_limit"] as? Int ?? 20
        self.checkMaxLimit = max(insertPageCheckLimit - initData.existedCharts.count, 0)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UDColor.bgFloatBase
        screen_height = UIScreen.main.bounds.size.height
        screen_width = UIScreen.main.bounds.size.width
        
        self.view.addSubview(self.topNaviBar)
        self.topNaviBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.width.equalToSuperview()
            make.height.equalTo(52)
        }
        
        self.view.addSubview(self.centerStatusView)
        self.centerStatusView.snp.makeConstraints { make in
            make.center.equalTo(self.view.snp.center)
        }
        
        self.view.addSubview(collectionView)
        self.updateTopNaviBarTitles()
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.topNaviBar.snp.bottom)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.topNaviBar.titleLabel.text = self.initData.title
        self.topNaviBar.titleImageView.di.setDocsImage(iconInfo: self.initData.iconInfo,
                                                       token: self.initData.token,
                                                       type: .bitable,
                                                       userResolver: self.userResolver)
        self.updateTopNaviBarTitles()
        
        self.topNaviBar.backButton.addTarget(self,
                                             action: #selector(backButtonTapped),
                                             for: .touchUpInside)
        self.topNaviBar.confirmButton.addTarget(self,
                                                action: #selector(confirmButtonTapped),
                                                for: .touchUpInside)
        self.centerStatusView.updateWithStatus(.loading)
        
        ChartRequest.requestChartsInDashboard(SkeletonRequestParam(token: self.initData.token)) { dashboardResponse, err in
            if let dashboards = dashboardResponse?.dashboards,
               err == nil {
                //先判断 dashboards 数据是否为空，为空更新中间状态区域内容
                guard !dashboards.isEmpty else {
                    self.collectionView.isHidden = true
                    self.centerStatusView.isHidden = false
                    self.centerStatusView.updateWithStatus(.empty)
                    return
                }
                self.dashboardResponse = dashboardResponse
                self.dashboards = dashboards.map {
                    //要检查一遍是否 dashboards下面存在 charts 空数组，如果存在需要添加一个伪数据。展现未添加图表的样式
                    if $0.charts.isEmpty {
                        $0.updateCharts(charts: [ChartInDashboard(JSON([:]))])
                    }
                    return  $0
                }
                self.selectData = dashboards.map { $0.charts }.compactMap{
                    $0.compactMap { _ in false }
                }
                self.collectionView.isHidden = false
                self.centerStatusView.isHidden = true
                self.collectionView.reloadData()
            } else {
                self.collectionView.isHidden = true
                self.centerStatusView.isHidden = false
                self.centerStatusView.updateWithStatus(.fail)
            }
        }
        //上报埋点
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartAddView, parameters: nil, context: context)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func confirmButtonTapped(){
        if let delegate = self.delegate {
            self.navigationController?.dismiss(animated: true)
            var charts: [Chart] = []
            for (section, list ) in selectData.enumerated() {
                for(row, value) in list.enumerated() {
                    //筛选出是 select 是 true 的数据
                    if value {
                        let dashboard = dashboards[section]
                        let chartInDashboard = dashboard.charts[row]
                           
                        if let dashboardToken = dashboard.token,
                           let token = chartInDashboard.token,
                           let name = chartInDashboard.name,
                           let type = chartInDashboard.type,
                           let dashboardResponse = self.dashboardResponse {
                            let chartModel = Chart(JSON(["base_token": self.initData.token,
                                                         "dashboard_token": dashboardToken,
                                                         "token": token,
                                                         "base_name": self.initData.title,
                                                         "dashboard_url": self.initData.dashboardUrl,
                                                         "name": name,
                                                         "type": type,
                                                         "is_template": dashboardResponse.isTemplate,
                                                         "base_icon": self.initData.iconInfo]))
                            charts.append(chartModel)
                        }
                    }
                }
            }
            delegate.addCharts(charts)
            //上报埋点
            DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartAddClick,
                                                   parameters: ["click:": "add", "component_num": charts.count],
                                                   context: context)
        }
    }
    
    func updateTopNaviBarTitles() {
        let checkedCount = self.selectData.flatMap { $0 }.filter { $0 == true }.count
        self.topNaviBar.confirmButton.isEnabled = checkedCount > 0
        self.topNaviBar.confirmButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_AddNum_Button(num: checkedCount),
                                               for: .normal)
    }
    
    private func checkButtonIsEnableForItem(_ indexPath: IndexPath) -> Bool {
        //如果已经超出限制，且当前未选中。需要设置为 disable
        let selectSectionList = self.selectData[indexPath.section]
        let isSelect = selectSectionList[indexPath.row]
        let checkedAmount = self.selectData.flatMap{ $0 }.filter{ $0 == true }.count
        //检查一下是否已经在existedChart里，如果在了就不能是 enable
        let existed = checkButtonIsSelectedInExistedForItem(indexPath)
        return (checkedAmount < self.checkMaxLimit ||  isSelect) && !existed
    }
    
    private func checkButtonIsSelectedInExistedForItem(_ indexPath: IndexPath) -> Bool {
        //检查一下是否已经在existedChart里，如果在了就不能是 enable
        let dashboard = self.dashboards[indexPath.section]
        let chartInResponse = dashboard.charts[indexPath.row]
        return self.initData.existedCharts.filter {
            $0.token == chartInResponse.token
        }.count > 0
    }
}

extension BitableChartInsertViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = screen_width - 32
        let dashboard = self.dashboards[indexPath.section]
        let chartInDashboard = dashboard.charts[indexPath.row]
        
        if let type = chartInDashboard.type {
            switch ChartType(rawValue: type) {
            case .statistics: return CGSizeMake(itemWidth, BitableHomeLayoutConfig.chartCardHeightStatistic + BitableHomeChartCellLayoutConfig.topBgViewHeight)
            default: return CGSizeMake(itemWidth, BitableHomeLayoutConfig.chartCardHeightNormal + BitableHomeChartCellLayoutConfig.topBgViewHeight)
            }
        }
        return CGSizeMake(itemWidth, 244)
    }
}

extension BitableChartInsertViewController: UICollectionViewDelegate, UICollectionViewDataSource, BitableInsertChartHeaderDelegate, BitableHomePageChartCellDelegate, UIScrollViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var chartModel: Chart = Chart(JSON(""))
        let dashboard = self.dashboards[indexPath.section]
        let chartInDashboard = dashboard.charts[indexPath.row]
        let isChecked = self.selectData[indexPath.section][indexPath.row] || checkButtonIsSelectedInExistedForItem(indexPath)
        //数据校验，有这些数据的可以正常显示，否则 chart 图表展示空样式
        if let dashboardToken = dashboard.token,
           let token = chartInDashboard.token,
           let name = chartInDashboard.name,
           let type = chartInDashboard.type {
            chartModel = Chart(JSON(["base_token": self.initData.token,
                                     "dashboard_token": dashboardToken,
                                     "token": token,
                                     "name": name,
                                     "type": type,
                                     "scene": ChartScene.add.rawValue]))
        }
        let viewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableHomePageChartCell.cellWithReuseIdentifierAnd(type: chartModel.type?.toReuseType()),
                                                          for: indexPath)
        if let chartCell = viewCell as? BitableHomePageChartCell {
            let chartStatus: BitableChartStatus = chartModel.token == nil ? .empty : .loading
            chartCell.delegate = self
            chartCell.renderCell(chartModel,
                                 dataProvider: chartLynxDataProvider,
                                 indexPath: indexPath,
                                 isInsertMode: true,
                                 isSelect: isChecked,
                                 chartStatus: chartStatus)
            chartCell.checkboxButton.isEnabled = checkButtonIsEnableForItem(indexPath)
        }
        return viewCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "chartHeader", for: indexPath)
        if let insertHeaderView = headerView as? BitableInsertChartHeader {
            insertHeaderView.delegate = self
            insertHeaderView.sectionNumber = indexPath.section
            let dashboard = self.dashboards[indexPath.section]
            insertHeaderView.updateTitleText(title: dashboard.name)
            //TODO 更新titleImageView
            
            //判断一下queue 出来 section +1 的下一个 header是不是存在
            //如果存在，则说明是从上往下滚动（会有scrollViewDidScroll 会重置箭头）
            //不存在，则是从下往上滚动(或最后一个header)，需要重置箭头
            if collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: indexPath.section+1)) == nil {
                insertHeaderView.changeArrowDirection(isOpen: true, withAnimation:false)
            }
        }
        return headerView
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dashboards[section].charts.count
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dashboards.count
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView ,
           let visibleHeaderViews = (collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader) as? [BitableInsertChartHeader])?.sorted(by: { $0.sectionNumber < $1.sectionNumber }) ,
           self.scrollDetectEnable {
            if visibleHeaderViews.count > 1 {
                let firstHeader = visibleHeaderViews[0]
                let secondHeader = visibleHeaderViews[1]
                //当前后两个header挨着的时，下一个 header 的箭头需要改变方向
                if secondHeader.frame.origin.y - firstHeader.frame.origin.y - firstHeader.frame.size.height < 1 {
                    firstHeader.changeArrowDirection(isOpen: false)
                } else if secondHeader.frame.origin.y - firstHeader.frame.origin.y - firstHeader.frame.size.height > 1 {
                    firstHeader.changeArrowDirection(isOpen: true)
                }
            } else if let lastHeader = visibleHeaderViews.first,
                      lastHeader.sectionNumber == (self.dashboards.count-1) {
                //只有一条而且是最后一个，滚动时时就应该展开箭头
                lastHeader.changeArrowDirection(isOpen: true)
            }
        }
    }
    
    func headerArrowActionTrigger(isOpen: Bool, headerView: BitableInsertChartHeader) {
        self.scrollDetectEnable = false
        //如果已经打开了，则关闭。反之打开
        headerView.changeArrowDirection(isOpen: !isOpen)
        //同时需要根据打开关闭状态，滚动 CollectionView 到指定的cell
        let targetIndexPath =  isOpen ? IndexPath(row: 0, section: headerView.sectionNumber + 1) : IndexPath(row: 0, section: headerView.sectionNumber)
        guard targetIndexPath.section < dashboards.count,
              let layout = collectionView.collectionViewLayout.layoutAttributesForItem(at: targetIndexPath) else {
            //最后一个的关闭
            let offset = CGPoint(x: 0, y: collectionView.contentSize.height - BitableInsertHeaderLayoutConfig.chartHeaderHeight)
            UIView.animate(withDuration: 0.3) {
                self.collectionView.contentOffset = offset
            } completion: { _ in
                self.scrollDetectEnable = true
            }
            return
        }
        let keepedHeaderHeight = isOpen ? 2*BitableInsertHeaderLayoutConfig.chartHeaderHeight : BitableInsertHeaderLayoutConfig.chartHeaderHeight
        let offset = CGPoint(x: 0, y: layout.frame.minY - keepedHeaderHeight)
        UIView.animate(withDuration: 0.3) {
            self.collectionView.contentOffset = offset
        } completion: { _ in
            self.scrollDetectEnable = true
        }
    }
    
    func selectCheckboxTrigger(_ isSelected: Bool, cell: BitableHomePageChartCell) {
        //检查一下 checkbox 是否可用，不可用的时候提示toast
        //如果 checkbox 不可用，且选择状态为未选择，则表示上限了，需要弹 toast
        if  cell.checkboxButton.isEnabled == false,
            cell.checkboxButton.isSelected == true  {
            //恢复到之前的状态，然后提示 toast
            cell.checkboxButton.isSelected = !cell.checkboxButton.isSelected
            UDToast.showTips(with: BundleI18n.SKResource.Bitable_HomeDashboard_MaxAdd20Charts_Desc(insertPageCheckLimit), on: self.view)
            return
        }
        if let indexPath = self.collectionView.indexPath(for: cell) {
            var selectSectionList = self.selectData[indexPath.section]
            selectSectionList[indexPath.row] = isSelected
            self.selectData[indexPath.section] = selectSectionList
            for (section, list ) in selectData.enumerated() {
                for(row, value) in list.enumerated() {
                    //筛选出是 select 是 true 的数据
                    let indexPath = IndexPath(row: row, section: section)
                    if let chartCell = collectionView.cellForItem(at: indexPath) as? BitableHomePageChartCell {
                        chartCell.checkboxButton.isEnabled = checkButtonIsEnableForItem(indexPath)
                        chartCell.checkboxButton.isSelected = value || checkButtonIsSelectedInExistedForItem(indexPath)
                    }
                }
            }
            
            //刷新顶部添加按钮中的文字
            self.updateTopNaviBarTitles()
        }
    }
}
