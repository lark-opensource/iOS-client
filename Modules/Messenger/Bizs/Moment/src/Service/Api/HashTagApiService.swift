//
//  HashTagApiService.swift
//  Moments
//
//  Created by liluobin on 2021/7/2.
//

import Foundation
import UIKit
import ServerPB
import RustPB
import RxSwift

protocol HashTagApiService {
    func hashTagListForHistory() -> Observable<(RawData.HashTagResponse, String)>
    func hashTagListForInput(_ input: String) -> Observable<(RawData.HashTagResponse, String)>
    func getDetailInfoWithHashTagId(_ id: String) -> Observable<RawData.HashTagDetailInfo>
    func getHashTagListPost(byCount count: Int32,
                          pageToken: String,
                          hashTagId: String,
                          hashTagOrder: RawData.hashTagOrder?) -> FeedApi.RxGetFeed
}
extension RustApiService: HashTagApiService {

    func hashTagListForHistory() -> Observable<(RawData.HashTagResponse, String)> {
        return hashTagListForInput("")
    }

    func hashTagListForInput(_ input: String) -> Observable<(RawData.HashTagResponse, String)> {
        var request = RustPB.Moments_V1_ListHashtagsByUserInputRequest()
        request.userInput = input
        return client.sendAsyncRequest(request).map {   (response) -> (RawData.HashTagResponse, String) in
                return (response, input)
        }
    }

    func getDetailInfoWithHashTagId(_ id: String) -> Observable<RawData.HashTagDetailInfo> {
        var request = Moments_V1_GetHashtagDetailRequest()
        request.hashtagID = id
        return client.sendAsyncRequest(request).map { (response: Moments_V1_GetHashtagDetailResponse) -> RawData.HashTagDetailInfo in
            return RawData.HashTagDetailInfo(stats: response.hashtagStats, hashTag: response.hashtag)
        }
    }
    func getHashTagListPost(byCount count: Int32,
                          pageToken: String,
                          hashTagId: String,
                          hashTagOrder: RawData.hashTagOrder?) -> FeedApi.RxGetFeed {
        var request = Moments_V1_ListHashtagPostsRequest()
        request.count = count
        request.pageToken = pageToken
        request.hashtagID = hashTagId
        if let hashTagOrder = hashTagOrder {
            request.order = hashTagOrder
        }
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListHashtagPostsResponse) -> FeedApiResponseData in
                let cost = CACurrentMediaTime() - start
                var postEntitys: [RawData.PostEntity] = []
                guard !response.entities.users.isEmpty else {
                    return FeedApiResponseData(nextPageToken: "String",
                                               posts: [],
                                               trackerInfo: MomentsTrackerInfo(timeCost: cost))
                }
                response.entryList.forEach { (feedEntity) in
                    if let postEntity = RustApiService.getPostEntity(postID: feedEntity.postID, entities: response.entities) {
                        postEntitys.append(postEntity)
                    }
                }
                ///HashTagList 都是时间序 所以没有lastNewRecommendPostID 接口也不支持
                return FeedApiResponseData(nextPageToken: response.nextPageToken,
                                           lastNewRecommendPostID: "",
                                           posts: postEntitys,
                                           trackerInfo: MomentsTrackerInfo(timeCost: cost))
            }
    }
}
