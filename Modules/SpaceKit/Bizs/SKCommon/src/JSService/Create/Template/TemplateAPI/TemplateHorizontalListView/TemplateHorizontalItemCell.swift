//
//  TemplateHorizontalItemCell.swift
//  SKCommon
//
//  Created by lijuyou on 2023/6/2.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignFont
import RxSwift
import RxCocoa
import UniverseDesignEmpty
import SKResource

class TemplateHorizontalItemDefaultCell: TemplateBaseCell {
    var defaultCellSize = CGSize(width: 128, height: 120)
    override var whiteBgViewHeight: CGFloat { TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth, defaultSize: defaultCellSize).height }
    override var whiteBgViewWidth: CGFloat { TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth, defaultSize: defaultCellSize).width }
    override var bottomContainerViewHeight: CGFloat { TemplateCellLayoutInfo.inCenterBottomContainerHeight }
    override var bottomViewConfig: TemplateBaseCell.BottomViewConfig {
        var config = BottomViewConfig.default
        config.topColor = UIColor.ud.N50 & UIColor.docs.rgb("313131")
        config.bottomColor = UDColor.bgBody & UIColor.docs.rgb("373737")
        return config
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        cacheTag = "TemplateHorizontalItemDefaultCell"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TemplateHorizontalMoreItemCell: UICollectionViewCell {

    var shadowConfig: TemplateBaseCell.ShadowConfig {
        TemplateBaseCell.ShadowConfig(xOffset: 0, yOffset: 4, opacity: 1, shadowRadius: 6)
    }

    private lazy var moreImageView: UIImageView = {
        let image = EmptyBundleResources.image(named: "ccmEmptySpecializedMoreTemplates")
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_Docs_Homepage_Templates_More_Epty
        label.textColor = UDColor.textCaption
        label.font = UDFont.caption3
        label.textAlignment = .center
        return label
    }()


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgFloat & UDColor.bgFloatOverlay
        contentView.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        contentView.layer.shadowOpacity = shadowConfig.opacity
        contentView.layer.shadowOffset = CGSize(width: shadowConfig.xOffset, height: shadowConfig.yOffset)
        contentView.layer.shadowRadius = shadowConfig.shadowRadius
        contentView.layer.cornerRadius = 6

        let containerView = UIView()
        containerView.addSubview(moreImageView)
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(moreImageView.snp.bottom).offset(4)
            $0.bottom.equalToSuperview()
            $0.leading.trailing.lessThanOrEqualToSuperview()
        }
        moreImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(43)
            $0.top.equalToSuperview()
        }

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
