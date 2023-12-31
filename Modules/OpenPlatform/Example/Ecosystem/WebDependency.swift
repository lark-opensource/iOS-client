import BootManager
import EcosystemWeb
import EEMicroAppSDK
import LarkAssembler
import LarkWebViewContainer
import OPSDK
import TTMicroApp
import RunloopTools
import Swinject
import WebBrowser

final class WebAssemblyV2: LarkAssemblyInterface {
    func registContainer(container: Swinject.Container) {
        container.register(LarkWebViewProtocol.self) { _ in
            WebAndAPIDependencyImpl()
        }.inObjectScope(.user)
        container.register(WebBrowserDependencyProtocol.self) { _ in
            WebAndAPIDependencyImpl()
        }.inObjectScope(.user)
        container.register(EcosyetemWebDependencyProtocol.self) { _ in
            WebAndAPIDependencyImpl()
        }.inObjectScope(.user)
        container.register(LarkWebViewQualityServiceProtocol.self) { _ in
            QualityService()
        }
        container.register(LarkWebViewMonitorServiceProtocol.self) { _ in
            LarkWebViewMonitorServiceWrapper()
        }
        container.register(WebAppMonitorProtocol.self) { _ in
            WebAppMonitorReporter.shared
        }
    }

    func registLaunch(container: Swinject.Container) {
        NewBootManager.register(WebBeforeLoginTask.self)
    }
}

class WebBeforeLoginTask: FlowBootTask, Identifiable {
    
    static var identify = "WebBeforeLoginTask"

    override var delayScope: Scope? { return .container }

    override var scope: Set<BizScope> { return [.specialLaunch] }
    
    override func execute(_ context: BootContext) {
        if LarkWebViewMonitorServiceWrapper.enableMonitor {
            LarkWebViewMonitorServiceWrapper.startMonitor()
        }
        if LarkWebViewMonitorServiceWrapper.enableReporter {
            LarkWebViewMonitorServiceWrapper.registerReportReceiver(receiver: WebAppMonitorReporter.shared)
        }
    }
}

class WebAndAPIDependencyImpl: WebBrowserDependencyProtocol, EcosyetemWebDependencyProtocol, LarkWebViewProtocol {
    func errorpageHTML() -> String? {
        if let p = OPBundle.timor.path(forResource: "errorpage", ofType: "html") {
            let url = URL(fileURLWithPath: p)
            let html = try? String(contentsOf: url, encoding: .utf8)
            return html
        }
        return nil
    }
    func offlineEnable() -> Bool { OPSDKFeatureGating.isWebappOfflineEnable() }
    func ajaxFetchHookString() -> String? { EMAAppEngine.current()?.componentResourceManager?.fetchAjaxHookJS() }
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? { nil }
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo? { nil }
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool { false }
    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol? { nil }
    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol? { nil }
    func registerBusinessExtensions(browser: WebBrowser) {}
    func setupAjaxFetchHook(webView: LarkWebView) {}
    func generateWebAppLink(targetUrl: String, appId: String) -> URL? { nil }
    func webDetectPageHTML() -> String? { return nil }
    func launchMyAI(browser: WebBrowser) {}
    func generateCustomPathWebAppLink(targetUrl: String, appId: String) -> URL? { return nil }
    func shareH5(webVC: WebBrowser) {}
    func isOfflineMode(browser: WebBrowser) -> Bool { return true }
    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {}
}
