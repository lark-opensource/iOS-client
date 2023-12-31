//
//  SKCatalogueBannerContainer.swift
//  SKUIKit
//
//  Created by yinyuan on 2022/9/22.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import SKFoundation
import LarkContainer
import UniverseDesignBadge

public protocol SKCatalogueBannerContainerDelegate: AnyObject {
    func preferedWidth(_ banner: SKCatalogueBannerContainer) -> CGFloat
    func shouldUpdateHeight(_ banner: SKCatalogueBannerContainer, newHeight: CGFloat)
}

/// 独立 Bitable 和 sheet@bitable 场景下的目录栏容器
public final class SKCatalogueBannerContainer: UIView {
    public weak var delegate: SKCatalogueBannerContainerDelegate?
    public var preferedHeight: CGFloat = 0
    
    private let bannerHeight: CGFloat = 44
    
    private lazy var catalogueView: SKCatalogueBannerView = {
        return SKCatalogueBannerView()
    }()
    
    private var customCatalogueView: UIView?
    private var currentCatalogueBannerData: SKCatalogueBannerData?
    
    private lazy var bottomSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bottomSeperatorView)
        bottomSeperatorView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取建议的 Onboarding 目标区域
    public func getOnboardingTargetRect(targetView: UIView) -> CGRect? {
        return nil  // 新逻辑不走后面的代码了
    }
    
    /// 支持单独设置隐藏（用于 Dashboard 全屏场景）
    public func setCatalogueBanner(visible: Bool) {
        DocsLogger.info("setCatalogueBanner.visible:\(visible)")
        customCatalogueView?.isHidden = !visible
    }
    
    /// 更新数据
    public func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?) {
        let forceUpdateHeight = currentCatalogueBannerData?.preferedHeight != catalogueBannerData?.preferedHeight
        currentCatalogueBannerData = catalogueBannerData
        customCatalogueView = catalogueBannerData?.customView
        let visible = !catalogueView.isHidden && catalogueBannerData != nil
        if visible, let catalogueView = customCatalogueView {
            DocsLogger.info("showCatalogueBanner")
            if catalogueView.superview == nil {
                addSubview(catalogueView)
                catalogueView.snp.remakeConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalTo(bottomSeperatorView.snp.top)
                }
            }
            if preferedHeight == 0 || forceUpdateHeight {
                preferedHeight = catalogueBannerData?.preferedHeight ?? bannerHeight
                delegate?.shouldUpdateHeight(self, newHeight: preferedHeight)
            }
        } else {
            DocsLogger.info("hideCatalogueBanner")
            if preferedHeight != 0 {
                preferedHeight = 0
                delegate?.shouldUpdateHeight(self, newHeight: preferedHeight)
            }
        }
        bottomSeperatorView.isHidden = catalogueBannerData?.showBottomSeperator != true
    }
}

public struct SKCatalogueBannerData {
    /// 一级目录文本
    public var firstLevelLabelText: String?
    /// 二级目录图标
    public var secondLevelIcon: UIImage?
    /// 二级目录图标 url 插件视图图片为用户自定义
    public var secondLevelIconUrl : String?
    /// 二级目录文本
    public var secondLevelLabelText: String?
    /// 底部是否显示分割线
    public var showBottomSeperator: Bool?
    /// 是否显示红点
    public var needShowBadge: Bool?
    
    public var customView: UIView?
    
    public var preferedHeight: CGFloat?
    
    public init() {
    }
}

public typealias SKCatalogueBannerViewCallback = (_ data: SKCatalogueBannerData) -> Void

/// 单独设计允许嵌入到 docs@bitabel 顶部栏中
public final class SKCatalogueBannerView: UIControl {
    
    fileprivate var callback: SKCatalogueBannerViewCallback?
    fileprivate var catalogueBannerData: SKCatalogueBannerData?
    
    lazy var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        return view
    }()
    
    lazy var firstLevelLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    lazy var divider = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
        it.image = BundleResources.SKResource.Bitable.catalogue_divider.withRenderingMode(.alwaysTemplate)
        it.tintColor = UDColor.lineDividerDefault.withAlphaComponent(1)
    }
    
    private lazy var viewIcon = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
        it.tintColor = UDColor.iconN1
        it.layer.cornerRadius = 2
        it.layer.masksToBounds = true
    }
    
    lazy var secondLevelLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    lazy var viewExpandDown = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
        it.image = UDIcon.expandDownFilled.withRenderingMode(.alwaysTemplate)
        it.tintColor = UDColor.iconN1
    }
    
    public var leftPaddingWidth: CGFloat = 16
    public var customFont: UIFont? {
        didSet {
            firstLevelLabel.font = customFont
            secondLevelLabel.font = customFont
        }
    }
    
    lazy var leftPaddingView = UIView()
    
    lazy var rightPaddingView = UIView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(leftPaddingView)
        leftPaddingView.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.height.equalTo(0)
        }
        
        contentStackView.addArrangedSubview(firstLevelLabel)
        
        contentStackView.addArrangedSubview(divider)
        divider.snp.makeConstraints { make in
            make.width.equalTo(22)
            make.height.equalTo(22)
        }
        
        contentStackView.addArrangedSubview(viewIcon)
        viewIcon.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        
        contentStackView.addArrangedSubview(secondLevelLabel)
        
        contentStackView.addArrangedSubview(viewExpandDown)
        viewExpandDown.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        
        contentStackView.addArrangedSubview(rightPaddingView)
        rightPaddingView.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.height.equalTo(0)
        }
        
        viewExpandDown.addBadge(.dot, anchor: .topRight, anchorType: .rectangle, offset: .init(width: 8, height: 0))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        contentStackView.isUserInteractionEnabled = true
        contentStackView.addGestureRecognizer(tap)
    }
    
    @objc
    private func statusBarOrientationChange() {
        updateViews()
    }
    
    @objc
    private func onClick() {
        guard let catalogueBannerData = self.catalogueBannerData else {
            DocsLogger.warning("catalogueBannerData is nil")
            return
        }
        guard let callback = callback else {
            DocsLogger.warning("callback is nil")
            return
        }
        callback(catalogueBannerData)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateViews()
    }
    
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateViews()
    }
    
    fileprivate func updateViews() {
        let maxWidth = self.frame.width
        let rightPadding: CGFloat = maxWidth * 0.2
        contentStackView.snp.remakeConstraints { make in
            let orientation = LKDeviceOrientation.getInterfaceOrientation()
            make.left.equalToSuperview().offset(orientation == .landscapeRight ? self.safeAreaInsets.left : 0)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-rightPadding - (orientation == .landscapeLeft ? self.safeAreaInsets.right : 0))
        }
        
        let shouldShowFirstLevelLabel = firstLevelLabel.text?.isEmpty == false  // 是否应当显示第一段内容
        let shouldShowViewIcon = viewIcon.image != nil || self.catalogueBannerData?.secondLevelIconUrl != nil// 是否应当显示 view icon
        
        firstLevelLabel.isHidden = !shouldShowFirstLevelLabel
        divider.isHidden = !shouldShowFirstLevelLabel
        viewIcon.isHidden = !shouldShowViewIcon
        viewExpandDown.badge?.isHidden = self.catalogueBannerData?.needShowBadge != true
        
        contentStackView.spacing = 6
        contentStackView.setCustomSpacing(0, after: firstLevelLabel)
        contentStackView.setCustomSpacing(0, after: divider)
        contentStackView.setCustomSpacing(8, after: secondLevelLabel)
        contentStackView.setCustomSpacing(leftPaddingWidth, after: leftPaddingView)
        contentStackView.setCustomSpacing(5, after: viewExpandDown)
        
        let maxFirstLevelLabelWidth = shouldShowFirstLevelLabel ? ceil(firstLevelLabel.sizeThatFits(CGSize(width: CGFLOAT_MAX, height: CGFLOAT_MAX)).width) : 0
        let minFirstLevelLabelWidth: CGFloat = min(50, maxFirstLevelLabelWidth)  // 一级目录文本的最短宽度
        firstLevelLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        firstLevelLabel.snp.remakeConstraints { make in
            make.width.greaterThanOrEqualTo(minFirstLevelLabelWidth)
        }
        
        secondLevelLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        rightPaddingView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    public func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?) {
        
        self.callback = callback
        if catalogueBannerData?.firstLevelLabelText == self.catalogueBannerData?.firstLevelLabelText,
           catalogueBannerData?.secondLevelIcon == self.catalogueBannerData?.secondLevelIcon,
           catalogueBannerData?.secondLevelIconUrl == self.catalogueBannerData?.secondLevelIconUrl,
           catalogueBannerData?.secondLevelLabelText == self.catalogueBannerData?.secondLevelLabelText,
           catalogueBannerData?.showBottomSeperator == self.catalogueBannerData?.showBottomSeperator,
           catalogueBannerData?.needShowBadge == self.catalogueBannerData?.needShowBadge {
            self.catalogueBannerData = catalogueBannerData
            // 内容没变化，不需要更新 layout，防止前端高频重复调用
            DocsLogger.info("same data no update")
            return
        }
        DocsLogger.info("update catalog views")
        self.catalogueBannerData = catalogueBannerData
        
        firstLevelLabel.text = catalogueBannerData?.firstLevelLabelText
        secondLevelLabel.text = catalogueBannerData?.secondLevelLabelText
        if let viewIconUrl = catalogueBannerData?.secondLevelIconUrl {
            viewIcon.bt.setLarkImage(.default(key: viewIconUrl), completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    DocsLogger.info("success request  by SKCatalogueBannerView setLarkImage with url: \(viewIconUrl.encryptToShort)")
                case .failure(let error):
                    self.viewIcon.image = UDIcon.bitableunknowOutlined
                    DocsLogger.error("fail request by SKCatalogueBannerView setLarkImage with url: \(viewIconUrl.encryptToShort) code: \(error.code) localizedDescription: \(error.localizedDescription)", error: error)
                }
                
            })
            viewIcon.snp.updateConstraints { make in
                make.width.height.equalTo(16)
            }
        } else {
            viewIcon.image = catalogueBannerData?.secondLevelIcon?.withRenderingMode(.alwaysTemplate)
            viewIcon.snp.updateConstraints { make in
                make.width.height.equalTo(18)
            }
        }
        
        // 在部分场景下直接刷新 UIStackView 会有布局错乱
        layoutIfNeeded()
        
        updateViews()
    }
    
}
