//
//  RustTourConfigAPI.swift
//  LarkTour
//
//  Created by Jiayun Huang on 2020/5/15.
//

import Foundation
import LarkModel
import RxSwift
import LKCommonsLogging
import RustPB
import LarkRustClient

final class RustTourConfigAPI: RustAPI, TourConfigAPI {
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]> {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(scheduler)
    }
}
