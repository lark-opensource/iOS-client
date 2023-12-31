//
//  OpenPluginThirdShare.swift
//  OPPlugin
//
//  Created by yi on 2021/4/14.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import OPSDK
import ECOInfra
import LKCommonsLogging
import LarkContainer
import UniverseDesignToast

final class OpenPluginThirdShare: OpenBasePlugin {
    let thirdShareHelper = OPThirdShareHelper()

    func share(
        params: OpenAPIThirdShareParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let gadgetContext = context.gadgetContext, let controller = gadgetContext.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        // process channelType
        var channelTypeParams = params.channelType
        // Lark 合规问题处理：
        // 与合规同学确认结果：
        // 1. Lark 不能走 weixinSDK 分享到 wx
        // 2. Lark 包不会集成 weixinSDK
        // 3. 可以走系统分享
        // 4. 飞书可以分享到微信
        if OPThirdShareHelper.isLark() {
            // 是 Lark，如果包含分享到 wx、wx_timeline，则报错
            if (channelTypeParams.contains(.wx) || channelTypeParams.contains(.wx_timeline)) {
                let error = OpenAPIError(code: OpenAPIShareErrorCode.canNotShareToWX)
                callback(.failure(error: error))
                return
            }
        }
        // iPad 问题处理：
        // UG snsShare MenuPanelOperationHandler 不支持 ipad（UI未适配）
        // 后续可以考虑接入UG新的share面板
        if BDPDeviceHelper.isPadDevice() {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("UG snsShare not impl ipad invoke")
            callback(.failure(error: error))
            context.apiTrace.error("share api app=\(uniqueID.fullString) unsupport")
            return
        }
        let channelType = channelTypeParams.map { (element) -> String in
            return element.rawValue
        }
        // process image
        let imageData = NSData(base64Encoded: params.image, options: NSData.Base64DecodingOptions(rawValue: 0)) ?? NSData()
        let image = UIImage(data: imageData as Data)
        
        // contentType + text/url/image 校验
        switch params.contentType {
        case .text:
            guard !params.content.isEmpty else {
                let error = OpenAPIError(code: OpenAPIShareErrorCode.textIsEmpty)
                callback(.failure(error: error))
                return
            }
        case .url:
            guard !params.url.isEmpty, let _ = URL(string: params.url) else {
                let error = OpenAPIError(code: OpenAPIShareErrorCode.urlIsInvalid)
                callback(.failure(error: error))
                return
            }
            guard !params.title.isEmpty else {
                let error = OpenAPIError(code: OpenAPIShareErrorCode.titleIsInvalid)
                callback(.failure(error: error))
                return
            }
        case .image:
            guard image != nil else {
                let error = OpenAPIError(code: OpenAPIShareErrorCode.imageIsInvalid)
                callback(.failure(error: error))
                return
            }
            if FSCrypto.isCryptoInterceptEnable(type: .apiShare){
                DispatchQueue.main.async {
                    if let view = context.controller?.view {
                        UDToast.showTips(
                            with: BundleI18n.OPPlugin.OpenPlatform_Workplace_SafetyWarning_OpenFailed,
                            on: view
                        )
                    } else {
                        context.apiTrace.error("cannot find controller view to show crypto tips")
                    }
                }
                let error = OpenAPIError(errno: OpenAPIShareErrno.securityPermissionDenied)
                callback(.failure(error: error))
                return
            }
        default:
            assertionFailure("get unknow contentType")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            callback(.failure(error: error))
            return
        }
        
        thirdShareHelper.share(
            container: controller,
            appID: uniqueID.appID,
            channelType: channelType as NSArray,
            contentType: params.contentType.rawValue,
            url: params.url,
            title: params.title,
            content: params.content,
            imageData: imageData
        ) {
            // 1. 多渠道分享时，构造「分享面板」成功，就会执行成功回调
            // 2. 单渠道分享时，拉起「单渠道分享面板」,就会执行成功回调
            callback(.success(data: nil))
        } failedHandler: { (error) in
            // 1. 多渠道分享时：
            //      如果构造「分享面板」失败，失败回调
            //      如果构造「分享面板」成功，成功回调，意味着后续的失败回调都会被吞掉
            // 2. 单渠道分享时：
            //      如果 channel 为空，失败回调（理论上不可能）
            //      如果 channle 不为空，拉起「单渠道分享面板」，成功回调，意味着后续的失败回调都会被吞掉
            context.apiTrace.error("share app=\(uniqueID.fullString) share failed error: \(error)")
            let apiError = OpenAPIError(code: OpenAPIShareErrorCode.shareFailed)
            callback(.failure(error: apiError))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "share", pluginType: Self.self, paramsType: OpenAPIThirdShareParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.share(params: params, context: context, callback: callback)
        }
    }
}
