//
//  NoPermissionAssembly.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/5/6.
//

import Foundation
import Swinject
import LarkAssembler
import LarkAccountInterface
import LarkContainer
import EENavigator
import LarkNavigator
import RustPB
import LarkSecurityComplianceInfra
import LarkRustClient
import LarkAppLinkSDK
import LarkUIKit
import SwiftyJSON
import LarkSetting
import LarkSceneManager
import SnapKit

final class NoPermissionAssembly: LarkAssemblyInterface {

    init() { }

    func registContainer(container: Container) {
        // 设备管理服务层
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(NoPermissionServiceImp.self) { resolver in
            NoPermissionServiceImp(resolver: resolver)
        }

        userContainer.register(NoPermissionService.self) { (r) in
            try r.resolve(assert: NoPermissionServiceImp.self)
        }

        container.register(SecurityComplianceDependency.self) { (r) in
            try r.resolve(assert: NoPermissionServiceImp.self)
        }
    }

    func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(NoPermissionAuthBody.self)
            .factory(NoPermissionAuthPageHandler.init(resolver:))
    }

    func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: NoPermissionAuthBody.pattern) { applink in
            let params = applink.url.queryParameters
            let scheme = params["scheme"] ?? ""
            let userId = params["uid"] ?? ""
            let webId = params["webdid"] ?? ""
            let body = NoPermissionAuthBody(webId: webId, scheme: scheme, userId: userId)
            if let from = applink.context?.from() {
                Navigator.shared.present(body: body, from: from) // Global
                Logger.info("goto auth page: \(params)")
            } else {
                Logger.error("show auth page failed")
            }
        }

        LarkAppLinkSDK.registerHandler(path: DeviceEntranceBody.pattern) { applink in
            guard let from = applink.context?.from() else {
                Logger.error("show visit limited device manager page failed with from null")
                return
            }
            // 临时改动，后续适配
            let resolver = container.getCurrentUserResolver()
            guard let viewModel = try? DeviceStatusViewModel(resolver: resolver, isLimited: false) else { return }
            let controller = DeviceStatusViewController(viewModel: viewModel)
            Navigator.shared.push(controller, from: from) // Global
        }
    }

    func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushReqRegulate, NoPermissionRustPushHandler.init(resolver:)) // Global
    }
}

/// H5 授权页设置
final class NoPermissionAuthPageHandler: UserTypedRouterHandler {

    typealias B = NoPermissionAuthBody

    static func compatibleMode() -> Bool { SCContainerSettings.userScopeCompatibleMode }

    @ScopedProvider private var userService: PassportUserService? // Global

    func handle(_ body: NoPermissionAuthBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        if userService?.user.userID != body.userId {
            Alerts.showAlert(from: req.from.fromViewController,
                             title: I18N.Lark_Conditions_TipsNotice(),
                             content: I18N.Lark_Conditions_HaveToStay,
                             actions: [Alerts.AlertAction(title: I18N.Lark_Conditions_GotIt(),
                                                          style: .default,
                                                          handler: nil)])
        } else {
            // 临时改动，后续适配
            let viewModel = try NoPermissionAuthViewModel(resolver: userResolver, scheme: body.scheme, webId: body.webId, userId: body.userId)
            let controller = NoPermissionAuthViewController(viewModel: viewModel)
            let nc = LkNavigationController(rootViewController: controller)
            if Display.phone {
                nc.modalPresentationStyle = .fullScreen
            }
            res.end(resource: nc)
        }
    }
}
