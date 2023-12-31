//
//  UserTabApiService.swift
//  Moment
//
//  Created by bytedance on 2021/4/23.
//

import Foundation
import UIKit
import RustPB
import RxSwift

protocol UserTabApiService {
    func getListTabRequest() -> Observable<[RawData.PostTab]>
    func configTabsRequestWithTabIds(_ tadIds: [String]) -> Observable<Void>
    func getUserSettingRequest() -> Observable<Moments_V1_GetUserSettingResponse>
    func getUserConfigAndSettingsRequest() -> Observable<Moments_V1_GetUserConfigAndSettingsResponse>
}

extension RustApiService: UserTabApiService {
    func getListTabRequest() -> Observable<[RawData.PostTab]> {
        let request = Moments_V1_ListTabsRequest()
        return client.sendAsyncRequest(request).map { (reponse: Moments_V1_ListTabsResponse) -> [RawData.PostTab] in
            return reponse.tabs
        }
    }

    func configTabsRequestWithTabIds(_ tadIds: [String]) -> Observable<Void> {
        var request = Moments_V1_ConfigTabsRequest()
        request.tabIds = tadIds
        return client.sendAsyncRequest(request).map { (_) -> Void in
            return
        }
    }

    func getUserSettingRequest() -> Observable<Moments_V1_GetUserSettingResponse> {
        let request = Moments_V1_GetUserSettingRequest()
        return client.sendAsyncRequest(request)
    }

    func getUserConfigAndSettingsRequest() -> Observable<Moments_V1_GetUserConfigAndSettingsResponse> {
        let request = Moments_V1_GetUserConfigAndSettingsRequest()
        return client.sendAsyncRequest(request)
    }
}
