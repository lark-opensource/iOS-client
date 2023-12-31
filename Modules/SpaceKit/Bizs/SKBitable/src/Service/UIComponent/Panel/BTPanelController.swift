//
// Created by duanxiaochen.7 on 2021/3/14.
// Affiliated with SKBitable.
//
// Description:


import SKFoundation
import SKUIKit
import SKCommon
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignShadow
import SpaceInterface
import SKBrowser
import RxSwift
import RxCocoa

private extension BTPanelController {
    enum Layout {
        static let itemHeight: CGFloat = 48
        static var contentInset: UIEdgeInsets {
            UIEdgeInsets(horizontal: 0, vertical: 10)
        }
        static let headerFooterHeight: CGFloat = 6
        static func tableViewHeight(sectionsItems: [Int]) -> CGFloat {
            let sectionCount = CGFloat(sectionsItems.count)
            let itemCount = CGFloat(sectionsItems.reduce(0, +))
            return sectionCount * headerFooterHeight * 2
                + itemCount * itemHeight
                + contentInset.top + contentInset.bottom
        }
    }
}

final class BTPanelController: SKPanelController,
                               UITableViewDataSource,
                               UITableViewDelegate {

    // MARK: Info

    // swiftlint:disable:next weak_delegate
    private(set) lazy var btAdaptivePresentationDelegate: BTPanelAdaptivePresentationDelegate = BTPanelAdaptivePresentationDelegate.default
    
    weak var delegate: BTPanelDelegate?
    
    private var hostDocsInfo: DocsInfo?

    private var items: BTCommonDataModel = BTCommonDataModel(groups: [])

    private var bottomFixedItem: BTCommonItem?

    private(set) var callback: DocsJSCallBack?

    var hasNoticedDismissal = false

    var popoverDisappearBlock: (() -> Void)?
    
    weak var hostVC: UIViewController?
    
    weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?
    
    private var hasAppear = false //页面是否已经可见，避免在页面show的过程中触发布局更新导致crash
    
    
    private var params: BTPanelItemActionParams = BTPanelItemActionParams()
    
    private let bottomViewHeight: CGFloat = 80
    
    private var headerViewHeight: CGFloat {
        realHeaderView.getHeight()
    }
    
    private let preferredContentWidth: CGFloat = 375 // iPad popover模式下view的宽度

    // MARK: Subviews
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast,因为正文已经有了
        return preventer
    }()
    
    let disposeBag = DisposeBag()

    private var observation: NSKeyValueObservation? = nil

    private var realHeaderView: CommonListBaseHeaderView
    
    var shouldgroup: Bool {
        UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel && self.params.groupInfo != nil
    }

    // 有header的时候不希望吸顶。需要设置为grouped
    private lazy var tableView = UITableView(frame: .zero, style: shouldgroup ? .grouped : .plain).construct { it in
        #if canImport(ShazamKit)
        if #available(iOS 15.0, *) {
            it.fillerRowHeight = 0
            it.sectionHeaderTopPadding = 0
        }
        #endif
        it.dataSource = self
        it.delegate = self
        it.separatorStyle = .none
        it.backgroundColor = .clear
        it.contentInset = Layout.contentInset
        it.register(BTCommonItemCell.self, forCellReuseIdentifier: BTCommonItemCell.reuseIdentifier)
        it.register(BTCustomViewCell.self, forCellReuseIdentifier: BTCustomViewCell.reuseIdentifier)
    }

    private lazy var bottomView = BTPanelBottomView().construct { it in
        it.addTarget(self, action: #selector(didTapBottomFixedItem), for: .touchUpInside)
        it.backgroundColor = UDColor.bgFloat
    }
    
    private lazy var bottomSafeAreaView = UIView()
    
    ///字段描述view
    private lazy var fieldDetailView = BTDescriptionView(limitButtonFont:
                                                            BTFieldLayout.Const.fieldDescriptionFont,
                                                         bgColor: self.modalPresentationStyle == .popover ? UDColor.bgFloatBase.withAlphaComponent(0.9) : UDColor.bgFloatBase,
                                                         textViewDelegate: self,
                                                         limitButtonDelegate: self)
    
    //描述view信息
    private var viewDescriptionHeight: CGFloat = 0
    private var viewDescriptionAttrString: NSAttributedString?
    private var viewDescriptionShouldLimitDescriptionLines = true // 默认折叠
    
    private var minViewHeight: CGFloat = 172
    
    private var maxViewHeight: CGFloat {
        (hostVC?.view.window?.bounds.height ?? CGFloat.greatestFiniteMagnitude) * 0.8
    }
    
    private let baseContext: BaseContext
    private let basePermissionHelper: BasePermissionHelper


    // 从前端过来
    init(params: BTPanelItemActionParams, delegate: BTPanelDelegate?, hostVC: UIViewController, hostDocsInfo: DocsInfo?, baseContext: BaseContext) {
        self.delegate = delegate
        self.params = params
        self.hostVC = hostVC
        self.hostDocsInfo = hostDocsInfo
        self.bottomFixedItem = params.bottomFixedData
        self.callback = DocsJSCallBack(params.callback)
        self.baseContext = baseContext
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        self.realHeaderView = CommonListBaseHeaderView(model: params)
        super.init(nibName: nil, bundle: nil)
        self.items = dataTransForm(params)
        self.isFormSheet = UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel && params.modalPresentationStyle == "formSheet"
    }
    
    // 从native过来
    init(title: String,
         data: BTCommonDataModel,
         delegate: BTPanelDelegate?,
         hostVC: UIViewController,
         baseContext: BaseContext) {
        self.items = data
        self.delegate = delegate
        self.hostVC = hostVC
        self.baseContext = baseContext
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        self.params.title = title
        self.realHeaderView = CommonListBaseHeaderView(model: params)
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = []
        transitioningDelegate = panelTransitioningDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        let container: UIView
        if ViewCapturePreventer.isFeatureEnable {
            container = viewCapturePreventer.contentView
            self.containerView.addSubview(container)
            container.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            container = self.containerView
        }
        
        realHeaderView = getCustomHeadrView()
        container.addSubview(realHeaderView)
        realHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(headerViewHeight)
            make.left.equalTo(container.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(container.safeAreaLayoutGuide.snp.right)
        }
        realHeaderView.layer.ud.setShadow(type: .s4Up)
        if modalPresentationStyle != .popover {
            container.backgroundColor = UDColor.bgFloatBase
            realHeaderView.backgroundColor = UDColor.bgFloatBase
        } else {
            container.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
            realHeaderView.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
        }
        

        container.addSubview(bottomView)
        container.addSubview(bottomSafeAreaView)

        if let contentExtendModel = items.contentExtendModel,
           let extra = items.extra {
            let contentView = contentExtendModel.view(json: extra)
            container.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.top.equalTo(realHeaderView.snp.bottom)
                make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(containerView.safeAreaLayoutGuide.snp.right)
                make.bottom.equalTo(container.safeAreaLayoutGuide.snp.bottom)
            }
        } else {
            let estimateHeight = getEstimateTableViewHeight()
            container.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.top.equalTo(realHeaderView.snp.bottom)
                make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).inset(16)
                make.right.equalTo(containerView.safeAreaLayoutGuide.snp.right).inset(16)
                make.height.equalTo(estimateHeight).priority(.required)
                make.bottom.equalTo(bottomView.snp.top)
            }
        }

        bottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(bottomViewHeight)
            make.bottom.equalTo(container.safeAreaLayoutGuide.snp.bottom)
        }
        bottomSafeAreaView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(container.safeAreaLayoutGuide.snp.bottom)
            make.bottom.equalToSuperview()
        }
        updateContent()
        
        self.navigationController?.navigationBar.isHidden = true
        self.btAdaptivePresentationDelegate.willDismissBlock = { [weak self] in
            self?.handlePanelDismiss()
        }
    }

    private func shouldCustomContent() -> Bool {
        return items.contentExtendModel != nil && items.extra != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.basePermissionHelper.startObserve(observer: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) // 从外部网页退回到描述页面时要把导航栏隐藏
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppear = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hasAppear = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }
    
    override func transitionToRegularSize() {
        super.transitionToRegularSize()
        if modalPresentationStyle == .popover {
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, params.leftAction != nil {
                return
            }
            realHeaderView.setCloseButtonHidden(isHidden: true)
        }
    }

    override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        containerView.snp.makeConstraints { make in
            if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, self.params.modalPresentationStyle == "formSheet" {
                make.edges.equalToSuperview()
            } else {
            make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.8)
            }
            
        }
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, params.leftAction != nil {
            return
        }
        realHeaderView.setCloseButtonHidden(isHidden: false)
    }
    
    private func getCustomHeadrView() -> CommonListBaseHeaderView {
        let customHeaderMode = params.headerExtendMode ?? .DEFAULT_HEADER
        let customHeaderView = CommonListCustomViewMannger.shared.getHeadertView(by: customHeaderMode,
                                                                                 params: params) { [weak self] id in
            self?.handleHeaderViewClick(id: id)
        }
        return customHeaderView
    }
    
    private func updateCustomHeadrView(params: BTPanelItemActionParams) {
        realHeaderView.update(headerModel: params)
    }
    
    private func handleHeaderViewClick(id: String) {
        DocsLogger.info("handleHeaderViewClick, \(id)")
        if id == "exit" {
            didClickMask()
            return
        }
        delegate?.panelController(self, didSelectItemId: id, extra: nil)
    }

    private func updateUI() {
        if shouldCustomContent() {
            return
        }
        if !UserScopeNoChangeFG.ZJ.btShowPanelHeightFixDisable {
            tableView.layoutIfNeeded()
        }
        var estimateHeight = getEstimateTableViewHeight()
        tableView.snp.updateConstraints { make in
            make.height.equalTo(estimateHeight).priority(.required)
        }
        
        if modalPresentationStyle == .popover {
            estimateHeight = estimateHeight + headerViewHeight
            if bottomFixedItem != nil {
                estimateHeight = estimateHeight + bottomViewHeight
            }
            preferredContentSize = CGSize(width: preferredContentWidth, height: estimateHeight)
        }
    }
    
    private func getEstimateTableViewHeight() -> CGFloat {
        var minHeight = minViewHeight
        if modalPresentationStyle == .popover {
            minHeight = headerViewHeight + viewDescriptionHeight
        }
        var maxTableViewHeight = maxViewHeight - headerViewHeight - (hostVC?.view.safeAreaInsets.bottom ?? 0)
        var minTableViewHeight = minHeight - headerViewHeight - (hostVC?.view.safeAreaInsets.bottom ?? 0)
        if bottomFixedItem != nil {
            maxTableViewHeight = maxTableViewHeight - bottomViewHeight <= 0 ? maxTableViewHeight : maxTableViewHeight - bottomViewHeight
            minTableViewHeight = minTableViewHeight - bottomViewHeight <= 0 ? minTableViewHeight : minTableViewHeight - bottomViewHeight
        }
        
        let tableViewContentHeight = tableView.contentSize.height
        var estTableViewContentHeight: CGFloat = 0
        if (tableViewContentHeight == 0) {
            estTableViewContentHeight = Layout.tableViewHeight(sectionsItems: items.groups.map(\.items.count)) + viewDescriptionHeight
        } else {
            let contentInset = tableView.contentInset
            estTableViewContentHeight = tableViewContentHeight +
                                        contentInset.top +
                                        contentInset.bottom  +
                                        viewDescriptionHeight
        }
        
        let estimateHeight = min(estTableViewContentHeight, maxTableViewHeight)
        // 目前基于 independent 可以正常运行，满足一行一群需求
        // 调整为使用 heightPercent 之后无法通过测试，当业务需求需要使用 heightPercent 的时候在进行后续兼容开发，不耦合在一行一群中
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, params.independent == true {
            return maxTableViewHeight
        }
        return max(minTableViewHeight, estimateHeight)
    }

    private func updateContent() {
        if let item = bottomFixedItem {
            bottomView.isHidden = false
            bottomView.update(info: item)
            bottomView.snp.updateConstraints { make in
                make.height.equalTo(bottomViewHeight)
            }
            bottomSafeAreaView.backgroundColor = UDColor.bgFloat
        } else {
            bottomView.isHidden = true
            bottomView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            bottomSafeAreaView.backgroundColor = .clear
        }
    }

    private func dataTransForm(_ params: BTPanelItemActionParams) -> BTCommonDataModel {
        let items = params.groupedItems
        var groupItems: [BTCommonDataGroup] = [];
        countDescriptionViewHeight()
        if viewDescriptionHeight > 0, viewDescriptionAttrString != nil {
            groupItems.append(BTCommonDataGroup(groupName: "customView",
                                                items: [BTCommonDataItem(id: "customView",
                                                                         customCell: .init(reuseID: BTCustomViewCell.reuseIdentifier,
                                                                                           cellForRowProvider: { [weak self] (tableView, indexPath) in
                let cell = tableView.dequeueReusableCell(withIdentifier: BTCustomViewCell.reuseIdentifier, for: indexPath)
                if let customCell = cell as? BTCustomViewCell, let self = self {
                    customCell.setCustomView(view: self.fieldDetailView)
                    customCell.layoutIfNeeded()
                    DispatchQueue.main.async {
                        guard self.viewDescriptionHeight > 0,
                              let descriptionAttrString = self.viewDescriptionAttrString else { return }
                        self.fieldDetailView.setDescriptionText(descriptionAttrString, showingHeight: self.viewDescriptionHeight)
                    }
                    
                    return customCell
                }
                return cell
            }))]))
        }
        
        items.forEach { item in
            if let groupId = item.first?.groupId {
                let commonDataItems = item.map { panelItem in
                    var selectCallback: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)? = { [weak self] (_, id, useInfo) in
                        guard let self = self, let itemId = id else { return }
                        
                        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                            var extra: String?
                            if let userInfo = useInfo as? String {
                                extra = userInfo
                            }
                            self.delegate?.panelController(self, didSelectItemId: itemId, extra: extra)
                        } else {
                            self.delegate?.panelController(self, didSelectItemId: itemId, extra: nil)
                        }
                        
                    }
                    
                    var selectable = true
                    if !panelItem.enable {
                        selectCallback = nil
                    } else {
                        // 禁用按压态
                        selectable = (panelItem.leftStyle != .disable)
                    }
                    
                    var leftIcon: BTCommonDataItemIconInfo
                    if panelItem.leftIcon?.gif == BTGifIconStyle.loading {
                        let loadingIcon = UDIcon.loadingOutlined.ud.withTintColor(UDColor.N400);
                        leftIcon = BTCommonDataItemIconInfo(image: loadingIcon, size: CGSize(width: 20, height: 20), alignment: .top(offset: 0), customRender: { imageView in
                            BTUtil.startRotationAnimation(view: imageView)
                        })
                    } else {
                        var customRender: ((_ imageView: UIView) -> Void)? = nil
                        if panelItem.leftIconImage != nil {
                            customRender = { imageView in
                                BTUtil.stopRotationAnimation(view: imageView)
                            }
                        }
                        leftIcon = BTCommonDataItemIconInfo(image: panelItem.leftIconImage, size: CGSize(width: 20, height: 20), customRender: customRender)
                    }
                    
                    var commonDataItem =  BTCommonDataItem(id: panelItem.id,
                                                           selectable: selectable,
                                                           selectCallback: selectCallback,
                                                           leftIcon: leftIcon,
                                                           leftIconTag: .init(image: panelItem.leftIconTagImage, size: CGSize(width: 12, height: 12)),
                                                           mainTitle: .init(text: panelItem.leftText, color: panelItem.leftTextColor),
                                                           subTitle: .init(text: panelItem.desc, lineNumber: 0),
                                                           rightInfo: .init(text: panelItem.rightText, color: panelItem.rightTextColor),
                                                           rightIcon: .init(image: panelItem.rightIconImage, size: CGSize(width: 20, height: 20)),
                                                           tagText: panelItem.tagText)
                    if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
                        
                        if let checkbox = panelItem.checkbox {
                            commonDataItem.checkbox = checkbox.value
                        }
                        
                        if let editable = panelItem.editable {
                            commonDataItem.editable = editable
                        }
                        
                        if let isSync = panelItem.leftIcon?.isSync {
                            commonDataItem.isSync = isSync
                        }
                        
                        if let placeholder = panelItem.placeholder {
                            commonDataItem.placeholder = placeholder
                        }
                        
                    }
                    return commonDataItem
                }
                groupItems.append(BTCommonDataGroup(groupName: groupId, items: commonDataItems))
            }
        }
        
        return BTCommonDataModel(groups: groupItems, contentExtendModel: params.contentExtendModel, extra: params.extra)
    }
    
    func reload(params: BTPanelItemActionParams) {
        guard hasAppear else {
            DocsLogger.btError("[BTPanelController] view not appear can not update")
            return
        }
        updateCustomHeadrView(params: params)
        items = dataTransForm(params)
        bottomFixedItem = params.bottomFixedData
        callback = DocsJSCallBack(params.callback)
        updateContent()
        tableView.reloadData()
    }
    
    func countDescriptionViewHeight() {
        guard let content = params.desc,
              !content.isEmpty else { return }
        var fullDescHeight: CGFloat = 0
        self.viewDescriptionAttrString = BTUtil.convert(content, font: BTFieldLayout.Const.fieldDescriptionFont)

        if let descriptionAttrText = viewDescriptionAttrString {
            var viewWidth = hostVC?.view.frame.width ?? self.view.frame.width
            if modalPresentationStyle == .popover {
                viewWidth = preferredContentWidth
            }
            fullDescHeight = calculateTextHeight(descriptionAttrText, inWidth: viewWidth - 32)
        } else {
            return
        }
        let lineHeight = BTFieldLayout.Const.fieldDescriptionFont.figmaHeight
        if fullDescHeight <= BTDescriptionView.maxNumberOfLines * lineHeight && !viewDescriptionShouldLimitDescriptionLines {
            // 在竖屏时点击了展开，转到横屏时可能由于宽度足够不再需要展示 limit button，这种情况下需要修正 flag，不然横屏下就会多出来收起按钮
            viewDescriptionShouldLimitDescriptionLines = true
        }
        let descriptionHeight: CGFloat
        if viewDescriptionShouldLimitDescriptionLines {
            descriptionHeight = min(fullDescHeight, BTDescriptionView.maxNumberOfLines * lineHeight)
        } else {
            descriptionHeight = fullDescHeight + lineHeight // 多出来的一行是收起按钮
        }
        self.viewDescriptionHeight = descriptionHeight
    }
    
    func calculateTextHeight(_ attrString: NSAttributedString, inWidth width: CGFloat, numberOfLines: Int = 0) -> CGFloat {
        let textView = BTFieldLayout.textHeightCalculator
        textView.attributedText = attrString
        textView.textContainer.maximumNumberOfLines = numberOfLines
        let textViewHeight = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return ceil(textViewHeight)
    }
    
    private func openURLByVCFollowIfNeed(_ url: URL, _ isNeedTransOrientation: Bool) -> Bool {
        let handler: () -> Void = {
            self.dismiss(animated: false) {
                if isNeedTransOrientation {
                    BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
                }
            }
        }
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: hostVC,
                                                   followDelegate: nil,
                                                   handler: SKDisplay.pad ? nil : handler) {
            //先判断DocComponent是否拦截
            return true
        }
        
        guard let followAPIDelegate = self.spaceFollowAPIDelegate else {
            return false
        }
        if SKDisplay.pad {
            followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: url.absoluteString)))
        } else {
            followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrlWithHandlerBeforeOpen(url: url.absoluteString, handler: handler)))
        }
        return true
    }

    @objc
    override func didClickMask() {
        popoverDisappearBlock?()
        delegate?.panelControllerDidTapDismissZone(self)
        self.dismiss(animated: true)
    }

    @objc
    private func didTapBottomFixedItem() {
        guard let bottomFixedItem = bottomFixedItem else { return }
        delegate?.panelController(self, didSelectItemId: bottomFixedItem.id, extra: nil)
    }

    // 由于在 deinit 里面有一些操作，导致 MLeakFinder 误报内存泄漏。事实上是不会泄漏的，我用 memory graph 验证过了
    @objc
    func willDealloc() -> Bool {
        return false
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
    
    private func handlePanelDismiss()  {
        popoverDisappearBlock?()
        if !hasNoticedDismissal {
            DocsLogger.btInfo("BTPanelController deinit: 需要通知前端主动 dismiss 一遍")
            delegate?.panelControllerDidTapDismissZone(self)
        }
    }
    
    deinit {
        handlePanelDismiss()
    }
    // MARK: - TableView Protocol Conformances,  UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        items.groups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < items.groups.count else { return 0 }
        return items.groups[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = items.groups[indexPath.section]
        let item = items.groups[indexPath.section].items[indexPath.row]
        
        if group.groupName == "customView", let customCell = item.customCell {
            return customCell.cellForRowProvider(tableView, indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BTCommonItemCell.reuseIdentifier, for: indexPath)
        guard let panelCell = cell as? BTCommonCell else {
            assertionFailure()
            return cell
        }
        panelCell.update(item: item, group: items.groups[indexPath.section], indexPath: indexPath)
        return panelCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, let groupedItem = params.groupedItems.safe(index: section) {
            if let groupedItemID = groupedItem.first?.groupId {
                if let info = params.groupInfo {
                    var groupName: String?
                    info.forEach { element in
                        if element.groupId == groupedItemID {
                            groupName = element.groupName
                        }
                    }
                    if let _ = groupName {
                        return 34
                    }
                }
            }
        }
        return Layout.headerFooterHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        Layout.headerFooterHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, let groupedItem = params.groupedItems.safe(index: section) {
            if let groupedItemID = groupedItem.first?.groupId {
                if let info = params.groupInfo {
                    var groupName: String?
                    info.forEach { element in
                        if element.groupId == groupedItemID {
                            groupName = element.groupName
                        }
                    }
                    if let groupName = groupName {
                        let view = PanelSectionHeader(text: groupName)
                        view.backgroundColor = UDColor.bgFloatBase
                        return view
                    }
                }
            }
        }
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = items.groups[indexPath.section]
        
        if group.groupName == "customView" {
            return viewDescriptionHeight
        }
        
        return UITableView.automaticDimension
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel else {
            return
        }
        var hasInput = false
        params.data.forEach { item in
            if item.editable == true {
                hasInput = true
            }
        }
        let item = items.groups[indexPath.section].items[indexPath.row]
        // cell中有input输入框且点击的不是input，就需要收起键盘
        if hasInput, item.editable != true {
            view.endEditing(true)
        }
    }

//    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) as? BTCommonCell else {
//            return
//        }
//        cell.update(isHighlighted: true)
//    }

//    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) as? BTCommonCell else {
//            return
//        }
//        cell.update(isHighlighted: false)
//    }
}

extension BTPanelController {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}

extension BTPanelController: BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BTPanelController initOrUpdateCapturePermission \(hasCapturePermission)")
        setCaptureAllowed(hasCapturePermission)
    }
}

extension BTPanelController: BTReadOnlyTextViewDelegate,
                             BTDescriptionViewDelegate {
    func readOnlyTextView(_ textView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        //描述字段内链接点击处理
        guard let hostDocsInfo = hostDocsInfo else { return }
        let attributes = BTUtil.getAttributes(in: textView, sender: sender)
        let hostVC = hostVC ?? self
        BTUtil.didTapView(hostVC: hostVC,
                          hostDocsInfo: hostDocsInfo,
                          needFullScreen: false,
                          withAttributes: attributes,
                          openURLByVCFollowIfNeed: openURLByVCFollowIfNeed)
    }
    
    func toggleLimitMode(to: Bool) {
        //点击展开/收起后更新面板高度
        viewDescriptionShouldLimitDescriptionLines = to
        countDescriptionViewHeight()
        tableView.reloadData()
    }
}

// 监听willDisMiss时机
public final class BTPanelAdaptivePresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {

    public var willDismissBlock: (() -> Void)?

    public static var `default`: BTPanelAdaptivePresentationDelegate {
        return BTPanelAdaptivePresentationDelegate()
    }
    
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        willDismissBlock?()
    }
}


final class BTCustomViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomView(view: UIView?) {
        guard let view = view, view.superview == nil else {
            return
        }

        contentView.addSubview(view)

        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
