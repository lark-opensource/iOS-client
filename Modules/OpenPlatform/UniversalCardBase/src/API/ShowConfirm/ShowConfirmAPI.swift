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

open class UniversalCardShowConfirmAPI: UniversalCardAPIPlugin {
    
    enum APIName: String {
        case UniversalCardShowConfirm
    }
    
    private func showConfirm(
        params: UniversalCardShowConfirmRequest,
        context: UniversalCardAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("showConfirm API call start")
            guard let sourceVC = context.cardContext.sourceVC else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.info("showConfirm API fail: internalError")
                return
            }
            let alert = LarkAlertController()
            alert.setTitle(text: params.title ?? "")
            alert.setContent(text: params.text ?? "")
            alert.addSecondaryButton(text: BundleI18n.UniversalCardBase.Lark_Legacy_Cancel, dismissCompletion: {
                context.apiTrace.info("showConfirm API fail: userCancel")
                callback(.failure(error: OpenAPIError(errno: OpenAPIMsgCardErrno.userCancel)))
            })
            alert.addPrimaryButton(text: BundleI18n.UniversalCardBase.Lark_Legacy_Sure, dismissCompletion: {
                context.apiTrace.info("showConfirm API success")
                callback(.success(data: OpenAPIUniversalCardResult(.success, resultCode: .success)))
            })
            presentController(vc: alert, context: context)
    }
    
    
    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerCardAsyncHandler(
            for: APIName.UniversalCardShowConfirm.rawValue,
            pluginType: Self.self,
            paramsType: UniversalCardShowConfirmRequest.self,
            resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            this.showConfirm(params: params, context: context, callback: callback)
        }
    }

}

