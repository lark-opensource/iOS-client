//
//  DislikeApiService.swift
//  Moment
//
//  Created by ByteDance on 2022/7/19.
//

import Foundation
import RxSwift
import RustPB
import ServerPB

protocol DislikeApiService {
    /// 拉去点踩原因列表
    func listDislikeReasons(entityID: String, entityType: RawData.DislikeEntityType) -> Observable<[RawData.DislikeReason]>
    /// 点踩
    func createDislike(entityID: String, entityType: RawData.DislikeEntityType, reasonIds: [String]) -> Observable<Void>
    /// 取消踩
    func deleteDislike(entityID: String, entityType: RawData.DislikeEntityType) -> Observable<Void>
}

extension RustApiService: DislikeApiService {

    func listDislikeReasons(entityID: String, entityType: RawData.DislikeEntityType) -> Observable<[RawData.DislikeReason]> {
        var request = ServerPB_Moments_ListDislikeReasonsRequest()
        request.entityID = entityID
        request.entityType = entityType
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsListDislikeReasons).map { (response: ServerPB_Moments_ListDislikeReasonsResponse) -> [RawData.DislikeReason] in
                return response.reasons
        }
    }

    func createDislike(entityID: String, entityType: RawData.DislikeEntityType, reasonIds: [String]) -> Observable<Void> {
        var request = ServerPB_Moments_CreateDislikeRequest()
        request.entityID = entityID
        request.entityType = entityType
        request.reasonIds = reasonIds
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsCreateDislike)
    }

    func deleteDislike(entityID: String, entityType: RawData.DislikeEntityType) -> Observable<Void> {
        var request = ServerPB_Moments_DeleteDislikeRequest()
        request.entityID = entityID
        request.entityType = entityType
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsDeleteDislike)
    }
}
