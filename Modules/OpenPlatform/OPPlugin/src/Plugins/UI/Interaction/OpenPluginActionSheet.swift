//
//  OpenPluginActionSheet.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LKCommonsLogging
import OPFoundation
import LarkContainer
import TTMicroApp

final class OpenPluginActionSheet: OpenBasePlugin {

    func showActionSheet(params: OpenAPIShowActionSheetParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowActionSheetResult>) -> Void) {
        guard let controller = (context.gadgetContext)?.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }

        context.apiTrace.info("bdp_showActionSheetWithModel")
        var actions = [EMAActionSheetAction]()
        for (index, item) in params.itemList.enumerated() {
            let action = EMAActionSheetAction(title: item, style: .default) {
                callback(.success(data: OpenAPIShowActionSheetResult(tapIndex: index)))
            }
            actions.append(action)

        }
        let cancelAction = EMAActionSheetAction(title: BundleI18n.OPPlugin.cancel, style: .cancel) {
            // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
            // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
            // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setOuterMessage("user cancel")
            callback(.failure(error: apiError))
        }
        actions.append(cancelAction)
        var vc: UIViewController? = BDPAppController.currentAppPageController(controller, fixForPopover: false)
        if vc == nil {
            vc = OPNavigatorHelper.topMostAppController(window: controller.view.window) as? UIViewController
        }
        if let vc = vc {
            let actionSheet = OPActionSheet.createActionSheet(with: actions, isAutorotatable: UDRotation.isAutorotate(from: vc))
            vc.present(actionSheet, animated: true, completion: nil)
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("actionSheet controller is nil")
            callback(.failure(error: error))
        }
    }


    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "showActionSheet", pluginType: Self.self, paramsType: OpenAPIShowActionSheetParams.self, resultType: OpenAPIShowActionSheetResult.self) { (this, params, context, callback) in
            
            this.showActionSheet(params: params, context: context, callback: callback)
        }
    }
}
