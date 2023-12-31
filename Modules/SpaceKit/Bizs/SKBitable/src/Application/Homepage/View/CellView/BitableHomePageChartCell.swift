//
//  BitableHomePageChartCell.swift
//
//  Created by ByteDance on 2023/10/29.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import Lynx
import LarkLynxKit
import UniverseDesignCheckBox
import SKResource

@objc protocol BitableHomePageChartCellDelegate: AnyObject {
    @objc optional func toggleFullScreen(_ cell: BitableHomePageChartCell)
    @objc optional func deleteChart(_ cell: BitableHomePageChartCell)
    @objc optional func selectCheckboxTrigger(_ isSelected: Bool, cell: BitableHomePageChartCell)
    @objc optional func reportChartStatus(_ isSuccess: Bool, detail: String?)
}

struct BitableHomeChartCellLayoutConfig {
    static let titleLabelFont: UIFont = UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14.0)
    static let maskCorner: CGFloat = 20.0
    static let buttonCorner8: CGFloat = 8.0
    static let topBgViewHeight: CGFloat = 46.0
    static let editbuttonSize: CGSize = CGSizeMake(44.0, 28.0)
    static let chartCellBackgroundColor: UIColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
    static func generateGradientColors(style: ChartGradientSTyle) -> [CGColor] {
        switch style {
        case .blue:
            return [
                (UDColor.rgb("#E4EFFF") & UDColor.rgb("#253855")).cgColor,
                BitableHomeChartCellLayoutConfig.chartCellBackgroundColor.cgColor,
                BitableHomeChartCellLayoutConfig.chartCellBackgroundColor.cgColor
            ]
        case .green:
            return [
                (UDColor.rgb("#E1F9E0") & UDColor.rgb("#3C4938")).cgColor,
                BitableHomeChartCellLayoutConfig.chartCellBackgroundColor.cgColor,
                BitableHomeChartCellLayoutConfig.chartCellBackgroundColor.cgColor
            ]
        }
    }
}

enum ChartGradientSTyle {
    case green
    case blue
}

enum ChartReuseType: String {
    case reuseForStatics = "statistic"
    case reuseForNormal = "normal"
}

extension ChartType {
    func toReuseType() -> ChartReuseType {
        switch self {
            case .statistics: return ChartReuseType.reuseForStatics
            default: return ChartReuseType.reuseForNormal
        }
    }
}

class BitableHomePageChartCell: UICollectionViewCell {
    private static let kCellButtonTag = Int.max
    
    weak var delegate: BitableHomePageChartCellDelegate?
    
    var chart: Chart?
    
    private lazy var bgView: UIView = {
        let bgView = UIView(frame: .zero)
        bgView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        return bgView
    }()
    
    private lazy var chartTitle: UILabel = {
        let chartTitle = UILabel(frame: .zero)
        chartTitle.font = BitableHomeChartCellLayoutConfig.titleLabelFont
        chartTitle.textColor = UDColor.textTitle
        chartTitle.sizeToFit()
        return chartTitle
    }()
    
    private lazy var titleLayer: CAGradientLayer = {
        let titleLayer = CAGradientLayer()
        titleLayer.locations = [0, 0.7, 1.0]
        titleLayer.startPoint = CGPoint(x: 0, y: 0)
        titleLayer.endPoint = CGPoint(x: 0.5, y: 0.7)
        return titleLayer
    }()
    
    let reorderButton: UIButton = {
        let reorderButton = UIButton(frame: .zero)
        reorderButton.setImage(UDIcon.getIconByKey(.dragOutlined, iconColor: UDColor.iconN3), for: .normal)
        reorderButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        reorderButton.isHidden = true
        return reorderButton
    }()
    
    lazy var checkboxButton: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        checkbox.isHidden = true
        checkbox.respondsToUserInteractionWhenDisabled = true
        return checkbox
    }()
    
    let deleteButton: UIButton = {
        let deleteButton = UIButton(frame: .zero)
        deleteButton.setImage(UDIcon.getIconByKey(.deleteColorful, iconColor: nil), for: .normal)
        deleteButton.isHidden = true
        deleteButton.isExclusiveTouch = true
        return deleteButton
    }()
    
    let chartStatusView: BitableChartStatusView = {
        let chartStatusView = BitableChartStatusView()
        chartStatusView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        return chartStatusView
    }()
    
    private var lynxContianer: BTLynxContainer?
    
    let dashborderLayer: CAShapeLayer = {
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UDColor.lineDividerDefault.cgColor
        borderLayer.lineDashPattern = [2]
        borderLayer.fillColor = nil
        borderLayer.isHidden = true
        return borderLayer
    }()
    
    private var chartLynxView: LynxView?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 20
        layer.masksToBounds = true
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        contentView.addSubview(bgView)
        
        // 渐变阴影
        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: BitableHomeChartCellLayoutConfig.topBgViewHeight))
        gradientView.backgroundColor = .clear
        titleLayer.frame = CGRect(x: 0, y: 0, width: gradientView.bounds.width, height: gradientView.bounds.height)
        gradientView.layer.addSublayer(titleLayer)

        self.layer.addSublayer(dashborderLayer)
        bgView.addSubview(gradientView)
        bgView.addSubview(chartTitle)
        bgView.addSubview(deleteButton)
        bgView.addSubview(reorderButton)
        bgView.addSubview(checkboxButton)
        
        deleteButton.addTarget(self, action: #selector(deleteChartClicked), for: .touchUpInside)
        
        bgView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.size.height.equalTo(BitableHomeChartCellLayoutConfig.topBgViewHeight)
        }
        
        chartTitle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(bgView).multipliedBy(0.8)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        
        reorderButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-13)
            make.top.equalToSuperview().offset(13)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        checkboxButton.snp.makeConstraints { make in
            make.centerX.equalTo(reorderButton.snp.centerX)
            make.centerY.equalTo(reorderButton.snp.centerY)
        }
        
        checkboxButton.tapCallBack = { [weak self] in
            $0.isSelected = !$0.isSelected
            if let self = self {
                self.delegate?.selectCheckboxTrigger?($0.isSelected,
                                                      cell: self)
            }
        }

        contentView.addSubview(chartStatusView)
        chartStatusView.snp.makeConstraints { make in
            make.top.equalTo(bgView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        chartStatusView.chartCell = self
        self.chartStatusView.refreshButton.addTarget(self,
                                                     action: #selector(refreshButtonTapped),
                                                     for: .touchUpInside)
    }
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                let blueColors = self.traitCollection.userInterfaceStyle != .dark ?
                [ UDColor.rgb("#E4EFFF").cgColor, UDColor.rgb("#FCFCFD").cgColor, UDColor.rgb("#FCFCFD").cgColor] :
                [ UDColor.rgb("#253855").cgColor, UDColor.rgb("#202020").cgColor, UDColor.rgb("#202020").cgColor ]
                
                let greenColors = self.traitCollection.userInterfaceStyle != .dark ?
                [ UDColor.rgb("#E1F9E0").cgColor, UDColor.rgb("#FCFCFD").cgColor, UDColor.rgb("#FCFCFD").cgColor] :
                [ UDColor.rgb("#3C4938").cgColor, UDColor.rgb("#202020").cgColor, UDColor.rgb("#202020").cgColor ]
                
                self.titleLayer.colors = self.chart?.gradientStyle == .blue ? blueColors : greenColors
                self.lynxContianer?.envUpdate()
            }
        }
    }
    
    @objc func refreshButtonTapped() {
        if let chart = chart {
            let (lynxContianer, _) = self.getLynxContainerAndViewWith(chart: chart)
            let lynxViewHeightOffset = BitableHomeChartCellLayoutConfig.topBgViewHeight
            let lynxViewSize = CGSizeMake(self.contentView.frame.size.width,
                                          self.contentView.frame.size.height - lynxViewHeightOffset)
            _ = lynxContianer.asyncLoadWithChart(chart, size: lynxViewSize)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        chartTitle.text = ""
        lynxContianer?.cancelAsyncLoad()
        chartStatusView.updateViewWithStatus(.loading)
        //lynxView 每次默认隐藏，渲染结束后会显示
        if let lynxView = self.chartLynxView {
            lynxView.isHidden = true
            lynxView.resetAnimation()
        }
    }
    
    static func cellWithReuseIdentifierAnd(type: ChartReuseType?) -> String {
        return "BitableHomePageChartCellIdentifier_\(type?.rawValue ?? ChartReuseType.reuseForNormal.rawValue)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.dashborderLayer.frame = CGRectMake(0, 0, self.bgView.frame.size.width, self.bgView.frame.size.height)
        self.dashborderLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 16, height: 16)).cgPath
    }
    
    func getLynxContainerAndViewWith(chart: Chart) -> (BTLynxContainer, LynxView) {
        //确保初始化一次，不能用 lazy，需要感知 chart 和 frame.width
        let lynxContianer = self.lynxContianer ?? createLynxContainerByChart(chart)
        if self.lynxContianer == nil {
            self.lynxContianer = lynxContianer
        }
        let chartLynxView = self.chartLynxView ?? lynxContianer.createView()
        if self.chartLynxView == nil {
            self.chartLynxView = chartLynxView
            chartLynxView.bitableChartStatusView = self.chartStatusView
            contentView.insertSubview(chartLynxView, belowSubview: self.chartStatusView)
            chartLynxView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
            chartLynxView.snp.makeConstraints { make in
                make.top.equalTo(bgView.snp.bottom)
                make.left.equalTo(bgView.snp.left)
                make.right.equalTo(bgView.snp.right)
                make.bottom.equalToSuperview()
            }
        }
        return (lynxContianer, chartLynxView)
    }
    
    private func createLynxContainerByChart(_ chart: Chart) -> BTLynxContainer {
        let height = chart.type == .statistics ? BitableHomeLayoutConfig.chartCardHeightStatistic : BitableHomeLayoutConfig.chartCardHeightNormal
        let contextData = BTLynxContainer.ContextData(bizContext: [:])
        let config = BTLynxContainer.Config(perferWidth: self.frame.width,
                                            perferHeight: height,
                                            maxHeight: height)
        let containerData = BTLynxContainer.ContainerData(contextData: contextData,
                                                          config:config)
        return BTLynxContainer.create(containerData, lifeCycleClient: nil)
    }
    
    func renderCell(_ model: Chart, dataProvider: BitableSliceDataProvider?, indexPath: IndexPath, 
                    isInsertMode: Bool = false, isSelect: Bool = false, chartStatus: BitableChartStatus = .loading,editMode:Bool = false) {
        chart = model
        
        let (lynxContianer, _) = self.getLynxContainerAndViewWith(chart: model)
        chartStatusView.updateChartToken(model.token)
        chartTitle.text = model.name
        titleLayer.colors = BitableHomeChartCellLayoutConfig.generateGradientColors(style: model.gradientStyle)
        reLayoutUI(editMode)
        
        lynxContianer.dataProvider = dataProvider
        let lynxViewHeightOffset = BitableHomeChartCellLayoutConfig.topBgViewHeight
        let lynxViewSize = CGSizeMake(self.contentView.frame.size.width,
                                      self.contentView.frame.size.height - lynxViewHeightOffset)
        _ = lynxContianer.asyncLoadWithChart(model, size: lynxViewSize)
        if isInsertMode {
            deleteButton.isHidden = true
            reorderButton.isHidden = true
            titleLayer.isHidden = true
            chartStatusView.updateViewWithStatus(chartStatus)
            checkboxButton.isHidden = false
            checkboxButton.isSelected = isSelect
            if chartStatus == .empty {
                //model 为空的情况下，隐藏所有多余视图，仅展示状态view
                bgView.visiblity(gone: true)
                self.dashborderLayer.isHidden = false
                self.layer.masksToBounds = false
                contentView.backgroundColor = UDColor.bgFloatBase
            } else {
                bgView.visiblity(gone: false)
                self.dashborderLayer.isHidden = true
                self.layer.masksToBounds = true
                contentView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
            }
            chartStatusView.backgroundColor = contentView.backgroundColor
        }
    }
    
    func toggleEditMode(_ editMode: Bool) {
        reLayoutUI(editMode)
        
        let scene: ChartScene = editMode ? .homeEdit : .home
        if self.chartStatusView.isHidden {
            lynxContianer?.updateRenderWithScene(scene: scene.rawValue)
        }
    }
    
    func reLayoutUI(_ editMode: Bool)  {
        reorderButton.isHidden = !editMode
        
        deleteButton.isHidden = !editMode
        
        chartTitle.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(editMode ? 44 : 16)
        }
    }
    
    @objc func deleteChartClicked(_ sender: UIButton) {
        delegate?.deleteChart?(self)
    }
}

private extension UIView {
    func visiblity(gone: Bool) -> Void {
        self.isHidden = gone
        let height = gone ? 0 : BitableHomeChartCellLayoutConfig.topBgViewHeight
        self.snp.updateConstraints { make in
            make.size.height.equalTo(height)
        }
    }
}

enum BitableChartStatus {
    case loading //加载中
    case empty  //该仪表盘未添加图表
    case fail   //仪表盘加载失败
    case success //记载完成，需要隐藏所有视图
}

final class BitableChartStatusView: UIView {
    fileprivate(set) weak var chartCell: BitableHomePageChartCell?
    private(set) var chartToken: String?
    private lazy var statusImageView: UIImageView = {
        let statusView = UIImageView(frame: .zero)
        statusView.contentMode = .scaleAspectFit
        statusView.image = BundleResources.SKResource.Bitable.base_homepage_dashboard_chart_loading
        return statusView
    }()
    
    private lazy var statusTitle: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = BundleI18n.SKResource.Bitable_Homepage_Loading_Desc
        titleLabel.textColor = UDColor.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.sizeToFit()
        return titleLabel
    }()
    
    let refreshButton: UIButton = {
        let refreshButton = UIButton(frame: .zero)
        refreshButton.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: UDColor.iconN1,size: CGSize(width: 16, height: 16)), for: .normal)
        refreshButton.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: UDColor.iconN1,size: CGSize(width: 16, height: 16)), for: .highlighted)
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        refreshButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_ReloadChart_Button,
                               for: .normal)
        refreshButton.isHidden = true
        refreshButton.setTitleColor(UDColor.textTitle, for: .normal)
        refreshButton.backgroundColor = UDColor.bgFloat
        refreshButton.contentMode = .scaleAspectFit
        refreshButton.layer.cornerRadius = 8
        refreshButton.layer.borderWidth = 1
        refreshButton.layer.borderColor = UDColor.lineBorderComponent.cgColor
        return refreshButton
    }()

    init() {
        super.init(frame: .zero)
        setupSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubview() {
        addSubview(statusImageView)
        addSubview(statusTitle)
        addSubview(refreshButton)
        statusImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        statusTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.statusImageView.snp.bottom).offset(12)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusTitle.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 92, height: 28))
        }
    }
    
    func updateViewWithStatus(_ status: BitableChartStatus, detail: String? = nil)  {
        switch status {
            case .loading :
                statusImageView.snp.updateConstraints { make in
                    make.centerY.equalToSuperview().offset(-10)
                }
                self.isHidden = false
                self.refreshButton.isHidden = true
                self.statusTitle.text = BundleI18n.SKResource.Bitable_Homepage_Loading_Desc
                self.statusImageView.image = BundleResources.SKResource.Bitable.base_homepage_dashboard_chart_loading
            case .empty :
                statusImageView.snp.updateConstraints { make in
                    make.centerY.equalToSuperview().offset(0)
                }
                self.isHidden = false
                self.refreshButton.isHidden = true
                self.statusTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_NoChartsInDashboard_Desc
                self.statusImageView.image = BundleResources.SKResource.Bitable.homepage_dashboard_no_data
            case .fail :
                statusImageView.snp.updateConstraints { make in
                    make.centerY.equalToSuperview().offset(-10 - 14 - 10)
                }
                self.isHidden = false
                self.refreshButton.isHidden = false
                self.statusTitle.text = BundleI18n.SKResource.Bitable_HomeDashboard_DashboardLoadFailed_Desc
                self.statusImageView.image = BundleResources.SKResource.Bitable.base_homepage_dashboard_error
                self.chartCell?.delegate?.reportChartStatus?(false, detail: detail)
            case .success :
                self.chartCell?.delegate?.reportChartStatus?(true, detail:nil)
                self.isHidden = true
        }
    }
    
    func updateChartToken(_ chartToken: String?) {
        self.chartToken = chartToken
    }
}
