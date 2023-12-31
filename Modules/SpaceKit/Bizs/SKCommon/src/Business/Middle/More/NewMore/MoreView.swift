//
//  MoreView.swift
//  SKCommon
//
//  Created by lizechuang on 2021/2/28.
//
// swiftlint:disable file_length type_body_length

import SKFoundation
import SKUIKit
import RxSwift
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import LarkSetting
import UIKit
import SKInfra
import LarkDocsIcon
import LarkContainer

public protocol MoreViewDelegate: AnyObject {
    func didClickMaskErea()
    // 选中item，当item为mSwitch类型是isSwitchOn才有意义
    func didClick(_ item: ItemsProtocol, isSwitchOn: Bool)
    // MoreViewV2RightButtonCell.Style 用于判断点击右侧还是点击左侧
    func didClick(_ item: ItemsProtocol, isSwitchOn: Bool, style: MoreViewV2RightButtonCell.Style)
}

public final class MoreView: UIButton {

    private var reuseBag = DisposeBag()

    struct Layout {
        static let manageCellHeight: CGFloat = 110
        static let nomalInfoCellHeight: CGFloat = 52
        static let headerHeight: CGFloat = 72
        static let collectionViewBottomInset: CGFloat = 24
        static let verticalHeaderViewHeight: CGFloat = 36
    }

    let draggable: Bool
    var bottomSafeAreaHeight: CGFloat {
        didSet {
            if bottomSafeAreaHeight != oldValue {
                resetHeight(orentation: UIApplication.shared.statusBarOrientation)
            }
        }
    }
    var realTopContainerHeight: CGFloat
    
    var isShowSentivePerm: Bool = false

    private lazy var contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    private lazy var blurBgView: SKBlurEffectView = {
        let view = SKBlurEffectView()
        view.set(cornerRadius: 12, corners: .top)
        view.updateMaskColor(isPopover: !draggable)
        return view
    }()

    private lazy var headerView = UIView()
    private lazy var typeImageView = UIImageView()
    /// cell 自定义icon
    private lazy var iconImageView: AvatarImageView = {
        let imageView = AvatarImageView(frame: CGRect.zero)
        imageView.contentMode = .top
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    private lazy var templateTag = TemplateTag()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UDColor.textCaption
        return label
    }()

    // 文档新鲜度图标
    private lazy var freshInfoIcon: UIImageView = {
        let v = UIImageView()
        v.isHidden = true
        return v
    }()
    // 分割线
    private lazy var seperatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.lineDividerDefault
        v.isHidden = true
        return v
    }()
    // 文档新鲜度信息
    private lazy var freshInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UDColor.textCaption
        label.isHidden = true
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = SKHighlightButton()
        button.imageEdgeInsets = UIEdgeInsets(edges: 5)
        button.setImage(UDIcon.closeBoldOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.normalBackgroundColor = UDColor.udtokenTagNeutralBgNormal
        button.highlightBackgroundColor = UDColor.udtokenTagNeutralBgNormalPressed
        return button
    }()

    private lazy var headerBottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private lazy var shortcutImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.wikiShortcutarrowColorful
        return imageView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        tableView.register(MoreViewV2ManageCell.self, forCellReuseIdentifier: MoreViewV2ManageCell.reuseIdentifier)
        tableView.register(MoreViewV2NormalCell.self, forCellReuseIdentifier: MoreViewV2NormalCell.reuseIdentifier)
        tableView.register(MoreViewV2SwitchCell.self, forCellReuseIdentifier: MoreViewV2SwitchCell.reuseIdentifier)
        tableView.register(MoreViewV2RightLabelCell.self, forCellReuseIdentifier: MoreViewV2RightLabelCell.reuseIdentifier)
        tableView.register(MoreViewV2RightIndicatorCell.self, forCellReuseIdentifier: MoreViewV2RightIndicatorCell.reuseIdentifier)
        tableView.register(MoreViewV2RightButtonCell.self, forCellReuseIdentifier: MoreViewV2RightButtonCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.reuseIdentifier)
        return tableView
    }()

    private weak var hostViewController: UIViewController?

    // 暂时妥协保留后续抽离Pano再统一处理
    public var docsInfo: DocsInfo

    // 记录特殊cell用于引导,默认只有一个
    private var onboardingItemType: MoreItemType?
    private weak var needShowOnboardingCell: UITableViewCell?
    private var needShowOnboardingIndexPath: IndexPath?

    public var dataSource: [MoreSection]

    public weak var delegate: MoreViewDelegate?

    // 显示数据
    var owner: String?
    var readingDataInfo: MoreReadingDataInfo?

    // 高度相关
    var totalMaxHeight: CGFloat = 0 // 动态计算出来的最大高度
    var startMaxHeight: CGFloat {
        return SKDisplay.activeWindowBounds.height * 0.75
    }
    var startY: CGFloat = 0
    var startHeight: CGFloat = 0

    let dismissOffset: CGFloat = 30

    var lastDragY: CGFloat = 0
    var lastStayY: CGFloat = 0
    public lazy var panGestureRecognizer: UIPanGestureRecognizer = { // 拖动手势
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        return panGestureRecognizer
    }()

    public init(frame: CGRect,
                sectionData: [MoreSection], docsInfo: DocsInfo,
                draggable: Bool = true,
                bottomSafeAreaHeight: CGFloat, realTopContainerHeight: CGFloat,
                from hostViewController: UIViewController) {
        self.dataSource = sectionData
        self.docsInfo = docsInfo
        self.draggable = draggable
        self.hostViewController = hostViewController
        self.bottomSafeAreaHeight = bottomSafeAreaHeight
        self.realTopContainerHeight = realTopContainerHeight
        super.init(frame: frame)
        setupDefualtValue()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.scrollToTop()
    }
    
    private func setupDefualtValue() {
        self.backgroundColor = .clear
        self.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)
        contentView.layer.cornerRadius = draggable ? 12 : 0
        if draggable {
            headerView.addGestureRecognizer(panGestureRecognizer)
        }
    }

    public func setupSubviews() {
        contentView.addSubview(headerView)
        contentView.addSubview(tableView)
        contentView.addSubview(headerBottomLineView)

        let containerView = headerView
        containerView.addSubview(typeImageView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(shortcutImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(templateTag)
        containerView.addSubview(infoLabel)
        containerView.addSubview(seperatorLine)
        containerView.addSubview(freshInfoIcon)
        containerView.addSubview(freshInfoLabel)
        containerView.addSubview(closeButton)
        closeButton.isHidden = !draggable
        closeButton.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: reuseBag)
        if OpenAPI.enableTemplateTag(docsInfo: docsInfo) {
            templateTag.isHidden = !OpenAPI.showTemplateTag(docsInfo: docsInfo)
        } else {
            templateTag.isHidden = true
        }

        setupConstraits()
    }

    private func setupConstraits() {
        resetHeight(orentation: UIApplication.shared.statusBarOrientation)
        insertSubview(blurBgView, belowSubview: contentView)
        if draggable {
            blurBgView.snp.makeConstraints { make in
                make.edges.equalTo(contentView)
            }
        } else {
            blurBgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(contentView.safeAreaLayoutGuide)
            make.height.equalTo(Layout.headerHeight)
        }
        headerBottomLineView.snp.makeConstraints { (make) in
            make.left.right.equalTo(contentView.safeAreaLayoutGuide)
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(0.5)
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            if draggable {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(contentView.safeAreaLayoutGuide)
            }
            make.left.right.equalTo(contentView.safeAreaLayoutGuide)
        }

        typeImageView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().inset(18)
            make.width.height.equalTo(40)
        }
        typeImageView.layer.masksToBounds = true
        iconImageView.snp.makeConstraints { (make) in
            make.center.equalTo(typeImageView)
            make.width.height.equalTo(40)
        }
        iconImageView.layer.cornerRadius = 20
        iconImageView.layer.masksToBounds = true

        nameLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.left.equalTo(typeImageView.snp.right).offset(10)
            make.top.equalToSuperview().inset(16)
        }
        templateTag.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(4)
            make.centerY.equalTo(nameLabel)
            make.right.lessThanOrEqualTo(closeButton.snp.left).offset(-12)
            make.width.equalTo(templateTag.intrinsicContentSize.width)
        }
        
        infoLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(20)
        }
        seperatorLine.snp.makeConstraints { make in
            make.left.equalTo(infoLabel.snp.right).offset(8)
            make.width.equalTo(1)
            make.height.equalTo(12)
            make.centerY.equalTo(infoLabel.snp.centerY)
        }
        freshInfoIcon.snp.makeConstraints { make in
            make.left.equalTo(seperatorLine.snp.right).offset(8)
            make.width.height.equalTo(14)
            make.centerY.equalTo(infoLabel.snp.centerY)
        }
        freshInfoLabel.snp.makeConstraints { make in
            make.left.equalTo(freshInfoIcon.snp.right).offset(5)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.centerY.equalTo(infoLabel.snp.centerY)
        }
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.right.equalToSuperview().inset(16)
        }
        shortcutImageView.snp.makeConstraints { make in
            make.center.equalTo(typeImageView)
            make.height.width.equalTo(typeImageView)
        }
        closeButton.layer.cornerRadius = 12
        closeButton.clipsToBounds = true
        closeButton.hitTestEdgeInsets = UIEdgeInsets(edges: -8)
        closeButton.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)
    }

    public func resetHeight(orentation: UIInterfaceOrientation) {
        if contentView.superview == nil {
            addSubview(contentView)
        }
        layoutIfNeeded()
        if SKDisplay.phone, orentation.isLandscape {
            contentView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(0.7)
                make.top.equalToSuperview().inset(bottomSafeAreaHeight + 11)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            self.startY = bottomSafeAreaHeight + 11
            totalMaxHeight = frame.height - startY
        } else {
            var totalHeight = Self.calculateHeight(self.dataSource) + bottomSafeAreaHeight

            totalMaxHeight = min(totalHeight, frame.height - realTopContainerHeight)

            totalHeight = min(totalHeight, startMaxHeight)
            startHeight = totalHeight
            self.startY = draggable ? frame.height - totalHeight : 0
            contentView.snp.remakeConstraints { (make) in
                make.top.equalTo(self.startY)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        lastStayY = startY
    }

    public func reloadData() {
        tableView.reloadData()
    }
    
    private func scrollToTop() {
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
    }

    public func config(with docsInfo: DocsInfo) {
        setIconInfoToImageView(with: docsInfo)
        if docsInfo.isVersion {
            nameLabel.text = docsInfo.versionInfo?.name ?? ""
        } else {
            nameLabel.text = docsInfo.name
        }
        self.owner = {
            if docsInfo.ownerDisplayName.count > 0 {
                return docsInfo.ownerDisplayName
            } else {
                return docsInfo.displayName
            }
        }()
        if docsInfo.isShortCut {
            infoLabel.text = BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder
        } else {
            updateInfoLabel()
        }
    }

    public func setIconInfoToImageView(with docsInfo: DocsInfo) {
        docsInfo.getActualFileEntry { [weak self] file in
            self?.setIconInfoToImageView(docsInfo: docsInfo, file: file)
        }
    }

    private func setIconInfoToImageView(docsInfo: DocsInfo, file: SpaceEntry) {
        var isShowIconImageView = false
        if let customIcon = docsInfo.customIcon,
           customIcon.iconType.isCurSupported {
            isShowIconImageView = true
            iconImageView.set(avatarKey: customIcon.iconKey,
                              fsUnit: customIcon.iconFSUnit,
                              placeholder: file.defaultIcon,
                              image: nil) { _ in
            }
        } else {
            /// file是根据objToken获取的本体的entry, 无法判断是否是shortCut, 需要在此处根据docInfo额外判断
            var container = ContainerInfo(isShortCut: file.isShortCut, isShareFolder: file.isShareFolder)
            if docsInfo.isShortCut && docsInfo.type == .folder {
                container.isShareFolder = true
            }
            typeImageView.di.setDocsImage(iconInfo: file.iconInfo ?? "",
                                          token: file.realToken,
                                          type: file.realType,
                                          container: container,
                                          userResolver: Container.shared.getCurrentUserResolver())
        }
        iconImageView.isHidden = !isShowIconImageView
        typeImageView.isHidden = isShowIconImageView
        shortcutImageView.isHidden = !docsInfo.isShortCut
    }

    public func update(readingDataInfo: MoreReadingDataInfo) {
        self.readingDataInfo = readingDataInfo
        updateInfoLabel()
    }
    
    public func updateTemplateTag(isShow: Bool) {
        templateTag.isHidden = !isShow
        if isShow {
            nameLabel.snp.remakeConstraints { (make) in
                make.height.equalTo(24)
                make.left.equalTo(typeImageView.snp.right).offset(10)
                make.top.equalToSuperview().inset(16)
            }
            templateTag.snp.remakeConstraints { make in
                make.left.equalTo(nameLabel.snp.right).offset(4)
                make.centerY.equalTo(nameLabel)
                make.right.lessThanOrEqualTo(closeButton.snp.left).offset(-12)
                make.width.equalTo(templateTag.intrinsicContentSize.width)
            }
        } else {
            nameLabel.snp.remakeConstraints { (make) in
                make.height.equalTo(24)
                make.left.equalTo(typeImageView.snp.right).offset(10)
                make.top.equalToSuperview().inset(16)
                if closeButton.isHidden {
                    make.right.equalToSuperview().offset(-16)
                } else {
                    make.right.lessThanOrEqualTo(closeButton.snp.left).offset(-12)
                }
            }
            templateTag.snp.remakeConstraints { make in
//                make.left.equalTo(nameLabel.snp.right).offset(4)
                make.centerY.equalTo(nameLabel)
                make.right.lessThanOrEqualTo(closeButton.snp.left).offset(-12)
                make.width.equalTo(0)
            }
        }
    }

    private func updateInfoLabel() {
        if docsInfo.isShortCut {
            infoLabel.text = BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder
            return
        }
        
        if docsInfo.isVersion,
           let updatetime = docsInfo.versionInfo?.create_time,
           let name = docsInfo.versionInfo?.localizedCreateName {
            let time = Double(updatetime).stampDateFormatter
            let realStr = name
            infoLabel.text = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_SavernTime_Tooltip(realStr, time)
            return
        }
        guard let ownerName = self.owner else { return }

        var infoString = ""
        if let wordCount = self.readingDataInfo?.wordCount {
            infoString += "\(BundleI18n.SKResource.Doc_Facade_WordsCount)\(wordCount)  "
        }
        if let readingCount = self.readingDataInfo?.readingCount {
            infoString += "\(BundleI18n.SKResource.Doc_Facade_ReadingCount)\(readingCount)  "
        }

        infoString += BundleI18n.SKResource.Doc_Facade_Owner + ownerName

        // 更新文档新鲜度相关信息
        updateFreshInfo(infoStr: &infoString)

        infoLabel.text = infoString
    }

    private func updateFreshInfo(infoStr: inout String) {
        guard let ownerName = self.owner else { return }
        if let freshInfo = docsInfo.freshInfo,
           freshInfo.shouldShowFreshStatusLabel(isInTopBar: true),
           docsInfo.isSameTenantWithOwner {
            infoStr = BundleI18n.SKResource.Doc_Facade_Owner + ownerName
            seperatorLine.isHidden = false
            freshInfoIcon.isHidden = false
            freshInfoLabel.isHidden = false
            freshInfoLabel.text = freshInfo.freshStatus.name
            freshInfoIcon.image = freshInfo.freshStatus.icon
        } else {
            DocsLogger.info("MoreView: no show freshInfo, isSameTenant: \(docsInfo.isSameTenantWithOwner)")
            seperatorLine.isHidden = true
            freshInfoIcon.isHidden = true
            freshInfoLabel.isHidden = true
        }
    }

    public func setOnboardingItemType(_ itemType: MoreItemType) {
        self.onboardingItemType = itemType
    }

    public func obtainOnboardingCellInfo() -> CGRect? {
        guard let cell = needShowOnboardingCell, let indexPath = needShowOnboardingIndexPath else {
            return nil
        }
        // 首先判断onboardCell是否在显示范围
        let visibleHeight = self.tableView.frame.height
        let targetHeight = cell.frame.height + cell.frame.minY
        if targetHeight > visibleHeight {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
        return cell.convert(cell.bounds, to: nil)
    }
}

// MARK: - UITableViewDataSource & UITableViewDataSource
extension MoreView: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let data = self.dataSource[section]
        switch data.sectionType {
        case .horizontal:
            return 1
        case .verticalSection:
            return data.items.count
        }
    }

    // swiftlint:disable cyclomatic_complexity
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.dataSource[indexPath.section]
        switch data.sectionType {
        case .horizontal:
            let cell = tableView.dequeueReusableCell(withIdentifier: MoreViewV2ManageCell.reuseIdentifier, for: indexPath)
            guard let manageCell = cell as? MoreViewV2ManageCell else {
                return cell
            }
            manageCell.delegate = self
            manageCell.update(items: data.items)
            return manageCell
        case .verticalSection:
            let row = indexPath.row
            guard row >= 0, row < data.items.count else {
                DocsLogger.info("MoreViewV2 info组 找不到目标section:\(indexPath.section), index:\(row),数据源总数：\(data.items.count)")
                return MoreViewV2NormalCell()
            }
            let item = data.items[row]
            if item.type == .sensitivtyLabel {
                isShowSentivePerm = true
            }
            let cell: UITableViewCell
            switch item.style {
            case .normal:
                cell = tableView.dequeueReusableCell(withIdentifier: MoreViewV2NormalCell.reuseIdentifier, for: indexPath)
            case .mSwitch:
                var reuseIdentifier = MoreViewV2SwitchCell.reuseIdentifier
                let switchIdentifier = item.type.switchIdentifier
                if !switchIdentifier.isEmpty {
                    reuseIdentifier += "_\(switchIdentifier)"
                    let switchCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
                    if let switchCell = switchCell {
                        cell = switchCell
                    } else {
                        tableView.register(MoreViewV2SwitchCell.self, forCellReuseIdentifier: reuseIdentifier)
                        cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
                    }
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
                }
            case .rightLabel:
                cell = tableView.dequeueReusableCell(withIdentifier: MoreViewV2RightLabelCell.reuseIdentifier, for: indexPath)
            case .rightIndicator:
                cell = tableView.dequeueReusableCell(withIdentifier: MoreViewV2RightIndicatorCell.reuseIdentifier, for: indexPath)
            case .mButton:
                cell = tableView.dequeueReusableCell(withIdentifier: MoreViewV2RightButtonCell.reuseIdentifier, for: indexPath)
            }

            guard let normalCell = cell as? MoreViewV2NormalCell else {
                return cell
            }
            var corners: CACornerMask = []
            if row == 0 {
                corners.insert(.top)
            }
            if row == (data.items.count - 1) {
                corners.insert(.bottom)
                normalCell.seperatorView.isHidden = true
            }
            normalCell.roundingCorners = corners
            if item.type.shouldShowNewTag {
                normalCell.showRedPoint(false)
                normalCell.showOnBoardingView(item.needNewTag)
            } else {
                normalCell.showRedPoint(item.needNewTag)
                normalCell.showOnBoardingView(false)
            }
            normalCell.showSubPageArrow(item.hasSubPage)
            normalCell.update(isEnabled: item.state != .disable)
            normalCell.update(title: item.title, image: item.image)
            
            if let switchCell = normalCell as? MoreViewV2SwitchCell {
                if case let .mSwitch(on, needLoading) = item.style {
                    switchCell.setCurrentSwitchValue(on)
                    switchCell.needLoading = needLoading
                } else {
                    spaceAssertionFailure()
                }
                switchCell.switchOnClosure = { [weak self] isOn in
                    self?.delegate?.didClick(item, isSwitchOn: isOn)
                }
            }
            // MoreViewV2RightButtonCell 点击cell 与 点击右侧的Button各有一个点击事件
            if let buttonCell = normalCell as? MoreViewV2RightButtonCell {
                if case .mButton(let title) = item.style {
                    buttonCell.update(rightTitle: title)
                    buttonCell.updateRightLabel(isEnabled: item.state != .disable)
                }
                buttonCell.switchOnClosure = { [weak self] style in
                    self?.delegate?.didClick(item, isSwitchOn: false, style: style)
                }
            }

            if let rightLabelCell = normalCell as? MoreViewV2RightLabelCell {
                if case .rightLabel(let title) = item.style {
                    rightLabelCell.update(rightTitle: title)
                } else {
                    rightLabelCell.update(rightTitle: "")
                }
            }

            if let rightLabelCell = normalCell as? MoreViewV2RightIndicatorCell {
                if case .rightIndicator(let icon, let title) = item.style {
                    rightLabelCell.update(rightTitle: title, rightIndicator: icon)
                }
            }

            if let onboardingItemType = self.onboardingItemType, item.type == onboardingItemType {
                self.needShowOnboardingCell = cell
                self.needShowOnboardingIndexPath = indexPath
            }
            return normalCell
        }
    }
}

extension MoreView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let items = dataSource[indexPath.section]
        switch items.sectionType {
        case .horizontal:
            let item = items.items[indexPath.row]
            self.delegate?.didClick(item, isSwitchOn: false)
        case .verticalSection:
            let item = items.items[indexPath.row]
            guard !item.style.isSwitch else { // 默认mSwitch无需响应
                return
            }
            // 如果点击的是 mButton类型，需要告诉外面是left点击还是right点击，因为这种cell有两种点击事件
            if item.style.isRightButton {
                self.delegate?.didClick(item, isSwitchOn: false, style: .left)
            } else {
                self.delegate?.didClick(item, isSwitchOn: false)
            }
        }
    }

    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MoreViewV2NormalCell else {
            return
        }
        cell.update(isHighlighted: true)
    }

    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MoreViewV2NormalCell else {
            return
        }
        cell.update(isHighlighted: false)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let data = self.dataSource[indexPath.section]
        switch data.sectionType {
        case .horizontal:
            return Layout.manageCellHeight
        case .verticalSection:
            return Layout.nomalInfoCellHeight
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let data = self.dataSource[section]
        switch data.sectionType {
        case .horizontal:
            return nil
        case let .verticalSection(verticalType):
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: MoreHeaderView.reuseIdentifier) ?? MoreHeaderView(reuseIdentifier: MoreHeaderView.reuseIdentifier)
            guard let headerView = headerView as? MoreHeaderView, let verticalType = verticalType else {
                // group style类型的tableview, 在多个section的时候会自动在多个section之间加一段padding，因此添加一个view且高度为0去除这个padding
                let view = UIView()
                view.backgroundColor = .clear
                return view
            }
            headerView.setupLabelTitle(verticalType.sectionText)
            return headerView
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let data = self.dataSource[section]
        switch data.sectionType {
        case .horizontal:
            return 0
        case let .verticalSection(verticalType):
            guard verticalType != nil else {
                return 0
            }
            return 36
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let data = self.dataSource[section]
        switch data.sectionType {
        case .horizontal:
            return nil
        case .verticalSection:
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let data = self.dataSource[section]
        switch data.sectionType {
        case .horizontal:
            return 0.01
        case .verticalSection:
            return 12
        }
    }
}

extension MoreView: MoreViewManageCellDelegate {
    func didClick(_ item: ItemsProtocol) {
        self.delegate?.didClick(item, isSwitchOn: false)
    }
}

// MARK: - calculate
extension MoreView {
    private static func calculateHeight(_ datas: [MoreSection]) -> CGFloat {
        var totalHeight = Layout.headerHeight
        for data in datas {
            switch data.sectionType {
            case .horizontal:
                totalHeight += Layout.manageCellHeight
            case .verticalSection(let verticalType):
                totalHeight += CGFloat(data.items.count) * Layout.nomalInfoCellHeight
                if verticalType != nil {
                    totalHeight += Layout.verticalHeaderViewHeight
                }
            }
        }
        totalHeight += 8 // tableView bottomInset
        return totalHeight
    }

    public func calculateRealHeight() -> CGFloat {
        let contentHeight = Self.calculateHeight(self.dataSource)
        if !draggable {
            // popover 场景给底部预留一部分空间
            return contentHeight + Layout.collectionViewBottomInset
        } else {
            return contentHeight
        }
    }
}

// MARK: - Private Method
extension MoreView {
    @objc
    private func didClickMaskView() {
        self.delegate?.didClickMaskErea()
    }

    private func dismiss() {
        didClickMaskView()
    }

    @objc
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        let state = gestureRecognizer.state

        let yTranslation = gestureRecognizer.translation(in: self).y // 上拖：负，下拉：正
        if self.lastDragY == 0 {
            self.lastDragY = yTranslation
        }

        let offsetY = yTranslation - self.lastDragY
        self.lastDragY = yTranslation

        let curY = contentView.frame.minY
        var targetY = curY + offsetY

        switch state {
        case .began:
            ()
//            startDragY = targetY
        case .changed:
            if targetY < frame.height - totalMaxHeight {
                targetY = frame.height - totalMaxHeight
            } else if targetY > frame.height - Layout.headerHeight {
                // 往下拖的时候，不能太低了
                targetY = frame.height - Layout.headerHeight
            }
            resetWhiteBgView(with: targetY)

        case .ended, .cancelled, .failed:

            guard targetY != startY else { return }

            if targetY > startY + dismissOffset { // 拖动低于最低高度，消失
                if yTranslation > 0 {
                    dismiss()
                } else {
                    targetY = startY
                }
            } else if targetY <= startY + dismissOffset, targetY > startY { // 拖动高于最低高度，但是低于起始位置，重置回起始位置
                targetY = startY
            } else if targetY > lastStayY { // 拖动高度位于起始位置和最大高度之间，但是是向下拖动的，说明是从最高点向下拉，回到初始位置
                targetY = startY
            } else { // 否则，就是从初始位置向上拖动，显示最大高度
                targetY = frame.height - totalMaxHeight
            }
            lastStayY = targetY

            resetWhiteBgView(with: targetY)
        default:()
        }
    }

    private func resetWhiteBgView(with targetY: CGFloat) {
        contentView.snp.updateConstraints { (make) in
            make.top.equalTo(targetY)
        }

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.superview?.layoutIfNeeded()
        }, completion: { _ in

        })
    }
}
