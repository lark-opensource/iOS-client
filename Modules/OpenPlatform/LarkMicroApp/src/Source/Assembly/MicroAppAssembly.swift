//
//  MicroAppAssembly.swift
//  Pods
//
//  Created by 殷源 on 2018/10/12.
//

import BootManager
import EEMicroAppSDK
import EENavigator
import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkAppLinkSDK
import LarkDebugExtensionPoint
import LarkRustClient
import LarkUIKit
import RxSwift
import Swinject
import TTMicroApp
import EEMicroAppSDK
import LarkModel
import LarkAssembler
import LarkContainer
import ECOInfra

public protocol MicroAppSendDocModel {
    var url: String { get }
    var title: String { get }
}
public typealias MicroAppSendDocBlock = (Bool, [MicroAppSendDocModel]) -> Void

public protocol MicroAppDependency: AnyObject {
    func shareAppPageCard(
        appId: String,
        title: String,
        iconToken: String?,
        url: String,
        appLinkHref: String?,
        options: ShareOptions,
        fromViewController: UIViewController,
        callback: @escaping (([String: Any]?, Bool) -> Void)
    )

    func presendSendDocBody(maxSelect: Int,
                            title: String?,
                            confirmText: String?,
                            sendDocBlock: @escaping MicroAppSendDocBlock,
                            wrap: UINavigationController.Type?,
                            from: NavigatorFrom,
                            prepare: ((UIViewController) -> Void)?,
                            animated: Bool)
    // from为nil, 则不push打开
    func openAppLinkWithWebApp(url: URL, from: NavigatorFrom?) -> URL?
}

public protocol GadgetObservableManagerProxy {
    func addObservableWhenAssemble()

    func addObservableAfterAccountLoaded()
}

public final class MicroAppAssembly: LarkAssemblyInterface {
    static let logger = Logger.log(MicroAppAssembly.self, category: "MicroAppAssembly")
    static let KEY_CAN_OPEN_IN_MICRO_APP = "_canOpenInMicroApp"
    //  小程序引擎胶水层所有push相关的管理请全部放入GadgetPush类
    public static var gadgetOB: GadgetObservableManagerProxy?
    public init() {}

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        
        userContainer.register(AppBadgeAPI.self) { (r) -> AppBadgeAPI in
            let rustService = try r.resolve(assert: RustService.self)
            return AppBadgeAPIImpl(client: rustService)
        }
        
        container.register(MetaLoadStatusListener.self) { _  in
            return MetaLoadStatusManager.shared
        }.inObjectScope(.container)
        
        // 目前部分 API 下沉到 rust, rust 中需要有对应生命周期监听, 使用了以下类实现
        container.register(BDPTimorStateListener.self) { _  in
            return BDPTimorStateListenerImpl()
        }.inObjectScope(.container)
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(GadgetSetupTask.self)
    }
    
    // 只有小程序用到的push在这里注册
    public func registRustPushHandlerInUserSpace(container: Container) {
        // 开发者工具通用push
        (Command.gadgetDevToolCommonPush, DevToolPushHandler.init(resolver:))
        // 产品化止血push
        (Command.pushOpenAppContainerCommand, OpenAppContainerPushHandler.init(resolver:))
    }


    public func registRouter(container: Container) {
        //  处理: sslocal://microapp
        //  面向内部，参数不受限制
        Navigator.shared.registerRoute.regex("^sslocal\\://microapp\\?").tester({ (req) -> Bool in
            req.context[MicroAppAssembly.KEY_CAN_OPEN_IN_MICRO_APP] = true
            return true
        }).factory(MicroAppSchemaHandler.init(resolver:))

        //  处理: 任意类型的URL（在白名单规则内的）
        //  面向内部，app_id 由白名单规则 host + path 规则映射，miniPath为空时跳转首页
        Navigator.shared.registerRoute.match({(url) -> Bool in
            return MicroAppRouteConfigManager.isMatchConfig(url: url)
        })
        .priority(.high)   // 如果命中，应当是高优作为小程序处理
        .tester({ (req) -> Bool in
            // judge context
            if let from = req.context["isFromWebviewComponent"] as? Bool, from == true {
                return false
            }
            req.context[MicroAppAssembly.KEY_CAN_OPEN_IN_MICRO_APP] = true
            return true
        })
        .factory(MicroAppSchemaHandler.init(resolver:))

        //  处理: lark://client/microapp 或者 MicroAppBody
        //  面向外部应用，只接受 app_id 和 path 两个参数
        Navigator.shared.registerRoute.type(MicroAppBody.self).tester({ (req) -> Bool in
            req.context[MicroAppAssembly.KEY_CAN_OPEN_IN_MICRO_APP] = true
            return true
        }).factory(MicroAppBodyHandler.init(resolver:))
        

        //  处理: sslocal://microapp/mpdt/log
        //  小程序日志调试开关
        Navigator.shared.registerRoute.regex("^sslocal\\://microapp/mpdt/log\\?").priority(.high).factory(MicroAppMpdtLogHandler.init(resolver:))
    }
    
    public func registURLInterceptor(container: Container) {
        (MicroAppBody.pattern, { (url, from) in
            OPUserScope.userResolver().navigator.present(url, context: [:], wrap: nil, from: from, prepare: { $0.modalPresentationStyle = .fullScreen }, animated: true, completion: nil)
        })
        
        ("^sslocal\\://microapp\\?", { (url: URL, from: NavigatorFrom) in
            let params = url.queryParameters
            let seqID = params["seqID"]
            // 消badge的接口需要seqID和feedID，但是接口方已定义feedID的key为appID
            let context: [String: Any] = ["from": "feed",
                                          "feedInfo": ["appID": params["feedID"],
                                                       "seqID": seqID]]
            MicroAppAssembly.logger.info("seqID = \(seqID ?? "nil")")
            if Display.pad {
                OPUserScope.userResolver().navigator.showDetail(url,
                                                                        context: context,
                                                                        wrap: LkNavigationController.self,
                                                                        from: from, completion: nil)
            } else {
                OPUserScope.userResolver().navigator.push(url,
                                                                  context: context,
                                                                  from: from,
                                                                  animated: true,
                                                                  completion: nil)
            }
        })
    }
}
