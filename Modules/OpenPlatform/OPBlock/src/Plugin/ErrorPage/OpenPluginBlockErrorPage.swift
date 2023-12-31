//
//  OpenPluginBlockErrorPage.swift
//  OPBlock
//
//  Created by doujian on 2022/8/3.
//

import OPSDK
import ECOProbe
import ECOProbeMeta
import OPBlockInterface
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkSetting
import OPFoundation
import LarkContainer

public final class OpenPluginBlockErrorPage: OpenBasePlugin {
    struct ErrorPageConfig: SettingDecodable {
        static let settingKey = UserSettingKey.make(userKeyLiteral: "block_custom_error_page")
        let enable_features: [String]
    }

    @Setting(.useDefaultKeys)
    private static var errorPageConfig: ErrorPageConfig?

    static func showBlockErrorPage(
        params: OpenPluginBlockErrorPageParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        // API 调用埋点
        let monitor = OPMonitor(
            name: "op_workplace_event",
            code: EPMClientOpenPlatformBlockitCustomErrorPageCode.invoke_error_page_api
        ).addCategoryValue("api_name", "showBlockErrorPage")
        guard let gadgetContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol,
              let container = OPApplicationService.current
                .getContainer(uniuqeID: gadgetContext.uniqueID) as? OPBlockContainer,
              let config = container.containerContext.containerConfig as? OPBlockContainerConfigProtocol,
              let blockTypeID = config.blockInfo?.blockTypeID else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            monitor.setResultTypeFail().flush()
            return
        }
        monitor.addCategoryValue("host", config.host).addCategoryValue("block_type_id", blockTypeID)
        context.apiTrace.info(
            "showBlockErrorPage",
            additionalData: [
                "whiteList": String(describing: errorPageConfig),
                "blockTypeId": "\(blockTypeID)"
            ]
        )
        // 命中灰度
        guard let enableFeaturesList = errorPageConfig?.enable_features as? [String],
              enableFeaturesList.contains(blockTypeID) else {
            // 不打埋点
            let error = OpenAPIError(errno: OpenAPICommonErrno.unable)
            callback(.failure(error: error))
            return
        }
        // check 是否已经展示 业务 错误页
        if container.isShowingErrorPage() {
            context.apiTrace.error("already showing error page")
            let error = OpenAPIError(errno: OpenAPIBlockErrorPageErrno.hasBeenDisplayed)
            monitor.addCategoryValue("is_showing", true).setResultTypeFail().flush()
            callback(.failure(error: error))
            return
        }
        // check 是否已经展示 block 错误页（guide info）
        if container.isShowingStatusView() {
            container.hideStatusView()
        }
        // check buttonText 是否为 nil、空字符串
        var buttonTextStr: String? = nil
        if let buttonText = params.buttonText {
            buttonTextStr = buttonText.isEmpty ? nil : buttonText
        }
        // 展示错误页
        container.showErrorPage(
            errorMessage: params.errorMessage,
            buttonText: buttonTextStr,
            success: { (isFromHost) in 
                callback(.success(data: nil))
                monitor.addCategoryValue("is_from_host", isFromHost).setResultTypeSuccess().flush()
            },
            failure: {
                let error = OpenAPIError(errno: OpenAPIBlockErrorPageErrno.failedToShowTheErrorPage)
                callback(.failure(error: error))
                monitor.addCategoryValue("is_showing", false).setResultTypeFail().flush()
            }
        )
    }

    static func hideBlockErrorPage(
        context: OpenAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        // API 调用埋点
        let monitor = OPMonitor(
            name: "op_workplace_event",
            code: EPMClientOpenPlatformBlockitCustomErrorPageCode.invoke_error_page_api
        ).addCategoryValue("api_name", "hideBlockErrorPage")
        guard let gadgetContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol,
              let container = OPApplicationService.current
                .getContainer(uniuqeID: gadgetContext.uniqueID) as? OPBlockContainer,
              let config = container.containerContext.containerConfig as? OPBlockContainerConfigProtocol,
              let blockTypeID = config.blockInfo?.blockTypeID else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            monitor.setResultTypeFail().flush()
            return
        }
        monitor.addCategoryValue("host", config.host).addCategoryValue("block_type_id", blockTypeID)
        context.apiTrace.info(
            "hideBlockErrorPage",
            additionalData: [
                "whiteList": String(describing: errorPageConfig),
                "blockTypeId": "\(blockTypeID)"
            ]
        )
        // 命中灰度
        guard let enableFeaturesList = errorPageConfig?.enable_features as? [String],
              enableFeaturesList.contains(blockTypeID) else {
            // 不打埋点
            let error = OpenAPIError(errno: OpenAPICommonErrno.unable)
            callback(.failure(error: error))
            return
        }
        // 不需要检查 block 错误页（guide info）展示状态
        // 检查 errorPage 展示状态
        guard container.isShowingErrorPage() else {
            let error = OpenAPIError(errno: OpenAPIBlockErrorPageErrno.cannotBeHidden)
            callback(.failure(error: error))
            monitor.addCategoryValue("is_showing", false).setResultTypeFail().flush()
            return
        }
        // 隐藏错误页
        container.hideErrorPage(
            success: { (isFromHost) in
                callback(.success(data: nil))
                monitor.addCategoryValue("is_from_host", isFromHost).setResultTypeSuccess().flush()
            },
            failure: {
                let error = OpenAPIError(errno: OpenAPIBlockErrorPageErrno.failedToHideTheErrorPage)
                callback(.failure(error: error))
                monitor.addCategoryValue("is_showing", true).setResultTypeFail().flush()
            }
        )
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandler(
            for: "showBlockErrorPage",
            paramsType: OpenPluginBlockErrorPageParams.self,
            handler: { (params, context, callback) in
                Self.showBlockErrorPage(params: params, context: context, callback: callback)
            }
        )
        registerAsyncHandler(
            for: "hideBlockErrorPage",
            handler: { (params, context, callback) in
                Self.hideBlockErrorPage(context: context, callback: callback)
            }
        )
    }
}
