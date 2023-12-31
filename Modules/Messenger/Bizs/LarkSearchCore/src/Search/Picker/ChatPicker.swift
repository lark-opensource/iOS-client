//
//  ChatPicker.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/16.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkCore
import SnapKit
import LarkModel
import LarkMessengerInterface
import LarkOpenFeed
import LarkFeatureGating
import UniverseDesignToast
import LarkSDKInterface
import RustPB
import LarkKeyCommandKit
import LarkKeyboardKit
import LarkFocusInterface
import Homeric
import EENavigator
import LarkBizTag
import UniverseDesignColor
import LarkContainer
import LarkSetting

/// https://bytedance.larksuite.com/wiki/wikcnRe2soDvxsozjM47Bfd7Geb#HXs9xn
/// 通用chat picker组件
@objc(LarkChatPicker)
public final class ChatPicker: Picker, UITableViewDataSource, UITableViewDelegate, PickerCommonUI, TableViewKeyboardHandlerDelegate, ForwardItemDataConvertable {
    public final class InitParam: Picker.InitParam {
        /// 搜索的场景
        public var pickType: UniversalPickerType = .defaultType
        /// 是否包含chat消息创建的thread
        public var includeMsgThread = false
        /// 是否确认选择权限
        // public var checkInvitePermission = true

        /// TODO: 目前先迁移兼容，以后可能会收敛filter，不再提供
        public var filter: ForwardDataFilter?
        /// 是否包含密聊/密聊群聊
        public var includeCrypto: Bool?
        /// 是否包含密盾单聊
        public var includeShieldP2PChat = false
        /// 是否包含密盾群
        public var includeShieldGroup = false
        /// 转发多端同步过滤参数
        public var includeConfigs: IncludeConfigs?
        /// 转发多端同步置灰参数
        public var enableConfigs: IncludeConfigs?
        /// 是否包含外部租户
        public var includeOuterTenant = true
        /// 是否不搜索离职用户
        public var doNotSearchResignedUser: Bool?
        /// 是否过滤外部单聊
        public var excludeOuterContact: Bool?
        /// 是否包含外部群聊
        public var includeOuterChat: Bool?
        /// 是否支持搜索冷冻群
        public var supportFrozenChat: Bool?
        /// 是否包含thread话题帖子的数据
        public var includeThread = true
        /// 是否展示最近转发
        public var shouldShowRecentForward = true
        public var permissions: [RustPB.Basic_V1_Auth_ActionType] = []
        public var isInForwardComponent: Bool = false
        /// 日志打印信息
        public override var description: String {
            return "includeOuterTenant:\(includeOuterTenant), excludeOuterContact:\(excludeOuterContact), includeOuterChat:\(includeOuterChat), includeThread:\(includeThread)"
        }
    }

    @objc public let includeOuterTenant: Bool
    @objc public let includeThread: Bool
    @objc public let clearQueryWhenSelected: Bool = true

    /// 在有外接键盘的 iPad 上，自动聚焦 searchTextField
    public var searchTextFieldAutoFocus: Bool {
        get { self.searchBar.searchUITextField.autoFocus }
        set { self.searchBar.searchUITextField.autoFocus = newValue }
    }
    public var filter: ForwardDataFilter?
    public var filterParameters: ForwardFilterParameters?
    var params: InitParam
    public var filterPickerResultViewWidth: (() -> CGFloat?)?

    deinit {
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "chat picker deinit")
    }

    public init(resolver: UserResolver, frame: CGRect, params: InitParam) {
        // 传入预选内容时, 默认打开多选状态
        if !params.preSelects.isEmpty { params.isMultiple = true }
        includeOuterTenant = params.includeOuterTenant
        includeThread = params.includeThread
        filter = params.filter
        self.params = params
        self.searchBar.searchUITextField.autocorrectionType = .no
        super.init(resolver: resolver, frame: frame, params: params)
        preloadItems(selects: params.preSelects)
        self.searchTextFieldAutoFocus = Display.pad && KeyboardKit.shared.keyboardType == .hardware
        var searchContext = searchVM.query.context.value
        searchContext[AuthPermissionsKey.self] = params.permissions
        searchVM.query.context.accept(searchContext)
        PickerLogger.shared.info(module: PickerLogger.Module.search, event: "chat picker config", parameters: "permissions: \(params.permissions)")
    }

    public func preloadItems(selects: [Option]) {
        if selects.isEmpty { return }
        preloadService.didFinishPreloadHandler = { [weak self] items in
            guard let self = self else { return }
            var currentSelects = self.selected
            currentSelects.insert(contentsOf: items, at: 0)
            self.selected = currentSelects
            self.selectedView.reloadData()
            self.selectedView.scrollToLeading()
        }
        preloadService.preload(selects: selects)
    }

    public convenience init(resolver: UserResolver, frame: CGRect) {
        self.init(resolver: resolver, frame: frame, params: InitParam())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var loaded = false // lazy load when appear on window
    public override func willMove(toWindow newWindow: UIWindow?) {
        guard !loaded, newWindow != nil else { return }
        loaded = true

        viewLoaded()
    }

    // MARK: UI Component
    /// searchBar下面，始终显示的topView. 会显示在selectedView的上面
    /// this view should have intrinsicContentSize or size constraint. but no position constraint
    public var topView: UIView? {
        didSet {
            if loaded {
                assertionFailure("should set picker top view before show on window")
                Self.logger.error("should set picker top view before show on window")
            }
        }
    }
    public let searchBar = SearchUITextFieldWrapperView()
    private var searchBarMaskView: UIView?
    private var searchTextValueCount: Int = 0

    public let resultView = SearchResultView(tableStyle: .plain)
    public lazy var selectedView: SelectedView = {
        let view = SelectedView(frame: .zero, delegate: self, supportUnfold: true, pickType: params.pickType)
        view.scene = scene
        return view
    }()
    @objc public lazy var defaultView: UIView = DefaultChatView(
        // TODO: 改成注入的
        resolver: self.userResolver,
        frame: .zero,
        customView: nil,
        selection: self,
        canForwardToTopic: includeThread,
        scene: self.scene,
        canForwardToMsgThread: self.params.includeMsgThread,
        shouldShowRecentForward: self.params.shouldShowRecentForward,
        filter: { [weak self, includeOuterTenant] item in
            if item.isCrossTenant {
                if !includeOuterTenant {
                    return false
                }
            }
            guard let self = self else { return true }
            return self.filter?(item) ?? true
        },
        filterParameters: filterParameters,
        includeConfigs: params.includeConfigs,
        enableConfigs: params.enableConfigs,
        fromVC: self.fromVC,
        targetPreview: targetPreview,
        isInForwardComponent: params.isInForwardComponent)

    private lazy var isShowDepartmentInfoFG = SearchFeatureGatingKey.showDepartmentInfo.isUserEnabled(userResolver: self.userResolver)
    func viewLoaded() {
        switch params.pickType {
        case .defaultType:
            resultView.tableview.register(ForwardChatTableCell.self, forCellReuseIdentifier: "ForwardChatTableCell")
        case .chat, .userAndGroupChat:
            resultView.tableview.register(ChatPickerTableCell.self, forCellReuseIdentifier: "ChatPickerTableCell")
        case .workspace, .folder:
            resultView.tableview.register(WikiPickerTableCell.self, forCellReuseIdentifier: "wikiPickerTableCell")
        case .filter:
            resultView.tableview.register(FilterSelectionCell.self, forCellReuseIdentifier: "FilterSelectionCell")
        default: break
        }
        bag.insert(bind(ui: self))
        topView: if let topView = topView {
            guard let stackView = selectedView.superview as? UIStackView else {
                assertionFailure("should layout in UIStackView")
                break topView
            }
            stackView.addArrangedSubview(topView) // 加在 selected View 下边
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

    public func avatar(for option: Option, callback: @escaping (SelectedOptionInfo?) -> Void) {
        avatar(for: option, bag: bag, callback: callback)
    }
    // MARK: Search Component Bind
    static let defaultPageCount = 20
    public typealias Item = ForwardItem
    public var listvm: ListVM { searchVM.result }
    public var listState: SearchListStateCases?
    public var results: [Item] = []
    public var searchLocation: String { "ChatPicker" }
    public var isDefaultInit: Bool = false
    lazy var searchVM: SearchSimpleVM<Item> = {
        let searchScene = { () -> SearchSceneSection in
            switch params.pickType {
            case .workspace, .folder: return .rustScene(.searchDoc)
            case .chat, .defaultType: return .rustScene(.transmitMessages)
            case let .filter(info): return .searchPlatformFilter(info.referenceAppID)
            case .label(_): return .rustScene(.searchDoc) // 暂时和folder保持一致,目前没有链路走到这里
            case .userAndGroupChat: return .searchUserAndGroupChat
            }
        }()
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: searchScene)
        maker.pickType = params.pickType
        maker.needSearchOuterTenant = includeOuterTenant
        maker.incluedOuterChat = params.includeOuterChat
        maker.supportFrozenChat = params.supportFrozenChat
        maker.doNotSearchResignedUser = true
        switch params.pickType {
        case .chat(let pickType):
            maker.doNotSearchResignedUser = false
            maker.chatFilterMode = [pickType]
        case .filter:
            maker.resultViewWidth = {
                return self.filterPickerResultViewWidth?() ?? 0
            }
        case .userAndGroupChat:
            maker.includeAllChat = true
        case .defaultType, .folder, .workspace: break
        default: break
        }
        // TODO: 权限可能要让外部配置
        maker.authPermissions = [.createP2PChat]
        maker.includeThread = includeThread
        // @qiuchen，PM表示ChatPicker搜索结果不展示密聊群聊
        maker.includeCrypto = self.params.includeCrypto ?? false
        maker.includeShieldGroup = self.params.includeShieldGroup
        maker.includeShieldP2PChat = self.params.includeShieldP2PChat
        maker.excludeOuterContact = self.params.excludeOuterContact ?? false
        maker.includeMyAi = self.params.includeMyAi
        maker.myAiMustTalked = self.params.myAiMustTalked
        let source = maker.makeAndReturnProtocol()
        let listvm = SearchListVM(
            source: source, pageCount: Self.defaultPageCount, compactMap: { [weak self](result: SearchItem) -> ForwardItem? in
                guard let result = result as? SearchResultType else {
                    assertionFailure("unreachable code!!")
                    return nil
                }
                return self?.compactMap(result: result)
            })
        let vm = SearchSimpleVM(result: listvm)
        switch params.pickType {
        case .workspace, .folder, .chat:
            vm.filterBottomPadding = 0
        case .chat(let pickType):
            vm.filterBottomPadding = 0
        case .filter(let info):
            vm.result.shouldClear = { [weak self] request in
                guard let self = self else {
                    return false
                }
                if request.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !self.isDefaultInit {
                    self.isDefaultInit = true
                    return false
                }
                return request.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        case .defaultType, .filter: break
        default: break
        }
        return vm
    }()
    // TODO: 换成依赖更小的，而不是现在这样特化的ForwardItem
    // nolint: long_function 数据模型转换逻辑,后续ChatPicker会废弃删除
    func compactMap(result: SearchResultType) -> ForwardItem? {
        // before filter
        if includeThread == false, case .thread = result.meta {
            return nil
        }

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
        var customStatus: ChatterFocusStatus?
        var wikiSpaceType: WikiSpaceType?
        var isShardFolder: Bool?
        var avatarId: String?
        var tagData: Basic_V1_TagData?
        var imageURLStr: String?
        var deniedReasons: [Basic_V1_Auth_DeniedReason]?
        var isUserCountVisible: Bool = true
        switch result.meta {
        case .chatter(let chatter):
            id = chatter.id
            chatId = chatter.p2PChatID
            type = ForwardItemType(rawValue: chatter.type.rawValue) ?? .unknown
            description = chatter.description_p
            flag = chatter.descriptionFlag
            // MyAI 目前没有下发 tenantID 字段，从设计上也是不会跨租户的
            if type == .myAi && chatter.tenantID.isEmpty {
                isCrossTenant = false
            } else {
                isCrossTenant = (chatter.tenantID != (userService?.userTenant.tenantID ?? ""))
            }
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            customStatus = chatter.customStatus.topActive
            let searchActionType: SearchActionType = .createP2PChat
            var forwardSearchDeniedReason: SearchDeniedReason = .unknownReason
            // 有deniedReason直接判断deniedReason，没有的情况下判断deniedPermissions
            if let searchDeniedReason = chatter.deniedReason[Int32(searchActionType.rawValue)] {
                forwardSearchDeniedReason = searchDeniedReason
            } else if !chatter.deniedPermissions.isEmpty {
                forwardSearchDeniedReason = .sameTenantDeny
            }
            tagData = chatter.relationTag.toBasicTagData()
            // 统一通过deniedReason判断OU权限(sameTenantDeny)和外部联系人的的权限（block）
            hasInvitePermission = !(forwardSearchDeniedReason == .sameTenantDeny || forwardSearchDeniedReason == .blocked)
            deniedReasons = Array(chatter.deniedReason.values)
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
            tagData = chat.relationTag.toBasicTagData()
            isUserCountVisible = chat.isUserCountVisible
            if isUserCountVisible == false {
                PickerLogger.shared.info(module: PickerLogger.Module.search, event: "search chat user count invisible", parameters: "id=\(id), name=\(result.title.string.count)")
            }
        case .shieldP2PChat(let chatter):
            //密盾聊单聊
            id = chatter.id
            chatId = chatter.id
            type = .chat
            isCrossTenant = (chatter.tenantID != (userService?.userTenant.tenantID ?? ""))
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            tagData = chatter.relationTag.toBasicTagData()
            isPrivate = true
        case .thread(let thread):
            id = thread.id
            type = .threadMessage
            channelID = thread.channel.id
            isThread = true
            avatarId = thread.channel.id
        case .doc(let doc):
            id = doc.id
            isShardFolder = doc.isShareFolder
            description = BundleI18n.LarkSearchCore.Lark_ASL_EntryLastUpdated(Date.lf.getNiceDateString(TimeInterval(doc.updateTime)))
        case .workspace(let workspace):
            id = workspace.spaceID
            wikiSpaceType = workspace.wikiSpaceType
            description = workspace.description_p
        case .slash(let slashMeta):
            id = result.id
            type = .generalFilter
            imageURLStr = !slashMeta.imageURL.isEmpty ? slashMeta.imageURL : nil
        default:
            break
        }

        var avatarKey = result.avatarKey
        // TODO: liuqingfeng@bytedance.com 说这个FG可以下线了
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
            customStatus: customStatus,
            wikiSpaceType: wikiSpaceType,
            isShardFolder: isShardFolder,
            tagData: tagData,
            imageURLStr: imageURLStr)
        item.chatUserCount = chatUserCount
        item.isUserCountVisible = isUserCountVisible
        item.avatarId = avatarId
        item.deniedReasons = deniedReasons
        Self.logger.info("init forwardItem with id:\(id), chatId:\(chatId), type:\(type), thread: \(isThread), outer: \(isCrossTenant)")
        // after filter
        if params.includeConfigs != nil {
            return item
        }
        return self.filter?(item) != false ? item : nil
    }
    // enable-lint: long_function
    // nolint: duplicated_code 两者使用的数据结构不同,且后续会废弃ChatPicker
    @objc
    private func presentPreviewViewController(button: UIButton) {
        guard results.count > button.tag,
              let fromVC = self.fromVC
        else { return }
        let item = results[button.tag]
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

    // MARK: Result Table View
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let isLastRow = results.count == indexPath.row + 1
        switch params.pickType {
        case .defaultType:
            if let cell = model.reuseCell(in: tableView, resolver: self.userResolver,
                                                 selectionDataSource: self,
                                                 isLastRow: isLastRow, targetPreview: targetPreview, isShowDepartmentTail: isShowDepartmentInfoFG) {
                cell.targetInfo.tag = indexPath.row
                cell.targetInfo.addTarget(self, action: #selector(presentPreviewViewController(button:)), for: .touchUpInside)
                return cell
            }
        case .chat, .userAndGroupChat:
            if let cell = model.reuseChatCell(in: tableView,
                                              resolver: self.userResolver,
                                              selectionDataSource: self,
                                              isLastRow: isLastRow) {
                return cell
            }
        case .folder, .workspace:
            if let cell = model.reuseWikiCell(in: tableView,
                                              resolver: self.userResolver,
                                              selectionDataSource: self,
                                              pickType: params.pickType,
                                              isLastRow: isLastRow) {
                return cell
            }
        case .filter:
            if let cell = model.reuseFilterCell(in: tableView,
                                                resolver: self.userResolver,
                                                selectionDataSource: self,
                                                pickType: params.pickType,
                                                isLastRow: isLastRow) {
                return cell
            }
        default: break
        }
        assertionFailure()
        return UITableViewCell()
    }

    lazy var isFinishAfterMultiSelectFG = SearchFeatureGatingKey.finishAfterMultiSelect.isUserEnabled(userResolver: self.userResolver)
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let model = results[indexPath.row]
        let v = self.toggle(option: model,
                            from: PickerSelectedFromInfo(sender: self, container: tableView, indexPath: indexPath, tag: "search"),
                            at: tableView.absolutePosition(at: indexPath),
                            event: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_CLICK,
                            target: Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_VIEW)
        if isFinishAfterMultiSelectFG {
            afterSelected(success: v)
        } else {
            setSearchBarSelectAllMode(searchBar: searchBar)
        }
    }
    public func triggerSearch() {
        search()
    }

    func afterSelected(success: Bool) {
        if success && isMultiple && self.clearQueryWhenSelected {
            searchBar.searchUITextField.text = ""
            searchViewTableViewKeyboardHandler?.resetFocus(shouldScrollToVisiable: false)
            self.search() // trigger change and show default view
        }
    }
    // MARK: KeyCommand 转发
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
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return resultView.tableview
    }

    public func showPlaceholder(state: ListVM.State) {
        self.resultView.isHidden = true
        self.topView?.isHidden = false
    }
    public func hidePlaceholder(state: ListVM.State) {
        self.resultView.isHidden = false
        self.topView?.isHidden = true
        // Picker 埋点
        SearchTrackUtil.trackPickerSelectSearchMemberView()
    }
}

extension ChatPicker: SelectedViewDelegate {
    public func unfold() {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.delegate?.unfold(self)
    }
}

extension ForwardItem: SelectedOptionInfoConvertable, SelectedOptionInfo {
    public var avaterIdentifier: String { self.avatarId ?? self.id }
    public var miniIcon: UIImage? {
        if type == .threadMessage {
            return BundleResources.LarkSearchCore.Picker.thread_topic
        }
        return nil
    }
    public var isMsgThread: Bool {
        return self.type == .replyThreadMessage
    }
}

public struct PickerSelectedFromInfo {
    /// 调用者, 一般是对应代码的self
    public var sender: Any?
    /// 容器View, 通常是tableView
    public var container: UIView?
    /// 操作item所在的位置
    public var indexPath: IndexPath?
    /// 额外的tag标识
    public var tag: String = ""
    /// 是否是搜索结果
    public var isSearch: Bool { tag == "search" }
}

public extension UDColor.Name {
    static let imMessageBgReactionBlue = UDColor.Name("imtoken-message-bg-reaction-blue")
}

public var imMessageBgReactionBlue: UIColor {
    return UDColor.getValueByKey(.imMessageBgReactionBlue) ?? UDColor.colorfulBlue.withAlphaComponent(0.15) & UDColor.rgb(0x102954)
}
