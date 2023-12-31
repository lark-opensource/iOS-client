//
//  OpenPluginShowConfirmAPI.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/4/26.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkDatePickerView
import Lynx
import UniverseDesignPopover
import EENavigator
import LarkNavigator
import LarkAlertController
import CryptoKit
import LarkContainer

open class OpenPluginMsgCardShowConfirmAPI: OpenBasePlugin {
    
    enum APIName: String {
        case msgCardShowConfirm
    }
    
    private func showConfirm(
        params: OpenPluginMsgCardShowConfirmRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("showMsgCardDateTimePicker API call start")
            let alert = LarkAlertController()
            alert.setTitle(text: params.title ?? "")
            alert.setContent(text: params.text ?? "")
            alert.addSecondaryButton(text: BundleI18n.LarkMessageCard.Lark_Legacy_Cancel, dismissCompletion: {
                callback(.failure(error: OpenAPIError(errno: OpenAPIMsgCardErrno.userCancel)))
            })
            alert.addPrimaryButton(text: BundleI18n.LarkMessageCard.Lark_Legacy_Sure, dismissCompletion: {
                callback(.success(data: OpenAPIMessageCardResult(.success, resultCode: .success)))
            })
            MsgCardAPIUtils.presentController(vc: alert, context: context)
    }
    
    
    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(
            for: APIName.msgCardShowConfirm.rawValue,
            pluginType: Self.self,
            paramsType: OpenPluginMsgCardShowConfirmRequest.self,
            resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            this.showConfirm(params: params, context: context, callback: callback)
        }
    }
}

