//  Created by heng zhu on 2019/4/23.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import RxSwift
import RoundedHUD
import LarkContainer
import ServerPB
import LarkRustClient
import LKCommonsLogging
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignToast

enum ExternalCalendarType {
    case google
    case exchange
}

final class ExternalCalendarManageViewController: CalendarController, UserResolverWrapper {
    private let cancelImportButton = OperationButton(model: OperationButton.getData(with: .unImportCalendar))
    private let icon: UIImageView = UIImageView()
    private let label: UILabel = UILabel.cd.textLabel()
    private let switchView: UISwitch = UISwitch.blueSwitch()
    private let accountValid: Bool
    private let oAuthUrl: String?
    private let disappearCallBack: (() -> Void)?
    private let disposeBag = DisposeBag()
    private let logger = Logger.log(ExternalCalendarManageViewController.self, category: "calendar.ExternalCalendarManageViewController")

    let userResolver: UserResolver

    @ScopedInjectedLazy private var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var serverPushService: ServerPushService?

    private let accountTitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Calendar.Calendar_GoogleCal_Title
        return label
    }()
    private let warpper = UIView()
    private let invalidWrapper = UIView()
    private let accountName: String
    private let type: ExternalCalendarType
    private let changeExternalAccount: (_ accountName: String, _ visibility: Bool) -> Void

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    private lazy var reauthorizeButton = OperationButton(model: OperationButton.getData(with: .reauthorizeCalendar))

    private var shouldSwitchToOauth = false

    init(userResolver: UserResolver,
         accountName: String,
         type: ExternalCalendarType,
         accountValid: Bool,
         oAuthUrl: String? = nil,
         changeExternalAccount: @escaping (_ accountName: String, _ visibility: Bool) -> Void,
         disappearCallBack: (() -> Void)? = nil) {
        self.userResolver = userResolver
        self.type = type
        self.accountName = accountName
        self.accountValid = accountValid
        self.oAuthUrl = oAuthUrl
        self.changeExternalAccount = changeExternalAccount
        self.disappearCallBack = disappearCallBack
        super.init(nibName: nil, bundle: nil)
        reauthorizeButton.addTarget(self, action: #selector(gotoRelink), for: .touchUpInside)
        cancelImportButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        reauthorizeButton.backgroundColor = UIColor.ud.bgFloat
        cancelImportButton.backgroundColor = UIColor.ud.bgFloat
        switchView.addTarget(self, action: #selector(switchChange), for: .valueChanged)
        if self.type == .google {
            icon.image = UDIcon.getIconByKeyNoLimitSize(.googleColorful)
        } else {
            icon.image = UDIcon.getIconByKeyNoLimitSize(.exchangeColorful)
        }
        warpper.backgroundColor = UIColor.ud.bgFloat
        label.text = accountName
        switchView.isOn = KVValues.getExternalCalendarVisible(accountName: accountName)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        (self.navigationController as? LkNavigationController)?.update(style: .custom(UIColor.ud.bgFloatBase))
        title = BundleI18n.Calendar.Calendar_GoogleCal_CalendarAccountsManagement
        if (self.navigationController?.viewControllers.count ?? 0) > 1 {
            addBackItem()
        } else {
            addDismissItem()
        }
        layout(label: accountTitleLabel)
        layout(warpper: warpper, topItem: accountTitleLabel.snp.bottom)
        warpper.layer.cornerRadius = 10
        layout(icon: icon, in: warpper)
        layout(switchView: switchView, in: warpper)
        layout(label: label, leftItem: icon.snp.right, rightItem: switchView.snp.left, in: warpper)
        let hasInvalidPart = !accountValid && FG.enableImportExchange
        shouldSwitchToOauth = !hasInvalidPart && !(oAuthUrl?.isEmpty ?? true)
        if hasInvalidPart || shouldSwitchToOauth {
            layout(invalidWrapper: invalidWrapper)
        }
        layout(stackView: buttonStackView, topItem: (hasInvalidPart || shouldSwitchToOauth) ? invalidWrapper.snp.bottom : warpper.snp.bottom)
        reauthorizeButton.isHidden = !hasInvalidPart && !shouldSwitchToOauth
        if !reauthorizeButton.isHidden && shouldSwitchToOauth {
            reauthorizeButton.label.text = BundleI18n.Calendar.Calendar_Ex_UpdateAuthorization
        } else {
            reauthorizeButton.label.text = BundleI18n.Calendar.Calendar_Sync_Relink
        }
        registerBindAccountNotification()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disappearCallBack?()
    }

    private func layout(stackView: UIStackView, topItem: ConstraintItem) {
        view.addSubview(stackView)
        stackView.addArrangedSubview(reauthorizeButton)
        stackView.addArrangedSubview(cancelImportButton)

        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(topItem).offset(28)
        }

        reauthorizeButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        cancelImportButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        reauthorizeButton.layer.cornerRadius = 10
        cancelImportButton.layer.cornerRadius = 10
    }

    private func layout(label: UILabel) {
        view.addSubview(label)
        label.text = (self.type == .google) ? BundleI18n.Calendar.Calendar_GoogleCal_Title : BundleI18n.Calendar.Calendar_Sync_ExchangeCalendar
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func layout(warpper: UIView, topItem: ConstraintItem) {
        view.addSubview(warpper)
        warpper.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.top.equalTo(topItem).offset(4)
        }
    }

    private func layout(icon: UIView, in superV: UIView) {
        superV.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    private func layout(switchView: UIView, in superV: UIView) {
        superV.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(28)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func layout(label: UIView, leftItem: ConstraintItem, rightItem: ConstraintItem, in superV: UIView) {
        superV.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftItem).offset(12)
            make.right.equalTo(rightItem).offset(-12)
        }
    }

    private func layout(invalidWrapper: UIView) {
        view.addSubview(invalidWrapper)
        invalidWrapper.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(32)
            make.top.equalTo(warpper.snp.bottom).offset(8)
        }

        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.warningOutlined).scaleInfoSize().ud.withTintColor(UIColor.ud.colorfulRed))
        invalidWrapper.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(16)
            make.top.left.equalToSuperview()
        }

        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Calendar.Calendar_Ex_ExpireLinkAgain
        if accountValid && shouldSwitchToOauth {
            label.text = BundleI18n.Calendar.Calendar_Ex_NoMoreSyncSoon
        }
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        invalidWrapper.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(4)
        }
    }

    private func registerBindAccountNotification() {
        serverPushService?
            .rxExchangeBind
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.onExchangeBindSuccess()
            }).disposed(by: disposeBag)
    }

    private func onExchangeBindSuccess() {
        logger.info("onExchangeBindSuccess")
        self.invalidWrapper.snp.remakeConstraints { (make) in
            make.height.equalTo(0)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.warpper.snp.bottom)
        }
        self.invalidWrapper.isHidden = true
        self.reauthorizeButton.isHidden = true
        UDToast.showTips(with: BundleI18n.Calendar.Calendar_G_UpdatedAuthToast, on: self.view)
    }

    @objc
    private func gotoRelink() {
        CalendarTracer.shared.accountManagerClick(clickParam: "redelegation", target: "none")
        switch type {
        case .exchange:
            logger.info("reauth exchange")

            if let authUrl = oAuthUrl, !authUrl.isEmpty {
                if let url = URL(string: authUrl) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    logger.error("Invalid auth Url!")
                }
            } else {
                let viewModel = PreImportExchangeViewModel(userResolver: self.userResolver, defaultEmail: accountName) { [weak self] (result) in
                    guard let self = self else { return }
                    if case .success = result {
                        self.invalidWrapper.snp.remakeConstraints { (make) in
                            make.height.equalTo(0)
                            make.leading.trailing.equalToSuperview()
                            make.top.equalTo(self.warpper.snp.bottom)
                        }
                        self.invalidWrapper.isHidden = true
                    }
                }
                let viewController = PreImportExchangeViewController(userResolver: self.userResolver, viewModel: viewModel)
                self.navigationController?.pushViewController(viewController, animated: true)
            }

        case .google:
            guard let rustApi = self.calendarApi else {
                logger.error("getBindGoogleCalAddr failed, can not get rustapi from larkcontainer")
                return
            }
            rustApi.getBindGoogleCalAddr(forceBindMail: false)
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
    }

    @objc
    private func switchChange() {
        KVValues.setExternalCalendarVisible(accountName: accountName, isVisible: switchView.isOn)
        if self.type == .google {
            CalendarTracer.shareInstance.calSettingImportGoogle(actionTargetSource: .init(isOn: switchView.isOn))
        }
        // 关闭可见去掉全部勾选，以后exchange也可能是这套逻辑
        if !switchView.isOn {
            changeExternalAccount(accountName, false)
        }
    }
    let dispose = DisposeBag()
    @objc
    private func cancelButtonPressed() {
        CalendarTracer.shared.accountManagerClick(clickParam: "remove", target: "remove_bullet_view")

        UDToast.showLoading(with: BundleI18n.Calendar.Calendar_GoogleCal_Canceling, on: view)

        var operation: Observable<Void>
        switch type {
        case .google: operation = revokeGoogleAccount()
        case .exchange: operation = revokeExchangeAccount()
        }

        operation
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded, on: self.view)
                if let navigationController = self.navigationController {
                    if navigationController.viewControllers.count > 1 {
                        navigationController.popViewController(animated: true)
                    } else {
                        navigationController.dismiss(animated: true)
                    }
                }
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_GoogleCal_TryLater, on: self.view)
            }).disposed(by: dispose)
    }

    private func revokeGoogleAccount() -> Observable<Void> {
        return calendarApi?.cancelImportGoogleCal(account: [accountName]) ?? .empty()
    }

    private func revokeExchangeAccount() -> Observable<Void> {
        return calendarApi?.revokeExchangeAccount(account: [accountName]) ?? .empty()
    }

}
