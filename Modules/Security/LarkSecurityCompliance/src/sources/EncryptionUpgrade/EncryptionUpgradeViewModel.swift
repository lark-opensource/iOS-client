//
//  EncryptionUpgradeViewModel.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/13.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkRustClient
import UniverseDesignDialog
import LarkSecurityComplianceInfra

struct EncryptionUpgrade {}

extension EncryptionUpgrade {
    enum State: String {
        case inProgress = "in_progress"
        case succeeded
        case failed
    }

    struct Progress: PushMessage {
        let percentage: Int
        let eta: Int
    }
}

protocol EncryptionUpgradeStateHandler {
    var stateUpdateSignal: Driver<EncryptionUpgrade.State> { get }
    var progressUpdateSignal: Driver<EncryptionUpgrade.Progress> { get }
}

protocol EncryptionUpgradeEndTaskDelegate: AnyObject {
    func quitAndResume()
}

final class EncryptionUpgradeViewModel: BaseViewModel {

    private var state = EncryptionUpgrade.State.inProgress {
        didSet {
            if isApplicationActive {
                Logger.info("set state:\(state)")
                nextStateRelay.accept(state)
            }
        }
    }

    private var progress = EncryptionUpgrade.Progress(percentage: 0, eta: 0) {
        didSet {
            if isApplicationActive {
                Logger.info("set progress:\(progress)")
                progressRelay.accept(progress)
            }
        }
    }

    private var isApplicationActive: Bool {
        UIApplication.shared.applicationState == .active
    }

    private let rustApi: EncryptionUpgradeRustApi

    weak var delegate: EncryptionUpgradeEndTaskDelegate?

    let disposeBag = DisposeBag()

    private let nextStateRelay = BehaviorRelay<EncryptionUpgrade.State>(value: .inProgress)
    private let progressRelay = PublishRelay<EncryptionUpgrade.Progress>()

    let skipButton = PublishRelay<Void>()
    let retryButton = PublishRelay<Void>()
    let laterButton = PublishRelay<Void>()

    private var upgradeSessionDuration: Int = 0

    var skipAlertShow: Binder<UIViewController?> {
        return Binder(self) { [weak self] _, from in
            Logger.info("dialog show alert triggered")
            self?.showSkipAlert(from)
        }
    }

    var laterAlertShow: Binder<UIViewController?> {
        return Binder(self) { [weak self] _, from in
            Logger.info("dialog show alert triggered")
            self?.showLaterAlert(from)
        }
    }

    init(rustApi: EncryptionUpgradeRustApi) {
        Logger.info("init viewModel")
        self.rustApi = rustApi
        super.init()
        setup()
    }

    private func setup() {
        // 展示
        viewDidLoad
            .bind { [weak self] _ in
                Logger.info("viewDidLoad triggered, start database rekey")
                self?.handleRustPush()
                self?.startDatabaseRekey(fromRetry: false)
            }.disposed(by: disposeBag)

        let retryButtonTapped = retryButton
            .filter { [weak self] in
                self?.state == .failed
            }
            .do(onNext: { [weak self] in
                Logger.info("retryButton tapped")
                self?.trackRetryButtonClicked()
            })

        retryButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.startDatabaseRekey(fromRetry: true)
            }).disposed(by: disposeBag)

        observeApplicationStates()
    }

    private func startDatabaseRekey(fromRetry: Bool) {
        Logger.info("database rekey session started from retry\(fromRetry)")
        state = .inProgress
        upgradeSessionDuration = 0
        let startTimeStamp = CACurrentMediaTime()
        rustApi.databaseRekeyExecuteSession()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                guard let self else { return }
                self.upgradeSessionDuration = Int((CACurrentMediaTime() - startTimeStamp) * 1000)
                Logger.info("receive rekey session success return with duration(ms):\(self.upgradeSessionDuration)")
                self.infoRekey(category: ["rekey_status": "success", "retry": fromRetry],
                               metric: ["duration": self.upgradeSessionDuration])
                self.state = .succeeded
                self.onRekeySuccess()
            } onError: { [weak self] error in
                guard let self else { return }
                self.upgradeSessionDuration = Int((CACurrentMediaTime() - startTimeStamp) * 1000)
                Logger.info("receive rekey session failed return with duration(ms):\(self.upgradeSessionDuration), error:\(error)")
                self.errorRekey(error: error,
                                category: ["rekey_status": "error", "retry": fromRetry],
                                metric: ["duration": self.upgradeSessionDuration])
                self.state = .failed
            }.disposed(by: disposeBag)
    }

    private func handleRustPush() {
        rustApi.databaseRekeyProgressSession()
            .drive { [weak self] progress in
                Logger.info("receive rekey rust push progress:\(progress)")
                self?.progress = progress
            }
            .disposed(by: disposeBag)

        Logger.info("database rekey rust push session started")
    }
}

extension EncryptionUpgradeViewModel {
    private func quitAndResume() {
        Logger.info("calling delegate to resume launch flow")
        delegate?.quitAndResume()
    }

    private func onRekeySuccess() {
        Logger.info("rekey succeeded, about to quit and resume launch flow")
        EncryptionUpgradeStorage.shared.updateShouldRekey(value: false)
        EncryptionUpgradeStorage.shared.updateIsUpgraded(value: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else {
                Logger.error("viewModel released when resuming launch task flow")
                return
            }
            self.quitAndResume()
        }
    }
}

// alerts
extension EncryptionUpgradeViewModel {
    // destrucitve alert
    private func showSkipAlert(_ from: UIViewController?) {
        guard let vc = from else { return }
        let dismissCompletion = { [weak self] in
            Logger.info("skip dialog confirmed tapped, will exit application")
            self?.trackSkipButtonActuallySkipped()
            EncryptionUpgradeStorage.shared.updateShouldSkipOnce(value: true)
            // exit on main thread
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var exitSel: Selector { Selector(["terminate", "With", "Success"].joined()) }
                UIApplication.shared.perform(exitSel,
                                             on: Thread.main,
                                             with: nil,
                                             waitUntilDone: false)
            }
        }
        let skipAction = Alerts.AlertAction(title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipButton2,
                                            style: .default,
                                            handler: dismissCompletion)

        let cancelAction = Alerts.AlertAction(title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_CancelButton,
                                              style: .secondary,
                                              handler: nil)

        let alertShown = Alerts.showAlertAndGetSignal(from: vc,
                                                      title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipOrNotTitle,
                                                      content: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipDuringUpgradeDescrip(),
                                                      actions: [cancelAction, skipAction])

        // dismiss dialog on state changed
        Observable.combineLatest(alertShown, nextStateRelay.asObservable().distinctUntilChanged())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (dialog, state) in
                guard state != .inProgress else { return }
                dialog.dismiss(animated: true)
            }).disposed(by: disposeBag)
    }

    private func showLaterAlert(_ from: UIViewController?) {
        guard let vc = from else { return }
        let dismissCompletion = { [weak self] in
            Logger.info("later dialog confirmed tapped, will resume launch tasks")
            self?.trackLaterButtonActuallyClicked()
            self?.quitAndResume()
        }
        let skipAction = Alerts.AlertAction(title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipButton2,
                                            style: .default,
                                            handler: dismissCompletion)

        let cancelAction = Alerts.AlertAction(title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_CancelButton,
                                              style: .secondary,
                                              handler: nil)

        Alerts.showAlert(from: vc,
                         title: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipOrNotTitle,
                         content: BundleI18n.EncryptionUpgrade.Lark_LocalDataEncryptionKey_SkipOrNotDescription(),
                         actions: [cancelAction, skipAction])
    }
}

// Track
extension EncryptionUpgradeViewModel {
    func trackStateShow(_ state: EncryptionUpgrade.State) {
        switch state {
        case .inProgress:
            Events.track("scs_key_update_view")
        case .succeeded:
            Events.track("scs_key_update_success_view", params: ["duration": upgradeSessionDuration / 1000])
        case .failed:
            Events.track("scs_key_update_fail_view", params: ["duration": upgradeSessionDuration / 1000])
        }
    }

    private func trackSkipButtonActuallySkipped() {
        Events.track("scs_key_update_click", params: ["click": "skip"])
    }

    private func trackLaterButtonActuallyClicked() {
        Events.track("scs_key_update_fail_click", params: ["click": "later"])
    }

    private func trackRetryButtonClicked() {
        Events.track("scs_key_update_fail_click", params: ["click": "retry"])
    }
}

// Monitor
extension EncryptionUpgradeViewModel {
    private func infoRekey(category: [String: Any], metric: [String: Any]) {
        SCMonitor.info(business: .encryption_upgrade,
                       eventName: "result",
                       category: category,
                       metric: metric)
    }

    private func errorRekey(error: Error, category: [String: Any], metric: [String: Any]) {
        let nsError = error as NSError
        var finalCategory: [String: Any] = ["status": 1]
        finalCategory["error_code"] = nsError.code
        finalCategory["error_domain"] = nsError.domain
        finalCategory["error_msg"] = nsError.localizedDescription
        finalCategory = finalCategory.merging(category) { $1 }

        SCMonitor.info(business: .encryption_upgrade,
                       eventName: "result",
                       category: finalCategory,
                       metric: metric)
    }
}

extension EncryptionUpgradeViewModel: EncryptionUpgradeStateHandler {
    var stateUpdateSignal: Driver<EncryptionUpgrade.State> {
        nextStateRelay.asDriver().distinctUntilChanged()
    }

    var progressUpdateSignal: Driver<EncryptionUpgrade.Progress> {
        progressRelay.asDriverOnErrorJustComplete()
    }
}

// NotificationCenter
extension EncryptionUpgradeViewModel {
    private func observeApplicationStates() {
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                Logger.info("application did become active")
                self.nextStateRelay.accept(self.state)
                self.progressRelay.accept(self.progress)
            }, onError: { error in
                Logger.error("application did become active with error:\(error)")
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                Logger.info("application did enter background")
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                Logger.info("application will resign active")
            }).disposed(by: disposeBag)
    }
}
