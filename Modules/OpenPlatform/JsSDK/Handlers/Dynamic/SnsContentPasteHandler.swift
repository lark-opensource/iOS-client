//
//  SnsContentPasteHandler.swift
//  JsSDK
//
//  Created by shizhengyu on 2020/3/15.
//

import WebBrowser
import LKCommonsLogging
import EENavigator
import LarkSnsShare
import LarkUIKit
import EEMicroAppSDK
import UniverseDesignToast

class SnsContentPasteHandler: JsAPIHandler {

    private enum ErrorCode: Int {
        case snsTypeInvalid = 101
        case notInstalled = 102
        case canceledByUser = 103
        case sdkWakeupFailed = 104
    }

    private static let logger = Logger.log(SnsContentPasteHandler.self, category: "jssdk.SnsContentPasteHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let onSuccess = args["onSuccess"] as? String
        let onFailed = args["onFailed"] as? String

        guard let copyContent = args["copyContent"] as? String,
            let title = args["title"] as? String,
            let displayContent = args["displayContent"] as? String,
            let ctaButtonTitle = args["ctaBtnText"] as? String,
            let ctaButtonTitleColorHex = args["ctaBtnTextColor"] as? String,
            let ctaButtonBackgroundColorHex = args["ctaBtnBgColor"] as? String,
            let ctaButtonHightlightColorHex = args["ctaBtnBgColorPressed"] as? String,
            let skipButtonTitle = args["skipBtnText"] as? String,
            let snsTypeToWake = args["snsTypeToWake"] as? Int else {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                SnsContentPasteHandler.logger.error("NewJsSDKErrorAPI.missingRequiredArgs, current args >>> \(args)")
                if onFailed != nil {
                    callbackWith(api: api, funcName: onFailed!, arguments: arguments)
                }
                return
        }
        guard let ctaButtonTitleColor = UIColor(hexString: ctaButtonTitleColorHex),
            let ctaButtonBackgroundColor = UIColor(hexString: ctaButtonBackgroundColorHex),
            let ctaButtonHightlightColor = UIColor(hexString: ctaButtonHightlightColorHex) else {
                let arguments = [NewJsSDKErrorAPI.wrongDataFormat.description()] as [[String: Any]]
                SnsContentPasteHandler.logger.error("NewJsSDKErrorAPI.wrongDataFormat, current args >>> \(args)")
                if onFailed != nil {
                    callbackWith(api: api, funcName: onFailed!, arguments: arguments)
                }
                return
        }

        let snsTypeInvalidHandler = {
            SnsContentPasteHandler.logger.error("snsType send by biz is invalid >>> \(snsTypeToWake)")
            if onSuccess != nil {
                let arguments: [[String: Any]] = [["isSuccess": false,
                                                   "snsType": snsTypeToWake,
                                                   "errorCode": ErrorCode.snsTypeInvalid.rawValue,
                                                   "errorMsg": "snsType send by biz is invalid"]]
                self.callbackWith(api: api, funcName: onSuccess!, arguments: arguments)
            }
        }

        let jsSnsType = LarkShareItemType.transform(rawVaule: snsTypeToWake)
        var snsType: SnsType?
        switch jsSnsType {
        case .wechat, .timeline: snsType = .wechat
        case .qq: snsType = .qq
        default: break
        }
        guard let pasteSnsType = snsType else {
            snsTypeInvalidHandler()
            return
        }
        guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController, currentVC.navigationController != nil else {
            SnsContentPasteHandler.logger.error("SnsContentPasteHandler failed, no baseVc")
            return
        }
        
        guard LarkShareBasePresenter.shared.checkShareSDKAuthority(snsType: pasteSnsType) == true else {
            Self.logger.info("have not share auth")
            var toast: String =  LarkShareBasePresenter.shared.getShareSdkDenyTipText(snsType: pasteSnsType) 
            UDToast.showFailure(with: toast, on: currentVC.view)
            return
        }

        let panelConfig = PanelConfig(
            copyContent: copyContent,
            title: title,
            displayContent: displayContent,
            ctaButtonIcon: UIImage(),
            ctaButtonTitle: ctaButtonTitle,
            ctaButtonTitleColor: ctaButtonTitleColor,
            ctaButtonBackgroundColor: ctaButtonBackgroundColor,
            ctaButtonHightlightColor: ctaButtonHightlightColor,
            skipButtonTitle: skipButtonTitle,
            ctaButtonDidClick: { (controller) in
                self.handleCTAButtonDidClick(onSuccess: onSuccess, api: api, snsType: pasteSnsType, controller: controller)
            }, skipButtonDidClick: { (controller) in
                self.handleSkipButtonDidClick(onSuccess: onSuccess, api: api, snsType: pasteSnsType, controller: controller)
            })
        Self.logger.info("open share panel")
        let panelController = SnsOperationTipPanel(panelConfig: panelConfig)
        currentVC.present(panelController, animated: false)
    }
}

private extension SnsContentPasteHandler {
    func handleCTAButtonDidClick(onSuccess: String?,
                                 api: WebBrowser,
                                 snsType: SnsType,
                                 controller: SnsOperationTipPanel) {
        func callBack(_ result: SnsWakeUpResult) {
            if let successCall = onSuccess {
                var arguments: [[String: Any]] = [[:]]
                if result.0 {
                    SnsContentPasteHandler.logger.info("wake sns type = \(snsType.rawValue) success")
                    arguments = [["isSuccess": true,
                                  "snsType": snsType.rawValue]]
                } else {
                    SnsContentPasteHandler.logger.info("wake sns type = \(snsType.rawValue) fail")
                    guard let error = result.1 else { return }
                    switch error {
                    case .notInstalled:
                        arguments = [["isSuccess": false,
                                      "snsType": snsType.rawValue,
                                      "errorCode": ErrorCode.notInstalled.rawValue,
                                      "errorMsg": "application is not installed"]]
                        SnsContentPasteHandler.logger.info("ErrorCode.notInstalled, application is not installed")
                    case .sdkWakeupFailed:
                        arguments = [["isSuccess": false,
                                      "snsType": snsType.rawValue,
                                      "errorCode": ErrorCode.sdkWakeupFailed.rawValue,
                                      "errorMsg": "share sdk wake up fail"]]
                        SnsContentPasteHandler.logger.error("ErrorCode.sdkWakeupFailed, share sdk wake up fail")
                    case .notSupported:
                        arguments = [["isSuccess": false,
                                      "snsType": snsType.rawValue,
                                      "errorCode": ErrorCode.snsTypeInvalid.rawValue,
                                      "errorMsg": "snsType send by biz is invalid"]]
                        SnsContentPasteHandler.logger.error("ErrorCode.snsTypeInvalid, snsType send by biz is invalid")
                    }
                }
                callbackWith(api: api, funcName: successCall, arguments: arguments)
            }
        }

        switch snsType {
        case .wechat:
            callBack(LarkShareBasePresenter.shared.wakeup(snsType: .wechat))
        case .qq:
            callBack(LarkShareBasePresenter.shared.wakeup(snsType: .qq))
        default: break
        }

        controller.dismiss()
    }

    func handleSkipButtonDidClick(onSuccess: String?,
                                  api: WebBrowser,
                                  snsType: SnsType,
                                  controller: SnsOperationTipPanel) {
        guard let successCall = onSuccess else { return }

        let arguments: [[String: Any]] = [["isSuccess": false,
                                           "snsType": snsType.rawValue,
                                           "errorCode": ErrorCode.canceledByUser.rawValue,
                                           "errorMsg": "canceled by user"]]
        callbackWith(api: api, funcName: successCall, arguments: arguments)

        controller.dismiss()
    }
}
