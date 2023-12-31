//
//  SelectionExternalContactsContentView.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/6.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkFeatureSwitch
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkAlertController
import UniverseDesignToast
import LarkAccountInterface
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkFeatureGating
import LarkSearchCore
import LKCommonsLogging
import UniverseDesignEmpty
import EENavigator
import Homeric
import LarkBizTag
import RustPB
import LarkContainer

private struct ExternalContractsContent {
    let chatter: Chatter
    let passportUserService: PassportUserService
    let hideCheckBox: Bool
    let enableCheckBox: Bool
    let isSelected: Bool
    let checkInDoNotDisturb: ((Int64) -> Bool)
    let canSelectExternalContacts: Bool
    let canSelect: Bool
    let tenantName: String
    let targetPreview: Bool
}

final class SelectionExternalContactsContentView: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                               HasSelectChannel, TableViewKeyboardHandlerDelegate, UserResolverWrapper {

    var selectChannel: SelectChannel {
        return .external
    }
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool
    static let log = Logger.log(SelectionExternalContactsContentView.self, category: "LarkContact")

    weak var selectionSource: SelectionDataSource?
    let viewModel: SelectionExternalContactsViewModel

    private let passportUserService: PassportUserService
    private let serverNTPTimeService: ServerNTPTimeService
    private let tableView = UITableView(frame: CGRect.zero)
    let disposeBag = DisposeBag()

    /// 勿扰模式检查
    lazy var checkInDoNotDisturb: ((Int64) -> Bool) = { [weak self] time -> Bool in
        guard let `self` = self else { return false }
        return self.serverNTPTimeService.afterThatServerTime(time: time)
    }

    private var datasource: [NewSelectExternalContact] = [] {
        didSet {
            if datasource.isEmpty {
                self.tableView.isHidden = true
                self.emptyView.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.emptyView.isHidden = true
            }
        }
    }
    private let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty),
        type: .noContact)
    )
    private let loadingPlaceholderView = LoadingPlaceholderView()

    // Tableview keyboard
    private var keyboardHandler: TableViewKeyboardHandler?

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? [])
    }

    struct Config {
        let pickerTracker: PickerAppReciable?
        let selectedHandler: ((Int) -> Void)?
    }
    private let config: Config
    public var targetPreview: Bool = false
    weak var fromVC: UIViewController?

    var canSelectExternalContacts = true
    var userResolver: LarkContainer.UserResolver
    init(
        viewModel: SelectionExternalContactsViewModel,
        selectionSource: SelectionDataSource,
        serverNTPTimeService: ServerNTPTimeService,
        config: Config,
        targetPreview: Bool = false,
        resolver: UserResolver
    ) throws {
        self.viewModel = viewModel
        self.selectionSource = selectionSource

        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.serverNTPTimeService = serverNTPTimeService
        self.config = config
        self.targetPreview = targetPreview
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)

        self.config.pickerTracker?.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.LarkContact.Lark_Legacy_StructureExternal
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(emptyView)
        emptyView.useCenterConstraints = true
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        initializeTableView()

        loadingPlaceholderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingPlaceholderView.frame = view.bounds
        view.addSubview(loadingPlaceholderView)

        bindViewModel()
        // keyboard
        keyboardHandler = TableViewKeyboardHandler(
            options: [.allowCellFocused(focused: Display.pad)]
        )
        keyboardHandler?.delegate = self

        self.config.pickerTracker?.firstRenderEnd()
        // Picker 埋点
        SearchTrackUtil.trackPickerSelectExternalView()
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let item = datasource[indexPath.row]
        // 通过behavior控制禁选时的错误弹窗
        let i = ContactPickerResultItem(externalContact: item.contactInfo)
        if let picker = selectionSource as? AddChatterPicker,
           let behavior = picker.params.externalContactBehavior,
           behavior.pickerItemCanSelect?(i) == false,
           let reason = behavior.pickerItemDisableReason?(i),
           let window = self.view.window {
            UDToast.showTips(with: reason, on: window)
            return
        }
        guard canSelectExternalContacts else {
            if let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_Chat_Add_Member_PublicChatAddExternalUser_ErrrorTip, on: window)
            }
            return
        }
        if let deniedReason = item.deniedReason, let window = self.view.window {
            if deniedReason == .blocked { // 被屏蔽逻辑, 由PickerBlockUserHandler统一处理
                let tips = deniedReason == .blocked ?
                    BundleI18n.LarkContact.Lark_NewContacts_BlockedOthersUnableToXToastGeneral :
                    BundleI18n.LarkContact.Lark_NewContacts_BlockedUnableToXToastGeneral
                UDToast.showTips(with: tips, on: window)
                return
            }
            if deniedReason == .sameTenantDeny {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Groups_NoPermissionToAdd, on: window)
                return
            }
            if deniedReason == .cryptoChatDeny {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Chat_CantSecretChatWithUserSecurityRestrict, on: window)
                return
            }
            if deniedReason == .targetExternalCoordinateCtl || deniedReason == .externalCoordinateCtl {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Contacts_CantAddExternalContactNoExternalCommunicationPermission, on: window)
                return
            }
        }

        if let chatter = item.chatter, let selectionSource = self.selectionSource {
            if viewModel.chattersIdsInChat.contains(chatter.id) {
                return
            }

            if selectionSource.toggle(option: item,
                                      from: self,
                                      at: tableView.absolutePosition(at: indexPath),
                                      event: Homeric.PUBLIC_PICKER_SELECT_EXTERNAL_CLICK,
                                      target: Homeric.PUBLIC_PICKER_SELECT_EXTERNAL_VIEW),
               selectionSource.state(for: item, from: self).selected {
                self.config.selectedHandler?(indexPath.row + 1)
            }

        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: ContactSearchTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ContactSearchTableViewCell {
            let selectExternalContact = self.datasource[indexPath.row]
            if let chatter = selectExternalContact.chatter, let selectionSource = self.selectionSource {
                var canSelect = true
                if let deniedReason = selectExternalContact.deniedReason {
                    let contactAuthNeedBlock = (deniedReason == .beBlocked || deniedReason == .blocked)
                    let OUAuthNeedBlock = (deniedReason == .sameTenantDeny)
                    let hasCryptoDeniedReason = deniedReason == .cryptoChatDeny
                    let coordinateCtl = deniedReason == .externalCoordinateCtl || deniedReason == .targetExternalCoordinateCtl
                    if contactAuthNeedBlock || OUAuthNeedBlock || hasCryptoDeniedReason || coordinateCtl {
                        canSelect = false
                    }
                }
                let state = selectionSource.state(for: chatter, from: self)
                // 通过behavior控制是否可选
                let i = ContactPickerResultItem(externalContact: selectExternalContact.contactInfo)
                if let picker = selectionSource as? AddChatterPicker,
                   let behavior = picker.params.externalContactBehavior,
                   behavior.pickerItemCanSelect?(i) == false {
                    canSelect = false
                }

                let externalContractsContent = ExternalContractsContent(
                    chatter: chatter,
                    passportUserService: passportUserService,
                    hideCheckBox: !selectionSource.isMultiple,
                    enableCheckBox: !(viewModel.chattersIdsInChat.contains(chatter.id) || state.disabled),
                    isSelected: viewModel.chattersIdsInChat.contains(chatter.id) || state.selected,
                    checkInDoNotDisturb: checkInDoNotDisturb,
                    canSelectExternalContacts: canSelectExternalContacts,
                    canSelect: canSelect && !state.disabled,
                    tenantName: selectExternalContact.contactInfo.tenantName,
                    targetPreview: targetPreview && TargetPreviewUtils.canTargetPreview(chatter: chatter)
                )
                cell.setExternalContractsContent(externalContractsContent)
            }
            cell.targetInfo.tag = indexPath.row
            cell.targetInfo.addTarget(self, action: #selector(presentPreviewViewController(button:)), for: .touchUpInside)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    @objc
    private func presentPreviewViewController(button: UIButton) {
        guard datasource.count > button.tag else { return }
        let item = datasource[button.tag]
        guard let fromVC = self.fromVC, let chatter = item.chatter else { return }
        if !TargetPreviewUtils.canTargetPreview(chatter: chatter) {
            if let window = fromVC.view.window {
                UDToast.showTips(with: BundleI18n.LarkContact.Lark_IM_UnableToPreviewContent_Toast, on: window)
            }
        } else {
            var name = chatter.name
            if isSupportAnotherNameFG && !chatter.nameWithAnotherName.isEmpty {
                name = chatter.nameWithAnotherName
            }
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: "", userId: chatter.id, title: name)
            navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        }
        let picker = selectionSource as? Picker
        SearchTrackUtil.trackPickerSelectClick(scene: picker?.scene, clickType: .chatDetail(target: "none"))
    }

    private func initializeTableView() {
        view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = view.bounds

        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        let identifier = String(describing: ContactSearchTableViewCell.self)
        tableView.register(ContactSearchTableViewCell.self, forCellReuseIdentifier: identifier)
    }

    private func bindViewModel() {
        selectionSource?.isMultipleChangeObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        selectionSource?.selectedChangeObservable.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        self.loadingPlaceholderView.isHidden = false

        let startLoadTimeStamp = CACurrentMediaTime()
        self.viewModel.datasourceDriver.drive(onNext: { [weak self] (contacts) in
            guard let self = self else { return }
            self.datasource = contacts
            self.loadingPlaceholderView.isHidden = true
            self.tableView.reloadData()
            self.config.pickerTracker?.updateSDKCost(CACurrentMediaTime() - startLoadTimeStamp)
            self.config.pickerTracker?.endLoadingTime()
        }).disposed(by: self.disposeBag)

        self.viewModel.hasMoreDriver.drive(onNext: { [weak self] (hasMore) in
            guard let `self` = self else { return }
            self.tableView.endBottomLoadMore()
            if hasMore {
                self.tableView.addBottomLoadMoreView { [weak self] in
                    self?.viewModel.loadMore(onError: { [weak self] error in
                        self?.config.pickerTracker?.error(error)
                    })
                }
            } else {
                self.tableView.removeBottomLoadMore()
            }
        }).disposed(by: self.disposeBag)

        self.viewModel.preloadData(onError: { [weak self] error in
            self?.config.pickerTracker?.error(error)
        })
    }
}

extension ContactSearchTableViewCell {
    private func transformChatterToSearchResult(chatter: Chatter, tenantName: String) -> Search.Result {
        var searchResult = Search_V2_SearchResult()

        var userMeta = Search_V2_UserMeta()
        userMeta.id = chatter.id
        userMeta.description_p = chatter.description_p.text
        userMeta.descriptionFlag = chatter.description_p.type
        userMeta.timezone.name = ""
        userMeta.doNotDisturbEndTime = chatter.doNotDisturbEndTime
        userMeta.tenantID = chatter.tenantId
        userMeta.isRegistered = chatter.isRegistered

        searchResult.resultMeta.typedMeta = Search_V2_SearchResult.ResultMeta.OneOf_TypedMeta.userMeta(userMeta)
        searchResult.avatarKey = chatter.avatarKey
        var name = chatter.name
        if isSupportAnotherNameFG && !chatter.nameWithAnotherName.isEmpty {
            name = chatter.nameWithAnotherName
        }
        searchResult.titleHighlighted = chatter.alias.isEmpty ? name : chatter.alias
        searchResult.summaryHighlighted = tenantName
        SelectionExternalContactsContentView.log.debug("[UGDebug]: cell searchResult avatarKey = \(chatter.avatarKey), title = \(searchResult.titleHighlighted)")
        return Search.Result(base: searchResult, contextID: nil)
    }

    fileprivate func setExternalContractsContent(_ content: ExternalContractsContent) {
        self.setContent(
            searchResult: transformChatterToSearchResult(
                chatter: content.chatter,
                tenantName: content.tenantName
            ),
            searchText: "",
            currentTenantId: content.passportUserService.userTenant.tenantID,
            hideCheckBox: content.hideCheckBox,
            enableCheckBox: content.enableCheckBox,
            isSelected: content.isSelected,
            checkInDoNotDisturb: content.checkInDoNotDisturb,
            needShowMail: false,
            currentUserType: Account.userTypeFromPassportUserType(content.passportUserService.user.type),
            // 此处为外部联系人选人列表 canSelectExternalContacts = false一定是公开群
            isPublic: !content.canSelectExternalContacts,
            canSelect: content.canSelect,
            targetPreview: content.targetPreview,
            tagData: content.chatter.tagData
        )
    }
}
