//
//  ChatterPicker.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/3.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkModel
import RxSwift
import RustPB
import SnapKit
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkKeyCommandKit
import LarkKeyboardKit
import Homeric
import EENavigator
import LarkFeatureGating
import UniverseDesignColor
import LarkListItem
import LarkContainer
import LarkSetting

/// https://bytedance.larksuite.com/wiki/wikcnRe2soDvxsozjM47Bfd7Geb#HXs9xn
/// 通用chatter picker组件，目前放在LarkSearch里
@objc(LarkChatterPicker)
public class ChatterPicker: Picker, SelectedViewDelegate, UITableViewDataSource, UITableViewDelegate, PickerCommonUI, TableViewKeyboardHandlerDelegate {
    public class InitParam: Picker.InitParam {
        /// 是否包含外部租户
        public var includeOuterTenant = true
        public var includeOuterChat: Bool?
        /// 是否过滤外部联系人，默认不过滤
        public var excludeOuterContact = false
        // 搜索结果是否包含机器人
        public var includeBot = false
        /// 需要查询的权限，会在返回数据chatterMeta的deniedPermissions里(通过Option动态转化为SearchResultType).
        /// chatterPicker内部不会用到这个权限，需要外部通过代理使用，比如禁选或者提示
        public var permissions: [RustPB.Basic_V1_Auth_ActionType] = []
        /// 强制选中在指定chat中的chatter
        public var forceSelectedInChatId: String?
        /// 是否支持展开数据源
        public var supportUnfold: Bool = false
        /// 是否包含内部用户，默认包含
        public var includeInnerGroupForChat: Bool = true
        // 用户组类型不为空，则可以选择用户组数据源
        public var userGroupSceneType: UserGroupSceneType?
        public var includeUserGroup: Bool {
            guard userGroupSceneType != nil else { return false }
            return true
        }
        // 控制用户离职情况
        public var userResignFilter: UserResignFilter?
    }

    @objc public var includeUserGroup: Bool
    @objc public var includeBot: Bool {
        didSet { toggleTypes(type: .bot, value: includeBot) }
    }

    @objc public dynamic var includeOuterTenant: Bool {
        didSet {
            assert(Thread.isMainThread, "should occur on main thread!")

            var searchContext = searchVM.query.context.value
            searchContext[SearchRequestIncludeOuterTenant.self] = includeOuterTenant
            searchVM.query.context.accept(searchContext)

            if includeOuterTenant == false {
                // 切换到内部时，去掉external的选中项. selected中external的需要删除掉
                guard let currentTenantID = userService?.userTenant.tenantID else {
                    return
                }

                var unknownOptions = [Option]()
                removeAllSelected { (v: Option) -> Bool in
                    if let id = getTenantID(option: v) {
                        return id != currentTenantID
                    } else {
                        unknownOptions.append(v)
                        return false
                    }
                }
                // pull tenant Info from remote
                let chatterIds = unknownOptions.compactMap { (option) -> String? in
                    let identifier = option.optionIdentifier
                    return identifier.type == "chatter" ? identifier.id : nil
                }
                if chatterIds.isEmpty { return }
                serviceContainer?.getChatters(ids: chatterIds)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self](chatters) in
                    guard let self = self, !chatters.isEmpty else { return }
                    chatters.forEach { self.cache(option: $0.value) }
                    guard self.includeOuterTenant == false else { return }
                    self.removeAllSelected { (v) -> Bool in
                        let identifier = v.optionIdentifier
                        guard identifier.type == "chatter", let chatter = chatters[identifier.id] else { return false }
                        return chatter.tenantId != currentTenantID
                    }
                }).disposed(by: self.bag)
            }
        }
    }
    /// NOTE: 权限处理由使用者负责。如果改变permissions的值，外部可能需要过滤已选中项
    public var permissions: [RustPB.Basic_V1_Auth_ActionType] {
        didSet {
            assert(Thread.isMainThread, "should occur on main thread!")

            var searchContext = searchVM.query.context.value
            searchContext[AuthPermissionsKey.self] = permissions
            searchVM.query.context.accept(searchContext)

            _permissionsChangeObservable.onNext(permissions)
        }
    }

    func toggleTypes(type: SearchRequestExcludeTypes, value: Bool) {
         assert(Thread.isMainThread, "should occur on main thread!")

        var searchContext = searchVM.query.context.value
        searchContext[type] = !value
        searchVM.query.context.accept(searchContext)

        if value == false {
            // 切换时清理不符合条件的选中项
            removeAllSelected { (v: Option) -> Bool in
                switch v.optionIdentifier.type {
                case OptionIdentifier.Types.chat.rawValue:
                    return type == .chat
                case OptionIdentifier.Types.department.rawValue:
                    return type == .department
                case OptionIdentifier.Types.chatter.rawValue:
                    return type == .chatter
                case OptionIdentifier.Types.bot.rawValue:
                    return type == .bot
                default:
                    return false
                }
            }
        }
    }

    /// observable when change, without inital value
    private lazy var _permissionsChangeObservable = PublishSubject<[RustPB.Basic_V1_Auth_ActionType]>()
    public var permissionsChangeObservable: Observable<[RustPB.Basic_V1_Auth_ActionType]> { _permissionsChangeObservable.asObservable() }

    @objc public let forceSelectedInChatId: String?
    @objc public let clearQueryWhenSelected: Bool = true

    /// 在有外接键盘的 iPad 上，自动聚焦 searchTextField
    public var searchTextFieldAutoFocus: Bool {
        get { self.searchBar.searchUITextField.autoFocus }
        set { self.searchBar.searchUITextField.autoFocus = newValue }
    }
    public var searchPlaceholder: String? {
        get { searchBar.searchUITextField.placeholder }
        set { searchBar.searchUITextField.placeholder = newValue }
    }

    // TableView KeyCommand 转发
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() +
            (isSearching() ? searchViewTableViewKeyboardHandler?.baseSelectiveKeyBindings ?? [] : [])
    }
    public override func subProviders() -> [KeyCommandProvider] {
        if !self.isSearching() {
            return [defaultView]
        }
        return []
    }

    // TableView Keyboard
    var searchViewTableViewKeyboardHandler: TableViewKeyboardHandler?

    /// 是否正在搜索
    /// - Note: 即 resultView 是否可见 / defaultView 是否不可见
    public func isSearching() -> Bool {
        return !resultView.isHidden
    }

    // override by subclass
    var needShowMail: Bool { false }

    // MARK: - Private property
    private let supportUnfold: Bool
    private lazy var isShowDepartmentInfoFG = SearchFeatureGatingKey.showDepartmentInfo.isUserEnabled(userResolver: self.userResolver)
    // TODO: 质量上报
    weak var newDelegate: SearchPickerDelegate? // 新的代理回调

    public let params: InitParam

    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        self.params = params
        includeOuterTenant = params.includeOuterTenant
        permissions = params.permissions
        forceSelectedInChatId = params.forceSelectedInChatId
        self.supportUnfold = params.supportUnfold
        includeBot = params.includeBot
        self.searchBar.searchUITextField.autocorrectionType = .no
        includeUserGroup = params.includeUserGroup

        super.init(resolver: resolver, frame: frame, params: params)
        self.searchTextFieldAutoFocus = Display.pad && KeyboardKit.shared.keyboardType == .hardware
        PickerLogger.shared.info(module: PickerLogger.Module.search, event: "chatter picker config", parameters: "permissions: \(params.permissions)")
    }

    public convenience init(resolver: LarkContainer.UserResolver, frame: CGRect) {
        self.init(resolver: resolver, frame: frame, params: InitParam())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func preloadItems(selects: [Option]) {
        if selects.isEmpty { return }
        preloadService.didFinishPreloadHandler = { [weak self] items in
            guard let self = self else { return }
            var currentSelects = self.selected
            currentSelects.insert(contentsOf: items, at: 0)
            self.selected = currentSelects
            self.selectedView.reloadData()
            if !currentSelects.isEmpty {
                self.selectedView.scrollToLeading()
            }
        }
        preloadService.preload(selects: selects)
    }

    var loaded = false // lazy load when appear on window
    public override func willMove(toWindow newWindow: UIWindow?) {
        guard !loaded, newWindow != nil else { return }
        loaded = true

        viewLoaded()
    }

    // MARK: UI Component
    /// defaultView show when query it empty
    public var defaultView: UIView {
        get { _defaultView }
        set {
            if loaded {
                assertionFailure("should set defaultView before show on window")
                Self.logger.error("should set defaultView before show on window")
            } else {
                _defaultView = newValue
            }
        }
    }
    let searchBar = SearchUITextFieldWrapperView()
    public let resultView = SearchResultView(tableStyle: .plain)
    public lazy var selectedView: SelectedView = {
        return createSelectedView(frame: .zero, delegate: self)
    }()
    // lazy loaded to give caller a change to replace it
    lazy var _defaultView: UIView = self.serviceContainer?.chatterDefaultView(picker: self) ?? UIView()

    func createSelectedView(frame: CGRect, delegate: SelectedViewDelegate) -> SelectedView {
        let view = SelectedView(frame: frame, delegate: delegate, supportUnfold: supportUnfold)
        view.scene = scene
        view.userId = self.userService?.user.userID ?? ""
        return view
    }

    private let cellIdentifier = "ContactSearchTableViewCell"
    func viewLoaded() {
        bag.insert(bind(ui: self))
        let rowHeight: CGFloat = 68
        if isShowDepartmentInfoFG {
            resultView.tableview.register(PickerSearchItemCell.self, forCellReuseIdentifier: cellIdentifier)
            resultView.tableview.rowHeight = UITableView.automaticDimension
            resultView.tableview.estimatedRowHeight = rowHeight
        } else {
            resultView.tableview.register(ContactSearchTableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        }
        if self is SearchPickerView {
            resultView.tableview.register(ItemTableViewCell.self, forCellReuseIdentifier: "ItemTableViewCell")
            resultView.tableview.rowHeight = UITableView.automaticDimension
            resultView.tableview.estimatedRowHeight = rowHeight
        }
        // init searchView keyboard handler
        searchViewTableViewKeyboardHandler = TableViewKeyboardHandler(
            options: [.allowCellFocused(focused: Display.pad)]
        )
        searchViewTableViewKeyboardHandler?.delegate = self
        searchBar.searchUITextField.rx.text.asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.searchViewTableViewKeyboardHandler?.resetFocus(shouldScrollToVisiable: false)
            }).disposed(by: bag)
    }

    /// SelectedViewDelegate protocol
    public func avatar(for option: Option, callback: @escaping (SelectedOptionInfo?) -> Void) {
        avatar(for: option, bag: bag, callback: callback)
    }

    public func unfold() {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.delegate?.unfold(self)
    }

    // MARK: Search Component Bind
    public typealias Item = SearchResultType
    public var listvm: ListVM { searchVM.result }
    public var listState: SearchListStateCases?
    public var results: [Item] = []
    public var searchLocation: String { "ChatterPicker" }
    lazy var searchVM: SearchSimpleVM<Item> = {
        let vm = SearchSimpleVM(result: makeListVM())
        configure(vm: vm)
        return vm
    }()
    func configure(vm: SearchSimpleVM<Item>) {
        var context = vm.query.context.value
        context[SearchRequestIncludeOuterTenant.self] = includeOuterTenant
        if !permissions.isEmpty {
            context[AuthPermissionsKey.self] = permissions
        }
        vm.query.context.accept(context)
    }
    func makeListVM() -> SearchListVM<Item> {
        SearchListVM<Item>(source: makeSource(), pageCount: Self.defaultPageCount)
    }
    func makeSource() -> SearchSource {
        // NOTE: 子类有覆盖并复制代码
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.addChatChatters))
        maker.doNotSearchResignedUser = false
        // 默认选中群里的所有人。使用场景为：群添加人，能搜索到这个人，但已经选中在群里，不需要再添加了
        // Rust会返回meta.inChatIds来标记这个人在哪些群里
        if let chatID = forceSelectedInChatId { maker.inChatID = chatID }
        maker.includeBot = includeBot
        maker.excludeOuterContact = params.excludeOuterContact
        maker.userGroupSceneType = params.userGroupSceneType
        maker.includeUserGroup = params.includeUserGroup
        maker.userResignFilter = params.userResignFilter
        maker.includeMyAi = params.includeMyAi
        maker.myAiMustTalked = params.myAiMustTalked
        return maker.makeAndReturnProtocol()
    }
    static let defaultPageCount = 30

    var chattersIdsInChat: Set<String> = []
    public func makeViewModel(item: Item) -> Item? {
        if case .chatter(let meta) = item.meta {
            if meta.isInChat {
                // chat是创建时不会动的。所以这里只更新在chat里的chatter，可以不用管清理.
                chattersIdsInChat.update(with: meta.id)
            }
        }
        return item
    }

    // MARK: TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return resultView.tableview
    }

    // TODO: 换成依赖更小的，而不是现在这样特化的ForwardItem
    // nolint: duplicated_code 不同业务映射逻辑略有不同
    func compactMap(result: SearchResultType) -> ForwardItem {
        // map
        var type = ForwardItemType.unknown
        var id = ""
        var description = ""
        var flag = Chatter.DescriptionType.onDefault
        var isCrossTenant = false
        var isCrossWithKa = false
        var isCrypto = false
        var isThread = false
        var isPrivate = false
        var doNotDisturbEndTime: Int64 = 0
        var hasInvitePermission: Bool = true
        var isOfficialOncall: Bool = false
        var channelID: String?
        var chatId = ""
        var chatUserCount = 0 as Int32
        var isUserCountVisible = true

        switch result.meta {
        case .chatter(let chatter):
            id = chatter.id
            chatId = chatter.p2PChatID.isEmpty ? "" : chatter.p2PChatID
            type = ForwardItemType(rawValue: chatter.type.rawValue) ?? .unknown
            description = chatter.description_p
            flag = chatter.descriptionFlag
            isCrossTenant = (chatter.tenantID != (self.userService?.userTenant.tenantID ?? ""))
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            let searchActionType: SearchActionType = .createP2PChat
            var forwardSearchDeniedReason: SearchDeniedReason = .unknownReason
            // 有deniedReason直接判断deniedReason，没有的情况下判断deniedPermissions
            if let searchDeniedReason = chatter.deniedReason[Int32(searchActionType.rawValue)] {
                forwardSearchDeniedReason = searchDeniedReason
            } else if !chatter.deniedPermissions.isEmpty {
                forwardSearchDeniedReason = .sameTenantDeny
            }
            // 统一通过deniedReason判断OU权限(sameTenantDeny)和外部联系人的的权限（block）
            hasInvitePermission = !(forwardSearchDeniedReason == .sameTenantDeny || forwardSearchDeniedReason == .blocked)
        case .chat(let chat):
            id = chat.id
            chatId = chat.id
            type = .chat
            isCrossTenant = chat.isCrossTenant
            isCrossWithKa = chat.isCrossWithKa
            isPrivate = chat.isShield
            isCrypto = chat.isCrypto
            isThread = chat.chatMode == .threadV2 || chat.chatMode == .thread
            isOfficialOncall = chat.isOfficialOncall
            chatUserCount = chat.userCountWithBackup
            isUserCountVisible = chat.isUserCountVisible
            if isUserCountVisible == false {
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "chatter picker search chat user count invisible", parameters: "id=\(id), name=\(result.title.string.count)")
            }
        case .shieldP2PChat(let chatter):
            //密盾聊单聊
            id = chatter.id
            chatId = chatter.id
            type = .chat
            isCrossTenant = (chatter.tenantID != (self.userService?.userTenant.tenantID ?? ""))
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            isPrivate = true
        case .thread(let thread):
            id = thread.id
            type = .threadMessage
            channelID = thread.channel.id
            isThread = true
        default:
            break
        }

        var avatarKey = result.avatarKey
        if userResolver.fg.staticFeatureGatingValue(with: "lark_feature_doc_icon_custom"),
           let icon = result.icon, icon.type == .image {
            avatarKey = icon.value
        }
        // TODO: 没有高亮..
        var item = ForwardItem(
            avatarKey: avatarKey,
            name: result.title.string,
            subtitle: result.summary.string,
            description: description,
            descriptionType: flag,
            localizeName: result.title.string,
            id: id,
            chatId: chatId,
            type: type,
            isCrossTenant: isCrossTenant,
            isCrossWithKa: isCrossWithKa,
            isCrypto: isCrypto,
            isThread: isThread,
            isPrivate: isPrivate,
            channelID: channelID,
            doNotDisturbEndTime: doNotDisturbEndTime,
            hasInvitePermission: hasInvitePermission,
            userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
            enableThreadMiniIcon: false,
            isOfficialOncall: isOfficialOncall,
            tags: result.tags,
            attributedTitle: result.title,
            attributedSubtitle: result.summary,
            customStatus: nil)
        item.chatUserCount = chatUserCount
        item.isUserCountVisible = isUserCountVisible
        return item
    }
    // enable-lint: duplicated_code

    // MARK: Result Table View

    // nolint: duplicated_code 两者使用的数据结构不同,且后续会废弃ChatPicker
    @objc
    private func presentPreviewViewController(button: UIButton) {
        guard results.count > button.tag,
              let fromVC = self.fromVC
        else { return }
        let item = self.compactMap(result: results[button.tag])
        let chatID = item.chatId ?? ""
        //未开启过会话的单聊，chatID为空时，需传入uid
        let userID = chatID.isEmpty ? item.id : ""
        if !TargetPreviewUtils.canTargetPreview(forwardItem: item) {
            if let window = fromVC.view.window {
                UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else if TargetPreviewUtils.isThreadGroup(forwardItem: item) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chatID)
            userResolver.navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatID, userId: userID, title: item.name)
            userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        }
        SearchTrackUtil.trackPickerSelectClick(scene: self.scene, clickType: .chatDetail(target: "none"))
    }
    // enable-lint: duplicated_code

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        exit: do {
            let item = results[indexPath.row]
            let state: SelectState = {
                if isForceSelectedInChat(item: item) {
                    return .forceSelected
                }
                // NOTE: permissions状态处理由外部实现
                return self.state(for: item, from: self, category: .search)
            }()

            // SearchPicker走新Cell渲染逻辑
            if isNewListItemCell(item: item) {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as? ItemTableViewCell,
                let result = item as? Search.Result {
                    let checkBox = ListItemNode.CheckBoxState(isShow: isMultiple, isSelected: state.selected, isEnable: !state.disabled)
                    let pickerItem = PickerItemFactory.shared.makeItem(result: result)
                    cell.context.userId = userService?.user.userID ?? ""
                    cell.node = PickerItemTransformer.transform(indexPath: indexPath, item: pickerItem, checkBox: checkBox)
                    return cell
                }
            }

            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PickerSearchItemCellType else { break exit }
            cell.isShowDepartmentInfo = isShowDepartmentInfoFG
            cell.setContent(resolver: self.userResolver,
                            searchResult: item,
                            currentTenantId: userService?.userTenant.tenantID ?? "",
                            hideCheckBox: !isMultiple,
                            enabled: !state.disabled,
                            isSelected: state.selected,
                            checkInDoNotDisturb: serverNTPTimeService?.afterThatServerTime(time:) ?? { _ in false },
                            needShowMail: self.needShowMail,
                            currentUserType: userService?.user.type ?? .undefined,
                            targetPreview: targetPreview && TargetPreviewUtils.canTargetPreview(searchResult: item))
            cell.targetInfo.tag = indexPath.row
            cell.targetInfo.addTarget(self, action: #selector(presentPreviewViewController(button:)), for: .touchUpInside)
            return cell
        }
        assertionFailure()
        return UITableViewCell()
    }
    lazy var isFinishAfterMultiSelectFG = SearchFeatureGatingKey.finishAfterMultiSelect.isUserEnabled(userResolver: self.userResolver)
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let item = results[indexPath.row]
        if isNewListItemCell(item: item) {
            let v = self.toggle(option: item,
                                from: self,
                                at: tableView.absolutePosition(at: indexPath),
                                event: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_CLICK,
                                target: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_VIEW)
            if isFinishAfterMultiSelectFG {
                afterSelected(success: v)
            } else {
                setSearchBarSelectAllMode(searchBar: searchBar)
            }
            if v, self.state(for: item, from: self).selected {
                SearchTrackUtil.trackChatterPickerItemSelect(indexPath.row + 1)
            }
            return
        }

        guard (tableView.cellForRow(at: indexPath) as? PickerSearchItemCellType) != nil else { return }

        if isForceSelectedInChat(item: item) {
            return
        }

        let v = self.toggle(option: item,
                            from: self,
                            at: tableView.absolutePosition(at: indexPath),
                            event: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_CLICK,
                            target: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_VIEW)
        if isFinishAfterMultiSelectFG {
            afterSelected(success: v)
        } else {
            setSearchBarSelectAllMode(searchBar: searchBar)
        }
        if v, self.state(for: item, from: self).selected {
            SearchTrackUtil.trackChatterPickerItemSelect(indexPath.row + 1)
        }
    }

    func afterSelected(success: Bool) {
        if success && isMultiple && self.clearQueryWhenSelected {
            searchBar.searchUITextField.text = ""
            searchViewTableViewKeyboardHandler?.resetFocus(shouldScrollToVisiable: false)
            self.search()
        }
    }
    // MARK: Helper
    func isForceSelectedInChat(item: Item) -> Bool {
        switch item.meta {
        case .chatter(let meta):
            if chattersIdsInChat.contains(meta.id) {
                return true
            }
        case .chat(let meta):
            if let chatID = forceSelectedInChatId, meta.id == chatID {
                return true
            }
        default: break
        }
        return false
    }
    func getTenantID(option: Option) -> String? {
        if let id = tenantID(option: option) { return id }
        if let option = optionCache[option.optionIdentifier], let id = tenantID(option: option) { return id }
        return nil
    }

    private func isNewListItemCell(item: ChatterPicker.Item) -> Bool {
        switch item.meta {
        case .doc(_), .wiki(_), .workspace(_):
            return true
        case .slash(let slashMeta):
            if item.bid.elementsEqual("lark"),
               (item.entityType.elementsEqual("mail-contact") || item.entityType.elementsEqual("mail-group") ||
                item.entityType.elementsEqual("name-card") || item.entityType.elementsEqual("mail_shared_account")) {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
}

extension SelectedOptionInfo {
    public func asSelectedOptionInfo() -> SelectedOptionInfo { self }
}

extension Search.Result: SelectedChatOptionInfo, SelectedOptionInfoConvertable {
    public var isUserCountVisible: Bool {
        if case .groupChatMeta(let meta) = getV2Meta() {
            return meta.isUserCountVisible
        }
        return true
    }

    public var chatUserCount: Int32 {
        if case .groupChatMeta(let meta) = getV2Meta() { return meta.userCount }
        return 0
    }
    public var chatDescription: String { "" }
    public var avaterIdentifier: String { avatarID ?? "" }
    public var name: String {
        switch type {
        case .userGroup, .userGroupAssign, .newUserGroup:
            switch meta {
            case .userGroup(let userGroupData), .userGroupAssign(let userGroupData), .newUserGroup(let userGroupData):
                return userGroupData.name
            default: return title.string
            }
        default: return title.string
        }
    }

    public var selectedOptionDescription: String? {
        switch type {
        case .slashCommand:
            if case .slash = meta, bid.elementsEqual("lark"),
               (entityType.elementsEqual("mail-contact") || entityType.elementsEqual("mail-group") ||
                entityType.elementsEqual("name-card") || entityType.elementsEqual("mail_shared_account")) {
                    return summary.string
            } else {
                break
            }
        default: break
        }
        return nil
    }

    public var avatarImageURLStr: String? {
        switch type {
        case .slashCommand:
            if case let .slash(slashCommandMeta) = meta, bid.elementsEqual("lark"),
               (entityType.elementsEqual("mail-contact") || entityType.elementsEqual("mail-group") ||
                entityType.elementsEqual("name-card") || entityType.elementsEqual("mail_shared_account")) {
                return slashCommandMeta.imageURL
            } else {
                break
            }
        default: break
        }
        return nil
    }

    public var backupImage: UIImage? {
        switch type {
        case .userGroup, .userGroupAssign, .newUserGroup: return BundleResources.LarkSearchCore.Picker.user_group
        default:  return type.backupImage
        }
    }
    public var crossTenant: Bool? {
        if case .groupChatMeta(let meta) = getV2Meta() { return meta.isCrossTenant }
        return nil
    }
}

extension Chatter: SelectedOptionInfoConvertable, SelectedOptionInfo {
    public var avaterIdentifier: String { self.id }
}

extension Chat: SelectedOptionInfoConvertable, SelectedChatOptionInfo {
    public var avaterIdentifier: String { self.id }
    public var chatUserCount: Int32 { userCount }
    public var chatDescription: String { description }
    public var crossTenant: Bool? { self.isCrossTenant }
}

private func tenantID(option: Option) -> String? {
    switch option {
    case let v as SearchResultType:
        if case let .chatter(meta) = v.meta { return meta.tenantID }
    case let v as Chatter:
        return v.tenantId
    default: break
    }
    return nil
}
