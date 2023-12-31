//
//  MicroAppAssemblyHandler.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/5/28.
//

import Foundation
import Swinject
import EENavigator
import LarkNavigator
import EEMicroAppSDK
import RoundedHUD
import SuiteAppConfig
import LarkOPInterface
import LarkAppLinkSDK
import LKCommonsLogging
import ECOInfra

fileprivate func showAlert() {
    //  弹出alert
    let alertVC = UIAlertController(
        title: BundleI18n.LarkMicroApp.Lark_Legacy_MiniMode_AppForbid_Title,
        message: BundleI18n.LarkMicroApp.Lark_Legacy_MiniMode_AppForbid_Detail,
        preferredStyle: .alert
    )
    alertVC.addAction(
        UIAlertAction(
            title: BundleI18n.LarkMicroApp.Lark_Legacy_MiniMode_AppForbid_Button,
            style: .default,
            handler: nil
        )
    )
    let navigator = OPUserScope.userResolver().navigator
    if let fromVC = navigator.mainSceneWindow?.fromViewController {
        navigator.present(alertVC, from: fromVC)
    } else {
        MicroAppSchemaHandler.logger.error("EMAProtocolImpl chooseChat can not present vc because no fromViewController")
    }
}

class MicroAppSchemaHandler: UserRouterHandler {
    static let logger = Logger.oplog(MicroAppSchemaHandler.self,
                                   category: "MicroAppSchemaHandler")
    
    static func compatibleMode() -> Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func handle(req: Request, res: Response) throws {
        //  增加切面判断是否打开功能，不打开说明需要弹框
        if !AppConfigManager.shared.feature(for: "gadget").isOn {
            showAlert()
            res.end(error: nil)
            return
        }
        var url = req.url
        guard let scheme = url.scheme else {
            res.end(error: RouterError.resourceWithWrongFormat)
            return
        }

        if scheme != "sslocal" {
            // 对非 sslocal 的 url 进行转换
            guard let sslocalUrl = MicroAppRouteConfigManager.convertHttpToSSLocal(url) else {
                res.end(error: RouterError.resourceWithWrongFormat)
                return
            }
            url = sslocalUrl
            // web_url场景定义:1.https协议，2.非appLink，3.未命中其他场景值（指端内无法区分来源的拦截访问-参考：https://bytedance.feishu.cn/sheets/shtcnK6GyZ1zpV45eOorIq9BKeb）
            if scheme == "https", OPScene.build(context: req.context).sceneCode() == OPScene.undefined.sceneCode() {
                req.context[OPSceneKey.key] = OPScene.web_url.rawValue
            }
        }
        MiniProgramHandler.handelMiniProgramRequest(url: url, req: req, res: res)
    }
}

// copy from LarkOpenPlatform LarkInterface+MicroApp.swift
public struct MicroAppBody: CodablePlainBody {
    public static let pattern: String = "//client/microapp"

    public let appId: String

    public let path: String?
    
    // 来源为路径包含/client/app_share/open的applink
    public var isShareLink: Bool = false

    public init(appId: String, path: String? = nil) {
        self.appId = appId
        self.path = path
    }
}


class MicroAppBodyHandler: UserTypedRouterHandler {
    private static let KEY_PATH = "path"
    
    static func compatibleMode() -> Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func handle(_ body: MicroAppBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        //  增加切面判断是否打开功能，不打开说明需要弹框
        if !AppConfigManager.shared.feature(for: "gadget").isOn {
            showAlert()
            res.end(error: nil)
            return
        }
        let sslocalModel = SSLocalModel()
        sslocalModel.type = .open
        if body.appId.isEmpty {
            if let app_id = req.url.queryParameters["app_id"] {
                sslocalModel.app_id = app_id
            }
            if let path = req.url.queryParameters["path"] {
                sslocalModel.start_page = path
            }
        } else {
            sslocalModel.app_id = body.appId
            if let path = body.path {
                sslocalModel.start_page = path
            }
        }

        if let url = sslocalModel.generateURL() {
            var channel: StartChannel = .undefined
            if body.isShareLink {
                channel = .sharelink
            }
            MiniProgramHandler.handelMiniProgramRequest(url: url, req: req, res: res,channel:channel)
        } else {
            res.end(error: RouterError.resourceWithWrongFormat)
        }
    }
}
