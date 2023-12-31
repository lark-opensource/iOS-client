//
//  CalendarSidebarDataProvider.swift
//  Calendar
//
//  Created by ByteDance on 2023/11/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignActionPanel
import LarkUIKit
import UniverseDesignDialog

struct CalendarSidebarModelData: SidebarModelData {
    
    var id: String {
        calendar.serverId
    }
    
    var trailBtnImg: UIImage? {
        if calendar.isGoogleCalendar() || calendar.isExchangeCalendar() || calendar.isLocalCalendar() {
            return nil
        }
        return FG.optimizeCalendar ? UDIcon.getIconByKeyNoLimitSize(.moreBoldOutlined) : UDIcon.getIconByKeyNoLimitSize(.settingOutlined)
    }
    
    let source: SidebarDataSource = .calendar
    
    var uniqueId: String {
        "\(source.description)\(calendar.serverId)"
    }
    
    var sectionType: CalendarListSection {
        var key: CalendarListSection
        let model = calendar
        if model.selfAccessRole == .owner {
            if model.type == .google {
                key = .google(CalendarListSectionContent(sourceTitle: model.externalAccountName))
            } else if model.type == .exchange {
                key = .exchange(CalendarListSectionContent(sourceTitle: model.externalAccountName))
            } else {
                let title = FG.optimizeCalendar ? I18n.Calendar_Manage_Managing : I18n.Calendar_Common_MyCalendars
                key = .larkMine(CalendarListSectionContent(sourceTitle: title))
            }
        } else if model.isLocalCalendar(),
                  let cal = model as? CalendarFromLocal {
            key = .local(CalendarListSectionContent(sourceTitle: cal.source.title))
        } else {
            let title = FG.optimizeCalendar ? I18n.Calendar_Manage_Following : I18n.Calendar_Common_SubscribedCalendar
            key = .larkSubscribe(CalendarListSectionContent(sourceTitle: title))
        }
        return key
    }
    
    var displayName: String {
        calendar.displayName()
    }
    
    var isVisible: Bool {
        calendar.isVisible
    }
    
    var weight: Int32 {
        calendar.weight
    }
    
    var colorIndex: ColorIndex {
        calendar.colorIndex
    }
    
    var isResign: Bool {
        !calendar.hiddenResignedTag
    }
    
    var isInactive: Bool {
        !calendar.hiddenInactivateTag
    }
    
    var isNeedApproval: Bool {
        !calendar.hiddenNeedApprovalTag
    }
    
    var accountValid: Bool {
        calendar.externalAccountValid
    }
    
    /// 由外部矫正
    var isExternal: Bool = false
    var isLoading: Bool = false
    var accountExpiring: Bool = false
    
    let calendar: CalendarModel
    
    init(from calendar: CalendarModel) {
        self.calendar = calendar
    }
}

class CalendarSidebarDataProvider: UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?

    private var user: CurrentUserInfo? {
        return calendarDependency?.currentUser
    }

    /// 数据源标识
    let source: SidebarDataSource = .calendar
    
    private(set) var data: [CalendarSidebarModelData] = []
    
    let dataChanged: BehaviorRelay<Void> = .init(value: ())


    private let queue = DispatchQueue(label: "lark.calendar.calendarListViewModel", qos: .userInteractive)
    
    private(set) var model: [CalendarModel] {
        get {
            queue.sync { [weak self] in
                return self?._model ?? []
            }
        }
        set {
            queue.async(group: nil, qos: .default, flags: .barrier) { [weak self] in
                guard let `self` = self else { return }
                self._model = newValue
            }
        }
    }
    private var _model: [CalendarModel] = []

    let rxShouldSwitchToOAuth: PublishRelay<Bool> = .init()

    var exchangeShouldOAuthAccounts = [String: String]()

    private var editVM: CalendarEditViewModel?

    private let disposeBag = DisposeBag()
    
    let rxRouter: PublishRelay<Route> = .init()
    let rxAlert = PublishRelay<(CalendarEditViewModel.Alert, UIViewController)>()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        
        self.bindRxRoute()
        self.bindRxAlert()

        guard let calendarManager = self.calendarManager,
              let pushService = self.pushService else {
            CalendarList.logError("init CalendarSidebarDataProvider failed, cannot get service from larkcontainer")
            return
        }

        self.updateModel(calendars: calendarManager.allCalendars)

        // 监听日历变化，v4.0版本只有exchange，后续会增加google
        let rxExternalCalendar = pushService.rxExternalCalendar.do(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.updateModel(calendars: calendarManager.allCalendars)
        }, afterNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.fetchExchangeOAuth()
        }).map { _ in }

        let rxCalendarUpdated = calendarManager.rxCalendarUpdated
            .do(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.updateModel(calendars: calendarManager.allCalendars)
            })

        let rxCalendarRefresh = pushService.rxCalendarRefresh.do(onNext: { [weak self] syncInfos in
            guard let `self` = self else { return }
            self.updateModel(calendarSyncInfos: syncInfos)
        }).map { _ in }

        Observable.merge(rxCalendarRefresh, rxCalendarUpdated, rxExternalCalendar)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.reload()
            })
            .disposed(by: disposeBag)

        self.fetchData()
    }

    func fetchData() {
        calendarManager?.updateAllCalendar()
        fetchExchangeOAuth()
    }

    func fetchExchangeOAuth() {
        calendarManager?.getShouldSwitchToOAuthExchangeAccounts()
            .asSingle()
            .subscribe(onSuccess: {[weak self] emailToAuthUrl in
                guard let self = self else { return }
                self.exchangeShouldOAuthAccounts = emailToAuthUrl
                if !emailToAuthUrl.isEmpty {
                    self.dataChanged.accept(())
                }
            }).disposed(by: disposeBag)
    }

    private func updateModel(calendars: [CalendarModel]) {
        self.model = calendars
            .filter { $0.isLocalCalendar() || $0.getCalendarPB().isSubscriber }
            .merge(isVisible: KVValues.getExternalCalendarVisible(accountName:)).localCalFilter()
    }

    private func updateModel(calendarSyncInfos: [Rust.CalendarSyncInfo]) {
        var calendars = self.model

        let syncInfoMap = calendarSyncInfos.reduce(into: [String: Rust.CalendarSyncInfo]()) { $0[$1.calendarID] = $1 }

        // 通过 SyncInfo 来的数据取消 loading
        calendars = calendars.map { calendar in
            var cal = calendar
            if let syncInfo = syncInfoMap[cal.serverId] {
                cal.upgradeCalendarSyncInfo(info: syncInfo)
            }
            return cal
        }


        self.model = calendars
    }

    private func reload() {
        self.data = self.transformSidebarModelData(models: self.model)
        self.dataChanged.accept(())
    }
    
    private func getCalIsLoading(_ model: CalendarModel) -> Bool {
        model.isLoading(
            eventViewStartTime: self.calendarManager?.eventViewStartTime ?? 0,
            eventViewEndTime: self.calendarManager?.eventViewEndTime ?? 0
        )
    }

    private func getCalIsExternal(_ model: CalendarModel) -> Bool {
        return model.getCalendarPB().cd.isExternalCalendar(userTenantId: user?.tenantId ?? "")
    }
    
    private func getCalAccountExpiring(_ model: CalendarModel) -> Bool {
        self.exchangeShouldOAuthAccounts[model.externalAccountName] != nil
    }

    private func transformSidebarModelData(models: [CalendarModel]) -> [CalendarSidebarModelData] {
        return models.map { calendar in
            var data = CalendarSidebarModelData(from: calendar)
            data.isExternal = self.getCalIsExternal(calendar)
            data.isLoading = self.getCalIsLoading(calendar)
            data.accountExpiring = self.getCalAccountExpiring(calendar)
            return data
        }
    }
}

// MARK: ArrayExtension
fileprivate extension Array where Element == CalendarModel {
    /// 本地日历的筛选
    func localCalFilter() -> [CalendarModel] {
        guard let sourceDic = KVValues.localCalendarSource else {
            return self.filter { !$0.isLocalCalendar() }
        }
        return self.reduce([]) { result, model in
            var result = result
            if model.isLocalCalendar() {
                guard let cal = model as? CalendarFromLocal,
                      let source = cal.source else { return result }
                if cal.ekType != .birthday,
                   source.sourceType != .subscribed,
                   source.sourceType != .birthdays,
                   sourceDic[source.sourceIdentifier] == true {
                    result.append(model)
                }
            } else {
                result.append(model)
            }
            return result
        }
    }

    /// 将google日历和lark日历合并，自己的google日历不合并
    func merge(isVisible: ((String) -> Bool)?) -> [CalendarModel] {
        return self.reduce([], { (result, m) -> [CalendarModel] in
            var r = result
            // 过滤本地设置不显示的google日历
            if m.type == .google, !(isVisible?(m.externalAccountName) ?? false) {
                return r
            }

            if m.type == .exchange, !(isVisible?(m.externalAccountName) ?? false) {
                return r
            }

            // 有依附的三方日历, 不显示在侧边栏
            if m.type == .exchange || m.type == .google {
                if !m.isPrimary && !m.userId.isEmpty && !(m.selfAccessRole == .owner) {
                    return r
                }
            }

            r.append(m)
            return r
        })
    }
}

// MARK: Router
extension CalendarSidebarDataProvider: SidebarDataProvider {
    var modelData: [SidebarModelData] {
        data
    }

    private func getCalendarBy(with uniqueId: String) -> CalendarModel? {
        if let modelData = self.data.first(where: { $0.uniqueId == uniqueId }) {
            return modelData.calendar
        }
        return nil
    }
    
    typealias Param = CalendarTracer.CalToggleCalendarVisibilityParam
    func updateVisibility(with uniqueId: String, from vc: UIViewController) {
        guard let calendar = getCalendarBy(with: uniqueId) else { return }
        let calType: Param.CalendarType
        if calendar.isLocalCalendar() {
            calType = .unknown
        } else {
            switch calendar.type {
            case .resources:
                calType = .meetingRoom
            case .other:
                calType = .publicCalendar
            @unknown default:
                calType = .contacts
            }
        }
        CalendarTracer
            .shareInstance
            .calToggleCalendarVisibility(actionTargetStatus: .init(isChecked: !calendar.isVisible),
                                         calendarType: calType)
        let isLocal = calendar.isLocalCalendar()
        let isVisible = !calendar.isVisible
        if !isLocal && isVisible {
            calendarSelectTracer?.start(with: calendar.serverId)
        }

        calendarManager?.updateCalendarVisibility(serverId: calendar.serverId, visibility: isVisible, isLocal: isLocal)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                if error.errorType() == .exceedMaxVisibleCalNum,
                   let window = self?.userResolver.navigator.mainSceneWindow {
                    UDToast.showFailure(with: I18n.Calendar_Detail_TooMuchViewReduce, on: window)
                }
                CalendarList.logError("update Calendar \(calendar.serverId) isVisible to \(!calendar.isVisible) error!!!")
                self?.dataChanged.accept(())
            }).disposed(by: disposeBag)
    }
    
    func clickTrailView(with uniqueId: String, from: UIViewController, _ popAnchor: UIView) {
        self.tapSetting(with: uniqueId, from: from, popAnchor)
    }
    
    func clickFooterView(with uniqueId: String, from: UIViewController) {
        self.tapExternal(with: uniqueId, from: from)
    }
    
    private func tapSetting(with uniqueId: String, from: UIViewController, _ popAnchor: UIView) {
        guard let calendar = data.first(where: { $0.uniqueId == uniqueId })?.calendar else { return }
        if FG.optimizeCalendar {
            self.editVM = CalendarEditViewModel(from: .fromEdit(calendar: calendar.getCalendarPB()), userResolver: self.userResolver)
            self.editVM?.rxCalendarListRefresh.bind(onNext: { [weak self] _ in
                self?.calendarManager?.updateAllCalendar()
            })
            .disposed(by: disposeBag)
            let isOwner = calendar.isOwnerOrWriter()
            let popSource = UDActionSheetSource(sourceView: popAnchor,
                                                sourceRect: popAnchor.bounds,
                                                arrowDirection: .right)
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: popSource))

            let showThisOnly: ActionSheetAction = { [weak self] in
                guard let self = self, let vm = self.editVM else { return }
                vm.rxToastStatus
                    .bind(to: from.rx.toast).disposed(by: self.disposeBag)
                vm.showSelfOnly()
                CalendarTracerV2.CalendarList.traceClick {
                    $0.click("only_show_this")
                    $0.under_management = isOwner.description
                }
            }

            let share: ActionSheetAction = { [weak self] in
                guard let self = self, let editVM = self.editVM,
                      let delegate = from as? CalendarShareForwardVCDelegate else { return }

                let shareVM = CalendarShareViewModel(
                    with: .init(
                        calID: calendar.serverId,
                        isManager: editVM.rxCalendar.value.pb.selfAccessRole == .owner
                    ),
                    userResolver: self.userResolver
                )

                let vc = CalendarShareViewController(viewModel: shareVM, userResolver: self.userResolver)
                vc.forwardVC.delegate = delegate
                let navi = LkNavigationController(rootViewController: vc)
                navi.update(style: .custom(.ud.bgFloat))
                navi.modalPresentationStyle = .fullScreen
                self.rxRouter.accept(.setting(navi, from: from))

                CalendarTracerV2.CalendarList.traceClick {
                    $0.click("share_cal")
                    $0.under_management = isOwner.description
                }
            }

            let changeColor: ActionSheetAction = { [weak self] in
                guard let self = self, let vm = self.editVM, vm.permission.isColorEditable else { return }
                let index = vm.rxCalendar.value.pb.personalizationSettings.colorIndex.rawValue
                vm.rxToastStatus
                    .bind(to: from.rx.toast).disposed(by: self.disposeBag)
                let pickerVC = ColorEditActionPanel(selectedIndex: index)
                pickerVC.colorSelectedHandler = { [weak self, weak pickerVC] newIndex in
                    guard let self = self, let pickerVC = pickerVC else { return }
                    pickerVC.dismiss(animated: true)
                    if index != newIndex { self.editVM?.directlyChangeColor(with: newIndex) }
                }

                // navi present action panel
                self.rxRouter.accept(.actionPanel(pickerVC, popAnchor: popAnchor, from: from))
                CalendarTracerV2.CalendarList.traceClick {
                    $0.click("change_color")
                    $0.under_management = isOwner.description
                }
            }

            let setting: ActionSheetAction = { [weak self] in
                guard let self = self, let vm = self.editVM else { return }
                let settingVC = CalendarEditViewController(viewModel: vm)
                let navi = LkNavigationController(rootViewController: settingVC)
                navi.modalPresentationStyle = .fullScreen
                if #available(iOS 13.0, *) { navi.isModalInPresentation = true }

                self.rxRouter.accept(.setting(navi, from: from))

                CalendarTracerV2.CalendarList.traceClick {
                    $0.click("cal_setting")
                    $0.under_management = isOwner.description
                }
            }

            let unSubscribe: ActionSheetAction = { [weak self] in
                guard let self = self, let vm = self.editVM else { return }
                vm.rxToastStatus
                    .bind(to: from.rx.toast).disposed(by: self.disposeBag)
                vm.rxAlert
                    .map { ($0, from) }
                    .bind(to: self.rxAlert).disposed(by: self.disposeBag)
                vm.unsubscribe()
                CalendarTracerV2.CalendarList.traceClick {
                    $0.click("unsub_cal")
                    $0.under_management = isOwner.description
                }
            }

            actionSheet.addItem(.init(title: I18n.Calendar_G_ShowThisCalendarOnly_Click, action: showThisOnly))

            if calendar.type != .resources {
                actionSheet.addItem(.init(title: I18n.Calendar_Share_ShareButton, action: share))
            }

            if self.editVM?.permission.isColorEditable ?? false {
                actionSheet.addItem(.init(title: I18n.Calendar_G_ChangeColor_Click, action: changeColor))
            }

            actionSheet.addItem(.init(title: I18n.Calendar_Setting_CalendarSetting, action: setting))

            if let showUnsubscribeBtn = editVM?.permission.isUnsubscriable, showUnsubscribeBtn {
                actionSheet.addItem(.init(title: I18n.Calendar_Detail_UnsubscribeButton, action: unSubscribe))
            }

            actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
            rxRouter.accept(.actionSheet(actionSheet, from: from))
        } else {
            guard let calendarManager = self.calendarManager,
                  let calendarApi = self.calendarApi, let calendarDependency = self.calendarDependency else {
                CalendarList.logInfo("go setting failed, cannot get calendarManager and calendarApi from larkcontainer")
                return
            }
            if let vc = CalendarManagerFactory.settingController(with: calendar.serverId,
                                                                  selfCalendarId: calendarManager.primaryCalendarID,
                                                                  selfUserId: self.userResolver.userID,
                                                                  calendarAPI: calendarApi,
                                                                  calendarManager: calendarManager,
                                                                 calendarDependency: calendarDependency,
                                                                  skinType: SettingService.shared().getSetting().skinTypeIos,
                                                                 navigator: self.userResolver.navigator,
                                                                  eventDeleted: { [weak self] in
                self?.localRefreshService?.rxCalendarNeedRefresh.onNext(())
            }, disappearCallBack: self.fetchData) {
                rxRouter.accept(.setting(vc, from: from))
            }
        }
    }

    private func tapExternal(with uniqueId: String, from: UIViewController) {
        guard let calendarManager = self.calendarManager,
              let model = data.first(where: { $0.uniqueId == uniqueId }) else { return }
        let listSection = model.sectionType
        CalendarList.logInfo("tap external manager of calendar \(listSection.content.sourceTitle)")
        CalendarTracerV2.CalendarList.traceClick {
            $0.click("manage_account").target("none")
            $0.calendar_id = model.calendar.serverId
        }
        let type: ExternalCalendarType = listSection.externalCalendarType
        let vc = ExternalCalendarManageViewController(
            userResolver: self.userResolver,
            accountName: listSection.content.sourceTitle,
            type: type,
            accountValid: model.calendar.externalAccountValid,
            oAuthUrl: self.exchangeShouldOAuthAccounts[listSection.content.sourceTitle] ?? "",
            changeExternalAccount: calendarManager.changeExternalAccount(accountName:visibility:),
            disappearCallBack: self.fetchData)
        self.rxRouter.accept(.external(vc, from: from))
    }
}

// MARK: - Router
extension CalendarSidebarDataProvider {
    typealias ActionSheetAction = () -> Void
    
    enum Route {
        // 跳转设置页
        case setting(_ targetVC: UIViewController, from: UIViewController)
        // 跳转三方日历管理页
        case external(_ targetVC: ExternalCalendarManageViewController, from: UIViewController)
        // 弹出actionSheet
        case actionSheet(_ targetVC: UIViewController, from: UIViewController)
        // 弹出 actionPanel
        case actionPanel(_ targetVC: UIViewController, popAnchor: UIView?, from: UIViewController)
    }
    
    func bindRxRoute() {
        self.rxRouter
            .subscribeForUI(onNext: { [weak self] route in
                guard let self = self else { return }
                switch route {
                case .setting(let vc, let from):
                    if Display.pad {
                        vc.modalPresentationStyle = .formSheet
                    }
                    from.present(vc, animated: true, completion: nil)
                case .external(let vc, let from):
                    if let navigationController = from.navigationController {
                        navigationController.pushViewController(vc, animated: true)
                    } else {
                        vc.addDismissItem()
                        self.userResolver.navigator.present(vc,
                                                 wrap: LkNavigationController.self,
                                                 from: from,
                                                 prepare: { vc in
                                                    vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                                                 },
                                                 animated: true,
                                                 completion: nil)
                    }
                case .actionSheet(let vc, let from):
                    from.present(vc, animated: true, completion: nil)
                case .actionPanel(let vc, let anchor, let from):
                    if let anchor = anchor, Display.pad {
                        vc.preferredContentSize = .init(width: 375, height: 128)
                        vc.modalPresentationStyle = .popover
                        vc.popoverPresentationController?.sourceView = anchor
                        vc.popoverPresentationController?.permittedArrowDirections = [.right]
                        vc.popoverPresentationController?.delegate = from as? UIPopoverPresentationControllerDelegate
                        from.present(vc, animated: true)
                    } else {
                        // header + margin(16+8) + panelHeight(12*2+48*3+8*2)
                        let panelHeight = 48 + 24 + 184 + from.view.safeAreaInsets.bottom
                        let actionPanel = UDActionPanel(
                            customViewController: vc,
                            config: UDActionPanelUIConfig(
                                originY: Display.height - panelHeight,
                                canBeDragged: false,
                                backgroundColor: UIColor.ud.bgFloatBase
                            )
                        )
                        from.present(actionPanel, animated: true, completion: nil)
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    func bindRxAlert() {
        self.rxAlert
            .subscribeForUI(onNext: { [weak self] (alert, from) in
                guard let self = self else { return }
                switch alert {
                case .deleteConfirm(let doAlert):
                    EventAlert.showDeleteOwnedCalendarAlert(controller: from, confirmAction: doAlert)
                case .successorUnsubscribe(let doUnsubscribe, let delete):
                    let pop = UDActionSheet(config: UDActionSheetUIConfig(style: .normal, isShowTitle: true))
                    pop.setTitle(BundleI18n.Calendar.Calendar_Detail_UnsubscribeResignedPersonCalendar)
                    pop.addDefaultItem(text: I18n.Calendar_Detail_UnsubscribeButton, action: doUnsubscribe)
                    pop.addDestructiveItem(text: BundleI18n.Calendar.Calendar_Detail_DeleteCalendar, action: delete)
                    pop.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel)
                    from.present(pop, animated: true, completion: nil)
                case .comfirmAlert(let title, let content):
                    let dialog = UDDialog(config: UDDialogUIConfig())
                    dialog.setTitle(text: title)
                    dialog.setContent(text: content)
                    dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                    from.present(dialog, animated: true)
                case .ownedCalUnsubAlert(let doUnsubscribe):
                    EventAlert.showUnsubscribeOwnedCalendarAlert(controller: from, confirmAction: doUnsubscribe)
                }
            }).disposed(by: disposeBag)
    }
}

extension CalendarListSection {
    var externalCalendarType: ExternalCalendarType {
        switch self {
        case .google: return .google
        default: return .exchange
        }
    }
}
