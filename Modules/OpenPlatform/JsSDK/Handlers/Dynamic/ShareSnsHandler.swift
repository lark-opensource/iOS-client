//
//  ShareSnsHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import EENavigator
import LarkMessengerInterface
import LarkSnsShare
import LarkContainer

class ShareSnsHandler: JsAPIHandler {

    enum ShareResType: Int {
        case image = 0
        case text = 1
    }

    private static let logger = Logger.log(ShareSnsHandler.self, category: "ShareSnsHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let resTypeRaw = args["resType"] as? Int,
            let resType = ShareResType(rawValue: resTypeRaw),
            let title = args["title"] as? String,
            let shareItemTypesRaw = args["snsTypes"] as? [Int] else {
                callFailureCallback(argus: args, webApi: api)
                return
        }
        guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController,
              currentVC.navigationController != nil else {
            ShareSnsHandler.logger.error("ShareSnsHandler failed, no baseVc")
            return
        }

        let shareItemTypes: [LarkShareItemType] = shareItemTypesRaw.map { .transform(rawVaule: $0) }

        var contentContext: ShareContentContext?
        /// 图片分享
        if resType == .image {
            if let imageBase64 = args["image"] as? String {
                if let imageData = Data(base64Encoded: imageBase64, options: []),
                    let shareImage = UIImage(data: imageData) {
                    contentContext = .image(ImagePrepare(
                        title: title,
                        image: shareImage
                    ))
                    if let encryptedImageDataStr = (imageData as NSData).web_md5String() {
                        ShareSnsHandler.logger.debug("ShareSnsHandler success",
                        additionalData: ["resType": "\(resType)",
                           "shareImage": encryptedImageDataStr,
                           "shareItemTypes": "\(shareItemTypes)"])
                    }
                } else {
                    callFailureCallback(argus: args, webApi: api)
                    ShareSnsHandler.logger.error("ShareSnsHandler image encode failed, imageBase64 = \(imageBase64)")
                }
            }
        } /// 文本链接分享
        else if resType == .text,
            let shareText = args["content"] as? String,
            let shareURL = args["url"] as? String {
            contentContext = .webUrl(WebUrlPrepare(
                title: title,
                webpageURL: shareURL,
                description: shareText
            ))
            if let encryptedURLDataStr = (shareURL.data(using: .utf8) as NSData?)?.web_md5String() {
                ShareSnsHandler.logger.debug("ShareSnsHandler success",
                additionalData: ["resType": "\(resType)",
                   "shareURL": encryptedURLDataStr,
                   "shareItemTypes": "\(shareItemTypes)"])
            }
        } else {
            callFailureCallback(argus: args, webApi: api)
        }

        /// 分享回调(也有可能是action)
        let shareCallBack: ((_ result: ShareResult, _ itemType: LarkShareItemType) -> Void)? = { [weak self] result, itemType in
            guard let `self` = self else { return }
            self.callSuccessCallback(argus: args, webApi: api, snsType: itemType.rawValue, result: result)
        }

        guard let context = contentContext else {
            return
        }
        (try? Container.shared.getCurrentUserResolver().resolve(assert: LarkShareService.self))?.present(
            with: shareItemTypes,
            contentContext: context,
            baseViewController: currentVC,
            popoverMaterial: nil,
            needDowngrade: nil,
            downgradeInterceptor: nil,
            shareCallback: shareCallBack
        )
    }
}

private extension ShareSnsHandler {
    /// 成功收到分享callback，通知h5
    func callSuccessCallback(argus args: [String: Any], webApi api: WebBrowser, snsType: Int, result: ShareResult) {
        if let onSuccess = args["onSuccess"] as? String {
            var arguments: [[String: Any]] = [[:]]
            if result.isSuccess() {
                arguments = [["isSuccess": true,
                              "snsType": snsType]]
                    as [[String: Any]]
            } else {
                if case .failure(let errorCode, let debugMsg) = result {
                    arguments = [["isSuccess": false,
                                  "snsType": snsType,
                                  "errorCode": errorCode.rawValue,
                                  "errorMsg": debugMsg]]
                        as [[String: Any]]
                }
            }

            callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            ShareSnsHandler.logger.debug("ShareSnsHandler success, isSuccess = \(true), snsType = \(snsType)")
        }
    }

    /// 分享过程发生异常，通知h5
    func callFailureCallback(argus args: [String: Any], webApi api: WebBrowser) {
        let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
        if let onFailed = args["onFailed"] as? String {
            self.callbackWith(api: api, funcName: onFailed, arguments: arguments)
        }
        ShareSnsHandler.logger.error("ShareSnsHandler failed, miss arguments args = \(args)")
    }
}
