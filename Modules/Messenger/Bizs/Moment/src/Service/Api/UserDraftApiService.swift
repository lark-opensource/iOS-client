//
//  UserDraftApiService.swift
//  Moment
//
//  Created by bytedance on 2021/3/22.
//

import Foundation
import UIKit
import RxSwift
import RustPB
/// 用户草稿的接口
protocol UserDraftApiService {
    func asynGetUserDraftWithKey(_ key: String) -> Observable<String>
    func asynSetUserDraftWithKey(_ key: String, value: String, type: RawData.StorageType) -> Observable<Void>
    func synGetUserDraftWithKey(_ key: String) -> String
    func synSetUserDraftWithKey(_ key: String, value: String, type: RawData.StorageType)
}

extension RustApiService: UserDraftApiService {
    func asynGetUserDraftWithKey(_ key: String) -> Observable<String> {
        var request = RustPB.Moments_V1_GetKeyValueRequest()
        request.key = key
        return client.sendAsyncRequest(request).map { (response: RustPB.Moments_V1_GetKeyValueResponse) -> String in
            return response.value
        }
    }

    func asynSetUserDraftWithKey(_ key: String, value: String, type: RawData.StorageType) -> Observable<Void> {
        var request = RustPB.Moments_V1_SetKeyValueRequest()
        request.key = key
        request.value = value
        request.keyType = type
        return client.sendAsyncRequest(request).map { (_) -> Void in
            return
        }
    }

    func synGetUserDraftWithKey(_ key: String) -> String {
        var request = RustPB.Moments_V1_GetKeyValueRequest()
        request.key = key
        let res: String
        do {
            let response: RustPB.Moments_V1_GetKeyValueResponse = try client.sendSyncRequest(request).response
            res = response.value
        } catch {
            res = ""
            assertionFailure("moments 获取 value出现异常")
        }
        return res
    }

    func synSetUserDraftWithKey(_ key: String, value: String, type: RawData.StorageType) {
        var request = RustPB.Moments_V1_SetKeyValueRequest()
        request.key = key
        request.value = value
        request.keyType = type
        do {
            try client.sendSyncRequest(request)
        } catch {
            assertionFailure("moments 设置key value出现异常")
        }
    }

}
