//
//  AdminApiService.swift
//  Moment
//
//  Created by zhuheng on 2021/1/11.
//

import Foundation
import RustPB
import RxSwift

/// USER 相关API
protocol AdminApiService {
    func setPost(id: String, distributionType: RawData.PostDistributionType, categoryIds: [String]) -> Observable<Void>
}

extension RustApiService: AdminApiService {
    func setPost(id: String, distributionType: RawData.PostDistributionType, categoryIds: [String]) -> Observable<Void> {
        var request = Moments_V1_SetDistributionRequest()
        request.postID = id
        request.distributionType = distributionType
        request.pushCategoryIds = categoryIds
        return client.sendAsyncRequest(request).map { (_: Moments_V1_SetDistributionResponse) -> Void in
            return
        }
    }
}
