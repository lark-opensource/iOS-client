//
//  AppLockSettingBlurService.swift
//  LarkMine
//
//  Created by qingchun on 2022/9/29.
//

import UIKit
import LarkBlur
import LKCommonsLogging
import LarkUIKit
import UniverseDesignColor
import LarkContainer
import LarkSecurityComplianceInfra
import LarkAccountInterface
import LarkSecurityComplianceInterface

private final class BlurViewController: BaseUIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.01)
        let blurView = LarkBlurEffectView()
        blurView.blurRadius = 16
        blurView.colorTint = UDColor.primaryOnPrimaryFill
        blurView.colorTintAlpha = 0.01
        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

    }
}

final class AppLockSettingBlurService: UserResolverWrapper {

    static let logger = Logger.log(AppLockSettingService.self, category: "app_lock")

    private static let blurViews = NSHashTable<AppLockBlurView>(options: .weakMemory)
    private static let blurVCs = NSHashTable<BlurViewController>(options: .weakMemory)
    private static let blurWindows = NSHashTable<UIWindow>(options: .strongMemory)

    var isRequestBiometric = false

    let userResolver: UserResolver
        
    @ScopedProvider private var userService: PassportUserService?
    @ScopedProvider private var settings: SCRealTimeSettingService?
    private let windowService: WindowService
    
    private var observeKey: String?
    
    var isSupportMultiSceneOpt: Bool {
        guard let uid = userService?.user.userID else { return true }
        let kv = SCKeyValue.MMKV(userId: uid)
        return !kv.bool(forKey: "disable_app_lock_scene_opt")
    }
    
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        windowService = try userResolver.resolve(assert: ExternalDependencyService.self).windowService
    }
    
    deinit {
        if let observeKey, let settings {
            settings.unregistObserver(identifier: observeKey)
        }
    }
    
    func syncAppLockSettingConfig() {
        guard let uid = userService?.user.userID, let value = settings?.bool(.disableAppLockSceneOpt) else {
            return
        }
        let kv = SCKeyValue.MMKV(userId: uid)
        kv.set(value, forKey: "disable_app_lock_scene_opt")
      
        observeKey = settings?.registObserver(key: .disableAppLockSceneOpt) { [weak self] result in
            guard self != nil, let value = result as? Bool  else { return }
            let kv = SCKeyValue.MMKV(userId: uid)
            kv.set(value, forKey: "disable_app_lock_scene_opt")
        }
    }

    func addBlurViews(_ windows: [UIWindow]? = nil) {
        let aWindows: [UIWindow]
        if isSupportMultiSceneOpt {
            aWindows = windows ?? self.windows
        } else {
            aWindows = self.windows
            removeBlurViews()
        }
        aWindows.forEach { window in
            guard !windowService.isLSCWindow(window) else { return }
            if let view = window.blurView {
                window.bringSubviewToFront(view)
                return
            }
            let blurView = AppLockBlurView(frame: window.bounds)
            window.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            Self.blurViews.add(blurView)
        }
        Self.logger.debug("did add blur views: \(aWindows.count)")
    }
    
    @available(iOS 13.0, *)
    func addBlurView(forScene scene: UIWindowScene) {
        let windows: [UIWindow] = {
            if let applockWindow = scene.windows.first(where: { windowService.isLSCWindow($0) }) {
                let targetWindows = scene.windows.filter { $0.windowLevel < applockWindow.windowLevel }
                return targetWindows
            } else {
                return scene.windows
            }
        }()
        addBlurViews(windows)
    }
    
    @available(iOS 13.0, *)
    func removeBlurView(forScene scene: UIWindowScene) {
        Self.blurViews.allObjects.forEach {
            if $0.window?.windowScene == scene {
                $0.removeFromSuperview()
            }
        }
    }

    func removeBlurViews() {
        if isSupportMultiSceneOpt {
            Self.blurViews.allObjects.forEach {
                $0.removeFromSuperview()
            }
            Self.blurWindows.allObjects.forEach {
                $0.isHidden = true
            }
            Self.blurWindows.removeAllObjects()
        } else {
            Self.blurViews.allObjects.forEach { $0.removeFromSuperview() }
        }
        Self.logger.debug("did remove blur views: \(Self.blurViews.allObjects.count)")
    }

    func addVisibleBlurVCs() {
        let windows = self.windows
        windows.forEach { window in
            guard !windowService.isLSCWindow(window) else { return }
            let topVC = window.lu.visibleViewController()
            guard topVC?.view.window != nil else { return }
            let blurVC = BlurViewController()
            blurVC.modalPresentationStyle = .overFullScreen
            if let navC = topVC?.navigationController {
                navC.pushViewController(blurVC, animated: false)
            } else {
                topVC?.present(blurVC, animated: false)
            }

            Self.logger.info("did add vc blurVC: \(blurVC)")
            Self.blurVCs.add(blurVC)
        }
    }

    func removeVisibleVCs() {
        Self.blurVCs.allObjects.forEach {
            $0.dismiss(animated: false)
        }
        Self.logger.debug("did remove vc's blur views: \(Self.blurVCs.allObjects.count)")
    }

    var appLockCoverViewController: UIViewController {
        let service = try? userResolver.resolve(assert: AppLockSettingDependency.self)
        guard (service?.enableAppLockSettingsV2).isTrue else {
            return AppLockCoverViewController()
        }
        return AppLockSettingV2.AppLockCoverViewController()
    }

    @available(iOS 13.0, *)
    func showCoverView(forScene windowScene: UIWindowScene) {
        guard !windowScene.windows.contains(where: { windowService.isLSCWindow($0) }) else { return }
        let window = windowService.createLSCWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        window.windowLevel = .alert - 3
        window.rootViewController = appLockCoverViewController
        window.isHidden = false
        Self.blurWindows.add(window)
        Self.logger.debug("did add cover view for scene: \(windowScene)")
    }
    
    @available(iOS 13.0, *)
    func hideCoverView(forScene windowScene: UIWindowScene) {
        Self.blurWindows.allObjects.forEach {
            $0.isHidden = true
        }
        Self.logger.debug("did remove cover view for scene: \(windowScene)")
    }

    // MARK: - PRIVATE

    private var windows: [UIWindow] {
        if #available(iOS 13.0, *) {
            var results = [UIWindow]()
            let scenes = UIApplication.shared.connectedScenes
            scenes.forEach { scene in
                guard let windows = (scene as? UIWindowScene)?.windows else { return }
                if let applockWindow = windows.first(where: { windowService.isLSCWindow($0) }) {
                    let targetWindows = windows.filter { $0.windowLevel < applockWindow.windowLevel }
                    results.append(contentsOf: targetWindows)
                } else {
                    results.append(contentsOf: windows)
                }
            }
            return results
        } else {
            let windows = UIApplication.shared.windows
            if let applockWindow = windows.first(where: { windowService.isLSCWindow($0) }) {
                return windows.filter { $0.windowLevel < applockWindow.windowLevel }
            } else {
                return windows
            }
        }
    }
}
