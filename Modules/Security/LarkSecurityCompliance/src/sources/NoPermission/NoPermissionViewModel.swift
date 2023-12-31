//
//  NoPermissionViewModel.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/14.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface
import LarkUIKit
import UIKit
import UniverseDesignActionPanel
import UniverseDesignToast
import LarkSecurityComplianceInfra

final class NoPermissionViewModel: BaseViewModel, UserResolverWrapper {

    @Provider private var passportService: PassportService // Global
    @ScopedProvider private var service: NoPermissionService?

    private var step: NoPermissionStep?
    private var isBackFromDeviceStatus: Bool = false
    private let bag = DisposeBag()
    var isRefreshing: Bool { return showRefreshLoading.value }

    let model: NoPermissionRustActionModel
    var UIConfig: NoPermissionStepUI? { return self.step }
    let retryButtonClicked = PublishRelay<Void>()
    let refreshWithAnimation = PublishRelay<Void>()
    let refreshWithoutAnimation = PublishRelay<Void>()
    let showDeviceOwnershipLoading = PublishRelay<Bool>()
    let nextButtonLoading = PublishRelay<Bool>()
    let updateUI = PublishRelay<Void>()
    let showRefreshLoading = BehaviorRelay<Bool>(value: false)

    let http = DeviceManagerAPI()
    let userResolver: UserResolver

    var showAlert: Binder<UIView?> {
        return Binder(self) { [weak self] _, view in
            self?.showSwithAlert(view)
        }
    }

    var gotoNext: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.gotoNextAction()
            if self?.model.action == .deviceOwnership {
                self?.isBackFromDeviceStatus = true
            }
        }
    }

    init(resolver: UserResolver, model: NoPermissionRustActionModel) throws {
        self.model = model
        self.userResolver = resolver
        super.init()
        setup()
        Logger.info("Will display logid: \(model.logId)")
    }

    deinit {
        Logger.info("End display logid: \(model.logId)")
    }

    private func endAllWindowsEditing() {
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach { scene in
                (scene as? UIWindowScene)?.windows.forEach({ $0.endEditing(true) })
            }
        } else {
            UIApplication.shared.windows.forEach { $0.endEditing(true) }
        }
    }

    private func setup() {
        viewDidLoad
            .bind { [weak self] in self?.setupSteps() }
            .disposed(by: bag)
        let keyboardWillShow = NotificationCenter.default.rx
            .notification(UIApplication.keyboardDidShowNotification)
            .mapToVoid()
        viewDidLoad.takeUntil(keyboardWillShow)
            .bind { [weak self] in self?.endAllWindowsEditing() }
            .disposed(by: bag)
        let validDeviceOwnership = viewWillAppear
            .take(1)
            .flatMapLatest { [weak self] () -> Observable<Bool> in
                guard let `self` = self else { return .just(false) }
                return self.validateDeviceOwnership()
            }
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
        validDeviceOwnership
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                if value {
                    self?.refreshWithoutAnimation.accept(())
                }
                self?.showDeviceOwnershipLoading.accept(false)
            }, onError: { [weak self] _ in
                self?.showDeviceOwnershipLoading.accept(false)
            })
            .disposed(by: bag)
        viewDidLoad
            .bind { [weak self] _ in
                self?.trackPageShow()
            }
            .disposed(by: bag)
        viewDidAppear
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.isBackFromDeviceStatus {
                    self.refreshWithAnimation.accept(())
                    self.isBackFromDeviceStatus = false
                }
            })
            .disposed(by: bag)
    }

    private func validateDeviceOwnership() -> Observable<Bool> {
        if model.action != .deviceOwnership {
            return .just(false)
        }
        showDeviceOwnershipLoading.accept(true)
        return http.getDeviceInfo()
            .flatMapLatest({ [weak self]  resp -> Observable<Bool> in
                guard let `self` = self else { return .just(false) }
                self.step?.context.deviceInfo = resp.data
                if !resp.data.exist {
                    return self.http.bindDevice().map { $0.data.success }
                } else {
                    return .just(false)
                }
            })
    }

    private func showSwithAlert(_ from: UIView?) {
        guard let view = from else { return }
        var items = [UDActionSheetItem]()
        let switchItem = UDActionSheetItem(title: BundleI18n.LarkSecurityCompliance.Lark_Conditions_SwitchAccount, action: { [weak self] in
            guard let controller = self?.coordinator?.fromViewController else { return }
            self?.passportService.pushToSwitchUserViewController(from: controller)
            self?.trackPageCick(.switchOrganization)
        })
        items.append(switchItem)
        let logoutItem = UDActionSheetItem(title: I18N.Lark_Conditions_Return, action: { [weak self] in
            self?.handleLogout()
            self?.trackPageCick(.logout)
        })
        items.append(logoutItem)
        Alerts.showSheet(source: view, from: coordinator?.fromViewController, title: I18N.Lark_Conditions_Action, items: items)
    }

    private func handleLogout() {
        guard let view = coordinator?.view else { return }
        UDToast.showLoading(with: "", on: view)

        let config: LogoutConf
        let userList = passportService.activeUserList
        if userList.count > 1 {
            config = LogoutConf(forceLogout: true, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, destination: .login, type: .all)
        }

        passportService.logout(conf: config, onInterrupt: {
            Logger.info("relogin interrupt")
            UDToast.removeToast(on: view)
        }, onError: { message in
            Logger.error(message)
            UDToast.removeToast(on: view)
        }, onSuccess: { [weak self] _, message in
            Logger.info("relogin success")
            guard let `self` = self else { return }
            UDToast.removeToast(on: view)
            Logger.info("switch to user sucessfully: \(String(describing: message))")
            self.service?.dismissCurrentWindow()
        }, onSwitch: { _ in

        })
    }

    private func gotoNextAction() {
        step?.next()
    }

    private func setupSteps() {
        let action = model.action
        let context = NoPermissionStepContext(model: model, from: coordinator)
        guard let stepType = context.getStepType(action) else { return }
        guard let step = try? stepType.init(resolver: userResolver, context: context) else { return }
        self.step = step

        viewDidAppear
            .bind(to: step.viewDidAppear)
            .disposed(by: bag)

        retryButtonClicked
            .filter { action != .mfa }
            .bind(to: refreshWithAnimation)
            .disposed(by: bag)

        let autoRefresh = refreshWithoutAnimation.debug().map { false }
        let buttonClickedRefresh = refreshWithAnimation
            .do(onNext: { [weak self] in
                self?.trackPageCick(.retry)
            }).map { true }
        Observable.merge([autoRefresh, buttonClickedRefresh])
            .debug()
            .flatMapLatest { [weak self] isButtonRefresh -> Observable<Bool> in
                guard let step = self?.step else { return .just(false) }
                if isButtonRefresh { // 点击按钮刷新，记录状态
                    self?.showRefreshLoading.accept(true)
                }
                return step.refresh()
                    .debug()
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] resp in
                self?.showRefreshLoading.accept(false)
                guard resp, let `self` = self else { return }
                self.service?.dismissCurrentWindow()
            }, onError: { err in
                Logger.error("\(err)")
            })
            .disposed(by: bag)

        step.updateUI
            .bind(to: updateUI)
            .disposed(by: bag)
        retryButtonClicked
            .bind(to: step.retryButtonClicked)
            .disposed(by: bag)
        step.refreshWithAnimationFromStep
            .bind(to: refreshWithAnimation)
            .disposed(by: bag)
        step.nextButtonLoading
            .bind(to: nextButtonLoading)
            .disposed(by: bag)
    }

    // MARK: - Events

    private func trackPageShow() {
        guard let reason = model.action.trackReason else { return }
        Events.track("scs_no_access_view", params: ["reason": reason])
    }

    private enum EventClick: String {
        case switchOrganization = "switch_organization"
        case logout = "log_out"
        case retry
    }

    private func trackPageCick(_ type: EventClick) {
        guard let reason = model.action.trackReason else { return }
        Events.track("scs_no_access_click", params: ["reason": reason, "click": type.rawValue])
    }
}

extension NoPermissionRustActionModel.Action {
    var trackReason: String? {
        switch self {
        case .unknown: return nil
        case .mfa: return "multi_factor"
        case .deviceOwnership: return "device_ownership"
        case .deviceCredibility: return "device_status"
        case .network: return "web_environment"
        case .fileblock, .dlp, .pointDowngrade, .ttBlock, .universalFallback: return nil
        }
    }
}
