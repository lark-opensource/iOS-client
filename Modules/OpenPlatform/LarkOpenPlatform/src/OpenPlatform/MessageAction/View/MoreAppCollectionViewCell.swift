//
//  MoreAppCollectionViewCell.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/7.
//

import LarkUIKit
import SnapKit
import UniverseDesignTheme
import UniverseDesignColor
import FigmaKit
import UniverseDesignIcon
import LarkBoxSetting

/// Message Action和加号菜单更多应用列表页Cell，支持常用和更多状态
class MoreAppCollectionViewCell: UICollectionViewCell {
    /// cell固定高度
    static let referencedCellHeight: CGFloat = 128.0
    /// 介绍文本高度需要自适应：1-2行文字的适配规则不同
    static func cellHeight(containerViewWidth: CGFloat, text: String) -> CGFloat {
        let labelWidth: CGFloat = containerViewWidth - 35 - Self.descriptionLabelRightInset
        let constraintRect = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [
                NSAttributedString.Key.font: Self.descriptionLabelFont
            ],
            context: nil
        )
        var labelHeight: CGFloat = ceil(boundingBox.height)
        let referencedOneLineHeight: CGFloat = 20
        let referencedTwoLineHeight: CGFloat = 40
        labelHeight = min(max(labelHeight, referencedOneLineHeight), referencedTwoLineHeight)
        let viewHeight = Self.referencedCellHeight - (referencedOneLineHeight - labelHeight)
        return viewHeight
    }
    /// cell标识
    static let cellIdentifier = String(describing: MoreAppCollectionViewCell.self)
    static let contentViewInsetHorizontal: CGFloat = 16.0
    static let contentViewInsetVertical: CGFloat = 8.0
    static let contentViewCornerRadius: CGFloat = 10.0
    /// 应用图标size
    static let logoEdge: CGFloat = 40.0
    static let logoSize = CGSize(width: logoEdge, height: logoEdge)
    /// 应用图标size
    static let iconEdge: CGFloat = 14.0
    static let iconSize = CGSize(width: iconEdge, height: iconEdge)
    static let descriptionLabelRightInset: CGFloat = 16.0
    static let descriptionLabelFont: UIFont = .systemFont(ofSize: 14.0)
    static let descriptionLabelLineBreakMode: NSLineBreakMode = .byTruncatingTail
    static let descriptionLabelTextAlignment: NSTextAlignment = .left

    /// 依赖的viewModel
    private var viewModel: MoreAppListCellViewModel?
    /// cell样式
    private var sectionMode: MoreAppListSectionMode = .externalList
    /// 检测当前常用列表是否已满
    private var isReachToMaxCommonItems: Bool = false
    private var bizScene: BizScene = .addMenu
    /// 仅支持桌面端
    private var onlyPCAvailable: Bool = false
    var onButtonTap: ((MoreAppListCellViewModel) -> Void)?
    var onMoreDescriptionTap: ((MoreAppListCellViewModel) -> Void)?
    // MARK: 视图组件
    /// Item的图标
    private lazy var logoView: UIImageView = {
        let logoView = UIImageView(frame: CGRect(x: 0, y: 0, width: Self.logoEdge, height: Self.logoEdge))
        logoView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        logoView.contentMode = UIView.ContentMode.scaleAspectFit
        logoView.layer.ux.setSmoothCorner(radius: 10)
        logoView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.N900.withAlphaComponent(0.15))
        
        let maskView = UIView(frame: logoView.frame)
        maskView.backgroundColor = UIColor.ud.fillImgMask
        logoView.addSubview(maskView)
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        /// 使title的内容更易收缩
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    /// Cell的标题
    private lazy var onlyPCAvailableView: UIView = {
        // padding label效果实现参考：https://stackoverflow.com/a/45373172
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        button.setTitle(BundleI18n.MessageAction.Lark_OpenPlatform_ScMblForPcDesc, for: .normal)
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .medium)
        button.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
        button.layer.cornerRadius = 4
        button.isUserInteractionEnabled = false
        /// 使title的内容更易拉伸
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return button
    }()
    private var onlyPCAvailableViewWidthConstraint: Constraint?
    /// 更多描述容器视图
    private lazy var moreDescriptionContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    /// 更多描述容器背后的按钮，负责选中态和边距控制
    private lazy var moreDescriptionContainerBgButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(operateMoreDescription), for: .touchUpInside)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillPressed), for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        return button
    }()
    /// 描述前的logo
    private lazy var descriptionImageView: UIImageView = {
        return UIImageView(image: UDIcon.describeOutlined.ud.withTintColor(UIColor.ud.iconN3))
    }()
    /// 描述
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Self.descriptionLabelFont
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = .clear
        label.textAlignment = Self.descriptionLabelTextAlignment
        label.numberOfLines = 2
        label.lineBreakMode = Self.descriptionLabelLineBreakMode
        return label
    }()
    /// 获取更多描述前的logo
    private lazy var moreDescriptionImageView: UIImageView = {
        return UIImageView()
    }()
    /// 获取更多描述
    private lazy var moreDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// 获取更多描述后的箭头
    private lazy var moreDescriptionArrowImageView: UIImageView = {
        let image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return UIImageView(image: image)
    }()
    /// Cell的操作按钮
    private lazy var operateButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(operateApp(sender:)), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillPressed), for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraint()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 视图刷新
    func refresh(
        bizScene: BizScene,
        sectionMode: MoreAppListSectionMode,
        isReachToMaxCommonItems: Bool,
        onlyPCAvailable: Bool,
        viewModel: MoreAppListCellViewModel,
        buttonEvent: ((MoreAppListCellViewModel) -> Void)?,
        moreDescriptionClickEvent: ((MoreAppListCellViewModel) -> Void)?
    ) {
        self.bizScene = bizScene
        switch bizScene {
        case .addMenu:
            moreDescriptionImageView.image = UDIcon.tabMoreOutlined.ud.withTintColor(UIColor.ud.iconN3)
        case .msgAction:
            moreDescriptionImageView.image = UDIcon.appDefaultOutlined.ud.withTintColor(UIColor.ud.iconN3)
        }
        self.sectionMode = sectionMode
        self.isReachToMaxCommonItems = isReachToMaxCommonItems
        self.onlyPCAvailable = onlyPCAvailable
        self.viewModel = viewModel
        self.onButtonTap = buttonEvent
        self.onMoreDescriptionTap = moreDescriptionClickEvent
        var image: UIImage?
        switch self.sectionMode {
        case .externalList:
            image = UDIcon.noOutlined.ud.withTintColor(UIColor.ud.iconN3)
        case .availabelList:
            image = UDIcon.moreAddOutlined.ud.withTintColor(UIColor.ud.iconN3)
        }

        // 处理仅支持桌面端的情况
        let opacity: Float = onlyPCAvailable ? 0.5 : 1.0
        logoView.layer.opacity = opacity
        descriptionImageView.layer.opacity = opacity
        titleLabel.textColor = onlyPCAvailable ? UIColor.ud.textDisable : UIColor.ud.textTitle
        descriptionLabel.textColor = onlyPCAvailable ? UIColor.ud.textDisable : UIColor.ud.textCaption
        onlyPCAvailableViewWidthConstraint?.isActive = !onlyPCAvailable
        onlyPCAvailableView.isHidden = !onlyPCAvailable
        operateButton.setImage(image, for: .normal)
        logoView.bt.setLarkImage(with: .avatar(key: viewModel.data.icon.key, entityID: "", params: .init(sizeType: .size(Self.logoEdge))))
        titleLabel.text = viewModel.getTitleText()
        descriptionLabel.text = viewModel.getDescText()
        moreDescriptionLabel.text = viewModel.getMoreDescText()
        // 检测当前常用列表是否已满时，禁止添加
        if sectionMode == .availabelList, isReachToMaxCommonItems {
            image = image?.ud.withTintColor(UIColor.ud.N400)
        }
        operateButton.setImage(image, for: .normal)
        operateButton.setImage(image, for: .selected)
        operateButton.setImage(image, for: .highlighted)
        operateButton.backgroundColor = .clear
    }

    @objc
    private func operateApp(sender: UIButton) {
        sender.backgroundColor = .clear
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("on button tapped, but viewModel is empty")
            return
        }
        onButtonTap?(model)
    }

    @objc
    private func operateMoreDescription() {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("on more description tapped, but viewModel is empty")
            return
        }
        onMoreDescriptionTap?(model)
    }
    
    override var isSelected: Bool {
        didSet {
            self.contentView.backgroundColor = UIColor.ud.bgFloat
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.contentView.backgroundColor = UIColor.ud.bgFloat
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.borderColor = (UIColor.ud.N300 & .clear).cgColor
        logoView.layer.ux.removeSmoothBorder()
        logoView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.N900.withAlphaComponent(0.15))
    }
}

// MARK: 视图展示相关
extension MoreAppCollectionViewCell {
    /// view composition
    private func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.layer.cornerRadius = Self.contentViewCornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = (UIColor.ud.N300 & .clear).cgColor

        // 选中颜色设置为透明
        selectedBackgroundView = BaseCellSelectView()
        selectedBackgroundView?.backgroundColor = UIColor.clear
        contentView.addSubview(logoView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(onlyPCAvailableView)
        contentView.addSubview(descriptionImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(moreDescriptionContainerBgButton)
        contentView.addSubview(moreDescriptionContainerView)
        if !BoxSetting.isBoxOff() {
            moreDescriptionContainerView.addSubview(moreDescriptionImageView)
            moreDescriptionContainerView.addSubview(moreDescriptionLabel)
            moreDescriptionContainerView.addSubview(moreDescriptionArrowImageView)
        }
        contentView.addSubview(operateButton)
    }

    /// layout constraint
    private func setupConstraint() {
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(Self.logoSize)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(logoView)
            make.left.equalTo(logoView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(onlyPCAvailableView.snp.left).offset(-4)
        }
        onlyPCAvailableView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.right.lessThanOrEqualTo(operateButton.snp.left).offset(-4)
            onlyPCAvailableViewWidthConstraint = make.width.equalTo(0).constraint
            onlyPCAvailableViewWidthConstraint?.isActive = false
        }
        descriptionImageView.snp.makeConstraints { make in
            make.left.equalTo(logoView)
            make.top.equalTo(descriptionLabel).inset(2)
            make.size.equalTo(Self.iconSize)
        }
        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(logoView.snp.bottom).offset(12)
            make.left.equalTo(descriptionImageView.snp.right).offset(5)
            make.right.equalToSuperview().inset(Self.descriptionLabelRightInset)
        }
        moreDescriptionContainerView.snp.makeConstraints { make in
            make.left.equalTo(logoView)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            make.right.lessThanOrEqualTo(descriptionLabel)
            make.height.equalTo(20)
        }
        moreDescriptionContainerBgButton.snp.makeConstraints { make in
            make.edges.equalTo(moreDescriptionContainerView).inset(UIEdgeInsets(top: -4, left: -6, bottom: -4, right: 0))
        }
        if !BoxSetting.isBoxOff() {
            moreDescriptionImageView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.centerY.equalTo(moreDescriptionLabel)
                make.size.equalTo(Self.iconSize)
            }
            moreDescriptionLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(moreDescriptionImageView.snp.right).offset(5)
            }
            moreDescriptionArrowImageView.snp.makeConstraints { make in
                make.left.equalTo(moreDescriptionLabel.snp.right)
                make.centerY.equalTo(moreDescriptionLabel)
                make.right.equalToSuperview()
                make.width.height.equalTo(14)
            }
        }
        operateButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(28.0)
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(12)
        }
    }
}
