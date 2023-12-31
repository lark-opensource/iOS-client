//
//  AtPicker.swift
//  LarkSearchCore
//
//  Created by Jiang Chun on 2022/4/14.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkCore
import SnapKit
import LarkModel
import LarkMessengerInterface
import LarkFeatureGating
import UniverseDesignToast
import LarkSDKInterface
import RustPB
import LarkKeyCommandKit
import LarkKeyboardKit
import Homeric
import LarkBizTag
import LarkFocusInterface
import LarkContainer

public final class AtPicker: Picker, UITableViewDataSource, UITableViewDelegate, PickerCommonUI, TableViewKeyboardHandlerDelegate {
    public final class InitParam: Picker.InitParam {
        /// 是否包含外部租户
        public var includeOuterTenant = true
        /// 是否包含thread的数据
        public var includeThread = true
        /// 是否确认选择权限
        // public var checkInvitePermission = true

        /// TODO: 目前先迁移兼容，以后可能会收敛filter，不再提供
        public var filter: ForwardDataFilter?
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
    public let params: InitParam

    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        includeOuterTenant = params.includeOuterTenant
        includeThread = params.includeThread
        filter = params.filter
        self.params = params
        defaultView = UIView()
        defaultView.backgroundColor = UIColor.ud.red
        super.init(resolver: resolver, frame: frame, params: params)
        self.searchTextFieldAutoFocus = Display.pad && KeyboardKit.shared.keyboardType == .hardware
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
    let searchBar = SearchUITextFieldWrapperView()

    public let resultView = SearchResultView(tableStyle: .plain)
    public lazy var selectedView: SelectedView = {
        let view = SelectedView(frame: .zero, delegate: self, supportUnfold: true)
        view.scene = scene
        return view
    }()
    public var defaultView: UIView

    func viewLoaded() {
        resultView.tableview.register(AtUserTableViewCell.self, forCellReuseIdentifier: "AtUserTableViewCell")
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
                self?.searchViewTableViewKeyboardHandler?.resetFocus(shouldScrollToVisiable: false)
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
    lazy var searchVM: SearchSimpleVM<Item> = {
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.transmitMessages))
        maker.needSearchOuterTenant = includeOuterTenant
        maker.doNotSearchResignedUser = true // 测试发现这个scene不会返回离职人员，这里设置上方便后续v2兼容
        // TODO: 权限可能要让外部配置
        maker.authPermissions = [.createP2PChat]
        maker.includeThread = includeThread
        maker.includeMyAi = params.includeMyAi
        maker.myAiMustTalked = params.myAiMustTalked
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
        return vm
    }()
    // TODO: 换成依赖更小的，而不是现在这样特化的ForwardItem
    // nolint: duplicated_code 不同业务映射逻辑略有不同
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
        var doNotDisturbEndTime: Int64 = 0
        var hasInvitePermission: Bool = true
        var isOfficialOncall: Bool = false
        var channelID: String?
        var chatId = ""
        var chatUserCount = 0 as Int32
        var customStatus: ChatterFocusStatus?
        var tagData: Basic_V1_TagData?

        switch result.meta {
        case .chatter(let chatter):
            id = chatter.id
            type = ForwardItemType(rawValue: chatter.type.rawValue) ?? .unknown
            /// 转发mention搜索屏蔽MyAi
            if type == .myAi { return nil }
            description = chatter.description_p
            flag = chatter.descriptionFlag
            isCrossTenant = (chatter.tenantID != (userService?.userTenant.tenantID ?? ""))
            doNotDisturbEndTime = chatter.doNotDisturbEndTime
            customStatus = chatter.customStatus.topActive
            tagData = chatter.relationTag.toBasicTagData()
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
            isCrypto = chat.isCrypto
            isThread = chat.chatMode == .threadV2
            isOfficialOncall = chat.isOfficialOncall
            chatUserCount = chat.userCountWithBackup
            tagData = chat.relationTag.toBasicTagData()
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
            tagData: tagData)
        item.chatUserCount = chatUserCount
        Self.logger.info("init forwardItem with id:\(id), chatId:\(chatId), type:\(type)")
        // after filter
        return self.filter?(item) != false ? item : nil
    }
    // enable-lint: duplicated_code

    // MARK: Result Table View
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let lastRow = results.count == indexPath.row + 1
        if let cell = model.reuseAtUserCell(in: tableView, resolver: self.userResolver, selectionDataSource: self, isLastRow: lastRow, fromVC: self.fromVC) {
            return cell
        }
        assertionFailure()
        return UITableViewCell()
    }
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
        afterSelected(success: v)
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

extension AtPicker: SelectedViewDelegate {
    public func unfold() {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.delegate?.unfold(self)
    }
}

//extension ForwardItem: SelectedOptionInfoConvertable, SelectedOptionInfo {
//    public var avaterIdentifier: String { self.id }
//    public var miniIcon: UIImage? {
//        if type == .threadMessage {
//            return BundleResources.LarkSearchCore.Picker.thread_topic
//        }
//        return nil
//    }
//}
