//
//  GuideTipHandler.swift
//  LarkAppStateSDK
//
//  Created by  bytedance on 2020/9/25.
//

import Foundation
import RustPB
import LarkMessengerInterface
import EENavigator
import ECOProbe
import LKCommonsTracker
import LarkNavigation
import EEMicroAppSDK
import LarkOPInterface
import UniverseDesignDialog
import LarkContainer

/// 展示引导弹窗的handler
class GuideTipHandler {
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    /// 展示引导弹窗统一入口
    func presentAlert(
        appId: String,
        appName: String,
        tip: Openplatform_V1_GuideTips,
        webVC: UIViewController? = nil,
        callback: MicroAppLifeCycleBlockCallback? = nil,
        appType: AppType,
        closeAppBlock: (() -> Void)? = nil) {
        guard let model = getGuideTipModel(appId: appId, appName: appName, tipData: tip) else {
            AppStateSDK.logger.error("AppStateSDK:build guide tip alert data failed, showAlert failed")
            return
        }
        AppStateSDK.logger.info("AppStateSDK:will display New stateSDK alert")
        presentAlertWith(alertData: model, webVC: webVC, callback: callback, appType: appType, closeAppBlock: closeAppBlock)
    }

    /// 生成引导弹窗的数据
    private func getGuideTipModel(appId: String, appName: String, tipData: Openplatform_V1_GuideTips) -> GuideTipModel? {
        if !tipData.hasLocalContent {
            AppStateSDK.logger.error("guide tip's title/content invalid, showAlert failed")
            return nil
        }
        if tipData.buttons.isEmpty {
            AppStateSDK.logger.error("guide tip's buttons invalid")
            return nil
        }
        var buttons = [GuideTipButton]()
        for button in tipData.buttons {
            buttons.append(GuideTipButton(content: button.localContent, schema: button.schema, extras: [:]))
        }
        return GuideTipModel(appID: appId,
                             appName: appName,
                             title: tipData.localTitle,
                             msg: tipData.localContent,
                             buttons: buttons)
    }

    /// 展示弹窗：from「不可用应用引导优化」
    private func presentAlertWith(
        alertData: GuideTipModel,
        webVC: UIViewController? = nil,
        callback: MicroAppLifeCycleBlockCallback? = nil,
        appType: AppType,
        closeAppBlock: (() -> Void)? = nil) {
            let dialog = UDDialog()
            dialog.setTitle(text: alertData.title)
            dialog.setContent(text: alertData.msg)
            AppStateSDK.logger.info("AppStateSDK:alert button count:\(alertData.buttons.count)")
            if alertData.buttons.count == 1, let singleBtn = alertData.buttons.first {
                AppStateSDK.logger.info("AppStateSDK:alert button type:\(singleBtn.content)")
                dialog.addPrimaryButton(text: singleBtn.content,
                                 dismissCompletion: getButtonTapEvent(schema: singleBtn.schema,
                                                                                               appId: alertData.appID,
                                                                                               appName: alertData.appName,
                                                                                               webVC: webVC,
                                                                                               callback: callback,
                                                                                               appType: appType, closeAppBlock: closeAppBlock))
            if let fromVC = webVC ?? Navigator.shared.mainSceneTopMost {
                AppStateSDK.logger.info("AppStateSDK: presentAlertWith fromViewController class:\(type(of:fromVC)), exist alert:\(dialog)")
                fromVC.present(dialog, animated: true)
            } else {
                AppStateSDK.logger.error("AppStateSDK:presentAlertWith can not present vc because no fromViewController")
            }
        } else if alertData.buttons.count == 2,
            let leftBtn = alertData.buttons.first,
            let rightBtn = alertData.buttons.last {
            AppStateSDK.logger.info("AppStateSDK:alert left button type:\(leftBtn.content), right button type:\(rightBtn.content)")
            dialog.addSecondaryButton(text: leftBtn.content,
                                                dismissCompletion: getButtonTapEvent(schema: leftBtn.schema,
                                                                                     appId: alertData.appID,
                                                                                     appName: alertData.appName,
                                                                                     webVC: webVC,
                                                                                     callback: callback,
                                                                                     appType: appType, closeAppBlock: closeAppBlock))

            dialog.addPrimaryButton(text: rightBtn.content,
                                      dismissCompletion: getButtonTapEvent(schema: rightBtn.schema,
                                                                           appId: alertData.appID,
                                                                           appName: alertData.appName,
                                                                           webVC: webVC,
                                                                           callback: callback,
                                                                           appType: appType, closeAppBlock: closeAppBlock))
            if let fromVC = webVC ?? Navigator.shared.mainSceneTopMost {
                AppStateSDK.logger.info("AppStateSDK: presentAlertWith fromViewController class:\(type(of:fromVC)), exist alert:\(dialog)")
                fromVC.present(dialog, animated: true)
            } else {
                AppStateSDK.logger.error("AppStateSDK: presentAlertWith can not present vc because no fromViewController")
            }
        } else {
            AppStateSDK.logger.error("guide tip alert not support more than 2 buttons")
            return
        }
    }

    /// 弹窗交互逻辑
    private func getButtonTapEvent(
        schema: String,
        appId: String,
        appName: String,
        webVC: UIViewController? = nil,
        callback: MicroAppLifeCycleBlockCallback? = nil,
        appType: AppType,
        closeAppBlock: (() -> Void)? = nil) -> () -> Void {
        return {
            /// button包含的URL解析不成功，不响应事件
            guard let url = URL(string: schema) else {
                AppStateSDK.logger.error("guide tip's schema convert to url failed")
                return
            }
            /// 按照schema解析结果，执行相应事件
            let tipSchema = TipSchema(schema: url)
            self.alertBtnTapReport(schema: tipSchema)    // TEA事件上报
            self.closeApp(webVC: webVC, callback: callback, appType: appType, appID: appId, closeAppBlock: closeAppBlock) // 所有schema都关闭应用
            switch tipSchema.schemaType {
            case .unKonwn:  // 未知
                AppStateSDK.logger.error("guide tip button's schema parse unknown, close App")
            case .confirm, .cancel: // 确认/取消
                AppStateSDK.logger.info("guide tip button's schema is confirm/cancel, close App")
            case .contactAdmin: // 联系管理员
                AppStateSDK.logger.info("guide tip button contact admin")
                guard let adminId = tipSchema.getAdminId() else {
                    AppStateSDK.logger.error("get adminId from schema failed, exit contactAdmin")
                    return
                }
                let body = ChatControllerByChatterIdBody(
                    chatterId: adminId,
                    isCrypto: false
                )
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                    self.resolver.navigator.push(body: body, from: fromVC)
                } else {
                    AppStateSDK.logger.error("AppState SDK getButtonTapEvent can not push vc because no fromViewController")
                }
            case .applyAccess: // 申请可见性
                AppStateSDK.logger.info("guide tip to apply for access")
                let body = ApplyForUseBody(
                    appId: appId,
                    appName: appName
                )
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                    self.resolver.navigator.push(body: body, from: fromVC)
                } else {
                    AppStateSDK.logger.error("AppState SDK getButtonTapEvent can not push vc because no fromViewController")
                }
            case .install:  // 安装应用
                AppStateSDK.logger.info("guide tip to install for app")
                guard let installUrl = tipSchema.getInstallUrl(), let url = installUrl.possibleURL() else {
                    AppStateSDK.logger.error("get installUrl from schema failed, exit install app")
                    return
                }
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                    self.resolver.navigator.push(url, from: fromVC)
                } else {
                    AppStateSDK.logger.error("AppState SDK getButtonTapEvent can not push url because no fromViewController")
                }
            }
        }
    }

    /// 关闭应用
    private func closeApp(
        webVC: UIViewController? = nil,
        callback: MicroAppLifeCycleBlockCallback? = nil,
        appType: AppType,
        appID: String,
        closeAppBlock: (() -> Void)? = nil) {
        switch appType {
        case .microApp:
            AppStateSDK.logger.info("guide tip alert: close microApp")
            if callback != nil {
                AppStateSDK.logger.info("guide tip alert: close microApp with cancelLoading")
                callback?.cancelLoading()
            }
            guard let microAppService = try? resolver.resolve(assert: MicroAppService.self) else {
                AppStateSDK.logger.error("MicroAppService impl is nil")
                return
            }
            microAppService.closeMicroAppWith(appID: appID)
        case .bot:
            // bot 无容器，不需要close行为
            AppStateSDK.logger.info("guide tip alert: close bot", additionalData: ["appId": "\(appID)"])
        case .webApp:
            closeAppBlock?()
        @unknown default: break
        }
    }

    /// 业务事件上报：用户在引导弹窗上的点击事件
    private func alertBtnTapReport(schema: TipSchema) {
        /// Tea事件上报
        let teaEventName: String = "op_launch_failpage_click"
        /// 参数Key
        let paramKey: String = "action_type"
        switch schema.schemaType {
        case .unKonwn:  // 未知
            AppStateSDK.logger.error("guide tip button's schema parse unknown, not report TEA")
        case .confirm:  // 确认
            Tracker.post(TeaEvent(teaEventName, params: [paramKey: "confirm"]))
        case .cancel: // 取消
            Tracker.post(TeaEvent(teaEventName, params: [paramKey: "cancel"]))
        case .contactAdmin: // 联系管理员
            Tracker.post(TeaEvent(teaEventName, params: [paramKey: "contact_admin"]))
        case .applyAccess: // 申请可见性
            Tracker.post(TeaEvent(teaEventName, params: [paramKey: "request_accessible"]))
        case .install:  // 安装应用
            Tracker.post(TeaEvent(teaEventName, params: [paramKey: "install"]))
        }
    }
}

extension String {
    func possibleURL() -> URL? {
        if let url = URL(string: self) {
            return url
        }
        if let urlEncode = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: urlEncode)
        }
        return nil
    }
}
