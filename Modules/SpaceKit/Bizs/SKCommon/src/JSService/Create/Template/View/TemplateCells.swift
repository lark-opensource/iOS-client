//
//  TemplateCells.swift
//  SKCommon
//
//  Created by bytedance on 2021/4/14.
//
import SKUIKit
import UniverseDesignEmpty
import SKResource

class TemplateSuggestCell: TemplateBaseCell {
    var defaultCellSize = CGSize(width: 128, height: 120)
    override var whiteBgViewHeight: CGFloat { TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth, defaultSize: defaultCellSize).height }
    override var whiteBgViewWidth: CGFloat { TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth, defaultSize: defaultCellSize).width }
    override var bottomContainerViewHeight: CGFloat { TemplateCellLayoutInfo.inCenterBottomContainerHeight }

    override init(frame: CGRect) {
        super.init(frame: frame)
        cacheTag = "TemplateSuggestCell"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TemplateCenterCell: TemplateBaseCell {
    override var whiteBgViewHeight: CGFloat { TemplateCellLayoutInfo.inCenter(with: TemplateCellLayoutInfo.baseScreenWidth).height }
    override var whiteBgViewWidth: CGFloat { TemplateCellLayoutInfo.inCenter(with: TemplateCellLayoutInfo.baseScreenWidth).width }
    override var bottomContainerViewHeight: CGFloat { TemplateCellLayoutInfo.inCenterBottomContainerHeight }
    override var loadingLinePaddingV: CGFloat { return 8 }
    override var loadingViewTop: CGFloat { return 18 }
    override var bottomViewConfig: BottomViewConfig {
        var config: BottomViewConfig = .default
        config.typeIconSize = CGSize(width: 16, height: 16)
        config.titleFontSize = 14
        config.subTitleTopPadding = 6
        return config
    }
    
    override var shadowConfig: ShadowConfig {
        ShadowConfig(xOffset: 0, yOffset: 4, opacity: 1, shadowRadius: 12)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        cacheTag = "TemplateCenterCell"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TemplateEmptyDataCell: UICollectionViewCell {
    static let cellID = "TemplateEmptyDataCell"

    private var udEmptyView = UDEmpty(config: UDEmptyConfig(type: .noCloudFile))

    enum EmptyType {
        case `default`
        case share
    }

    private lazy var emptyView: UIView = {
        let view = UIView()
        let config = self.defaultEmptyConfig(with: BundleI18n.SKResource.Doc_List_EmptyTemplateCategory)
        let blankView = UDEmpty(config: config)
        blankView.backgroundColor = .clear
        view.addSubview(blankView)
        blankView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(152)
        }
        self.udEmptyView = blankView
        return view
    }()
    
    func defaultEmptyConfig(with descriptionText: String) -> UDEmptyConfig {
        let desc = UDEmptyConfig.Description(
            descriptionText: descriptionText,
            font: .docs.pfsc(14)
        )
        return UDEmptyConfig(
            title: nil,
            description: desc,
            spaceBelowImage: 12,
            spaceBelowTitle: 0,
            spaceBelowDescription: 0,
            spaceBetweenButtons: 0,
            type: .noCloudFile
        )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func update(emptyType: EmptyType) {
        switch emptyType {
        case .default:
            self.udEmptyView.update(config: defaultEmptyConfig(with: BundleI18n.SKResource.Doc_List_EmptyTemplateCategory))
        case .share:
            self.udEmptyView.update(config: defaultEmptyConfig(with: BundleI18n.SKResource.LarkCCM_Mobile_EmptyState_TemplatesSharedByOthersWillBeShown_Description))
        }
        
    }
}
