//
//  BlockCatalogueContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/28.
//

import SKUIKit
import LarkUIKit
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import RxSwift
import RxDataSources
import UniverseDesignEmpty
import UniverseDesignFont
import SKCommon

protocol BlockCatalogueContainerDelegate: AnyObject {
    func blockContainerRequestHide()
}

private struct Const {
    static let cornerRadius: CGFloat = 8 // 圆角
    static let leftOffset: CGFloat = 16 // 左边距
    static let rightOffset: CGFloat = 28 // 右边距
    static let keyboardTrigger: String = "base.catalog.container"
    
    struct BlockTree {
        static let minBottomInset: CGFloat = 50
        
        // item选中时的背景色
        static let itemSelectedBgColor: UIColor = UDColor.fillSelected.withAlphaComponent(0.1)
        // item选中状态下，用户点击时的颜色
        static let itemSelectedColor: UIColor = UDColor.fillSelected.withAlphaComponent(0.2)
        
        static let mainTitleFont: UIFont = UDFont.body0
        static let mainTitleColor: UIColor =  UDColor.textTitle
        static let mainTitleSelectedColor: UIColor = UDColor.primaryPri500
        static let mainTitleLineNumber: Int = 2
        static let mianTitleLineSpacing: CGFloat = 6
        
        static let leftIconSize: CGSize = CGSize(width: 18.0, height: 18.0)
        static let rightIconSize: CGSize = CGSize(width: 18.0, height: 18.0)
        static let leftIconTagSize: CGSize = CGSize(width: 12.0, height: 12.0)
        
        static let rightIconColor: UIColor = UDColor.iconN3
        static let rightIconHighlightColor: UIColor = UDColor.N300
        
        static let leftIconTitleSpacing: CGFloat = 10
        
        // 内边距
        static let edgeInset: UIEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 4)
    }
    
    struct ActionContainer {
        static let height: CGFloat = 90
        
        // actionButton颜色
        static func getActionButtonColor(type: String?, disable: Bool = false) -> UIColor {
            guard !disable else { return UDColor.iconDisabled }
            
            guard let type = type else { return UDColor.iconN1 }
            
            guard let action = BlockCatalogAction(rawValue: type) else {
                return UDColor.iconN1
            }
            
            switch action {
            case .DocCreate:
                return UDColor.B600
            case .TableCreate:
                return UDColor.P600
            }
        }
    }
    
    struct SearchBar {
        static let height: CGFloat = 40
        static let backgroundColor: UIColor = UDColor.N900.withAlphaComponent(0.05)
        
        static let searchIconSize: CGSize = CGSize(width: 16, height: 16)
        static let searchIconColot: UIColor = UDColor.iconN2
        static let searchTextFont: UIFont = UDFont.body0
        static let searchTextOffset: UIOffset = UIOffset(horizontal: 2.0, vertical: 0.0)
        static let searchIconOffset: UIOffset = UIOffset(horizontal: -2.0, vertical: 0.0)
        
        static let buttonTitleFont: UIFont = UDFont.body0
    }
}

final class BlockCatalogueContainer: UIView {
    
    weak var delegate: BlockCatalogueContainerDelegate?
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = []
        return preventer
    }()
    
    private lazy var searchViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.alpha = 0
        button.titleLabel?.font = Const.SearchBar.buttonTitleFont
        button.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonCancel, for: .normal)
        button.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(didClickCancelButton), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var searchBar: UISearchBar = {
        let view = UISearchBar()
        view.delegate = self
        view.backgroundColor = Const.SearchBar.backgroundColor
        view.backgroundImage = UIImage()
        view.setSearchFieldBackgroundImage(UIImage(), for: .normal)
        view.setImage(UDIcon.getIconByKey(.searchOutlined,
                                          iconColor: Const.SearchBar.searchIconColot,
                                          size: Const.SearchBar.searchIconSize), for: .search, state: .normal)
        view.searchTextPositionAdjustment = Const.SearchBar.searchTextOffset
        view.setPositionAdjustment(Const.SearchBar.searchIconOffset, for: .search)
        if #available(iOS 13.0, *) {
            view.searchTextField.font = Const.SearchBar.searchTextFont
        }
        
        view.layer.cornerRadius = Const.cornerRadius
        view.layer.masksToBounds = true
        view.docsListenToToSubViewResponder = true
        return view
    }()
    
    // 目录列表和底部action面板交接处的mask
    private lazy var blockTreeMaskView: UIView = {
        let view = UIView()
        view.layer.addSublayer(gradientLayer)
        if !UserScopeNoChangeFG.XM.blockCatalogueDarkModeFixDisable {
            gradientLayer.ud.setColors([UDColor.bgBody.withAlphaComponent(0), UDColor.bgBody])
        }
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        return gradientLayer
    }()
    
    func updateDarkMode() {
        if UserScopeNoChangeFG.XM.blockCatalogueDarkModeFixDisable {
            gradientLayer.colors = [UDColor.bgBody.withAlphaComponent(0).cgColor, UDColor.bgBody.cgColor]
        }
    }
    
    private lazy var blockTree: BlockTreeView = {
        let view = BlockTreeView()
        view.blockTreeDelegate = self
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var blockTreeWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var actionContainer: ActionContainer = {
        let view = ActionContainer()
        return view
    }()
    
    private lazy var searchEmptyViewContainer: UIView = UIView().construct { it in
        it.isHidden = true
        it.addSubview(searchEmptyView)
        searchEmptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
    }

    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(title: .init(titleText: "",
                                                                        font: UDFont.body2),
                                                           description: .init(descriptionText: ""),
                                                           imageSize: 100,
                                                           type: .noContent,
                                                           labelHandler: nil,
                                                           primaryButtonConfig: nil,
                                                           secondaryButtonConfig: nil)
    
    private lazy var searchEmptyView: UDEmptyView = {
        let blankView = UDEmptyView(config: emptyConfig)
        // 不用userCenterConstraints会非常不雅观
        blankView.useCenterConstraints = true
        blankView.backgroundColor = .clear
        return blankView
    }()
    
    private var keyboard = Keyboard()
    private let disposeBag = DisposeBag()
    //是否在搜索状态
    private var isInSearchMode = false {
        didSet {
            guard isInSearchMode != oldValue else {
                return
            }
            didChangeSearchMode()
        }
    }
    
    private weak var api: BTContainerService?
    
    private var model: BlockCatalogueModel?
    
    private var blockTreeRealData: BTCommonDataModel?
    private var blockTreeSearchData: BTCommonDataModel = BTCommonDataModel(groups: []) {
        didSet {
            guard isInSearchMode else {
                exitSearchMode()
                return
            }
            
            if blockTreeSearchData.groups.isEmpty {
                showSearchEmptyView()
                return
            }
            
            hideSearchEmptyView()
            
            blockTree.setData(items: blockTreeSearchData)
        }
    }
    
    private var shouldShowActionContainer: Bool {
        canEdit && (model?.bottomMenu?.isEmpty == false)
    }
    
    private var canEdit: Bool {
        // iPhone 横屏下不能编辑
        !(Display.phone && UIApplication.shared.statusBarOrientation.isLandscape)
    }
    
    // 键盘frame转换到目录view后的高度
    private var keyboardHeightInBlockTree: CGFloat = 0
    
    private var baseContext: BaseContext? {
        didSet {
            guard let baseContext = baseContext else {
                return
            }
            self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
            self.basePermissionHelper?.startObserve(observer: self)
        }
    }
    private var basePermissionHelper: BasePermissionHelper?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = blockTreeMaskView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateLayout() {
        actionContainer.isHidden = !shouldShowActionContainer
        blockTreeMaskView.isHidden = !shouldShowActionContainer
        
        searchViewContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(model?.searchBar == nil ? 0 : Const.SearchBar.height)
        }
        
        blockTreeWrapperView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchViewContainer.snp.bottom).offset(12)
            if shouldShowActionContainer {
                make.bottom.equalTo(actionContainer.snp.top).offset(-8)
            } else {
                make.bottom.equalToSuperview().offset(-8)
            }
        }
        updateBlockTreeBottomOffset()
    }
    
    private func setup() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        
        var contentView: UIView = self
        if ViewCapturePreventer.isFeatureEnable,
           UserScopeNoChangeFG.LYL.disableFixBaseDragTableSplash {
            contentView = viewCapturePreventer.contentView
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        contentView.addSubview(searchViewContainer)
        contentView.addSubview(blockTreeWrapperView)
        contentView.addSubview(actionContainer)
        contentView.addSubview(searchEmptyViewContainer)
        contentView.addSubview(blockTreeMaskView)
        
        searchViewContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(Const.SearchBar.height)
        }
        
        searchViewContainer.addSubview(searchBar)
        searchViewContainer.addSubview(cancelButton)
        
        searchBar.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(0)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        actionContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.bottom.equalToSuperview()
            make.height.equalTo(Const.ActionContainer.height)
        }
        
        updateLayout()
        
        searchEmptyViewContainer.snp.makeConstraints { make in
            make.top.equalTo(searchViewContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.bottom.equalToSuperview()
        }
        
        blockTreeWrapperView.addSubview(blockTree)
        blockTree.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.top.bottom.equalToSuperview()
        }
        
        blockTreeMaskView.snp.makeConstraints { make in
            make.height.equalTo(Const.BlockTree.minBottomInset)
            make.left.equalToSuperview().inset(Const.leftOffset)
            make.right.equalToSuperview().inset(Const.rightOffset)
            make.bottom.equalTo(actionContainer.snp.top)
        }
        
        keyboard = Keyboard(listenTo: [searchBar], trigger: Const.keyboardTrigger)
        keyboard.on(events: [.willShow, .willHide]) { [weak self] (options) in
            self?.handleKeyboard(options: options)
        }
        keyboard.start()
        
        updateDarkMode()
    }
    
    private func didChangeSearchMode() {
        if !isInSearchMode {
            exitSearchMode()
        }
        
        // 搜索状态不能拖拽
        blockTree.setDraggable((model?.canSort ?? false) && !isInSearchMode)
    }
    
    @objc
    private func orientationDidChange() {
        // 转屏时下掉键盘，修复https://meego.feishu.cn/larksuite/issue/detail/15533560?#detail
        searchBar.resignFirstResponder()
        updateLayout()
    }
    
    @objc
    private func didClickCancelButton() {
        clearSearchText()
        searchBar.resignFirstResponder()
    }
    
    // 更新block列表bottomInset
    private func updateBlockTreeBottomOffset() {
        let blockTreeBottomOffset = max(keyboardHeightInBlockTree, Const.BlockTree.minBottomInset)
        blockTree.contentInset.bottom = blockTreeBottomOffset
    }
    
    // 处理搜索框键盘事件
    private func handleKeyboard(options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .willShow:
            let offset = cancelButton.bounds.width + 8
            keyboardHeightInBlockTree = blockTree.bounds.height - blockTreeWrapperView.convert(options.endFrame, from: nil).minY
            updateBlockTreeBottomOffset()
            
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.searchBar.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                    make.right.equalToSuperview().offset(-offset)
                }
                self?.cancelButton.alpha = 1
                self?.layoutIfNeeded()
            })

            searchEmptyViewContainer.snp.remakeConstraints { it in
                it.top.equalTo(searchViewContainer.snp.bottom).offset(8)
                it.left.equalToSuperview().inset(16)
                it.right.equalToSuperview().inset(28)
                it.bottom.equalToSuperview().offset(-options.endFrame.height)
            }
        case .willHide:
            keyboardHeightInBlockTree = 0
            //isInSearchMode = false
            //searchBar.text = nil
            updateBlockTreeBottomOffset()
            searchEmptyViewContainer.snp.remakeConstraints { it in
                it.top.equalTo(searchViewContainer.snp.bottom).offset(8)
                it.left.equalToSuperview().inset(16)
                it.right.equalToSuperview().inset(28)
                it.bottom.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.searchBar.snp.remakeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                    make.right.equalToSuperview().offset(0)
                }
                self?.cancelButton.alpha = 0
                self?.layoutIfNeeded()
            })
            
        default:
            break
        }
    }
    
    // 显示搜索无结果view
    private func showSearchEmptyView() {
        searchEmptyViewContainer.isHidden = false
        blockTree.isHidden = true
    }
    
    // 隐藏搜索无结果view
    private func hideSearchEmptyView() {
        searchEmptyViewContainer.isHidden = true
        blockTree.isHidden = false
    }
    
    // 设置底部新建Action
    private func setBottomMenu(_ data: BlockCatalogueModel) {
        guard let bottomMenu = data.bottomMenu else {
            return
        }
        
        var items: [ActionButtonModel] = []
        bottomMenu.forEach({ menu in
            guard let text = menu.text,
                  var imag = menu.iconImage else {
                return
            }
            
            let disable = menu.style == .DISABLE
            let tinColor = Const.ActionContainer.getActionButtonColor(type: menu.clickAction,
                                                                      disable: disable)
            
            imag = imag.ud.withTintColor(tinColor)
            let model = ActionButtonModel(icon: imag,
                                          title: text,
                                          disable: disable,
                                          clickCallback: { [weak self] in
                // 新建数据表
                self?.api?.callFunction(
                    DocsJSCallBack(data.callback ?? ""),
                    params: [
                        "action": menu.clickAction ?? "",
                    ],
                    completion: nil
                )
            })
            
            items.append(model)
        })
        
        actionContainer.setData(
            ActionContainerModel(
                title: BundleI18n.SKResource.Bitable_Mobile_CreateNew_Text,
                items: items
            )
        )
    }
    
    // model转换， BaseUIKit -> commonCell
    private func convertBlockTreeData(_ data: BlockCatalogueModel) -> [BTCommonDataItem] {
        let catalogData = data.items.map { item in
            let leftIcon = item.leftIconImage
            let rightIcon = item.rightIconImage
            let selected = item.isSelected
            let mainTitleColor = selected ? Const.BlockTree.mainTitleSelectedColor : Const.BlockTree.mainTitleColor
            
            let leftImage = leftIcon?.ud.withTintColor(selected ? UDColor.primaryPri500 : UDColor.iconN2)
            let rightImage = canEdit ? rightIcon?.ud.withTintColor(UDColor.iconN3) : nil
            
            var data = BTCommonDataItem(
                id: item.id,
                selectCallback: { [weak self] _, _, _ in
                    self?.delegate?.blockContainerRequestHide()
                    self?.api?.callFunction(
                        DocsJSCallBack(data.callback ?? ""),
                        params: ["action": item.clickAction ?? "", "id": item.id],
                        completion: nil
                    )
                },
                background: .init(color: selected ? Const.BlockTree.itemSelectedBgColor : .clear,
                                  selectedColor: selected ?  Const.BlockTree.itemSelectedColor : nil),
                leftIcon: .init(image: leftImage,
                                size: Const.BlockTree.leftIconSize,
                                alignment: .top(offset: 1)),
                leftIconTag: .init(image: item.leftIconTagImage,
                                   size: Const.BlockTree.leftIconTagSize,
                                   alignment: .top(offset: 4)),
                mainTitle: .init(text: item.leftText,
                                 color: mainTitleColor,
                                 font: Const.BlockTree.mainTitleFont,
                                 lineNumber: Const.BlockTree.mainTitleLineNumber,
                                 lineSpacing: Const.BlockTree.mianTitleLineSpacing),
                rightIcon: .init(image: rightImage,
                                 size: Const.BlockTree.rightIconSize,
                                 color: Const.BlockTree.rightIconColor,
                                 highlightColor: Const.BlockTree.rightIconHighlightColor,
                                 alignment: .top(offset: 0),
                                 clickCallback: { [weak self] sourceView in
                                     var params: [String: Any] = ["id": item.id, "action": item.rightIcon?.clickAction ?? ""]
                                     if self?.api?.shouldPopoverDisplay() == true {
                                         params["sourceViewID"] = BTPanelService.weakBindSourceView(view: sourceView)
                                     }
                                     
                                     self?.api?.callFunction(
                                        DocsJSCallBack(data.callback ?? ""),
                                        params: params,
                                        completion: nil
                                     )
                                 }),
                edgeInset: Const.BlockTree.edgeInset
            )
            
            data.isSync = item.leftIcon?.isSync
            data.isSelected = item.isSelected
            
            return data
        }
        
        return catalogData
    }
    
    // 设置block目录列表数据
    private func setBlockTreeData(_ data: BlockCatalogueModel) {
        defer {
            blockTree.setDraggable(data.canSort && !isInSearchMode)
        }
        
        guard let latestModel = self.model else {
            updateTreeViewData(data)
            return
        }
        
        do {
            let oldData = BTCommonItemContainer(identifier: "blockCatalog", items: latestModel.items)
            let newData = BTCommonItemContainer(identifier: "blockCatalog", items: data.items)
            let differences = try Diff.differencesForSectionedView(initialSections: [oldData], finalSections: [newData])
            guard !differences.isEmpty else {
                DocsLogger.btInfo("[BlockCatalog] data no change")
                return
            }
            updateTreeViewData(data)

        } catch {
            updateTreeViewData(data)
            DocsLogger.btError("[BlockCatalog] diff error")
        }
    }
    
    private func updateTreeViewData(_ data: BlockCatalogueModel) {
        let catalogData = convertBlockTreeData(data)
        let groupData = BTCommonDataGroup(groupName: "",
                                          items: catalogData,
                                          showSeparatorLine: false,
                                          cornersMode: .always,
                                          leftIconTitleSpacing: Const.BlockTree.leftIconTitleSpacing)
        var groupDatas = [groupData]
        var isCaptureAllowed = true
        if !UserScopeNoChangeFG.LYL.disableFixBaseDragTableSplash {
            isCaptureAllowed = viewCapturePreventer.isCaptureAllowed
        }
        self.blockTreeRealData = BTCommonDataModel(groups: [groupData], isCaptureAllowed: isCaptureAllowed)
        
        if isInSearchMode {
            // 搜索状态更新数据
            groupDatas = BTCatalogSearchHelper.getSearchResult(datas: self.blockTreeRealData?.groups ?? [], searchKey: searchBar.text)
        }
        
        blockTree.setData(items: BTCommonDataModel(groups: groupDatas, isCaptureAllowed: isCaptureAllowed))
    }
    
    private func updateSearchBar(_ data: BlockCatalogueModel) {
        searchBar.placeholder = data.searchBar?.hint
        searchViewContainer.isHidden = data.searchBar == nil
        if data.searchBar == nil {
            clearSearchText()
        }
    }
    
    private func exitSearchMode() {
        // 退出搜索状态，恢复数据
        hideSearchEmptyView()
        if let data = blockTreeRealData {
            blockTree.setData(items: data)
        }
    }
    
    // 数据更新
    func setData(_ data: BlockCatalogueModel, api: BTContainerService?, baseContext: BaseContext) {
        self.api = api
        self.baseContext = baseContext
        setBlockTreeData(data)
        self.model = data
        emptyConfig.description = .init(descriptionText: data.empty?.text ?? BundleI18n.SKResource.Bitable_Option_NoOptionFound)
        searchEmptyView.update(config: emptyConfig)
        setBottomMenu(data)
        updateSearchBar(data)
        updateLayout()
    }
 
    // 搜索
    private func searchRequest(key: String) {
        if let api = api, let callback = model?.callback {
            api.callFunction(
                DocsJSCallBack(callback),
                params: ["action": model?.searchAction ?? "", "text": key],
                completion: nil
            )
        }
        
        // 搜索native处理
        guard let data = blockTreeRealData else {
            return
        }
                                          
        blockTreeSearchData.groups = BTCatalogSearchHelper.getSearchResult(datas: data.groups, searchKey: key)
    }

    // 清除搜索框内容
    private func clearSearchText() {
        isInSearchMode = false
        searchBar.text = nil
    }
    
    // 打开block目录
    func openBlockCatalogue() {
        if let api = api, let callback = model?.callback {
            // 打开block目录主动获取数据
            api.callFunction(
                DocsJSCallBack(callback),
                params: ["action": model?.getDataAction ?? ""],
                completion: nil
            )
        }
        clearSearchText()
        // 滚动到选中行
        blockTree.scrollToHighLightRow(animated: false)
        // 刷新tableView布局
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blockTree.performBatchUpdates(nil)
        CATransaction.commit()
    }
}

extension BlockCatalogueContainer: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isInSearchMode = !searchBar.text.isEmpty
        searchRequest(key: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 调用搜索接口
        searchRequest(key: searchBar.text ?? "")
    }
}

extension BlockCatalogueContainer: BlockTreeViewDelegate {
    func didSwapItem(id: String, from: Int, to: Int) {
        // 目录拖拽排序
        guard let api = api, let callback = model?.callback else {
            return
        }
        
        api.callFunction(
            DocsJSCallBack(callback),
            params: ["id": id,
                     "action": model?.sortAction ?? "",
                     "fromIndex": from,
                     "toIndex": to],
            completion: nil
        )
    }
}

extension BlockCatalogueContainer: BasePermissionObserver {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        DocsLogger.info("BlockCatalogueContainer setCaptureAllowed => \(allow)")
        viewCapturePreventer.isCaptureAllowed = allow
        if let model = model {
            updateTreeViewData(model)
        }
    }
    
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BlockCatalogueContainer initOrUpdateCapturePermission \(hasCapturePermission)")
        setCaptureAllowed(hasCapturePermission)
    }
}
