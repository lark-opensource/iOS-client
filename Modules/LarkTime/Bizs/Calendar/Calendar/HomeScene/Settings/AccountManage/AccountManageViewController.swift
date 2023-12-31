//
//  AccountManageViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/4/14.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit
import RichLabel
import RxSwift
import RoundedHUD
import LarkContainer
import LKCommonsLogging
import UniverseDesignTheme
import UniverseDesignToast
import FigmaKit
import LarkUIKit
import UniverseDesignEmpty

struct AccountManageViewControllerDependency {
    enum PresentStyle {
        case push
        case present
    }

    let getAllCalendars: () -> Observable<([CalendarModel])>
    var getImportCalendarViewController: () -> UIViewController
    let getShouldSwitchToOAuthExchangeAccounts: () -> Observable<[String: String]>  // email:authUrl
    let bindGoogleCalAddrGetter: (Bool) -> Observable<String>
    let presentStyle: PresentStyle
}

struct AccountCellData: CalendarAccountSwitchCellModel, CalendarAccountAccessCellModel {
    var isSelectedAsNotificaionEmail: Bool
    var type: CalendarAccountType
    var name: String
    var isVisibility: Bool
    var desc: String?
    var isValid: Bool

    init(type: CalendarAccountType,
         name: String,
         isVisibility: Bool = false,
         isSelectedAsNotificaionEmail: Bool = false,
         isValid: Bool) {
        self.type = type
        self.name = name
        self.isVisibility = isVisibility
        self.isSelectedAsNotificaionEmail = isSelectedAsNotificaionEmail
        self.isValid = isValid
    }
}

final class AccountManageViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var serverPushService: ServerPushService?

    let userResolver: UserResolver

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private var googleCalendars: [AccountCellData] = [AccountCellData]()
    private var localCalendars: [AccountCellData] = [AccountCellData]()
    private var exchangeCalendars: [AccountCellData] = [AccountCellData]()
    private var exchangeShouldOAuthAccounts = [String: String]()  // email:authurl
    private lazy var noCalendarView: NoCalendarView = {
        let view = NoCalendarView(importClick: { [unowned self] in
            CalendarTracer.shareInstance.calAddAccount(actionSource: .accountManagement)
            self.importCalendarOnTap()
        })
        view.isHidden = true
        return view
    }()
    private let tableView: UITableView = {
        let tableView = InsetTableView()
        tableView.separatorStyle = .none
        tableView.register(CalendarAccountAccessCell.self, forCellReuseIdentifier: "CalendarAccountAccessCell")
        tableView.register(CalendarAccountSwitchCell.self, forCellReuseIdentifier: "CalendarAccountSwitchCell")
        tableView.register(CalendarAccountAddCell.self, forCellReuseIdentifier: "CalendarAccountAddCell")
        tableView.register(AccountManageHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: AccountManageHeaderView.self))
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.isHidden = true
        return tableView
    }()
    private let disposeBag = DisposeBag()
    private let dependency: AccountManageViewControllerDependency
    private let needAuthWarningController = LocalCalNoAuthWarningController()
    private let logger = Logger.log(AccountManageViewController.self, category: "calendar.AccountManageViewController")

    // 埋点用
    var source: CalendarTracer.AccountManageParam.ActionSource = .other

    var newEmailAddressSelectedCallback: ((String?) -> Void)?
    init(dependency: AccountManageViewControllerDependency, userResolver: UserResolver) {
        self.dependency = dependency
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func refreshUI() {
        logger.info("""
            refresh UI:
            google: \(googleCalendars.map { $0.name }),
            exchange: \(exchangeCalendars.map { $0.name }),
            local: \(localCalendars.map { $0.name })
        """)
        var showData: Bool = false
        if (!FG.isTurnoffGoogleCalendarImport && googleCalendars.count > 1)
            || (FG.enableImportExchange && exchangeCalendars.count > 1)
            || !localCalendars.isEmpty {
            self.tableView.reloadData()
            showData = true
        } else {
            showData = false
        }
        self.tableView.isHidden = !showData
        self.noCalendarView.isHidden = showData
        self.tableView.reloadData()
    }

    private func reloadData() {
        logger.info("reload data")
        self.localCalendars.removeAll()
        self.googleCalendars.removeAll()
        self.exchangeCalendars.removeAll()
        let localCalendars = LocalCalendarManager.getVisibiltyItems(scenarioToken: .loadLocalCalendarOnAccountManager)
        localCalendars.forEach({ (item) in
            let data = AccountCellData(type: .local, name: item.title, isVisibility: item.isSelected, isValid: true)
            self.localCalendars.append(data)
        })

        self.localCalendars.sort(by: {(itemLeft, itemRight) in
            return itemLeft.name < itemRight.name
        })

        if self.localCalendars.isEmpty && !self.localCalendars.contains(where: { (cellData) -> Bool in return cellData.type == .add }) {
            self.localCalendars.append(AccountCellData(type: .add, name: BundleI18n.Calendar.Calendar_Setting_LocalCalendars, isValid: true))
        }

        if FG.isTurnoffGoogleCalendarImport && !FG.enableImportExchange {
            self.refreshUI()
            return
        }

        if FG.enableImportExchange {
            // 拉取日历并拉取绑定的 exchange 账号是否需要升级为 OAuth，
            // 需要升级的话，UI 显示上，在账号管理 item 上会显示即将失效的提示
            dependency.getAllCalendars()
                .observeOn(MainScheduler.instance)
                .flatMap { [weak self] (calendars: [CalendarModel]) -> Observable<[String: String]> in
                    guard let `self` = self else {
                        return Observable.empty()
                    }
                    let sortedCalendars = calendars.sorted { $0.weight < $1.weight }
                    self.buildCalendarCellData(calendars: sortedCalendars)
                    self.refreshUI()
                    if sortedCalendars.contains { $0.selfAccessRole == .owner && $0.type == .exchange } {
                        return self.getShouldOAuthAccounts().catchErrorJustReturn([:])
                    } else {
                        return Observable.empty()
                    }
                }
                .catchError { error in
                        .error(error)
                }
                .subscribe(onNext: { [weak self] (emailTOAuthUrl) in
                    guard let `self` = self else {
                        return
                    }
                    self.logger.info("getShouldOAuthAccounts, count: \(emailTOAuthUrl.count)")
                    self.exchangeShouldOAuthAccounts = emailTOAuthUrl
                    self.refreshUI()
                }, onError: {[weak self] error in
                    guard let `self` = self else {
                        return
                    }
                    self.logger.error("getAllCalendars failed: \(error)")
                    self.refreshUI()
                    UDToast.showTips(with: BundleI18n.Calendar.Calendar_View_SyncListFailed, on: self.view)
                }).disposed(by: disposeBag)
        } else {
            // 原来的逻辑不变
            dependency.getAllCalendars()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (calendars) in
                    guard let `self` = self else {
                        return
                    }
                    let sortedCalendars = calendars.sorted { $0.weight < $1.weight }
                    self.buildCalendarCellData(calendars: sortedCalendars)
                    self.refreshUI()
                    }, onError: {[weak self] error in
                        guard let `self` = self else {
                            return
                        }
                        self.logger.error("getAllCalendars failed: \(error)")
                        self.refreshUI()
                        UDToast.showTips(with: BundleI18n.Calendar.Calendar_View_SyncListFailed, on: self.view)
                }).disposed(by: disposeBag)
        }
    }

    // 需要请求外部服务，可能比较耗时
    private func getShouldOAuthAccounts() -> Observable<[String: String]> {
        return self.dependency.getShouldSwitchToOAuthExchangeAccounts()
            .observeOn(MainScheduler.instance)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_NewSettings_CalendarThirdPartyAccount
        if dependency.presentStyle == .push {
            _ = addBackItem()
        } else {
            _ = addCloseItem()
        }
        layout(table: tableView)
        noCalendarView.layout(equalTo: self.view)
        self.view.bringSubviewToFront(noCalendarView)

        if let pushService = self.pushService,
           let calendarManager = self.calendarManager {
            let calendarSyncPush = Observable.of(
                pushService.rxGoogleCalAccount.map({ _ in }),
                calendarManager.rxCalendarUpdated,
                pushService.rxExternalCalendar.map({ _ in }))
                .merge()

            calendarSyncPush.subscribe(onNext: { [weak self] () in
                DispatchQueue.main.async {
                    self?.reloadData()
                }
            }).disposed(by: disposeBag)
        } else {
            logger.error("register external calendar push failed, can not get service from larkcontainer")
        }
        registerBindAccountNotification()
        CalendarTracer.shared.accountManageShow(from: source)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerBindAccountNotification() {
        serverPushService?
            .rxExchangeBind
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_EmailGuest_AccountAddedSuccessfully, on: self.view)
            }).disposed(by: disposeBag)
    }

    @objc
    private func importCalendarOnTap() {
        self.navigationController?
            .pushViewController(dependency.getImportCalendarViewController(), animated: true)
    }

    private func layout(table: UIView) {
        view.addSubview(table)
        table.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        table.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func sectionData(with section: Int) -> [AccountCellData] {
        var cellData = [[AccountCellData]]()

        if !FG.isTurnoffGoogleCalendarImport && !googleCalendars.isEmpty {
            cellData.append(googleCalendars)
        }

        if !exchangeCalendars.isEmpty && FG.enableImportExchange {
            cellData.append(exchangeCalendars)
        }

        if !localCalendars.isEmpty {
            cellData.append(localCalendars)
        }

        return cellData[safeIndex: section] ?? [AccountCellData]()
    }

    private func sectionCount() -> Int {
        var count = 0
        if FG.enableImportExchange && !exchangeCalendars.isEmpty {
            count += 1
        }
        if !localCalendars.isEmpty {
            count += 1
        }
        if !FG.isTurnoffGoogleCalendarImport && !googleCalendars.isEmpty {
            count += 1
        }
        return count
    }

    func getExternalCalendarManageViewController(accountName: String, type: ExternalCalendarType, accountValid: Bool, oAuthUrl: String? = nil) -> UIViewController {
        guard let calendarManager = self.calendarManager else {
            logger.error("getExternalCalendarManageViewController failed, can not get calendarmanager from larkcontainer")
            return UIViewController()
        }
        return ExternalCalendarManageViewController(userResolver: self.userResolver,
                                                    accountName: accountName,
                                                    type: type,
                                                    accountValid: accountValid,
                                                    oAuthUrl: oAuthUrl,
                                                    changeExternalAccount: calendarManager.changeExternalAccount(accountName:visibility:)) { [weak self] in
            self?.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellModel = sectionData(with: indexPath.section)[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return
        }

        switch cellModel.type {
        case .google:
            let vc = getExternalCalendarManageViewController(accountName: cellModel.name, type: .google, accountValid: cellModel.isValid)
            navigationController?.pushViewController(vc, animated: true)
            logger.info("jump to external manage for google: \(cellModel.name)")
        case .exchange:
            let vc = getExternalCalendarManageViewController(accountName: cellModel.name, type: .exchange, accountValid: cellModel.isValid, oAuthUrl: self.exchangeShouldOAuthAccounts[cellModel.name])
            navigationController?.pushViewController(vc, animated: true)
            logger.info("jump to external manage for exchange: \(cellModel.name)")
        case .local:
            break
        case .add:
            jumpToImportCalendar(section: indexPath.section)
        }
    }

    private func importGoogleCalendar() {
        logger.info("import google calendar")
        CalendarTracer.shared.accountManagerClick(clickParam: "google", target: "none")
        dependency.bindGoogleCalAddrGetter(false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (addr) in
                guard let `self` = self else { return }
                if let url = URL(string: addr), !addr.isEmpty {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    let roundedHud = RoundedHUD()
                    roundedHud.showFailure(with: BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: self.view)
                    operationLog(message: "invaild url: \(addr)")
                }
                }, onError: { (error) in
                    let roundedHud = RoundedHUD()
                    roundedHud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: self.view)
            }).disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let updateAble = cell as? CalendarAccountBaseCell {
            let data = sectionData(with: indexPath.section)
            updateAble.updateBottomBorder(isHidden: data.count - 1 == indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData(with: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellModel = sectionData(with: indexPath.section)[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return UITableViewCell()
        }

        switch cellModel.type {
        case .add:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountAddCell", for: indexPath) as? CalendarAccountAddCell else {
                assertionFailureLog()
                return UITableViewCell()
            }
            cell.configCellInfo(labelText: BundleI18n.Calendar.Calendar_GoogleCal_ImportCalendars)
            return cell
        case .google:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountAccessCell", for: indexPath) as? CalendarAccountAccessCell else {
                assertionFailureLog()
                return UITableViewCell()
            }
            cell.update(model: cellModel)
            return cell
        case .exchange:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountAccessCell", for: indexPath) as? CalendarAccountAccessCell else {
                assertionFailureLog()
                return UITableViewCell()
            }
            let showAccountWarning = (self.exchangeShouldOAuthAccounts[cellModel.name] != nil) || !cellModel.isValid
            cell.update(model: cellModel, showAccountWarning: showAccountWarning)
            return cell
        case .local:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountSwitchCell", for: indexPath) as? CalendarAccountSwitchCell else {
                assertionFailureLog()
                return UITableViewCell()
            }

            var sourceIdentifier = ""
            LocalCalendarManager.getVisibiltyItems(scenarioToken: .loadLocalCalendarOnAccountManager).forEach { (item) in
                if item.title == cellModel.name {
                    sourceIdentifier = item.sourceIdentifier
                }
            }
            cell.onSwitch = { (isOn) in
                var sourceKeys = KVValues.localCalendarSource
                sourceKeys?[sourceIdentifier] = isOn
                KVValues.localCalendarSource = sourceKeys ?? [:]
                CalendarTracer.shareInstance.calSettingsLocalCalendar(actionTargetSource: .init(isOn: isOn))
                CalendarTracer.shared.accountManagerClick(clickParam: "local", target: "none", isOpen: isOn)
            }

            cell.update(model: cellModel)
            return cell
        }
    }

    private func jumpToImportCalendar(section: Int) {
        guard let type = typeWithSection(section) else {
            return
        }

        func importExchange() {
            logger.info("import exchange calendar")
            CalendarTracer.shared.accountManagerClick(clickParam: "exchange", target: "none")
            let viewModel = PreImportExchangeViewModel(userResolver: self.userResolver, resultCallback: nil)
            let viewController = PreImportExchangeViewController(userResolver: self.userResolver, viewModel: viewModel)
            self.navigationController?.pushViewController(viewController, animated: true)
        }

        func importLocalCalendar() {
            if LocalCalendarManager.isLocalCalendarAccessable() == .unauthorized {
                needAuthWarningController.show(self.navigationController)
            } else {
                var forToken: SensitivityControlToken = SensitivityControlToken.requestCalendarAccessOnAccountManagerView
                if #available(iOS 17.0, *) {
                    forToken = SensitivityControlToken.requestCalendarFullAccessOnAccountManagerView
                }
                LocalCalendarManager.requireLocalCalendarAuthorization(for: forToken) { [weak self] (success) in
                    if success {
                        CalendarTracer.shareInstance.grandAccess(haveAccess: true)
                        CalendarTracer.shared.accountManagerClick(clickParam: "local", target: "none")
                        DispatchQueue.main.async {
                            let localCal = LocalCalendarSettingController()
                            self?.navigationController?.pushViewController(localCal, animated: true)
                        }
                        return
                    } else {
                        DispatchQueue.main.async {
                            if let baseView = self?.view {
                                UDToast.showTips(with: BundleI18n.Calendar.Calendar_Toast_LoadErrorToast, on: baseView)
                            }
                        }
                    }
                    CalendarTracer.shareInstance.grandAccess(haveAccess: false)
                }
            }
        }

        switch type {
        case .google:
            importGoogleCalendar()
        case .exchange:
            importExchange()
        case .local:
            importLocalCalendar()
        default:
            return
        }

    }

    private func buildCalendarCellData(calendars: [CalendarModel]) {
        if !FG.isTurnoffGoogleCalendarImport {
            calendars.filter({ (model) -> Bool in
               return model.selfAccessRole == .owner && model.type == .google
            }).forEach({ (model) in
                if !self.googleCalendars.contains(where: { (data) -> Bool in
                    return data.name == model.externalAccountName
                }) {
                    let data = AccountCellData(type: .google, name: model.externalAccountName, isValid: model.externalAccountValid)
                    self.googleCalendars.append(data)
                }
            })
            if !self.googleCalendars.contains(where: { (cellData) -> Bool in return cellData.type == .add }) {
                self.googleCalendars.append(AccountCellData(type: .add, name: BundleI18n.Calendar.Calendar_GoogleCal_ImportCalendars, isValid: true))
            }
        }

        if FG.enableImportExchange {
            calendars.filter({ (model) -> Bool in
               return model.selfAccessRole == .owner && model.type == .exchange
            }).forEach({ (model) in
                if !self.exchangeCalendars.contains(where: { (data) -> Bool in
                    return data.name == model.externalAccountName
                }) {
                    let data = AccountCellData(type: .exchange, name: model.externalAccountName, isValid: model.externalAccountValid)
                    self.exchangeCalendars.append(data)
                }
            })

            if !self.exchangeCalendars.contains(where: { (cellData) -> Bool in return cellData.type == .add }) {
                self.exchangeCalendars.append(AccountCellData(type: .add, name: BundleI18n.Calendar.Calendar_GoogleCal_ImportCalendars, isValid: true))
            }
        }
    }

    private func typeWithSection(_ section: Int) -> CalendarAccountType? {
        guard let data = sectionData(with: section).first else {
            return nil
        }
        if data.type != .add { return data.type }
        var types: [CalendarAccountType] = []
        if !FG.isTurnoffGoogleCalendarImport && !googleCalendars.isEmpty { types.append(.google) }
        if !exchangeCalendars.isEmpty && FG.enableImportExchange { types.append(.exchange) }
        if !localCalendars.isEmpty { types.append(.local) }
        return types[safeIndex: section]
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: AccountManageHeaderView.self)) as? AccountManageHeaderView,
              let type = typeWithSection(section) else {
            return nil
        }
        header.setup(with: type)
        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellModel = sectionData(with: indexPath.section)[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return 46
        }
        return 46
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionCount()
    }
}

private final class NoCalendarView: UIView {
    private let titleLabel: LKLabel = {
        let label = LKLabel()
        let font = UIFont.cd.regularFont(ofSize: 16)
        var stringFront = BundleI18n.Calendar.Calendar_GoogleCal_NoCalendars
        let stringBehind = BundleI18n.Calendar.Calendar_GoogleCal_MayImportOtherCal
        let attributedString = NSMutableAttributedString(string: stringFront + stringBehind, attributes: [
            .font: font,
            .foregroundColor: UIColor.ud.textPlaceholder
            ])
        attributedString.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: NoCalendarView.getBlueStringRange(frontString: stringFront, behindString: stringBehind))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.numberOfLines = 0
        return label
    }()

    private let imageView: UIImageView = UIImageView(image: UDEmptyType.noSchedule.defaultImage())
    private let importClick: () -> Void
    init(importClick: @escaping () -> Void) {
        self.importClick = importClick
        super.init(frame: .zero)
        layout(title: titleLabel)
        backgroundColor = UIColor.ud.N200
        layout(image: imageView, bottomItem: titleLabel.snp.top)

        var textLink = LKTextLink(range: NoCalendarView.getBlueStringRange(
            frontString: BundleI18n.Calendar.Calendar_GoogleCal_NoCalendars,
            behindString: BundleI18n.Calendar.Calendar_GoogleCal_MayImportOtherCal),
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.functionDangerContentPressed],
                                  activeAttributes: [.foregroundColor: UIColor.ud.primaryContentDefault,
                                                     .backgroundColor: UIColor.clear])
        textLink.linkTapBlock = { (_, _) in
            importClick()
        }
        titleLabel.addLKTextLink(link: textLink)
    }

    private static func getBlueStringRange(frontString: String, behindString: String) -> NSRange {
        return NSRange(location: frontString.count, length: behindString.count)
    }

    private func layout(title: UIView) {
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(3)
            make.centerX.equalToSuperview()
//            make.left.equalToSuperview().offset(16)
//            make.right.equalToSuperview().offset(-16)
        }
    }

    private func layout(image: UIView, bottomItem: ConstraintItem) {
        addSubview(image)
        image.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomItem).offset(-10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private final class AccountManageHeaderView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    func setup(with type: CalendarAccountType) {
        var title = ""
        switch type {
        case .exchange:
            title = BundleI18n.Calendar.Calendar_Sync_ExchangeCalendar
        case .google, .add:
            title = BundleI18n.Calendar.Calendar_GoogleCal_Title
        case .local:
            title = BundleI18n.Calendar.Calendar_Setting_LocalCalendars
        }
        titleLabel.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
