//
//  DynamicResourceAPI.swift
//  LarkSDKInterface
//
//  Created by shizhengyu on 2020/9/14.
//

import Foundation
import RustPB
import RxSwift

public protocol DynamicResourceAPI {
    func fetchDynamicResource(
        businessScenario: RustPB.Contact_V1_BizScenario,
        imageOptions: RustPB.Contact_V1_ImageOptions,
        extraRequestParams: RustPB.Contact_V1_GetDynamicMediaRequest.OneOf_BusinessOptions?
    ) -> Observable<RustPB.Contact_V1_GetDynamicMediaResponse>
}
