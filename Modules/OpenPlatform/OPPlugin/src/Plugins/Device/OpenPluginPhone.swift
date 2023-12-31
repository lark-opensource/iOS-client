//
//  OpenPluginPhone.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import LarkSetting
import LarkContainer

class OpenPluginPhone: OpenBasePlugin {
    
    private var refactorEnabled: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.makephonecall_refactor_enabled")
    }

    public func makePhoneCall(params: OpenAPIMakePhoneCallParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        var phoneNumber = params.phoneNumber
        if phoneNumber.isEmpty, refactorEnabled {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "phoneNumber")))
            callback(.failure(error: error))
            return
        }
        
        phoneNumber = phoneNumber.removingPercentEncoding?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? phoneNumber

        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            callback(.success(data: nil))
        } else {
            context.apiTrace.error("The telephone service failed to be called, cannot init tel url obj, number length=\(phoneNumber.count)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "phoneNumber")))
                .setOuterMessage(BundleI18n.OPPlugin.telephone_service_failed())
                .setMonitorMessage("can not call telephone, length=\(phoneNumber.count)")
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "makePhoneCall", pluginType: Self.self, paramsType: OpenAPIMakePhoneCallParams.self) { (this, params, context, callback) in
            
            this.makePhoneCall(params: params, context: context, callback: callback)
        }
    }

}
