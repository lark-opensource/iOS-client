//
//  BTBottomToolBar.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/11.
//  


import SKFoundation
import SKUIKit
import SKCommon
import UniverseDesignColor
import UniverseDesignIcon
import CoreGraphics
import UIKit
import UniverseDesignBadge

protocol BTBottomToolbarDelegate: AnyObject {
    func bottomToolbar(_ toolbar: BTBottomToolBar, didSelect item: BTBottomToolBarItemModel)
}

final class BTBottomToolBar: UIView {
    
    weak var delegate: BTBottomToolbarDelegate?
    
    static let toolBarHeight: CGFloat = 56
    
    private(set) var models: [BTBottomToolBarItemModel] = []
    
    private let topLine = UIView()
    
    private(set) lazy var itemsStackView = UIStackView().construct {
        $0.distribution = .fillEqually
    }
    
    private lazy var invalidBadge: UDBadge = {
        let config = UDBadgeConfig(type: .dot, contentStyle: .custom(UIColor.ud.colorfulOrange))
        let badge = UDBadge(config: config)
        return badge
    }()
    
    init(models: [BTBottomToolBarItemModel] = []) {
        super.init(frame: .zero)
        setupViews()
        updateModels(models)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateModels(_ models: [BTBottomToolBarItemModel]) {
        self.models = models
        itemsStackView.removeAllArrangedSubviews()
        for model in models {
            let itemView = BTBottomToolBarItemView(model: model)
            itemView.didTapItem = {[weak self] model in
                guard let self = self else { return }
                self.delegate?.bottomToolbar(self, didSelect: model)
                if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable,
                   model.itemType == .layout {
                    OnboardingManager.shared.markFinished(for: [OnboardingID.bitableCardViewCoverSupportEntryNew])
                    itemView.imageView?.badge?.removeFromSuperview()
                }
            }
            if shouldShowRedBadge(model: model) {
                let config = UDBadgeConfig(type: .dot)
                itemView.imageView?.layer.masksToBounds = false
                let dotSize = UDBadgeDotSize.middle.size
                itemView.imageView?.addBadge(config,
                                             offset: CGSize(width: dotSize.width / 2.0, height: -dotSize.height / 4.0))
            } else {
                itemView.imageView?.badge?.removeFromSuperview()
            }
            itemsStackView.addArrangedSubview(itemView)
        }
    }
    
    private func shouldShowRedBadge(model: BTBottomToolBarItemModel) -> Bool {
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable,
           model.itemType == .layout {
            return !OnboardingManager.shared.hasFinished(OnboardingID.bitableCardViewCoverSupportEntryNew)
        }
        return model.hasInvalidCondition ?? false
    }
    
    func itemView(for type: BTBottomToolBarItemModel.ItemType) -> UIView? {
        itemsStackView.arrangedSubviews.first { vi in
            if let itemView = vi as? BTBottomToolBarItemView {
                return itemView.model.itemType == type
            }
            return false
        }
    }
    
    private func setupViews() {
        self.backgroundColor = UDColor.bgBody
        self.itemsStackView.backgroundColor = UDColor.bgBody
        self.topLine.backgroundColor = UDColor.lineDividerDefault
        
        addSubview(itemsStackView)
        addSubview(topLine)
        
        itemsStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.equalTo(self.safeAreaLayoutGuide.snp.left)
            $0.right.equalTo(self.safeAreaLayoutGuide.snp.right)
            $0.height.equalTo(BTBottomToolBar.toolBarHeight)
        }
        
        topLine.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}

struct BTBottomToolBarItemModel: Codable, Equatable {
  
    enum ItemType: String {
        case filter = "Filter"
        case sort = "Sort"
        case layout = "Layout"
        case unknow
    }
    
    var id: String = ""
    var title: String = "" // 文案
    var count: Int = 0
    var active: Bool? = false
    var hasInvalidCondition: Bool? = false // 是否包含不可见字段的筛选项
    
    var shouldShowNewBadge: Bool? = false // 显示红点引导
    var newBadgeText: String? = "" // 引导文案

    var itemType: ItemType {
        return ItemType(rawValue: id) ?? .unknow
    }
    
    var iconImage: UIImage? { // icon 图片
        switch itemType {
        case .filter: return UDIcon.filterOutlined
        case .sort: return UDIcon.sortAToZOutlined
        case .layout: return UDIcon.autoLayoutOutlined
        case .unknow: return nil
        }
    }
    
    var trackTarget: String {
        switch itemType {
        case .filter: return "ccm_bitable_filter_set_view"
        case .sort: return "ccm_bitable_sort_set_view"
        case .layout: return "ccm_bitable_mobile_grid_format_view"
        case .unknow: return ""
        }
    }
}

final class BTBottomToolBarItemView: UIButton {
    
    var didTapItem: ((BTBottomToolBarItemModel) -> Void)?
    
    private(set) var model: BTBottomToolBarItemModel
    
    init(model: BTBottomToolBarItemModel) {
        self.model = model
        super.init(frame: .zero)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        self.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
        configModel(model)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize = CGSize(width: 22, height: 22)
        let titleSize = self.titleLabel?.intrinsicContentSize ?? CGSize.zero
        let spacingBetweenImageAndTitle: CGFloat = 3
        self.imageEdgeInsets = UIEdgeInsets(top: -titleSize.height - (spacingBetweenImageAndTitle / 2),
                                            left: 0,
                                            bottom: 0,
                                            right: -titleSize.width)
        self.titleEdgeInsets = UIEdgeInsets(top: 0,
                                            left: -imageSize.height,
                                            bottom: -imageSize.height - (spacingBetweenImageAndTitle / 2),
                                            right: 0)
    }
    
    private func configModel(_ model: BTBottomToolBarItemModel) {
        let text = (model.count > 0 && (model.active ?? false)) ? "\(model.count) \(model.title)" : model.title
        let iconTintColor = (model.active ?? false) ? UDColor.primaryContentDefault : UDColor.iconN1
        let titleTintColor = (model.active ?? false) ? UDColor.primaryContentDefault : UDColor.textTitle
        self.setImage(model.iconImage?.ud.withTintColor(iconTintColor), for: .normal)
        self.setTitle(text, for: .normal)
        self.setTitleColor(titleTintColor, for: .normal)
        self.setBackgroundImage(UIImage.docs.color(UDColor.fillPressed), for: .highlighted)
    }
    
    @objc
    private func selfTapped() {
        didTapItem?(model)
    }
}

extension UIStackView {
    @discardableResult
    func removeAllArrangedSubviews() -> [UIView] {
        return arrangedSubviews.reduce([UIView]()) { $0 + [removeArrangedSubViewProperly($1)] }
    }

    func removeArrangedSubViewProperly(_ view: UIView) -> UIView {
        removeArrangedSubview(view)
        NSLayoutConstraint.deactivate(view.constraints)
        view.removeFromSuperview()
        return view
    }
}
