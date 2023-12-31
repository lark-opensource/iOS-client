//
//  AtUserDefaultView.swift
//  LarkForward
//
//  Created by Jiang Chun on 2022/4/14.
//

import Foundation
import UIKit
import RxSwift
import LarkFeatureGating
import LarkMessengerInterface
import LarkAccountInterface
import LKCommonsLogging
import LarkModel
import UniverseDesignToast
import LarkKeyCommandKit
import Homeric
import LarkUIKit
import RustPB
import LarkContainer
import LarkSDKInterface

public final class AtUserDefaultView: UIView, UITableViewDelegate, UITableViewDataSource, TableViewKeyboardHandlerDelegate, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    static let logger = Logger.log(AtUserDefaultView.self, category: "AtUserDefaultView")
    weak var selectionDataSource: SelectionDataSource?
    let tableView: UITableView
    var keyboardHandler: TableViewKeyboardHandler?
    let bag = DisposeBag()

    let filter: ForwardItemFilter?
    let canForwardToTopic: Bool

    @ScopedInjectedLazy var serviceContainer: PickerServiceContainer?

    lazy var feedSyncDispatchService: FeedSyncDispatchService? = { self.serviceContainer?.feedSyncDispatchService }()
    lazy var contactAPI: ContactAPI? = { self.serviceContainer?.contactAPI }()
    private let scene: String?
    weak var fromVC: UIViewController?

    public init(resolver: UserResolver,
                frame: CGRect,
                customView: UIView?,
                selection: SelectionDataSource,
                canForwardToTopic: Bool,
                scene: String?,
                fromVC: UIViewController,
                filter: ((ForwardItem) -> Bool)?) {
        self.userResolver = resolver
        tableView = UITableView(frame: CGRect(origin: .zero, size: frame.size), style: .plain)
        selectionDataSource = selection
        self.filter = filter
        self.canForwardToTopic = canForwardToTopic
        self.scene = scene
        self.fromVC = fromVC
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgBody

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = 68
        tableView.separatorColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.register(AtUserTableViewCell.self, forCellReuseIdentifier: "AtUserTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        if let customView = customView {
            // set to nil cause a space at head! so only set when pass a view
            tableView.tableHeaderView = customView
        }
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif

        self.addSubview(tableView)

        // tableview keyboard
        keyboardHandler = TableViewKeyboardHandler(options: [.allowCellFocused(focused: Display.pad)])
        keyboardHandler?.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var loaded = false // lazy load when appear on window
    public override func willMove(toWindow newWindow: UIWindow?) {
        guard !loaded, newWindow != nil else { return }
        loaded = true

        loadData()
        // FIXME: 是否有动态切换的选项?
        let tableView = self.tableView
        selectionDataSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: {_ in
            tableView.reloadData()
            }).disposed(by: bag)
        selectionDataSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: {_ in
            tableView.reloadData()
            }).disposed(by: bag)
    }

    // MARK: Model
    static let maxDataCount = 40
    static let minShowDataCount = 3
    var sections: [ForwardSectionData] = []
    // nolint: long_function 内部有函数拆分,后续整个类会做重构
    func loadData() {
        // TODO: 外部有其他依赖直接复用了ForwardViewModel

        struct Context {
            var resolver: UserResolver
            var sections: [ForwardSectionData] = []
            func makeItem(chatter: Basic_V1_Chatter, type: ForwardItemType) -> ForwardItem {
                let userService = try? resolver.resolve(assert: PassportUserService.self)
                var item = ForwardItem(
                    avatarKey: chatter.avatarKey,
                    name: chatter.nameWithAnotherName,
                    subtitle: "",
                    description: chatter.description_p.text,
                    descriptionType: chatter.description_p.type ?? .onDefault,
                    localizeName: chatter.localizedName,
                    id: chatter.id,
                    chatId: chatter.chatExtra.chatID,
                    type: type,
                    isCrossTenant: false,
                    isCrossWithKa: false,
                    // code_next_line tag CryptChat
                    isCrypto: false,
                    isThread: false,
                    channelID: "",
                    doNotDisturbEndTime: chatter.doNotDisturbEndTime ?? 0,
                    hasInvitePermission: true,
                    userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                    enableThreadMiniIcon: false,
                    isOfficialOncall: false,
                    tags: chatter.tags,
                    customStatus: chatter.status.topActive,
                    tagData: chatter.tagInfo
                )
                AtUserDefaultView.logger.info("init forwardItem with id:\(chatter.id), chatId:\(chatter.chatExtra.chatID), type:\(type)")
                return item
            }
        }
        var context = Context(resolver: self.userResolver)
        var counter = 0
        let reload = { [weak self] in
            guard let self = self else { return }
            counter += 1
            let sections = context.sections
            // 获取需要去查询权限的外部联系人，dic[key: value] key是chatterId，valus是chatID
            var authDic: [String: String] = [:]
            // 过滤出没有外部联系人的items
            let items = sections.map({ (data) -> ForwardSectionData in
                var data = data
                data.dataSource = data.dataSource.filter({ (item) -> Bool in
                    if item.isCrossTenant, item.type == .user, !(item.chatId?.isEmpty ?? true) {
                        authDic[item.id] = item.chatId
                        return false
                    }
                    return true
                })
                return data
            })
            // 根据过滤的数据先初始化list
            self.reload(items: items)
            // 如果没有鉴权的用户直接结束
            guard !authDic.isEmpty else {
                return
            }
            // 批量查询外部联系人的权限
            self.contactAPI?.fetchAuthChattersRequest(
                actionType: .shareMessageSelectUser, isFromServer: true, chattersAuthInfo: authDic
            ).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, capture = counter] (res) in // 异步排重
                guard let `self` = self, capture == counter else { return }
                let sections = sections.map { (data) -> ForwardSectionData in
                    var newData = data
                    let dataSource = data.dataSource.map { (item) -> ForwardItem in
                        guard let deniedReason = res.authResult.deniedReasons[item.id] else {
                            return item
                        }
                        var item = item
                        // 如果block则没有权限
                        if item.isCrossTenant,
                           item.type == .user,
                           deniedReason == .blocked {
                            item.hasInvitePermission = false
                        } else {
                            switch deniedReason {
                            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                                item.hasInvitePermission = false
                            @unknown default: break
                            }
                        }
                        return item
                    }
                    newData.dataSource = dataSource
                    return newData
                }
                self.reload(items: sections)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.reload(items: sections)
                Self.logger.error("fetchAuthChattersRequest error, error = \(error)")
            }).disposed(by: self.bag)
        }

        // 加载可能想at的人的数据
        func loadWantToMentionItems() {
            let maxWantToMentionNumber: Int32 = 30
            contactAPI?.getWantToMentionChatters(topCount: maxWantToMentionNumber)
                .retry(2)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let self = self else { return }
                    var chatters: [Basic_V1_Chatter] = []
                    let wantToMentionIds = resp.wantToMentionIds
                    let idToChatters = resp.entity.chatters
                    for id in wantToMentionIds {
                        let chatter = idToChatters[id]
                        guard let chatter = chatter else { continue }
                        chatters.append(chatter)
                    }
                    /// 转发mention推荐过滤MyAi
                    let mentionItems = chatters.filter { $0.type != .ai }
                        .map { chatter -> ForwardItem in
                            let tmpChatterType = ForwardItemType(rawValue: chatter.type.rawValue ?? 0) ?? .unknown
                            return context.makeItem(chatter: chatter, type: tmpChatterType)
                        }
                    let wantToMentionSection = ForwardSectionData(title: "",
                                                                  dataSource: mentionItems,
                                                                  canFold: false,
                                                                  shouldFold: false,
                                                                  tag: "mention")
                    context.sections.append(wantToMentionSection)
                    // update UI after async load
                    reload()
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    self.reload(items: self.sections)
                    Self.logger.error("getWantToMentionChattersRequest error, error = \(error)")
                }).disposed(by: self.bag)
        }

        loadWantToMentionItems()
        reload()
    }
    // enable-lint: long_function

    func reload(items: [ForwardSectionData]) {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.sections = items
        self.tableView.reloadData()
    }

    // MARK: TableView
    static let headerViewHeight: CGFloat = 23
    static let footerViewHeight: CGFloat = 32
    public func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        let count = section.dataSource.count
        if section.canFold, section.shouldFold {
            return min(count, Self.minShowDataCount)
        }
        return count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.sections[indexPath.section]
        let model = section.dataSource[indexPath.row]
        let lastRow = section.dataSource.count == indexPath.row + 1
        if let selectionDataSource = self.selectionDataSource,
           let cell = model.reuseAtUserCell(in: tableView, resolver: self.userResolver, selectionDataSource: selectionDataSource, isLastRow: lastRow, fromVC: self.fromVC) {
            return cell
        }

        assertionFailure()
        return UITableViewCell()
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        guard let model = model(at: indexPath), let selectionDataSource = self.selectionDataSource else { return }
        selectionDataSource.toggle(option: model,
                                   from: PickerSelectedFromInfo(sender: self, container: tableView, indexPath: indexPath, tag: sections[indexPath.section].tag),
                                   at: tableView.absolutePosition(at: indexPath),
                                   event: Homeric.PUBLIC_PICKER_SELECT_CLICK,
                                   target: Homeric.PUBLIC_PICKER_SELECT_VIEW,
                                   scene: self.scene)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (sections.count == 1 && sections[0].title.isEmpty) || sections[section].dataSource.isEmpty {
            return nil
        }
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody

        let headerLabel = UILabel()
        headerLabel.textColor = UIColor.ud.textPlaceholder
        headerLabel.textAlignment = .left
        headerLabel.font = UIFont.systemFont(ofSize: 12)
        headerLabel.text = sections[section].title
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(17)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        if section != 0 { headerView.lu.addTopBorder() }

        return headerView
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (sections.count == 1 && sections[section].title.isEmpty) || sections[section].dataSource.isEmpty {
            return .leastNormalMagnitude
        } else {
            return Self.headerViewHeight
        }
    }

    // nolint: duplicated_code 创建视图的方式略有不同
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard sections[section].canFold else { return nil }

        let footerView = UIView()
        footerView.backgroundColor = UIColor.ud.bgBody
        let warpperView = UIView()

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        footerView.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.top.left.right.equalToSuperview()
        }

        let footerLabel = UILabel()
        footerLabel.text = sections[section].shouldFold ? BundleI18n.LarkSearchCore.Lark_Legacy_ItemShowMore : BundleI18n.LarkSearchCore.Lark_Legacy_ItemShowLess
        footerLabel.textColor = UIColor.ud.textPlaceholder
        footerLabel.textAlignment = .center
        footerLabel.font = UIFont.systemFont(ofSize: 12)

        warpperView.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(7)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        let image = sections[section].shouldFold ? Resources.LarkSearchCore.Picker.table_fold : BundleResources.LarkSearchCore.Picker.table_unfold
        let footerImageView = UIImageView(image: image)
        warpperView.addSubview(footerImageView)
        footerImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(12)
            make.centerY.equalTo(footerLabel)
            make.left.equalTo(footerLabel.snp.right).offset(4)
            make.right.equalToSuperview()
        }

        footerView.addSubview(warpperView)
        warpperView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        footerView.tag = section
        footerView.lu.addTapGestureRecognizer(action: #selector(tapFooterView(_:)),
                                              target: self,
                                              touchNumber: 1)
        return footerView
    }
    // enable-lint: duplicated_code
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].canFold {
            return Self.footerViewHeight
        } else {
            return .leastNormalMagnitude
        }
    }
    @objc
    private func tapFooterView(_ sender: UIGestureRecognizer) {
        guard let section = sender.view?.tag, section < sections.count else { return }
        sections[section].shouldFold.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .none)
    }

    func model(at: IndexPath) -> ForwardItem? {
        if at.section < sections.count, case let section = sections[at.section],
           at.row < section.dataSource.count {
            return section.dataSource[at.row]
        }
        return nil
    }
    // MARK: KeyBinding
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }
    // TableViewKeyboardHandlerDelegate
    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

}

extension ForwardItem {
    func reuseAtUserCell(in tableView: UITableView,
                         resolver: LarkContainer.UserResolver,
                         selectionDataSource: SelectionDataSource,
                         isLastRow: Bool = false,
                         fromVC: UIViewController?) -> AtUserTableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AtUserTableViewCell") as? AtUserTableViewCell else { return nil }

        let state = selectionDataSource.state(for: self, from: tableView)
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let serverNTPTimeService = try? resolver.resolve(assert: ServerNTPTimeService.self)
        cell.personInfoView.bottomSeperator.isHidden = isLastRow
        cell.setContent(resolver: resolver,
                        model: self,
                        currentTenantId: userService?.userTenant.tenantID ?? "",
                        isSelected: state.selected,
                        hideCheckBox: !selectionDataSource.isMultiple,
                        enable: !state.disabled && self.hasInvitePermission,
                        animated: false,
                        fromVC: fromVC,
                        checkInDoNotDisturb: serverNTPTimeService?.afterThatServerTime(time:) ?? { _ in false })
        return cell
    }
}
