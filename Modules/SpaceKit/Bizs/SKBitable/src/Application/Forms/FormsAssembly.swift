import EENavigator
import Foundation
import LarkAssembler
import LarkContainer
import LarkNavigator
import LarkSetting
import LKCommonsLogging
import SKFoundation
import Swinject

final public class FormsAssembly: LarkAssemblyInterface {
    
    static let logger = Logger.formsSDKLog(FormsAssembly.self, category: "FormsAssembly")
    
    public init() {
        Self.logger.info("FormsAssembly init")
    }
    
    deinit {
        Self.logger.info("FormsAssembly deinit")
    }
    
    public func registContainer(container: Container) {
        
        container
            .inObjectScope(.userV2)
            .register(
                FormsBrowserManager.self
            ) { userResolver in
                FormsBrowserManager(userResolver: userResolver)
            }
        
    }
    
    public func registRouter(container: Swinject.Container) {
        
        Navigator
            .shared
            .registerRoute_(
                match: { url in
                    FormsConfiguration.checkHostFormsValid(url: url)
                    && FormsConfiguration.checkPathFormsValid(url: url)
                },
                priority: .default
            ) { req in
                if req.context["__handleInHalfOrPanelBrowserReq__"] as? Bool == true {
                    // 部分场景下（比如群接龙场景下的半屏/面板容器）其他地方会请求不走独立容器，这个时候我们批准这个申请
                    req.context["__handleInHalfOrPanelBrowserRes__"] = true
                    Self.logger.info("load in half panel browser, not handle it")
                    return false
                } else {
                    return true
                }
            } _: { req, res in
                Self.logger.info("recieve forms router callback and res.redirect FormsBody, url:\(req.url)")
                res.redirect(
                    body: FormsBody(
                        url: req.url
                    ),
                    context: req.context
                )
            }
        
        Navigator
            .shared
            .registerRoute
            .type(
                FormsBody.self
            )
            .factory(
                FormsRouterHandler.init(resolver:)
            )
        
    }
    
}
