//
//  LarkRustMagicConfigAPI.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/3.
//

import Foundation
import RxSwift
import LKCommonsLogging
import RustPB
import LarkRustClient

final class LarkRustMagicConfigAPI: RustAPI, LarkMagicConfigAPI {
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]> {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(scheduler)
    }
}
