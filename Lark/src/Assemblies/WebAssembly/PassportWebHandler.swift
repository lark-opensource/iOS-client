// swiftlint:disable all
import Homeric
import LKCommonsTracker
import RxCocoa
import RxSwift
import Swinject
import EENavigator
import LKCommonsLogging
import LarkTab
import LarkOPInterface
import WebBrowser
import CookieManager
import LarkAccountInterface
import LarkFeatureGating
import SuiteAppConfig
import LarkCreateTeam
import LarkAccountAssembly

final class UnloginWebHandler: TypedRouterHandler<UnloginWebBody> {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    override func handle(_ body: UnloginWebBody, req: EENavigator.Request, res: Response) {
        /// some config default vaule follows the init func default vaule
        let config = WebBrowserConfiguration(
            customUserAgent: body.customUserAgent,
            //未改动逻辑
            shouldNonPersistent: !resolver.resolve(AppConfigService.self)!.feature(for: "sso").isOn,
            jsApiMethodScope: body.jsApiMethodScope,
            webBizType: body.webBizType,
            notUseUniteRoute: true //登录前webview不走统一路由拦截,请不要随意修改这个值. 可以联系passport
        )
        let controller = WebBrowser(url: body.url, configuration: config)
        registerPassportExtensionItems(browser: controller)
        try? controller.register(item: PassportAPIExtensionItem(resolver: resolver))
        let i = PassportAPIExtensionItem.buildAccountSecurityCenterAPIExtensionItem(resolver: resolver)
        try? controller.register(item: i)
        let it = PassportSingleExtensionItem(browser: controller, resolve: resolver)
        it.jsSDKBuilder = i.jsSDKBuilder
        try? controller.register(singleItem: it)
        res.end(resource: controller)
    }
}

final class SimpleWebHandler: TypedRouterHandler<SimpleWebBody> {
    override func handle(_ body: SimpleWebBody, req: EENavigator.Request, res: Response) {
        let unloginBody = UnloginWebBody(
            url: body.url,
            jsApiMethodScope: .none,
            showMore: body.showMore,
            showLoadingFirstLoad: body.showLoadingFirstLoad,
            customUserAgent: body.customUserAgent
        )
        res.redirect(body: unloginBody)
    }
}
// swiftlint:enable all
