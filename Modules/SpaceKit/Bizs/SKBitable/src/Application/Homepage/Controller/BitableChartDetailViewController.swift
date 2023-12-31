//
//  BitableChartDetailViewController.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/08.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkUIKit
import SKFoundation
import SKInfra
import EENavigator
import SKResource
import LarkContainer
import SKCommon

class BitableChartDetailViewController: UIViewController {
    private let userResolver: UserResolver
    
    let chart: Chart
    let context: BaseHomeContext
    let initTimeInterval: TimeInterval = Date().timeIntervalSince1970
    private(set) var chartLynxDataProvider: BitableSliceDataProvider?
    
    
    private lazy var navigationBar: UIView = {
        let navigationBar = UIView(frame: .zero)
        return navigationBar
    }()
    
    private lazy var backButton: UIButton = {
        let backButton = UIButton(frame: .zero)
        backButton.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UDColor.iconN1), for: .normal)
        return backButton
    }()
    
    private lazy var navigationTitle: UILabel = {
        let navigationTitle = UILabel(frame: .zero)
        navigationTitle.sizeToFit()
        navigationTitle.numberOfLines = 1
        return navigationTitle
    }()
    
    private var lynxContianer: BTLynxContainer?
    private var safeAreaInsetsFrom: UIEdgeInsets
    
    private lazy var loadingView: BitableChartStatusView = {
        let loadingView = BitableChartStatusView()
        loadingView.updateViewWithStatus(.loading)
        return loadingView
    }()
    
    private lazy var fromTitle: UILabel = {
        let fromTitle = UILabel(frame: .zero)
        fromTitle.font = UIFont.systemFont(ofSize: 14)
        fromTitle.textColor = UDColor.textCaption
        fromTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_From_Text
        fromTitle.sizeToFit()
        return fromTitle
    }()
    
    private lazy var fromBaseButton: UIButton = {
        let fromBaseButton = UIButton(frame: .zero)
        return fromBaseButton
    }()
    
    private lazy var baseTypeImage: UIImageView = {
        let baseTypeImage = UIImageView(frame: .zero)
        return baseTypeImage
    }()
    
    private lazy var baseNameLabel: UILabel = {
        let fromTitle = UILabel(frame: .zero)
        fromTitle.font = UIFont.systemFont(ofSize: 14)
        fromTitle.textColor = UDColor.textTitle
        return fromTitle
    }()

    private lazy var fromTemplateLabelWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.udtokenTagBgBlue
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var fromTemplateLabel: UILabel = {
        let fromTemplateLabel = UILabel(frame: .zero)
        fromTemplateLabel.font = UIFont.systemFont(ofSize: 12)
        fromTemplateLabel.textColor = UDColor.udtokenTagTextSBlue
        fromTemplateLabel.textAlignment = .center
        fromTemplateLabel.text = BundleI18n.SKResource.Bitable_HomeDashboard_Template_Tag
        fromTemplateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return fromTemplateLabel
    }()
    
    private lazy var arrowImage: UIImageView = {
        let arrowImage = UIImageView(frame: .zero)
        arrowImage.image = UDIcon.getIconByKey(.rightOutlined, iconColor: UDColor.iconN3)
        return arrowImage
    }()
    
    init(chart: Chart, context: BaseHomeContext, chartLynxDataProvider: BitableSliceDataProvider?, safeAreaInsetsFrom: UIEdgeInsets, userResolver: UserResolver) {
        self.chart = chart
        self.context = context
        self.chartLynxDataProvider = chartLynxDataProvider
        self.userResolver = userResolver
        self.safeAreaInsetsFrom = safeAreaInsetsFrom
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //上报时间，单位毫秒
        let duration  = abs(Date().timeIntervalSince1970 - initTimeInterval) * 1000
        var params :[String: Any] = [:]
        params["duration"] = Int(duration)
        params["block_token"] = chart.dashboardToken?.encryptToShort
        params["is_mobile_homepage"] = "true"
        // 上报埋点
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseDashboardDurationView, parameters: params, context: context)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .dashboard_full_screen)
    }
    
    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        
        // 导航栏
        view.addSubview(navigationBar)
        navigationBar.addSubview(backButton)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        navigationTitle.text = chart.name ?? ""
        navigationBar.addSubview(navigationTitle)
        
        fromBaseButton.addTarget(self, action: #selector(openFromBasePage), for: .touchUpInside)
        view.addSubview(fromBaseButton)
        fromBaseButton.addSubview(fromTitle)
        fromBaseButton.addSubview(baseTypeImage)
        baseTypeImage.di.setDocsImage(iconInfo: chart.baseIcon ?? "",
                                      token: chart.token ?? "",
                                      type: .bitable,
                                      shape: .SQUARE,
                                      userResolver: userResolver)
        let baseName = chart.baseName ?? BundleI18n.SKResource.Doc_Facade_UntitledBitable
        baseNameLabel.text = baseName.isEmpty ? BundleI18n.SKResource.Doc_Facade_UntitledBitable : baseName
        fromBaseButton.addSubview(baseNameLabel)
        
        fromTemplateLabelWrapper.isHidden = chart.isTemplate == false
        fromBaseButton.addSubview(fromTemplateLabelWrapper)
        fromTemplateLabelWrapper.addSubview(fromTemplateLabel)
        fromBaseButton.addSubview(arrowImage)
        
        // 导航栏约束
        navigationBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(56)
        }
        
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        navigationTitle.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(navigationBar).multipliedBy(0.7)
        }

        fromBaseButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.right.equalTo(arrowImage.snp.right)
            make.width.lessThanOrEqualTo(self.view).multipliedBy(0.8)
        }

        fromTitle.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        baseTypeImage.snp.makeConstraints { make in
            make.left.equalTo(fromTitle.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14.0, height: 14.0))
        }
        
        baseNameLabel.snp.makeConstraints { make in
            make.left.equalTo(baseTypeImage.snp.right).offset(2)
            make.centerY.equalToSuperview()
        }
        
        fromTemplateLabelWrapper.snp.makeConstraints { make in
            make.left.equalTo(baseNameLabel.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
        }

        fromTemplateLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
        
        arrowImage.snp.makeConstraints { make in
            make.left.equalTo(chart.isTemplate ? fromTemplateLabelWrapper.snp.right : baseNameLabel.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14.0, height: 14.0))
            make.right.lessThanOrEqualTo(view).offset(-20)
        }
        // 图表和跳转,lynx容器不支持调整frame,必须先算好,全屏容器,需要计算安全区,只能在`viewDidAppear`中
        setupChartLynxView()
        renderChart()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func setupChartLynxView() {
        let inset = self.safeAreaInsetsFrom
        let lynxHeight = view.frame.height - inset.bottom - inset.top - 56.0 - 56.0
        let contextData = BTLynxContainer.ContextData(bizContext: [:])
        let config = BTLynxContainer.Config(perferWidth: view.frame.width,
                                            perferHeight: lynxHeight,
                                            maxHeight: lynxHeight)
        let containerData = BTLynxContainer.ContainerData(contextData: contextData,
                                                          config:config)
        lynxContianer = BTLynxContainer.create(containerData)
        
        if let lynxView = lynxContianer?.createView() {
            lynxView.frame = CGRect(x: 0.0, y: inset.top + 56.0, width: view.frame.width, height: lynxHeight)
            loadingView.updateChartToken(chart.token)
            view.addSubview(lynxView)
            lynxView.bitableChartStatusView = loadingView
            loadingView.frame = lynxView.frame
            view.addSubview(loadingView)
        }
    }
    
    func renderChart() {
        self.lynxContianer?.dataProvider = self.chartLynxDataProvider
        _ = self.lynxContianer?.asyncLoadWithChart(chart, size: CGSize(width: view.frame.width, height: view.frame.height - 190))
        
        // 上报埋点
        var params :[String: Any] = [:]
        params["chart_id"] = chart.token ?? ""
        params["file_id"] = chart.baseToken ?? ""
        params["block_token"] = chart.dashboardToken ?? ""
        params["is_template"] = chart.isTemplate ? "true" : "false"
        DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartToggleFullScreen, parameters: params, context: context)
    }
    
    @objc func back() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func openFromBasePage() {
        if let pushUrl = chart.dashboardUrl, let url = URL(string: pushUrl) {
            var fromParams = ["ccm_open_type": "mobile_homepage_dashboard",
                              "source": "mobile_homepage_dashboard"]
            if chart.isTemplate {
                fromParams["template_source"] = "mobile_homepage_dashboard"
            }
            let urlAppended = url.docs.addOrChangeEncodeQuery(parameters: fromParams)
            Navigator.shared.docs.showDetailOrPush(urlAppended, context:["showTemporary": false], from: self)
            // 上报埋点
            let params: [String:  Any] = ["click": "base_view",
                                                  "chart_id": chart.token ?? "",
                                                  "file_id": chart.baseToken ?? "",
                                                  "block_token": chart.dashboardToken ?? "",
                                                  "template_token": chart.baseToken ?? "",
                                                  "is_template": chart.isTemplate ? "true" : "false"]
            DocsTracker.reportBitableHomePageEvent(enumEvent: DocsTracker.EventType.baseHomepageChartFullScreenCilck, parameters: params, context: context)
        }
    }
}

