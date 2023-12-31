//
//  FileAppealAssembly.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/18.
//

import Foundation
import Swinject
import LarkAssembler
import EENavigator
import LarkAppLinkSDK
import LarkSetting
import LarkSecurityComplianceInfra
import SwiftyJSON
import LarkNavigator

final class FileAppealAssembly: LarkAssemblyInterface {

    func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(FileAppealPageBody.self)
            .factory(FileAppealPageHandler.init(resolver:))

    }

    func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: FileAppealPageBody.pattern) { applink in
            guard let from = applink.context?.from() else {
                Logger.error("show file appeal page failed with from null")
                return
            }
            let jsonParams = JSON(applink.url.queryParameters)
            let objToken = jsonParams["obj_token"].stringValue
            let version = jsonParams["version"].intValue
            let fileType = jsonParams["file_type"].intValue
            let locale = jsonParams["locale"].stringValue
            Logger.info("objToken: \(objToken) version: \(version) file_type: \(fileType) locale: \(locale)")
            let body = FileAppealPageBody(objToken: objToken, version: version, fileType: fileType, locale: locale)
            Navigator.shared.push(body: body, from: from) // Global
        }
    }
}

/// H5 授权页设置
final class FileAppealPageHandler: UserTypedRouterHandler {

    typealias B = FileAppealPageBody

    static func compatibleMode() -> Bool { SCContainerSettings.userScopeCompatibleMode }

    func handle(_ body: FileAppealPageBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let pathSuffx = "/document-security-inspection/appeal"
        let schema = "https://"
        guard let domain = DomainSettingManager.shared.currentSetting[.securityWeb]?.first else {
            Logger.error("Invalid domain key: securityWeb; Register file appeal router failed")
            return
        }
        guard var url = URL(string: schema + domain + pathSuffx) else {
            Logger.error("file appeal URL initializing failed")
            return
        }
        var parameters = [String: String]()
        parameters.updateValue(body.objToken, forKey: "obj_token")
        parameters.updateValue(String(body.version), forKey: "version")
        parameters.updateValue(String(body.fileType), forKey: "file_type")
        parameters.updateValue(body.locale, forKey: "locale")
        url = url.append(parameters: parameters, forceNew: false)
        Logger.info("file appeal url: \(url)")
        navigator.push(url, from: req.from)
    }
}
