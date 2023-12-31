//
//  NotificationSettingDiagnoseModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/10.
//

import UserNotifications
import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import LarkMessengerInterface
import LarkFocus
import EENavigator
import LarkNavigation
import LarkTab
import UniverseDesignDialog
import LarkUIKit
import LarkSDKInterface
import LarkContainer
import RustPB
import ServerPB
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkOpenSetting
import LarkSettingUI
import EENotification
import LarkStorage

#if DEBUG
let appGrounpName = "group.com.bytedance.ee.lark.yzj"
#else
let appGrounpName = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
#endif

struct NotificationDiagnosisModel {
    enum DiagnosisType {
        case network
        case notification
        case focus
        case push
        case other
        case message
        case none
    }

    enum Status: Equatable {
        case waiting
        case loading
        case ok
        case warning([Result])

        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.ok, .ok): return true
            case (.loading, .loading): return true
            case (.waiting, .waiting): return true
            default: return false
            }
        }

        static func != (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.ok, .ok): return false
            case (.loading, .loading): return false
            case (.waiting, .waiting): return false
            default: return true
            }
        }
    }

    struct Result {
        enum Style {
            case warning
            case error
        }

        var title: String = ""
        var detail: String = ""
        var priority = 5 // 优先级默认是5，需要显示在顶层的优先级是10，
        var style: Style = .warning
        var callback: (() -> Void)?
    }

    var title: String = ""
    var status: Status = .ok
    var diagnosisType: DiagnosisType = .none
}

final class NotificationDiagnosisingModule: BaseModule {

    lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal) // 默认是空
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        return button
    }()

    lazy var headerView: UITableViewHeaderFooterView = { [weak self] () -> UITableViewHeaderFooterView in
        let containerView = UITableViewHeaderFooterView()
        guard let self = self else { return containerView }
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.numberOfLines = 0
        titleLabel.text = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_DiagnosisTitle
        containerView.contentView.addSubview(titleLabel)
        containerView.contentView.addSubview(self.button)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(4)
            $0.bottom.equalTo(-4)
            $0.top.equalTo(12)
        }
        self.button.snp.makeConstraints {
            $0.trailing.equalTo(-4)
            $0.centerY.equalTo(titleLabel)
        }
        return containerView
    }()

    private lazy var viewModel: NotificationDiagnosisingModuleModel = {
        return NotificationDiagnosisingModuleModel(userResolver: self.userResolver)
    }()

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.addStateListener(.viewDidLoad) { [weak self] in
            self?.bindModel()
            self?.viewModel.startDiagnosingAll()
        }
        self.onRegisterDequeueViews = { tableView in
            tableView.register(NotificationDiagnosisCell.self,
                               forCellReuseIdentifier: "NotificationDiagnosisCell")
            tableView.register(NotificationDiagnosisResultCell.self,
                               forCellReuseIdentifier: "NotificationDiagnosisResultCell")
        }
    }

    func bindModel() {
        // 重试按钮
        let buttonStr = Observable.combineLatest(viewModel.dataReplay.asObservable(),
                                                 viewModel.isDiagnosing.asObservable()) { models, isDiagnosing -> String in
            if isDiagnosing { return "" } // 检查中不展示
            if models.allSatisfy({ $0.status == .ok }) {
                return BundleI18n.LarkMine.Lark_NotificationTroubleShooting_RunDiagnosisAgain
            }
            return BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NotAllClearTryAgain
        }.distinctUntilChanged()
        // 更新按钮文案
        buttonStr
            .bind(to: button.rx.title(for: .normal))
            .disposed(by: disposeBag)
        // 文案为空时隐藏
        buttonStr.map { $0.isEmpty }.bind(to: button.rx.isHidden)
            .disposed(by: disposeBag)
        // 点击事件
        button.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel.startDiagnosingAll()
            MineTracker.trackClickNotificationDiagnosis()
        }).disposed(by: disposeBag)

        viewModel.delegate = self

        // 生成sections
        Observable.combineLatest(viewModel.dataReplay.asObservable(), viewModel.isDiagnosing.asObservable())
            .subscribe(onNext: { [weak self] _, _ in
                guard let self = self else { return }
                self.context?.reload()
            })
            .disposed(by: disposeBag)
    }

    override func createSectionPropList(_ key: String) -> [SectionProp] {
        if key == ModulePair.NotificationDiagnose.diagnoseTips.createKey {
            let models = viewModel.dataReplay.value
            let isDiagnosing = viewModel.isDiagnosing.value
            let errorSections = self.createErrorSections(models)
            let hasNoError = errorSections.isEmpty
            let noticeSections = isDiagnosing ? [] : (hasNoError ? self.createWarningSections(models) : errorSections)
            return noticeSections
        }
        return []
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.NotificationDiagnose.diagnoseMain.createKey {
            let models = viewModel.dataReplay.value
            let showFooterString = self.shouldShowFooterString(models)
            let diagnosisSection = self.createDiagnosisSection(models, showFooterString: showFooterString)
            return diagnosisSection
        }
        return nil
    }

    // MARK: - 变换操作
    func getWarningResults(_ models: [NotificationDiagnosisModel]) -> [NotificationDiagnosisModel.Result] {
        return models.map { (model: NotificationDiagnosisModel) -> [NotificationDiagnosisModel.Result] in
            switch model.status {
            case .warning(let resList): return resList
            case .loading, .waiting, .ok: return []
            @unknown default:   return []
            }
        }.flatMap { $0 }
    }

    func createErrorSections(_ models: [NotificationDiagnosisModel]) -> [SectionProp] {
        return getWarningResults(models)
            .filter { $0.style == .error }
            .sorted { $0.priority > $1.priority }
            .map(mapResultToSectionProp(.error))
    }

    func createWarningSections(_ models: [NotificationDiagnosisModel]) -> [SectionProp] {
        return getWarningResults(models)
            .filter { $0.style == .warning }
            .map(mapResultToSectionProp(.warning))
    }

    func createDiagnosisSection(_ models: [NotificationDiagnosisModel], showFooterString: Bool) -> SectionProp {
        let diagnosisItems = models.map { (model: NotificationDiagnosisModel) -> NotificationDiagnosisCellProp in
            let type = mapStatusToCellType(model.status)
            return NotificationDiagnosisCellProp(title: model.title, type: type)
        }
        let footerStr = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_AllClearYetProblemRemain_ContactSupportOrIT()
        let diagnosisSection = SectionProp(items: diagnosisItems,
                                                  header: .custom({ self.headerView }),
                                                  footer: showFooterString ? .title(footerStr) : .normal)
        return diagnosisSection
    }

    let mapResultToSectionProp = { (type: NotificationDiagnosisResultCellProp.ResultType) in
        return { (res: NotificationDiagnosisModel.Result) -> SectionProp in
            let item = NotificationDiagnosisResultCellProp(title: res.title, detail: res.detail, type: type, onClick: { _ in res.callback?() })
            return SectionProp(items: [item])
        }
    }

    let mapStatusToCellType = { (status: NotificationDiagnosisModel.Status) -> NotificationDiagnosisCellProp.DiagnosisType in
        switch status {
        case .loading: return .loading
        case .ok: return .ok
        case .waiting: return .waiting
        case .warning(let resList):
            // 只有warnning，没有error时图标是绿色的
            if resList.contains(where: { $0.style == .error }) {
                return .warning
            }
            return .ok
        @unknown default: return .ok
        }
    }

    // 是否在footer显示文案，规则是：全部完成，并且没有error
    func shouldShowFooterString(_ models: [NotificationDiagnosisModel]) -> Bool {
        return models.map { $0.status }.allSatisfy {
            switch $0 {
            case .ok:
                return true
            case .warning(let resList):
                return resList.allSatisfy { $0.style == .warning }
            default:
                return false
            }
        }
    }
}

extension NotificationDiagnosisingModule: NotificationDiagnosisingModuleModelDelegate {
    func goToNotificationSetting(highlight: MineNotificationSettingBody.ItemKey?) {
        if let vc = self.context?.vc {
            let body = MineNotificationSettingBody(highlight: highlight)
            self.userResolver.navigator.push(body: body, from: vc)
        }
    }

    func goToFocusSetting() {
        let focusListVC = FocusListController(userResolver: userResolver)
        if let vc = self.context?.vc {
            self.userResolver.navigator.present(focusListVC, from: vc)
        }
    }

    func showNetworkErrorAlert() {
        let dialog = UDDialog()
        if let vc = self.context?.vc {
            dialog.setTitle(text: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_UnableToCompleteDiagnosisRetry_ErrorMessage)
            dialog.addSecondaryButton(text: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_QuitTest_Button, dismissCompletion: { [weak vc] in
                vc?.navigationController?.popViewController(animated: true)
            })
            dialog.addPrimaryButton(text: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_RunDiagnosisAgain, dismissCompletion: { [weak self] in
                self?.viewModel.startDiagnosingAll()
            })
            self.userResolver.navigator.present(dialog, from: vc)
        }
    }

    func goToSystemSetting() {
        self.goToSetting()
    }
}

protocol NotificationDiagnosisingModuleModelDelegate: AnyObject {
    func goToNotificationSetting(highlight: MineNotificationSettingBody.ItemKey?)
    func goToFocusSetting()
    func showNetworkErrorAlert()
    func goToSystemSetting()
}

final class NotificationDiagnosisingModuleModel {
    private let userResolver: UserResolver
    private var notificationDiagnoseAPI: NotificationDiagnoseAPI?
    private var userPushCenter: PushNotificationCenter?

    weak var delegate: NotificationDiagnosisingModuleModelDelegate?

    let isDiagnosing = BehaviorRelay<Bool>(value: false)

    private var items: SafeArray<NotificationDiagnosisModel> = [] + .semaphore
    private var _items: [NotificationDiagnosisModel] {
        return self.items.getImmutableCopy()
    }

    private var netDiagnoseEventParams: SafeArray<RustPB.Im_V1_SendDiagnosticEventRequest.Param> = [] + .semaphore
    private var diagnoseID = ""

    private var currentIndex = 0

    private var shouldSendMessage = true

    private var isNetWorkError = false
    private var isAuthorized = false
    private var sendMesStatus: String = "unknown"
    private var sendMsgTraceID = ""
    private var messageNotificationsOffDuringCalls = false
    private var notificationOptionsSetting = RustPB.Settings_V1_MessengerNotificationSetting()

    var dataReplay = BehaviorRelay<[NotificationDiagnosisModel]>(value: [])

    private var configReplay = BehaviorRelay<ServerPB_Messages_DiagnoseMessageConfigResponse>(value: ServerPB_Messages_DiagnoseMessageConfigResponse())

    private let disposeBag: DisposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        // 网络状态
        self.notificationDiagnoseAPI = try? self.userResolver.resolve(type: NotificationDiagnoseAPI.self)
        self.userPushCenter = try? self.userResolver.userPushCenter

        self.userPushCenter?.observable(for: PushDynamicNetStatus.self, replay: true)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                /// 判断网络、服务问题
                switch push.dynamicNetStatus {
                case .offline, .serviceUnavailable, .netUnavailable:
                    self.isNetWorkError = true
                @unknown default:
                    self.isNetWorkError = false
                }
            }).disposed(by: disposeBag)

        // 应用内通知设置
        self.userPushCenter?.observable(for: RustPB.Settings_V1_PushUserSetting.self, replay: true)
            .subscribe(onNext: { [weak self] (allSettings) in
                guard let self = self else { return }
                self.messageNotificationsOffDuringCalls = allSettings.messageNotificationsOffDuringCalls
                self.notificationOptionsSetting = allSettings.notificationSettingV2.messengerNotificationSetting
            }).disposed(by: self.disposeBag)

        // 服务端返回诊断结果解析
        self.configReplay.subscribe(onNext: { [weak self] response in
            guard let self = self else { return }
            self.resloveServerDiagnoseResult(response)
        }).disposed(by: disposeBag)
    }

    private func initResult() {
        isDiagnosing.accept(true)
        items.removeAll()
        var network = NotificationDiagnosisModel()
        network.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NetworkStatus
        network.status = .waiting
        network.diagnosisType = .network
        items.append(network)

        var notification = NotificationDiagnosisModel()
        notification.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NotificationAccess
        notification.status = .waiting
        notification.diagnosisType = .notification
        items.append(notification)

        var push = NotificationDiagnosisModel()
        push.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_InAppSettings
        push.status = .waiting
        push.diagnosisType = .push
        items.append(push)

        var focus = NotificationDiagnosisModel()
        focus.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_PersonalStatus
        focus.status = .waiting
        focus.diagnosisType = .focus
        items.append(focus)

        var other = NotificationDiagnosisModel()
        other.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_OtherConfiguration
        other.status = .waiting
        other.diagnosisType = .other
        items.append(other)

        var message = NotificationDiagnosisModel()
        message.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_SendTestMessage
        message.status = .waiting
        message.diagnosisType = .message
        items.append(message)

        self.dataReplay.accept(_items)
    }

    private func startNextDiagnosis() {
        let index = currentIndex
        guard index < items.count else { return }

        // 卡点
        switch items[index].diagnosisType {
        case .push:
            guard !isNetWorkError else {
                self.isDiagnosing.accept(false)
                break
            }
        case .message:
            guard self.shouldSendMessage else {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.isDiagnosing.accept(false)
                    self?.uploadDiagnoseEvent()
                }
                return
            }
        default:
            break
        }

        // 正常诊断
        let goNext = { [weak self] in
            self?.currentIndex += 1
            self?.startNextDiagnosis()
        }
        self.items[index].status = .loading
        self.dataReplay.accept(self._items)

        switch items[index].diagnosisType {
        case .network:
            self.diagnoseNetwork(index: index, completion: goNext)
        case .notification:
            self.diagnoseNotification(index: index, completion: goNext)
        case .push:
            fetchDiagnoseMessageConfig { [weak self] in
                guard let self = self else { return }
                self.diagnosePush(index: index, completion: goNext)
            }
        case .focus:
            self.diagnoseFocus(index: index, completion: goNext)
        case .other:
            self.diagnoseOther(index: index, completion: goNext)
        case .message:
            self.diagnoseMessage(index: index) { [weak self] in
                self?.isDiagnosing.accept(false)
                self?.uploadDiagnoseEvent()
            }
        case .none:
            break
        }
    }

    private func fetchDiagnoseMessageConfig(onSuccess: @escaping (() -> Void)) {
        self.notificationDiagnoseAPI?
            .fetchDiagnoseMessageConfig()
            .subscribe(onNext: { [weak self] (response) in
                self?.configReplay.accept(response)
                onSuccess()
            }, onError: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.delegate?.showNetworkErrorAlert()
                }
            }).disposed(by: self.disposeBag)
    }

    private func diagnoseNetwork(index: Int, completion: (() -> Void)? = nil) {

        var item = self.items[index]
        if self.isNetWorkError {
            var result = NotificationDiagnosisModel.Result()
            result.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NetworkError_Title
            result.detail = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NetworkError_Desc
            result.style = .error
            result.callback = {
                DispatchQueue.main.async {
                    if let url = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(url as URL) {
                        UIApplication.shared.open(url as URL)
                    }
                }
            }
            item.status = .warning([result])
            self.shouldSendMessage = false
        } else {
            item.status = .ok
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { // 0.5秒是为了延迟动画效果
            if item.status != self.items[index].status {
                self.items[index] = item
                self.dataReplay.accept(self._items)
            }
            completion?()
        }
    }

    private func diagnoseNotification(index: Int, completion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (setting) in
            guard let `self` = self else { return }
            var item = self.items[index]
            // https://stackoverflow.com/questions/48630537/how-to-detect-ios-push-notification-permissions-settings-programmatically
            // 打开通知，但把「通知中心」、「锁屏」、「横幅」这3个都关掉，会收不到离线推送
            let relateSettingsAreEnable: Bool = setting.notificationCenterSetting == .enabled
                || setting.lockScreenSetting == .enabled
                || (setting.alertSetting == .enabled && setting.alertStyle != .none)
            if setting.authorizationStatus != .authorized || (setting.authorizationStatus == .authorized && !relateSettingsAreEnable) {
                var result = NotificationDiagnosisModel.Result()
                result.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NoNotificationAccess_Title2()
                result.detail = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_NoNotificationAccess_Desc()
                result.style = .error
                result.callback = self.delegate?.goToSystemSetting
                item.status = .warning([result])
                self.shouldSendMessage = false
                self.isAuthorized = false
            } else {
                var results = [NotificationDiagnosisModel.Result]()
                if #available(iOS 15.0, *) {
                    // 时效性通知
                    if setting.timeSensitiveSetting == .disabled {
                        var result = NotificationDiagnosisModel.Result()
                        result.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_TimeSensitiveNotificationsOff_Title
                        result.detail = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_TimeSensitiveNotificationsOff_Desc()
                        result.style = .warning
                        result.callback = self.delegate?.goToSystemSetting
                        results.append(result)
                    }
                    // 定时摘要推送
                    if setting.scheduledDeliverySetting == .enabled {
                        var result = NotificationDiagnosisModel.Result()
                        result.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_ScheduledSummaryOn_Title
                        result.detail = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_ScheduledSummaryOn_Desc()
                        result.style = .warning
                        result.callback = self.delegate?.goToSystemSetting
                        results.append(result)
                    }
                }
                let isOK = results.isEmpty
                item.status = isOK ? .ok : .warning(results) // 只是蓝色级别提醒
                self.isAuthorized = true
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                if item.status != self.items[index].status {
                    self.items[index] = item
                    self.dataReplay.accept(self._items)
                }
                completion?()
            }
        }
    }

    private func diagnoseFocus(index: Int, completion: (() -> Void)? = nil) {

        self.configReplay.take(1)
            .subscribe(onNext: { [weak self] config in
                guard let `self` = self else {
                    return
                }
                let checkedItems = config.checkedItems.filter { item in
                    return item.item == .customizeStatus
                }
                let resultCallback = { [weak self] in
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.goToFocusSetting()
                    }
                }
                var item = self.items[index]
                var isError = false
                var results: [NotificationDiagnosisModel.Result] = []

                for checkItem in checkedItems {
                    if checkItem.status == .error {
                        self.shouldSendMessage = false
                    }
                    switch checkItem.status {
                    case .error, .warn:
                        isError = true
                        var result = NotificationDiagnosisModel.Result()
                        for (key, value) in checkItem.reason {
                            result.title = key
                            result.detail = value
                        }
                        result.style = checkItem.status == .error ? .error : .warning
                        result.callback = resultCallback
                        results.append(result)
                    @unknown default:
                        break
                    }
                }
                item.status = isError ? .warning(results) : .ok

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    if item.status != self.items[index].status {
                        self.items[index] = item
                        self.dataReplay.accept(self._items)
                    }
                    completion?()
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func diagnosePush(index: Int, completion: (() -> Void)? = nil) {

        self.configReplay.take(1)
            .subscribe(onNext: { [weak self] config in
                guard let `self` = self else {
                    return
                }
                let checkedItems = config.checkedItems.filter { item in
                    return item.item == .notificationClosePhone || item.item == .notificationDisableAll || item.item == .notificationDisableNormal || item.item == .notificationMeetingOrCalling
                }

                var item = self.items[index]
                var isError = false
                var results: [NotificationDiagnosisModel.Result] = []

                for checkItem in checkedItems {
                    if checkItem.status == .error {
                        self.shouldSendMessage = false
                    }
                    switch checkItem.status {
                    case .error, .warn:
                        isError = true
                        var result = NotificationDiagnosisModel.Result()
                        for (key, value) in checkItem.reason {
                            result.title = key
                            result.detail = value
                        }
                        result.style = checkItem.status == .error ? .error : .warning
                        var highlight: MineNotificationSettingBody.ItemKey?
                        switch checkItem.item {
                        case .notificationClosePhone:
                            highlight = MineNotificationSettingBody.ItemKey.OffWhenPCOnline
                        case .notificationDisableAll:
                            highlight = MineNotificationSettingBody.ItemKey.NotifyScopeNone
                        case .notificationDisableNormal:
                            highlight = MineNotificationSettingBody.ItemKey.NotifyScopePartial
                        case .notificationMeetingOrCalling:
                            highlight = MineNotificationSettingBody.ItemKey.OffDuringCalls
                        @unknown default:
                            break
                        }
                        result.callback = { [weak self] in
                            DispatchQueue.main.async {
                                self?.delegate?.goToNotificationSetting(highlight: highlight)
                            }
                        }
                        results.append(result)
                    @unknown default:
                        break
                    }
                }
                item.status = isError ? .warning(results) : .ok

                self.items[index] = item
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    if item.status != self.items[index].status {
                        self.dataReplay.accept(self._items)
                    }
                    completion?()
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func diagnoseOther(index: Int, completion: (() -> Void)? = nil) {

        self.configReplay.take(1)
            .subscribe(onNext: { [weak self] config in
                guard let `self` = self else {
                    return
                }
                let checkedItems = config.checkedItems.filter { item in
                    return item.item == .otherSettings
                }

                var item = self.items[index]
                var isError = false
                var results: [NotificationDiagnosisModel.Result] = []

                for checkItem in checkedItems {
                    if checkItem.status == .error {
                        self.shouldSendMessage = false
                    }
                    switch checkItem.status {
                    case .error, .warn:
                        isError = true
                        var result = NotificationDiagnosisModel.Result()
                        for (key, value) in checkItem.reason {
                            result.title = key
                            result.detail = value
                        }
                        if checkItem.otherSettingChildStatus == .peerLogin {
                            result.priority = 10 // 顶层的优先级是10
                        }
                        result.style = checkItem.status == .error ? .error : .warning
                        results.append(result)
                    @unknown default:
                        break
                    }
                }
                item.status = isError ? .warning(results) : .ok

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    if item.status != self.items[index].status {
                        self.items[index] = item
                        self.dataReplay.accept(self._items)
                    }
                    completion?()
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func diagnoseMessage(index: Int, completion: (() -> Void)? = nil) {
        let logger = SettingLoggerService.logger(.module("diagnosising"))

        logger.info("[LarkNSE]: start diagnostic")

        self.notificationDiagnoseAPI?
            .sentDiagnoseMessage()
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else {
                    return
                }
                self.sendMsgTraceID = response.traceID

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    let savedMsgId = KVPublic.NotificationDiagnosis.message.value()
                    let isSameMsg = savedMsgId == response.message.id

                    logger.info("api/sendDiagnosticMessage/res: status: \(response.status), messageID: userDefaults: \(savedMsgId) response: \(response.message.id)")

                    let isOfflinePushed = response.status == .offlineAndOnlinePushed || response.status == .offlinePushed
                    let isReceived = isSameMsg && isOfflinePushed
                    self.sendMesStatus = self.convertPBStatusToUpload(status: response.status)

                    if isOfflinePushed && savedMsgId.isEmpty {
                        // 服务端以推送但是客户端没收到
                        // 解决token可能已经无法收到推送的问题，取消掉原来的，重新注册一个
                        logger.info("[LarkNSE]: Diagnostic Message push receive failed, try regist new notification token")
                        NotificationManager.shared.unregisterRemoteNotification()
                        NotificationManager.shared.registerRemoteNotification()
                        self.sendMesStatus = "noRecievedOfflinePush"
                    }

                    var status = self.items[index].status
                    if isReceived {
                        status = .ok
                    } else {
                        var result = NotificationDiagnosisModel.Result()
                        result.title = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_FailedToSendTestMessage_Title
                        result.detail = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_FailedToSendTestMessage_Desc
                        result.style = .error
                        status = .warning([result])
                    }

                    logger.info("api/sendDiagnosticMessage/upload: status: \(status), item.status: \(self.items[index].status)")

                    if status != self.items[index].status {
                        self.items[index].status = status
                        self.dataReplay.accept(self._items)
                    }
                    completion?()
                }
            }, onError: { [weak self] (_) in
                guard let `self` = self else {
                    return
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    self.items[index].status = .ok
                    self.dataReplay.accept(self._items)
                    completion?()
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func createParam(_ name: String, stringValue: String) -> RustPB.Im_V1_SendDiagnosticEventRequest.Param {
        var param = RustPB.Im_V1_SendDiagnosticEventRequest.Param()
        param.name = name
        param.stringValue = stringValue
        return param
    }

    private func createParam(_ name: String, longValue: Int64) -> RustPB.Im_V1_SendDiagnosticEventRequest.Param {
        var param = RustPB.Im_V1_SendDiagnosticEventRequest.Param()
        param.name = name
        param.longValue = longValue
        return param
    }

    // MARK: - 由vc调用
    func startDiagnosingAll() {
        currentIndex = 0
        shouldSendMessage = true
        sendMesStatus = "unknown"
        initResult()
        startNextDiagnosis()
    }
}

// 上报事件
extension NotificationDiagnosisingModuleModel {

    private func convertPBStatusToUpload(status: RustPB.Im_V1_SendDiagnosticMessageResponse.MessageStatus) -> String {
        let sendMsgRes: String
        switch status {
        case .offlinePushed: sendMsgRes = "offlinePushed"
        case .offlineAndOnlinePushed: sendMsgRes = "offlineAndOnlinePushed"
        case .onlinePushed: sendMsgRes = "onlinePushed"
        default: sendMsgRes = "unknown"
        }
        return sendMsgRes
    }

    private func uploadDiagnoseEvent() {
        var params = [RustPB.Im_V1_SendDiagnosticEventRequest.Param]()

        // 网络情况
        params.append(createParam("network", stringValue: self.isNetWorkError ? "error" : "passed"))

        // 系统通知
        params.append(createParam("system_notification_switch", stringValue: self.isAuthorized ? "passed" : "error"))

        // 个人状态
        params.append(contentsOf: focusStatusEventParams())

        // 发送测试消息
        params.append(createParam("server_put_diagnose_message", stringValue: self.sendMesStatus))
        params.append(createParam("server_put_diagnose_message_trace_id", stringValue: sendMsgTraceID))

        // 上传服务端返回的诊断信息（因为服务端返回结果的时候不保存）
        params.append(contentsOf: self.netDiagnoseEventParams.getImmutableCopy())

        // 应用内通知设置
        params.append(contentsOf: self.notificationEventParams())

        // 上报诊断结果信息
        self.notificationDiagnoseAPI?.sendDiagnoseEvent(ID: self.diagnoseID, name: "push_message_diagnosis", params: params)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func focusStatusEventParams() -> [RustPB.Im_V1_SendDiagnosticEventRequest.Param] {
        var res = [RustPB.Im_V1_SendDiagnosticEventRequest.Param]()

        let chatterManager = try? self.userResolver.resolve(type: ChatterManagerProtocol.self)
        let focusStatus = chatterManager?.currentChatter.focusStatusList.first { status in
            status.isActive && status.isNotDisturbMode
        }
        res.append(createParam("app_custom_status", stringValue: focusStatus == nil ? "passed" : "error"))

        // 时间相关
        if let interval = focusStatus?.effectiveInterval {
            res.append(createParam("app_custom_status_is_show_end_time", stringValue: interval.isShowEndTime ? "true" : "false"))
            if interval.isShowEndTime {
                res.append(createParam("app_custom_status_start_time", longValue: interval.startTime))
                res.append(createParam("app_custom_status_end_time", longValue: interval.endTime))
            }
        }
        return res
    }

    private func notificationEventParams() -> [RustPB.Im_V1_SendDiagnosticEventRequest.Param] {
        var res = [RustPB.Im_V1_SendDiagnosticEventRequest.Param]()

        res.append(createParam("app_notification_meeting_or_calling",
                               stringValue: self.messageNotificationsOffDuringCalls ? "true" : "false"))

        let userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self)
        let config = userGeneralSettings?.notifyConfig
        let notifyDisable = config?.notifyDisable ?? false
        let atNotifyOpen = config?.atNotifyOpen ?? false
        let notifySpecialFocus = config?.notifySpecialFocus ?? false
        res.append(createParam("app_notification_close_phone",
                               stringValue: notifyDisable ? "true" : "false"))
        res.append(createParam("app_notification_close_phone_at_me",
                               stringValue: atNotifyOpen ? "true" : "false"))
        res.append(createParam("app_notification_close_phone_star",
                               stringValue: notifySpecialFocus ? "true" : "false"))

        let setting = self.notificationOptionsSetting
        let switchState: String
        switch setting.switchState {
        case .closed: switchState = "close"
        case .open: switchState = "open"
        case .halfOpen: switchState = "half_open"
        default: switchState = "unknown"
        }
        res.append(createParam("app_notification_able", stringValue: switchState))
        res.append(createParam("app_notification_star", stringValue: setting.specialFocusOpen ? "true" : "false"))
        res.append(createParam("app_notification_at_me", stringValue: setting.mentionOpen ? "true" : "false"))
        res.append(createParam("app_notification_at_all", stringValue: setting.mentionAllOpen ? "true" : "false"))
        res.append(createParam("app_notification_p2p", stringValue: setting.userP2PChatOpen ? "true" : "false"))

        res.append(createParam("app_notification_star_not_disturb",
                               stringValue: setting.specialFocusSetting.noticeInMuteChat ? "true" : "false"))
        res.append(createParam("app_notification_star_box",
                               stringValue: setting.specialFocusSetting.noticeInChatBox ? "true" : "false"))
        res.append(createParam("app_notification_star_mute",
                               stringValue: setting.specialFocusSetting.noticeInMuteMode ? "true" : "false"))
        return res
    }

    private func resloveServerDiagnoseResult(_ result: ServerPB_Messages_DiagnoseMessageConfigResponse) {
        var res = [RustPB.Im_V1_SendDiagnosticEventRequest.Param]()
        var title = ""
        var status = "unknown"
        for item in result.checkedItems {
            switch item.item {
            case .customizeStatus:
                title = "server_custom_status"
            case .notificationClosePhone:
                title = "server_notification_close_phone"
            case .notificationDisableAll:
                title = "server_notification_disable_all"
            case .notificationDisableNormal:
                title = "server_notification_disable_normal"
            case .notificationMeetingOrCalling:
                title = "server_notification_meeting_or_calling"
            case .otherSettings:
                if item.status == .error {
                    var statusStr = "unknown"
                    switch item.otherSettingChildStatus {
                    case .peerLogin: statusStr = "peerLogin"
                    case .channelListEmpty: statusStr = "channelListEmpty"
                    case .channelValid: statusStr = "channelValid"
                    case .tokenValid: statusStr = "tokenValid"
                    @unknown default: break
                    }
                    res.append(self.createParam("server_other_setting_error_reason", stringValue: statusStr))
                }
                title = "server_other_settings"
            default:
                break
            }

            switch item.status {
            case .warn:
                status = "warn"
            case .error:
                status = "error"
            case .passed:
                status = "passed"
            default:
                status = "unknown"
            }
            res.append(self.createParam(title, stringValue: status))
        }
        self.diagnoseID = result.id
        self.netDiagnoseEventParams.removeAll()
        self.netDiagnoseEventParams.append(contentsOf: res)
    }
}

final class NotificationDiagnoseCustomServiceModule: BaseModule {

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.NotificationDiagnose.customService.createKey {
            return createCustomServiceSection()
        }
        return nil
    }

    func createCustomServiceSection() -> SectionProp {
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NotificationTroubleShooting_ContactSupport,
                                         accessories: [.arrow()], onClick: { [weak self] _ in
            MineTracker.trackClickContactService()
            self?.goToCustomService()
        })
        let section = SectionProp(items: [item])
        return section
    }

    func goToCustomService() {
        let logger = SettingLoggerService.logger(.module(key))
        var body = CustomServiceChatBody()
        body.plainMessage = BundleI18n.LarkMine.Lark_NotificationTroubleShooting_WhyNoNotifications_Text
        logger.info("goToCustomService: begin")
        guard let vc = self.context?.vc else { return }
        self.userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: true) { _ in
            logger.info("goToCustomService: switchTab complete")
            guard let realFrom = (RootNavigationController.shared.viewControllers.first as? UITabBarController)?.selectedViewController else {
                logger.info("goToCustomService: getRealFrom failed")
                return
            }
            logger.info("goToCustomService: showDetailOrPush")
            self.userResolver.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: realFrom)
        }
    }
}
