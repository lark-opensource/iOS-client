//
//  RustDynamicResourceAPI.swift
//  LarkSDK
//
//  Created by shizhengyu on 2020/9/14.
//

import Foundation
import LarkSDKInterface
import RustPB
import RxSwift

final class RustDynamicResourceAPI: LarkAPI, DynamicResourceAPI {
    func fetchDynamicResource(
        businessScenario: RustPB.Contact_V1_BizScenario,
        imageOptions: RustPB.Contact_V1_ImageOptions,
        extraRequestParams: RustPB.Contact_V1_GetDynamicMediaRequest.OneOf_BusinessOptions?
    ) -> Observable<RustPB.Contact_V1_GetDynamicMediaResponse> {

        var request = Contact_V1_GetDynamicMediaRequest()
        request.businessScenario = businessScenario
        request.imageOptions = imageOptions
        request.businessOptions = extraRequestParams

        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}
