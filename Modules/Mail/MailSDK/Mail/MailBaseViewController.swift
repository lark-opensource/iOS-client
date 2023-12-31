//  Created by majunxiao on 5/12/2017.

/*!
 所有ViewController应当继承本类
 提供默认 LoadingView
 */

import Foundation
import LarkUIKit
import Homeric
import RxSwift
import EENavigator

open class MailBaseViewController: BaseUIViewController {
    /// 是否记录Mail页面进出
    var shouldRecordMailState: Bool = true

    /// 是否监听账号权限变化
    var shouldMonitorPermissionChanges: Bool = true

    /// 垃圾袋
    let baseDispose = DisposeBag()

    let loadingView = MailBaseLoadingView()

    var rootSizeClassIsRegular: Bool {
        return view.window?.lkTraitCollection.horizontalSizeClass == .regular
    }

    var rootSizeClassIsSystemRegular: Bool {
        return view.window?.traitCollection.horizontalSizeClass == .regular
    }

    /// NavigationBar 颜色，复写可配置颜色
    open var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBody
    }

    open var realTopBarHeight: CGFloat {
        return Display.realStatusBarHeight() + naviHeight
    }

    /// 配置 navigationBarStyle 为 none，使用 navigationBarTintColor 配置颜色
    open override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    var serviceProvider: MailSharedServicesProvider? {
        mailAssertionFailure("[UserContainer] subclass \(String(describing: Self.self)) should override this property to return UserContext or AccountContext")
        return nil
    }

    var navigator: Navigatable? {
        serviceProvider?.navigator
    }

    var alertHelper: MailClientAlertHelper? {
        serviceProvider?.alertHelper
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .shareAccountChange(let change) = push {
                    if change.isCurrent && !change.isBind {
                        self?.mailCurrentAccountUnbind()
                    }
                }
            }).disposed(by: baseDispose)

        Store.settingData
            .permissionChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (permissionChange, needPopToMailHome) in
                guard let `self` = self else { return }
                guard self.shouldMonitorPermissionChanges && self.isInMailTab() else { return }
                MailLogger.info("[mail_client] coexist permissionChange: \(permissionChange) needPopToMailHome: \(needPopToMailHome)")
                if needPopToMailHome {
                    self.backToMailHome(completion: { [weak self] in
                        guard let `self` = self else { return }
                        self.handlePermissChange(permissionChange)
                    })
                } else {
                    self.handlePermissChange(permissionChange)
                }
        }).disposed(by: baseDispose)
    }

    func isInMailTab() -> Bool {
        if let currentTab = self.tabBarController?.animatedTabBarController?.currentTab, currentTab == .mail {
            return true
        }
        return false
    }

    func handlePermissChange(_ permissionChange: MailPermissionChangeStatus) {
        switch permissionChange {
        case .mailClientRevoke:
            self.alertHelper?.showRevokeMailClientConfirmAlert(confirmHandler: nil, fromVC: self)
        case .lmsRevoke:
            self.alertHelper?.showRevokeLMSConfirmAlert(confirmHandler: nil, fromVC: self)
        case .gcRevoke:
            self.alertHelper?.showRevokeGCConfirmAlert(confirmHandler: nil, fromVC: self)
        case .mailClientAdd:
            break
        case .lmsAdd(let emailAddress):
            self.alertHelper?.showLMSAddConfirmAlert(onboardEmail: emailAddress, fromVC: self)
        case .gcAdd:
            self.alertHelper?.showGCAddConfirmAlert(confirmHandler: nil, fromVC: self)
        case .apiMigration(let emailAddress):
            self.alertHelper?.showApiMigrationAlert(onboardEmail: emailAddress, confirmHandler: nil, fromVC: self)
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// if view appear, track page view event
        trackPageViewEvent()
        if shouldRecordMailState {
            MailStateManager.shared.enterMailPage()
        }
        updateNavigationBar()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// 告诉离开Email页面
        if shouldRecordMailState {
            MailStateManager.shared.exitMailPage()
        }
    }

    @objc
    open func mailCurrentAccountUnbind() {
        if isInMailTab() {
            backToMailHome()
        }
    }

//handler: @escaping (Bool) -> Void
    func backToMailHome(completion: (() -> Void)? = nil) {
        if let presentingViewController = self.presentingViewController {
            closeBtnTapped()
            presentingViewController.dismiss(animated: true, completion: {
                presentingViewController.navigationController?.popToRootViewController(animated: true)
                completion?()
            })
        } else {
            backItemTapped()
            navigationController?.popToRootViewController(animated: true)
            completion?()
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.viewDidTransition(to: size)
        }
    }

    open func viewDidTransition(to size: CGSize) { }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
         NotificationCenter.default.removeObserver(self)
    }

    /// 主端 BaseUIViewController 使用 setBackgroundImage 方式配置颜色，导致侧滑返回时导航栏颜色跳变
    /// 配置 navigationBarStyle 为 none，且使用 barTintColor 配置颜色，实现侧滑渐变效果
    func updateNavigationBar() {
        guard navigationController?.isNavigationBarHidden == false else {
            // 隐藏导航栏时不配置颜色，防止侧滑返回时下层调用，导致导航栏颜色跳变
            return
        }
        navigationController?.navigationBar.barTintColor = navigationBarTintColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = UIColor.ud.textTitle
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

    func isVisible() -> Bool {
        if isViewLoaded {
            return view.window != nil
        }
        return false
    }

    @objc
    func willEnterForeground() {
        /// if enter fore ground, track page view event
        if isVisible() {
            trackPageViewEvent()
        }
    }

    @objc
    func didEnterBackground() {
        // handled in subclass
    }

    open func pageTrackName() -> String {
        return String(describing: type(of: self))
    }

    open func trackPageViewEvent() {
        MailPageViewTracker.trackPageViewEvent(pageTrackName())
    }

    func updateNavAppearanceIfNeeded() {
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = navigationBarTintColor
            appearance.backgroundImage = UIImage.ud.fromPureColor(navigationBarTintColor)
            appearance.shadowImage = UIImage.ud.fromPureColor(navigationBarTintColor)
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
            navigationController?.navigationBar.shadowImage = nil
        }
    }

    func showLoading(frame: CGRect? = nil, duration: Int = 0) {
        view.addSubview(loadingView)
        if let frame = frame {
            loadingView.snp.makeConstraints({ (make) in
                make.center.equalToSuperview()
                make.width.equalTo(frame.size.width)
                make.height.equalTo(frame.size.height)
            })
        } else {
            loadingView.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })
        }
        view.bringSubviewToFront(loadingView)
        loadingView.play()

        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(duration), execute: { [weak self] in
                self?.hideLoading()
            })
        }
    }

    func hideLoading () {
        asyncRunInMainThread {
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal, animations: {
                self.loadingView.alpha = 0.0
            }) { (_) in
                self.loadingView.stop()
                self.loadingView.removeFromSuperview()    
            }
        }
    }
}

extension MailBaseViewController: LarkNaviBarAbility {}
