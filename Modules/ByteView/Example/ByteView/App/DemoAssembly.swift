//
//  AppAssembly.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/5.
//

import Foundation
import Swinject
import BootManager
import LarkSceneManager
import LarkRustClient
import LarkAccountInterface
import LarkTab
import ByteWebImage
import LarkNavigation
import LarkAssembler
import EENavigator
import ByteViewMod
#if !canImport(LarkSDK) && canImport(LarkCustomerService)
import LarkCustomerService
#endif
import AppContainer
import ByteViewWidgetService
import ByteViewLiveCert
import RxCocoa
import SnapKit
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
import LarkQuickLaunchInterface
#endif
#if !canImport(LarkBaseService) && canImport(LarkTracker)
import LarkTracker
#endif
#if canImport(LarkOpenPlatform)
import EcosystemWeb
#endif

final class DemoApplicationDelegate: ApplicationDelegate {
    init(context: AppContainer.AppContext) {
        context.dispatcher.add(observer: self) { [weak self] _, message in
            self?.willTerminate(message)
        }

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.handleSceneContinueUserActivity(message)
            }
        }
    }

    static var config = Config(name: "ByteViewDemo", daemon: true)

    private func willTerminate(_ message: WillTerminate) -> WillTerminate.HandleReturnType {
        ByteViewWidgetService.forceEndAllActivities("Terminate")
    }

    @available(iOS 13.0, *)
    private func handleSceneContinueUserActivity(_ message: SceneContinueUserActivity) {
        NotificationCenter.default.post(name: VCNotification.didReceiveContinueUserActivityNotification, object: self,
                                        userInfo: [VCNotification.userActivityKey: message.userActivity])
    }
}

class DemoAssembly: LarkAssemblyInterface {
    init() {}

    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        #if canImport(LarkOpenPlatform)
        DemoOpenPlatformAssembly()
        #endif
        #if canImport(WebBrowser)
        DemoWebBrowserAssembly()
        #endif
        #if canImport(LarkAIInfra) && !canImport(LarkAI)
        DemoAIAssembly()
        #endif
    }

    func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        #if !canImport(LarkFeed)
        user.register(MainTabbarControllerDependency.self) { _ in
            MainTabbarControllerDependencyImpl()
        }
        #endif
        #if !canImport(LarkSDK) && canImport(LarkCustomerService)
        user.register(LarkCustomerServiceAPI.self) { r in
            let rustClient = try r.resolve(assert: RustService.self)
            return LarkCustomerService(client: rustClient, navigator: r.navigator, userResolver: r)
        }
        #endif
        #if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
        user.register(OpenNavigationProtocol.self) { _ in
            OpenNavigationImpl()
        }
        #endif
        #if !canImport(LarkBaseService) && canImport(LarkTracker)
        container.register(TrackService.self) { _ in
            TrackService(traceUserInterfaceIdiom: Display.pad, isStaging: DemoEnv.isStaging, isRelease: DemoEnv.isRelease)
        }.inObjectScope(.container)
        let _ = {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                _ = try? container.resolve(assert: TrackService.self)
            })
        }()
        #endif
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { DemoLauncherDelegate() }, PassportDelegatePriority.middle)
    }

    func registLaunch(container: Container) {
        NewBootManager.register(SetupLoggerTask.self)
        NewBootManager.register(InitIdleLoadTask.self)
        // initialize LarkRustHTTP
        NewBootManager.register(SetupURLProtocolTask.self)
    }

    func registBootLoader(container: Container) {
        // 优先级设为 high，及时响应 willTerminate 事件，退出灵动岛
        (DemoApplicationDelegate.self, DelegateLevel.high)
    }

    @available(iOS 13.0, *)
    func registLarkScene(container: Container) {
        SceneManager.shared.register(config: DemoScene.self)
        #if !canImport(LarkChat)
        SceneManager.shared.register(config: DemoChatScene.self)
        #endif
    }

    @available(iOS 13.0, *)
    struct DemoScene: SceneConfig {
        static let key = "demo"
        static func icon() -> UIImage {
            UDIcon.getIconByKey(.callVideoFilled, iconColor: .white, size: CGSize(width: 24, height: 24))
        }
        static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
            let vc = DemoSceneViewController()
            return vc
        }
    }

    #if !canImport(LarkChat)
    @available(iOS 13.0, *)
    struct DemoChatScene: SceneConfig {
        static let key = "Chat"
        static func icon() -> UIImage {
            UDIcon.getIconByKey(.chatFilled, iconColor: .white, size: CGSize(width: 24, height: 24))
        }
        static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {
            let vc = DemoSceneViewController()
            vc.displayTitle = sceneInfo.title ?? "Demo Chat Scene"
            return vc
        }
    }
    #endif

    final class DemoSceneViewController: UIViewController {
        var displayTitle: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor.ud.bgBody
            let textLabel = UILabel()

            if let displayTitle {
                textLabel.text = displayTitle
            } else {
                let address = Unmanaged.passUnretained(self).toOpaque()
                textLabel.text = "Demo Scene \(address)"
            }
            textLabel.textColor = UIColor.ud.textTitle
            textLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            textLabel.textAlignment = .center
            textLabel.lineBreakMode = .byTruncatingMiddle
            view.addSubview(textLabel)
            textLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            }

            let activateBtn = UIButton(type: .system)
            activateBtn.setTitle("Activate VCScene", for: .normal)
            activateBtn.setTitleColor(UIColor.ud.blue, for: .normal)
            activateBtn.addTarget(self, action: #selector(activateVCScene), for: .touchUpInside)
            view.addSubview(activateBtn)
            activateBtn.snp.makeConstraints { make in
                make.center.equalToSuperview().offset(-8)
                make.width.equalTo(200)
                make.height.equalTo(44)
            }

            let closeBtn = UIButton(type: .system)
            closeBtn.setTitle("Close Scene", for: .normal)
            closeBtn.setTitleColor(UIColor.ud.red, for: .normal)
            closeBtn.addTarget(self, action: #selector(closeCurrentScene), for: .touchUpInside)
            view.addSubview(closeBtn)
            closeBtn.snp.makeConstraints { make in
                make.width.equalTo(200)
                make.height.equalTo(44)
                make.centerX.equalTo(activateBtn)
                make.top.equalTo(activateBtn.snp.bottom).offset(16)
            }
        }

        @objc private func activateVCScene() {
            VCScene.activateIfNeeded()
        }

        @objc private func closeCurrentScene() {
            if #available(iOS 13, *), let window = self.view.window, let ws = window.windowScene {
                VCScene.closeScene(ws)
            }
        }
    }
}

private final class MainTabbarControllerDependencyImpl: MainTabbarControllerDependency {
    var showTabbarFocusStatus: Driver<Bool> = .just(false)

    func userFocusStatusView() -> UIView? {
        return nil
    }
}

#if !canImport(LarkSearch) && canImport(LarkQuickLaunchInterface)
private final class OpenNavigationImpl: OpenNavigationProtocol {
    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo]) {}
}
#endif
