//
//  WPCommonAppHeader.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2021/12/24.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import UniverseDesignIcon
import LarkSetting
import ByteWebImage
import UniverseDesignFont
import UniverseDesignColor
import LarkWorkplaceModel
import LKCommonsLogging

enum WPCommonAreaState: Int {
    case normal = 0
    case editing = 1
}

enum WPCommonAppHeaderNotification: String, NotificationName {
    case stickTop = "WPCommonAppHeaderNotification.stickTop"
    case leaveTop = "WPCommonAppHeaderNotification.leaveTop"
}

protocol WPCommonAppHeaderDelegate: NSObjectProtocol {
    func onTitleClick(_ view: WPCommonAppHeader, urlStr: String)

    func onEditClick(view: WPCommonAppHeader, indexPath: IndexPath)

    func onAddClick(view: WPCommonAppHeader)

    func onFinishEditClick(view: WPCommonAppHeader, indexPath: IndexPath)

    func onSubModuleSelected(subModuleIndex: Int, indexPath: IndexPath)
}

/// 我的常用 Header
final class WPCommonAppHeader: UICollectionReusableView {
    static let logger = Logger.log(WPCommonAppHeader.self)
    weak var delegate: WPCommonAppHeaderDelegate?

    var horizontalMargin: Int = 0

    var indexPath: IndexPath?

    /// View Model
    private(set) var component: GroupTitleComponent?

    private var disposeBag = DisposeBag()

    private var configService: WPConfigService?
    private var enableHeaderBlur: Bool { !Display.pad }

    private var enableRecentlyUsedApp: Bool {
        return configService?.fgValue(for: .enableRecentlyUsedApp) ?? false
    }

    private let blurView = UIVisualEffectView(effect: nil)

    /// Content view, no margin
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// Title icon - single module
    private lazy var titleLeadingIcon = { () -> WPMaskImageView in
        let icon = WPMaskImageView()
        icon.backgroundColor = UIColor.ud.bgFiller
        icon.clipsToBounds = true
        icon.sqRadius = WPUIConst.AvatarRadius.xs6
        icon.sqBorder = WPUIConst.BorderW.pt1
        return icon
    }()

    /// Title label - single module
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_MyFavTtl
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    /// Title redirect icon - single module
    private lazy var titleTrailingIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return icon
    }()

    /// Title Container - single module
    private lazy var titleContainerView: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [
            titleLeadingIcon, titleLabel, titleTrailingIcon
        ])
        // the stack view lays out its arranged views relative to its layout margins
        containerView.isLayoutMarginsRelativeArrangement = true
        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0)
        containerView.setCustomSpacing(Layout.Title.LeadingIconRightSpacing, after: titleLeadingIcon)
        containerView.setCustomSpacing(Layout.Title.LabelRightSpacing, after: titleLabel)
        containerView.layer.cornerRadius = Layout.Title.ContainerRadius
        containerView.alignment = .center
        containerView.distribution = .fill
        return containerView
    }()

    /// Title Container - multi module
    private lazy var multiTabView: CatagroyLabelHorizontalCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        let collectionView = CatagroyLabelHorizontalCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.clipsToBounds = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private lazy var divideLine: UIView = {
        let vi = UIView()
        vi.isUserInteractionEnabled = false
        vi.backgroundColor = UIColor.ud.lineDividerDefault
        return vi
    }()

    // 标题点击 热区
    private lazy var titleHotArea = {
        let hotArea = CommonTitleHotAreaView()
        hotArea.isUserInteractionEnabled = false
        hotArea.touchEvent = { [weak self] in
            self?.titleContainerView.backgroundColor = UIColor.ud.fillPressed
        }
        hotArea.cancelEvent = { [weak self] in
            self?.titleContainerView.backgroundColor = .clear
        }
        hotArea.clickEvent = { [weak self] urlStr in
            guard let `self` = self else { return }
            self.titleContainerView.backgroundColor = .clear
            Self.logger.info("header title is clicked")
            self.delegate?.onTitleClick(self, urlStr: urlStr)
        }
        return hotArea
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.addMiddleOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.ud.primaryContentDefault
        button.tintAdjustmentMode = .normal
        button.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AppGroupUrlAddBttn, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = Layout.Title.TitleFontOfAddButton
        button.titleLabel?.lineBreakMode = .byClipping
        button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        button.titleEdgeInsets = Layout.Title.TitleInsetsOfAddButton
        button.addTarget(self, action: #selector(addCommon), for: .touchUpInside)
        return button
    }()

    private lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.adminOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor.ud.primaryContentDefault
        button.tintAdjustmentMode = .normal
        button.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_ManageBttn, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = Layout.Title.TitleFontOfEditButton
        button.titleLabel?.lineBreakMode = .byClipping
        button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        button.titleEdgeInsets = Layout.Title.TitleInsetsOfEditButton
        button.addTarget(self, action: #selector(editCommon), for: .touchUpInside)
        return button
    }()

    private lazy var finishEditingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Done, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.titleLabel?.font = .systemFont(ofSize: 14.0)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(finishEditing), for: .touchUpInside)
        return button
    }()

    private lazy var buttonContainerView: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [
            addButton, editButton, finishEditingButton
        ])
        containerView.axis = .horizontal
        containerView.alignment = .center
        containerView.distribution = .equalSpacing
        containerView.spacing = 16
        containerView.backgroundColor = .clear
        return containerView
    }()

    // MARK: view initial

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = enableHeaderBlur ? .clear : UIColor.ud.bgBody

        /* view hierarchy
         - blurView
            - contentView
                - titleContainerView
                    - titleHotArea
                - multiTabView
                - divideLine
                - buttonContainerView
        */
        addSubview(blurView)
        blurView.contentView.addSubview(contentView)
        contentView.addSubview(titleContainerView)
        contentView.addSubview(multiTabView)
        contentView.addSubview(divideLine)
        titleContainerView.addSubview(titleHotArea)
        contentView.addSubview(buttonContainerView)
    }

    private func setupConstraints() {
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(favoriteSingleModuleHeaderBottomPadding)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(favoriteSingleModuleHeaderHeight)
        }
        titleContainerView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(buttonContainerView.snp.leading)
                .offset(-Layout.SpaceBetweenTitleAreaAndEditArea)
        }
        titleHotArea.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalTo(blurView.snp.bottom)
        }
        multiTabView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(buttonContainerView.snp.leading).offset(-16)
        }
        divideLine.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(WPUIConst.BorderW.pt1)
        }
        buttonContainerView.snp.makeConstraints { (make) in
            make.top.bottom.trailing.equalToSuperview()
        }
        titleLeadingIcon.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.Title.LeadingIconEdge)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(Layout.Title.LabelHeight)
        }

        titleTrailingIcon.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.Title.TrailingIconEdge)
        }

        let finishEditTextWidth = finishEditingButton.titleLabel?.text?.size(
            // swiftlint:disable init_font_with_token
            withAttributes: [.font: UIFont.systemFont(ofSize: 14.0)]
            // swiftlint:enable init_font_with_token
        ).width ?? 0
        finishEditingButton.snp.makeConstraints { (make) in
            make.width.equalTo(finishEditTextWidth + 32)
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        if layoutAttributes.zIndex == 0 {
            backgroundColor = .clear
        } else {
            backgroundColor = .ud.bgBody
        }
    }

    // MARK: - update views
    /// 刷新视图
    /// - Parameters:
    ///   - layoutParams: 布局参数
    ///   - titleComponents: title 数据
    func refreshViews(
        with layoutParams: BaseComponentLayout?,
        titleComponents: GroupTitleComponent?,
        configService: WPConfigService
    ) {
        self.configService = configService

        component = titleComponents
        let marginLeft = max(layoutParams?.marginLeft ?? 0, 4)
        let marginRight = max(layoutParams?.marginRight ?? 0, 4)
        if let subTitle = titleComponents?.subTitle, subTitle.count > 1,
           let selectedIndex = titleComponents?.selectedSubTitleIndex {
            // Multi Module
            contentView.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().inset(marginLeft)
                make.trailing.equalToSuperview().inset(marginRight)
                make.height.equalTo(favoriteMultiModuleHeaderHeight)
                make.bottom.equalToSuperview().inset(favoriteMultiModuleHeaderBottomPadding)
            }
            showMultiTab(subTitle, selectedIndex: selectedIndex)
        } else {
            // Single Module
            contentView.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().inset(marginLeft)
                make.trailing.equalToSuperview().inset(marginRight)
                make.height.equalTo(favoriteSingleModuleHeaderHeight)
                make.bottom.equalToSuperview().inset(favoriteSingleModuleHeaderBottomPadding)
            }
            let title = titleComponents?.title ?? .init(text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_MyFavTtl)
            showSingleTab(title)
        }
        // button style controlled by recently used fg
        updateButtonStyle()
    }

    /// Show multi-tab view
    ///
    /// - Parameters:
    ///    - subTitles: list of sub title
    ///    - selectedIndex: index of selected tab
    private func showMultiTab(_ subTitles: [GroupTitleComponent.Title], selectedIndex: Int) {
        multiTabView.isHidden = false
        titleContainerView.isHidden = true
        divideLine.isHidden = false
        multiTabView.reloadData()
        multiTabView.selectItem(
            at: .init(item: selectedIndex, section: 0),
            animated: false,
            scrollPosition: .centeredHorizontally
        )
    }

    /// Show single-tab view (actually no tab)
    private func showSingleTab(_ title: GroupTitleComponent.Title) {
        multiTabView.isHidden = true
        titleContainerView.isHidden = false
        divideLine.isHidden = true
        updateLeadingIcon(with: title.iconUrl)
        updateTitle(with: title.text)
        updateTitleHotArea(with: title.schema)
    }

    /// Update leading icon image
    /// If `urlStr` is `nil` or `urlStr` is empty,  hide the leading icon
    ///
    /// - Parameter urlStr: image source url.
    private func updateLeadingIcon(with urlStr: String?) {
        guard let imageURLStr = urlStr, !urlStr.isEmpty else {
            titleLeadingIcon.isHidden = true
            return
        }
        titleLeadingIcon.bt.setLarkImage(.default(key: imageURLStr), placeholder: Resources.icon_placeholder)
        titleLeadingIcon.isHidden = false
    }

    /// Update title text
    /// If `text` is nil or empty string, hide the title label
    ///
    /// - Parameter text: text string
    private func updateTitle(with text: String?) {
        guard let text = text, !text.isEmpty else {
            titleLabel.isHidden = true
            return
        }
        titleLabel.text = text
        titleLabel.isHidden = false
    }

    /// Update hot area and trailing button. If `urlStr` is `nil` or empty string, hide them all.
    ///
    /// - Parameter urlStr: Redirect url
    private func updateTitleHotArea(with urlStr: String?) {
        if let urlStr = urlStr, !urlStr.isEmpty {
            titleHotArea.urlStr = urlStr
            titleHotArea.isUserInteractionEnabled = true
            titleTrailingIcon.isHidden = false
        } else {
            titleHotArea.urlStr = nil
            titleHotArea.isUserInteractionEnabled = false
            titleTrailingIcon.isHidden = true
        }
    }

    func updateBlurStyle(isSticked: Bool) {
        guard enableHeaderBlur else {
            return
        }
        if isSticked {
            blurView.effect = nil
            // 原色，5.14
            backgroundColor = .ud.bgBody
//            // 高斯模糊，5.15+ 做
//            if #available(iOS 13.0, *) {
//                blurView.effect = UIBlurEffect(style: .systemThickMaterial)
//            } else { // Fallback on earlier versions
//                blurView.effect = UIBlurEffect(style: .regular)
//            }
        } else {
            backgroundColor = .clear
            blurView.effect = nil
        }
    }

    /// If the text is too long, hide the title of the button and only show the icon
    ///
    /// In normal state:  if width of the add button's title + width of the edit button's title > 128, then only show buttons' icon
    /// In editing state: if width of the add button's title > 64, then for add button, only show it's icon
    ///
    /// - Parameter state: `editing` in editing state; `normal` not in editing state
    private func hideLongTitleOfButton(with state: WPCommonAreaState) {
        let addTitle = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AppGroupUrlAddBttn
        let editTitle = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_ManageBttn

        let addTitleWidth = addTitle.size(withAttributes: [.font: Layout.Title.TitleFontOfAddButton]).width
        let editTitleWidth = editTitle.size(withAttributes: [.font: Layout.Title.TitleFontOfEditButton]).width

        switch state {
        case .normal:
            if ceil(addTitleWidth) + ceil(editTitleWidth) > Layout.Title.WidthLimitInNormalState {
                addButton.setTitle("", for: .normal)
                addButton.titleEdgeInsets = .zero
                editButton.setTitle("", for: .normal)
                editButton.titleEdgeInsets = .zero
            } else {
                addButton.setTitle(addTitle, for: .normal)
                addButton.titleEdgeInsets = Layout.Title.TitleInsetsOfAddButton
                editButton.setTitle(editTitle, for: .normal)
                editButton.titleEdgeInsets = Layout.Title.TitleInsetsOfEditButton
            }
        case .editing:
            if ceil(addTitleWidth) > Layout.Title.WidthLimitInEditingState {
                addButton.setTitle("", for: .normal)
                addButton.titleEdgeInsets = .zero
            } else {
                addButton.setTitle(addTitle, for: .normal)
                addButton.titleEdgeInsets = Layout.Title.TitleInsetsOfAddButton
            }
        }
    }

    /// Button style controlled by recently used fg
    private func updateButtonStyle() {
        // add button style controlled by fg
        addButton.tintColor = enableRecentlyUsedApp ? UIColor.ud.iconN2 : UIColor.ud.primaryContentDefault
        let addButtonText = enableRecentlyUsedApp ? "" : BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AppGroupUrlAddBttn
        addButton.setTitle(addButtonText, for: .normal)
        addButton.titleEdgeInsets = enableRecentlyUsedApp ? .zero : Layout.Title.TitleInsetsOfAddButton
        // edit button style controlled by fg
        let sortIcon = UDIcon.sortOutlined.withRenderingMode(.alwaysTemplate)
        let adminIcon = UDIcon.adminOutlined.withRenderingMode(.alwaysTemplate)
        editButton.setImage(enableRecentlyUsedApp ? sortIcon : adminIcon, for: .normal)
        editButton.tintColor = enableRecentlyUsedApp ? UIColor.ud.iconN2 : UIColor.ud.primaryContentDefault
        let editButtonText = enableRecentlyUsedApp ? "" : BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_ManageBttn
        editButton.setTitle(editButtonText, for: .normal)
        editButton.titleEdgeInsets = enableRecentlyUsedApp ? .zero : Layout.Title.TitleInsetsOfEditButton
    }
}

// MARK: - 编辑我的常用
extension WPCommonAppHeader {
    /// 更新编辑状态
    /// - Parameters:
    ///   - state: 是否在编辑态
    ///   - isEditable: 是否可编辑
    ///   - displaySubModule: 当前展示的子模块类型
    func updateState(with state: WPCommonAreaState, isEditable: Bool, displaySubModule: FavoriteSubModule) {
        switch displaySubModule {
        case .recentlyUsed:
            addButton.isHidden = true
            editButton.isHidden = true
            finishEditingButton.isHidden = true
        case .favorite:
            addButton.isHidden = !isEditable || state == .editing && enableRecentlyUsedApp
            editButton.isHidden = !isEditable || state == .editing
            finishEditingButton.isHidden = !isEditable || state == .normal
        @unknown default:
            addButton.isHidden = true
            editButton.isHidden = true
            finishEditingButton.isHidden = true
        }
        if !enableRecentlyUsedApp { hideLongTitleOfButton(with: state) }
        updateMultiTabViewConstraints(isEditable: isEditable, displaySubModule: displaySubModule)
    }

    /// 更新多标签容器布局。如果没有操作 Button，右侧与父视图对齐。如果有操作 Button，右侧和 Button 保持 16pt Margin
    ///
    /// - Parameters:
    ///   - isEditable: 是否可编辑
    ///   - displaySubModule: 当前展示的子模块类型
    private func updateMultiTabViewConstraints(isEditable: Bool, displaySubModule: FavoriteSubModule) {
        if !isEditable || displaySubModule == .recentlyUsed {
            multiTabView.snp.updateConstraints { (make) in
                make.trailing.equalTo(buttonContainerView.snp.leading)
            }
        } else {
            multiTabView.snp.updateConstraints { (make) in
                make.trailing.equalTo(buttonContainerView.snp.leading).offset(-16)
            }
        }
    }

    @objc private func addCommon() {
        delegate?.onAddClick(view: self)
    }

    @objc private func editCommon() {
        guard let indexPath = indexPath else { return }
        delegate?.onEditClick(view: self, indexPath: indexPath)
    }

    @objc private func finishEditing() {
        guard let indexPath = indexPath else {
            return
        }
        delegate?.onFinishEditClick(view: self, indexPath: indexPath)
    }
}

extension WPCommonAppHeader: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }
        return component?.subTitle.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let unknownCell = collectionView.dequeueReusableCell(withReuseIdentifier: CatagroyLabelHorizontalCollectionView.cellID,for: indexPath)
        guard let cell = unknownCell as? HorizontalLabelCell, let component = component,
              indexPath.item < component.subTitle.count else {
            return unknownCell
        }
        cell.refreshViews(
            text: component.subTitle[indexPath.item].text,
            avatarURLStr: component.subTitle[indexPath.item].iconUrl,
            selectedFont: .systemFont(ofSize: 16, weight: .medium),
            unselectedFont: .systemFont(ofSize: 16, weight: .medium),
            cellLeftPadding: indexPath.item == 0 ? 0 : 10,
            cellRightPadding: 10
        )
        cell.isSelected = indexPath.item == component.selectedSubTitleIndex
        return cell
    }
}

extension WPCommonAppHeader: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let component = component, indexPath.item < component.subTitle.count else { return .zero }
        let textFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let text = component.subTitle[indexPath.item].text
        let margin = CGFloat(indexPath.item == 0 ? 10 : 20)
        var iconWidth: CGFloat = 0
        if let iconURL = component.subTitle[indexPath.item].iconUrl, !iconURL.isEmpty { iconWidth = 28 }
        var size = text.size(withAttributes: [.font: textFont])
        size.height = max(42, size.height)
        size.width = CGFloat(ceil(Double(size.width + margin + iconWidth)))
        return size
    }
}

extension WPCommonAppHeader: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let outerIndexPath = self.indexPath else { return }
        self.delegate?.onSubModuleSelected(subModuleIndex: indexPath.item, indexPath: outerIndexPath)
    }
}


// MARK: - 布局常量
extension WPCommonAppHeader {
    enum Layout {
        enum Title {
            static let ContainerRadius: CGFloat = 4.0

            static let LeadingIconEdge: CGFloat = 22.0
            static let LeadingIconRightSpacing: CGFloat = 8.0

            static let LabelHeight: CGFloat = 22.0
            static let LabelRightSpacing: CGFloat = 2.0

            static let TrailingIconEdge: CGFloat = 14.0

            static let WidthLimitInEditingState: CGFloat = 64
            static let WidthLimitInNormalState: CGFloat = 128

            static let TitleFontOfAddButton: UIFont = UDFont.body0
            static let TitleFontOfEditButton: UIFont = UDFont.body0

            static let TitleInsetsOfAddButton: UIEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            static let TitleInsetsOfEditButton: UIEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        }

        static let SpaceBetweenTitleAreaAndEditArea: CGFloat = 12
    }
}

// MARK: - 点击热区
private final class CommonTitleHotAreaView: UIView {
    /// Redirect url
    var urlStr: String?

    /// 触碰事件
    var touchEvent: (() -> Void)?
    /// 完成点击
    var clickEvent: ((String) -> Void)?
    /// 取消点击
    var cancelEvent: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchEvent?()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let urlStr = urlStr { clickEvent?(urlStr) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelEvent?()
    }
}
