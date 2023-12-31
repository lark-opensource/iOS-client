//
//  WPRequestInjectMiddleware.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/29.
//

import Foundation
import ECOInfra
import LarkOPInterface
import LKCommonsLogging
import LarkAccountInterface

struct WPRequestInjectMiddleware: ECONetworkMiddleware {
    static let logger = Logger.log(WPRequestInjectMiddleware.self)

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        var request = request
        guard let context = task.context as? WPNetworkContext else {
            WPRequestInjectMiddleware.logger.error("processRequest fail, context type error")
            return .failure(OPError.contextTypeError(detail: "contextType = \(task.context.self)"))
        }
        let userService = context.userResolver?.resolve(PassportUserService.self)
        let userSession = userService?.user.sessionKey

        Self.logger.info("start process inject request info", additionalData: [
            "userSessionLength": "\(userSession?.count ?? 0)",
            "request.domain": request.domain ?? "",
            "request.path": request.path,
            "request.headerKeys": "\(request.headerFields.keys)",
            "request.bodyKeys": "\(request.bodyFields.keys)"
        ])

        if let customDomain = context.injectInfo.customDomain {
            request.domain = customDomain
        }
        if let path = context.injectInfo.path {
            request.path = path
        }
        if let port = context.injectInfo.port {
            request.port = port
        }
        if let headerAuthType = context.injectInfo.headerAuthType,
           let userSession = userSession {
            switch headerAuthType {
            case .cookie:
                request.setHeaderField(key: "Cookie", value: "session=\(userSession)")
            case .session:
                request.setHeaderField(key: "session", value: userSession)
            }
        }
        if let passportService = context.userResolver?.resolve(PassportService.self) {
            let deviceId = passportService.deviceID
            request.setHeaderField(key: "Device-Id", value: deviceId)
        }
        let configService = context.userResolver?.resolve(WPConfigService.self)
        if !(configService?.fgValue(for: .enableLarkUa) ?? false) {
            /// fg 关，使用业务生成的 UA
            Self.logger.info("use workplace ua")
            let modelName = UIDevice.current.lu.modelName()
            let uiDevice = UIDevice.current
            let systemName = uiDevice.systemName
            let systemVersion = uiDevice.systemVersion
            let appVersion = WPUtils.appVersion
            request.setHeaderField(key: "User-Agent", value: "Feishu/\(appVersion) (\(systemName) \(systemVersion); \(modelName))")
        }
        request.mergingHeaderFields(with: context.injectInfo.bizHeaders)
        return .success(request)
    }
}
