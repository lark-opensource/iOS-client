//
//  IndustryOnboardingTask.swift
//  LarkContact
//
//  Created by Yuri on 2023/6/25.
//

import Foundation
import BootManager
import EENavigator
import RxSwift
import ServerPB
import LarkContainer
import LarkMessengerInterface
import LarkAccountInterface
import LarkAccount
import WebBrowser
import LarkSetting
import LarkFeatureGating
import LarkNavigation
import UniverseDesignTheme

class IndustryOnboardingContext {
    static let shared = IndustryOnboardingContext()

    var applink: String?
}

final class IndustryOnboardingTask: UserAsyncBootTask, Identifiable {
    static var identify = "IndustryOnboardingTask"
    typealias Module = ContactLogger.Module
    let logger = ContactLogger.shared

    enum OnboardingError: Error {
        case notMatch
        case noMaterial
        case urlError(String)
        case noWindow
    }
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var passportService: PassportUserService?
    @ScopedInjectedLazy private var materialsApi: GetSceneMaterialsAPI?
    @Provider private var deviceService: LarkAccountInterface.DeviceService

    override var runOnlyOnceInUserScope: Bool { return false }

    var notificationToken: NSObjectProtocol?

    private var webFactory: WebControllerFactory = {
        return WebControllerFactory()
    }()

    deinit {
        ContactLogger.shared.info(module: ContactLogger.Module.onboarding, event: "\(self) deinit")
        if let token = self.notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    override func execute(_ context: BootContext) {
        checkOnboarding(isSessionFirstActive: context.isSessionFirstActive)
            .flatMap { [weak self] _ in self?.pullOnboardingUrl() ?? .never() }
            .flatMap { [weak self] in self?.fullUrl(urlString: $0) ?? .never() }
            .flatMap { [weak self] in
                let ob = self?.openWeb(urlString: $0) ?? .never()
                return ob.subscribeOn(MainScheduler.instance)
            }
            .subscribe { [weak self] _ in
                self?.end()
            } onError: { [weak self] error in
                DispatchQueue.main.async {
                    // 有AppLink就需要打开小程序, 哪怕打开H5流程失败
                    self?.logger.error(module: Module.onboarding, event: "industry - task error: ", parameters: "\(error)")
                    self?.end()
                }
            }.disposed(by: disposeBag)
    }

    private func checkOnboarding(isSessionFirstActive: Bool) -> Observable<Bool> {
        let isCreator = passportService?.user.isTenantCreator ?? false
        ContactLogger.shared.info(module: Module.onboarding, event: "industry - passport", parameters: "active: \(isSessionFirstActive), creator: \(isCreator)")
        if isCreator && isSessionFirstActive {
            return .just(true)
        } else {
            return .error(OnboardingError.notMatch)
        }
    }

    private func pullOnboardingUrl() -> Observable<String> {
        let scene = OnboardingSceneType.authorizationPage
        let ob = materialsApi?.getMaterialsBySceneRequest(scenes: [scene]) ?? .error(OnboardingError.noMaterial)
        return ob
            .do(onNext: { _ in
                ContactLogger.shared.info(module: Module.onboarding, event: "industry - get materials success")
            }, onError: {
                ContactLogger.shared.error(module: Module.onboarding, event: "industry - get materials error: ", parameters: $0.localizedDescription)
            })
            .map { (result: ServerPB_Retention_GetMaterialsBySceneResponse) -> String in
                let res = result.scenes[scene.rawValue]
                if res?.result == false { return "" } // 服务端返回false,直接不处理后续流程
                let material = res?.materials.first
                let extra = res?.extra ?? ""
                let link = material?.entity.weblink.link ?? ""
                var applink: String?
                if let jsonData = extra.data(using: .utf8) {
                    let json = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: String]
                    applink = json?["onboardingApplinkPC"] as? String
                }
                if applink == nil {
                    ContactLogger.shared.error(module: Module.onboarding, event: "industry - fetch applink failed: ", parameters: res?.extra)
                }
                IndustryOnboardingContext.shared.applink = applink
                return link
            }
    }

    private func fullUrl(urlString: String) -> Observable<String> {
        return Observable.create { [weak self] ob in
            if urlString.isEmpty {
                ob.onError(OnboardingError.urlError(urlString))
                return Disposables.create()
            }
            var link = urlString
            if let deviceId = self?.deviceService.deviceId, !deviceId.isEmpty {
                link += "&device_id=\(deviceId)"
            }
            let darkMode: String = {
                if #available(iOS 13.0, *) {
                    return UDThemeManager.getRealUserInterfaceStyle() == .dark ? "true" : "false"
                } else {
                    return "false"
                }
            }()
            link += "&is_dark_mode=\(darkMode)"
            ob.onNext(link)
            ob.onCompleted()
            return Disposables.create()
        }
    }

    private func openWeb(urlString: String) -> Observable<Void> {
        ContactLogger.shared.info(module: Module.onboarding, event: "industry - open web: ", parameters: urlString)
        return Observable.create { [weak self] ob in
            guard let self = self else { return Disposables.create() }
            guard let url = URL(string: urlString) else {
                ob.onError(OnboardingError.urlError(urlString))
                return Disposables.create()
            }
            self.notificationToken = NotificationCenter.default.addObserver(forName: Notification.Name(self.notificationKey), object: nil, queue: .main) { _ in
                ob.onNext(())
                ob.onCompleted()
            }
            if let window = Navigator.shared.mainSceneWindow {
                let webBrower = self.webFactory.load(url: url) {
                    switch $0 {
                    case .failure(let err):
                        ob.onError(err)
                    default: break // 成功链路等待通知回调
                    }
                }
                webBrower.modalPresentationStyle = .fullScreen
                Navigator.shared.present(webBrower, from: window, animated: false)
            } else {
                self.logger.error(module: Module.onboarding, event: "industry - open web without window")
                ob.onError(OnboardingError.noWindow)
            }
            return Disposables.create()
        }
    }

    let notificationKey = "ug.onboarding.industry.finish"
}
