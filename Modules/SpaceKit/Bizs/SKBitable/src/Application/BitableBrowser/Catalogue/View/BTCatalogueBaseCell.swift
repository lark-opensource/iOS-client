//
//  BTCatalogueBaseCell.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/23.
//  


import UIKit
import SKFoundation
import SKUIKit
import SnapKit
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignButton

protocol BitableCatalogueData: AnyObject {
    
    var arrowIcon: UIImage? { get }
    
    var iconImg: UIImage { get }
    
    var title: String? { get }
    
    var iconImgUrl: String? { get }
    
    var catalogueType: BTCatalogueCellType { get }
    
    /// 是否选中， 根据不同typy表现不一样。typy: head时“展开”子节点；type: node时， 展示高亮样式
    var isSelected: Bool { get }
    
    /// 是否可左滑
    var editable: Bool { get }
    
    /// 左滑后显示的操作
    var slideActions: [BTCatalogueContextualAction.ActionType] { get }

    var canAddView: Bool { get }
    
    var canHighlighted: Bool { get }
    
    var canExpand: Bool { get }
    
    var canBackgroundHighlighted: Bool { get }
    
    /// 是否展示 lighting 标识
    var showLighting: Bool { get }
    /// 是否展示 warning 标识
    var showWarning: Bool { get }
}

enum BTCatalogueCellType {
    case head
    case node
}

class BTCatalogueBaseCell: SKSlideableTableViewCell {

    private enum Layout {
        static var iconTitleSpacing: CGFloat = 9
        static var arrowSize: CGSize = CGSize(width: 16, height: 16)
        static var iconSize: CGSize = CGSize(width: 20, height: 20)
        /// 左边高亮条
        static var highlightedWidth: CGFloat = 4
        static var warnIconSize: CGFloat = 16.0
        static var warnIconMarginH: CGFloat = 6.0
    }

    var leftContentInset: CGFloat { 16 }
    var addHandler: ((_ sourceView: Weak<UIView>) -> Void)?
    var moreHandler: ((_ sourceView: Weak<UIView>) -> Void)?
    let disposeBag = DisposeBag()

    private(set) lazy var arrowView = UIImageView()
    
    private lazy var titleWrapper = UIView()
    
    private(set) lazy var iconView: BTLightingIconView = {
        let view = BTLightingIconView()
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()

    private(set) lazy var titleLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UIFont.systemFont(ofSize: 16)
    }
    
    private(set) lazy var warnView: UIImageView = {
        let vi = UIImageView()
        vi.image = UDIcon.warningColorful
        vi.clipsToBounds = true
        return vi
    }()

    private(set) lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.addOutlined.ud.withTintColor(UDColor.iconN3), for: [.normal, .highlighted])
        button.backgroundColor = .clear
        button.contentEdgeInsets = UIEdgeInsets(edges: 4)
        button.setBackgroundImage(.btd_image(with: CGSize(width: 28, height: 28), cornerRadius: 6, backgroundColor: UDColor.fillPressed), for: [.highlighted])
        return button
    }()
    
    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.moreOutlined.ud.withTintColor(UDColor.iconN3), for: [.normal, .highlighted])
        button.backgroundColor = .clear
        button.contentEdgeInsets = UIEdgeInsets(edges: 4)
        button.setBackgroundImage(.btd_image(with: CGSize(width: 28, height: 28), cornerRadius: 6, backgroundColor: UDColor.fillPressed), for: [.highlighted])
        return button
    }()

    private lazy var highlightedView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.primaryContentDefault
        view.isHidden = true
        return view
    }()

    private var labelButtonConstraint: Constraint!
    private var moreButtonConstraint: Constraint!
    private var addButtonLeftToMoreButtonConstraint: Constraint!
    private var addButtonLeftToSuperviewConstraint: Constraint!
        
    override var isSelected: Bool {
        didSet {
            guard let data = data else {
                return
            }
            let isHighlighted = data.canBackgroundHighlighted && data.isSelected
            if isHighlighted {
                containerView.backgroundColor = UDColor.fillActive.skOverlayColor(with: UDColor.bgFloat)
            } else {
                containerView.backgroundColor = isSelected ? UDColor.fillPressed.skOverlayColor(with: UDColor.bgFloat) : UDColor.bgFloat
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupInit()
        setupLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        addHandler = nil
    }

    func setupInit() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = UDColor.bgFloatBase
        containerView.docs.addHover(with: UDColor.fillPressed.skOverlayColor(with: UDColor.bgFloat), disposeBag: disposeBag)
        containerView.addSubview(highlightedView)
        containerView.addSubview(arrowView)
        containerView.addSubview(titleWrapper)
        titleWrapper.addSubview(iconView)
        titleWrapper.addSubview(titleLabel)
        titleWrapper.addSubview(warnView)
        containerView.addSubview(addButton)
        containerView.addSubview(lineView)
        titleWrapper.isUserInteractionEnabled = false
        containerView.addSubview(moreButton)
        // SKSlideableTableViewCell 不支持 cell hight 事件，这里主动构造
        containerView.addTarget(self, action: #selector(toutchContainerView), for: [.touchDown, .touchDragInside, .touchDragEnter])
        containerView.addTarget(self, action: #selector(toutchupContainerView), for: [.touchUpInside, .touchCancel, .touchUpOutside, .touchDragExit, .touchDragOutside])
    }
    
    @objc
    private func toutchContainerView() {
        isSelected = true
    }
    
    @objc
    private func toutchupContainerView() {
        isSelected = false
    }

    func setupLayout() {
        highlightedView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(Layout.highlightedWidth)
        }
        
        arrowView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(leftContentInset)
            make.size.equalTo(Layout.arrowSize)
            make.right.equalTo(titleWrapper.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        titleWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            // addButton 显示
            labelButtonConstraint = make.right.lessThanOrEqualTo(addButton.snp.left).offset(-12).constraint
            // moreButton 显示，addButton 不显示
            moreButtonConstraint = make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-12).constraint
        }
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
            make.left.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(Layout.iconTitleSpacing)
            make.centerY.equalToSuperview()
        }
        
        warnView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(Layout.warnIconMarginH)
            make.width.height.equalTo(Layout.warnIconSize)
            make.right.centerY.equalToSuperview()
        }

        lineView.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(iconView.snp.left)
        }
        addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            // moreButton 不显示
            addButtonLeftToSuperviewConstraint = make.right.equalToSuperview().offset(-12).constraint
            // moreButton 显示
            addButtonLeftToMoreButtonConstraint = make.right.equalTo(moreButton.snp.left).offset(-16).constraint
            make.height.width.equalTo(28)
        }
        addButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -8, bottom: -10, right: -4)
        let weakAddButton: Weak<UIView> = Weak(addButton)
        addButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.addHandler?(weakAddButton)
        }).disposed(by: disposeBag)
        
        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.height.width.equalTo(28)
        }
        moreButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -8, bottom: -10, right: -12)
        let weakMoreButton: Weak<UIView> = Weak(moreButton)
        moreButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.moreHandler?(weakMoreButton)
        }).disposed(by: disposeBag)
    }
    
    var data: BitableCatalogueData?

    func update(data: BitableCatalogueData) {
        self.data = data
        arrowView.image = data.arrowIcon
        if arrowView.image == nil {
            arrowView.snp.updateConstraints { make in
                make.size.equalTo(CGSize.zero)
                make.right.equalTo(titleWrapper.snp.left).offset(0)
            }
        } else {
            arrowView.snp.updateConstraints { make in
                make.size.equalTo(Layout.arrowSize)
                make.right.equalTo(titleWrapper.snp.left).offset(-8)
            }
        }
        
        if let iconUrl = data.iconImgUrl {
            iconView.update(iconUrl, grayScale: !isHighlighted)
        } else {
            iconView.update(data.iconImg, showLighting: data.showLighting, tintColor: UDColor.iconN1)
        }

        titleLabel.text = data.title
        update(showAddButton: data.canAddView, editable: data.editable)
        
        titleLabel.font = (data.catalogueType == .head || isHighlighted) ? UIFont.systemFont(ofSize: 16, weight: .medium) : UIFont.systemFont(ofSize: 16)
        let isBackgroundHighlighted = data.canBackgroundHighlighted && data.isSelected
        highlightedView.isHidden = !isBackgroundHighlighted
        
        updateChildViewsColor()
    }
    
    private func updateChildViewsColor() {
        guard let data = data else { return }
        warnView.snp.updateConstraints { make in
            make.width.equalTo(data.showWarning ? Layout.warnIconSize : 0)
            make.left.equalTo(titleLabel.snp.right).offset(data.showWarning ? Layout.warnIconMarginH : 0)
        }
        
        arrowView.image = data.arrowIcon?.ud.withTintColor(UDColor.iconN2)
        let isHighlighted = data.canHighlighted && data.isSelected
        let isBackgroundHighlighted = data.canBackgroundHighlighted && data.isSelected
        if isBackgroundHighlighted {
            containerView.backgroundColor = UDColor.fillActive.skOverlayColor(with: UDColor.bgFloat)
        } else {
            containerView.backgroundColor = containerView.isHighlighted ? UDColor.fillPressed.skOverlayColor(with: UDColor.bgFloat) : UDColor.bgFloat
        }
        titleLabel.textColor = isHighlighted ? UDColor.primaryContentDefault : UDColor.textTitle
        let iconColor = isHighlighted ? UDColor.primaryContentDefault : UDColor.iconN2
        
        if let iconUrl = data.iconImgUrl {
            iconView.update(iconUrl, grayScale: !isHighlighted)
            iconView.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: Layout.iconSize.width - 2, height: Layout.iconSize.height - 2))
            }
        } else {
            iconView.update(data.iconImg, showLighting: data.showLighting, tintColor: iconColor)
            iconView.snp.updateConstraints { make in
                make.size.equalTo(Layout.iconSize)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateChildViewsColor()
    }

    private func update(showAddButton: Bool, editable: Bool) {
        addButton.isHidden = !showAddButton
        if showAddButton {
            labelButtonConstraint.activate()
        } else {
            labelButtonConstraint.deactivate()
        }
        moreButton.isHidden = !editable
        if editable, !showAddButton {
            moreButtonConstraint.activate()
        } else {
            moreButtonConstraint.deactivate()
        }
        if editable {
            addButtonLeftToSuperviewConstraint.deactivate()
            addButtonLeftToMoreButtonConstraint.activate()
        } else {
            addButtonLeftToSuperviewConstraint.activate()
            addButtonLeftToMoreButtonConstraint.deactivate()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
