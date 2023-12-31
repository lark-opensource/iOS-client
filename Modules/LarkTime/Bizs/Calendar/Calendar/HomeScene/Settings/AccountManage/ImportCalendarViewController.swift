//
//  ImportCalendarViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/4/15.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignToast
import Foundation
import CalendarFoundation
import SnapKit
import LarkUIKit
import RxSwift
import RoundedHUD
import LarkContainer

struct GoogleCellData: CalendarAccountAccessCellModel {
    var isSelectedAsNotificaionEmail = false

    var type: CalendarAccountType = .google
    var name: String = BundleI18n.Calendar.Calendar_GoogleCal_Title
    var desc: String?
}

struct LocalCellData: CalendarAccountAccessCellModel {
    var isSelectedAsNotificaionEmail = false
    var type: CalendarAccountType = .local
    var name: String = BundleI18n.Calendar.Calendar_Setting_LocalCalendars
    var desc: String?
}

struct ExchangeCellData: CalendarAccountAccessCellModel {
    var isSelectedAsNotificaionEmail = false

    var type: CalendarAccountType = .exchange
    var name: String = BundleI18n.Calendar.Calendar_Sync_ExchangeCalendar
    var desc: String? = BundleI18n.Calendar.Calendar_Sync_ExchangeCalendarDescription
}

struct ImportCalendarViewControllerDependency {
    let bindGoogleCalAddrGetter: (Bool) -> Observable<String>
    let disappearCallBack: (() -> Void)?
}

final class ImportCalendarViewController: CalendarController, UserResolverWrapper {
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var serverPushService: ServerPushService?
    let userResolver: UserResolver

    private var cellDatas: [[CalendarAccountAccessCellModel]]
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.register(CalendarAccountAccessCell.self, forCellReuseIdentifier: "CalendarAccountAccessCell")
        tableView.register(CalendarAddAccountFooterView.self, forHeaderFooterViewReuseIdentifier: "CalendarAddAccountFooterView")
        let zeroRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: Double.leastNormalMagnitude)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: zeroRect)
        return tableView
    }()

    private let dependency: ImportCalendarViewControllerDependency
    private let disposeBag = DisposeBag()
    private let needAuthWarningController = LocalCalNoAuthWarningController()
    static func controllerWithBack(userResolver: UserResolver, dependency: ImportCalendarViewControllerDependency) -> ImportCalendarViewController {
        let vc = buildController(userResolver: userResolver, dependency: dependency)
        vc.addBackItem()
        return vc
    }

    static func controllerWithClose(userResolver: UserResolver, dependency: ImportCalendarViewControllerDependency) -> ImportCalendarViewController {
        let vc = buildController(userResolver: userResolver, dependency: dependency, forceShowLocal: true)
        vc.addCloseItem()
        return vc
    }

    static func buildController(userResolver: UserResolver, dependency: ImportCalendarViewControllerDependency, forceShowLocal: Bool = false) -> ImportCalendarViewController {
        let localAuthorized = LocalCalendarManager.isLocalCalendarAccessable() == .authorized
        let enableImportGoogle = !FG.isTurnoffGoogleCalendarImport
        let enableImportExchange = FG.enableImportExchange
        let emptyData: [CalendarAccountAccessCellModel] = []
        var externalAccounts: [CalendarAccountAccessCellModel?] = [
            enableImportGoogle ? GoogleCellData() : nil,
            enableImportExchange ? ExchangeCellData() : nil
        ]
        let data: [[CalendarAccountAccessCellModel]] = [
            externalAccounts.flatMap { $0 },
            (!localAuthorized || forceShowLocal) ? [LocalCellData()] : emptyData
        ]
        let vc = ImportCalendarViewController(userResolver: userResolver, dependency: dependency, cellDatas: data.filter { !$0.isEmpty })
        return vc
    }

    private init(userResolver: UserResolver, dependency: ImportCalendarViewControllerDependency, cellDatas: [[CalendarAccountAccessCellModel]]) {
        self.userResolver = userResolver
        self.cellDatas = cellDatas
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
        pushService?
            .rxGoogleBind
            .observeOn(MainScheduler.instance)
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_EmailGuest_AccountAddedSuccessfully, on: self.view.window ?? self.view)
                if self.isUsingCloseStyle {
                    self.closePressed()
                } else {
                     if let viewControllers = self.navigationController?.viewControllers,
                           viewControllers.count >= 3 {
                           self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                    }
                }
            }).disposed(by: disposeBag)

        serverPushService?
            .rxExchangeBind
            .observeOn(MainScheduler.instance)
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_EmailGuest_AccountAddedSuccessfully, on: self.view.window ?? self.view)
                if self.isUsingCloseStyle {
                    self.closePressed()
                } else {
                     if let viewControllers = self.navigationController?.viewControllers,
                           viewControllers.count >= 3 {
                           self.navigationController?.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                    }
                }
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.Calendar.Calendar_Sync_AddThirdPartyCalendarTitle
        self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgFloatBase
        (self.navigationController as? LkNavigationController)?.update(style: .custom(UIColor.ud.bgFloatBase))
        layout(subView: tableView)
        tableView.reloadData()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dependency.disappearCallBack?()
    }

    public func layout(subView: UIView) {
        view.addSubview(subView)
        subView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }

    fileprivate var isUsingCloseStyle: Bool = false
    fileprivate func addCloseItem() {
        let barItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1), title: nil)
        barItem.button.addTarget(self, action: #selector(closePressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        isUsingCloseStyle = true
    }

    @objc
    private func closePressed() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    private func importGoogleCalendar() {
        CalendarTracer.shared.accountManagerClick(clickParam: "google", target: "none")
        dependency.bindGoogleCalAddrGetter(false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (addr) in
                guard let self = self else { return }
                if let url = URL(string: addr), !addr.isEmpty {
                    // google 要求使用外置浏览器
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    let roundedHud = RoundedHUD()
                    roundedHud.showFailure(with: BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: self.view)
                    operationLog(message: "invaild url: \(addr)")
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                let roundedHud = RoundedHUD()
                roundedHud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: self.view)
            }).disposed(by: disposeBag)
    }

    private func importLocalCalendar() {
        CalendarTracer.shared.accountManagerClick(clickParam: "local", target: "none")
        if LocalCalendarManager.isLocalCalendarAccessable() == .unauthorized {
            needAuthWarningController.show(self.navigationController)
        } else {
            var forToken: SensitivityControlToken = SensitivityControlToken.requestCalendarAccessWhenImportLocalCalendar
            if #available(iOS 17.0, *) {
                forToken = SensitivityControlToken.requestCalendarFullAccessWhenImportLocalCalendar
            }
            LocalCalendarManager.requireLocalCalendarAuthorization(for: forToken) { [weak self] (success) in
                if success {
                    CalendarTracer.shareInstance.grandAccess(haveAccess: true)
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

    private func importExchangeCalendar() {
        CalendarTracer.shared.accountManagerClick(clickParam: "exchange", target: "none")

        let viewModel = PreImportExchangeViewModel(userResolver: self.userResolver) {[weak self] result in
            guard let `self` = self else { return }
            if case .success = result {
                self.dismiss(animated: true, completion: nil)
            }
        }
        let viewController = PreImportExchangeViewController(userResolver: self.userResolver, viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

}

extension ImportCalendarViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        cellDatas.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDatas[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < cellDatas.count else {
            assertionFailureLog()
            return CGFloat.leastNormalMagnitude
        }
        return 46
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountAccessCell", for: indexPath) as? CalendarAccountAccessCell, indexPath.section < cellDatas.count else {
            assertionFailureLog()
            return UITableViewCell()
        }
        cell.update(model: cellDatas[indexPath.section][indexPath.row])
        cell.bottomLine?.isHidden = true
        if cellDatas[indexPath.section].count == 1 {
            // 只有一行的全部圆角
            cell.layer.cornerRadius = 10
            cell.midBottomLine?.isHidden = true
        } else {
            switch indexPath.row {
            case 0:
                // 第一行，左上、右上圆角
                cell.layer.cornerRadius = 10
                cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case cellDatas[indexPath.section].count - 1:
                // 最后一行，左下、右下圆角
                cell.layer.cornerRadius = 10
                cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.midBottomLine?.isHidden = true
            default:
                break
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < cellDatas.count else {
            assertionFailureLog()
            return
        }
        switch cellDatas[indexPath.section][indexPath.row].type {
        case .google:
            importGoogleCalendar()
        case .local:
            importLocalCalendar()
        case .exchange:
            importExchangeCalendar()
        case .add:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 16
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else {
            return UIView()
        }
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CalendarAddAccountFooterView") as? CalendarAddAccountFooterView,
              section < cellDatas.count else {
            return UIView()
        }
        if section == 0 {
            headerView.title = BundleI18n.Calendar.Calendar_Sync_ExchangeCalendarDescription
            return headerView
        }
        return nil
    }
}

final class CalendarAddAccountFooterView: UITableViewHeaderFooterView {

    var title: String {
        didSet {
            titleLabel.text = title
        }
    }
    override init(reuseIdentifier: String?) {
        self.title = ""
        super.init(reuseIdentifier: reuseIdentifier)
        layoutUI()
    }

    private func layoutUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(4)
            make.bottom.equalTo(-12)
            make.leading.equalTo(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_EmailGuest_OtherAccountTypeNotSupport
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.font = UIFont.cd.regularFont(ofSize: 14)
        return label
    }()
}
