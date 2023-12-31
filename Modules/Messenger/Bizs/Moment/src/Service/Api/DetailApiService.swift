//
//  DetailApiService.swift
//  Moment
//
//  Created by zhuheng on 2021/1/11.
//

import UIKit
import Foundation
import RustPB
import RxSwift

enum DetailApi { }
extension DetailApi {
    typealias ListComments = (nextPageToken: String, comments: [RawData.CommentEntity], post: RawData.PostEntity?, trackerInfo: MomentsTrackerInfo?)
    typealias RxListComments = Observable<ListComments>
}

/// Post Detail 相关API
protocol DetailApiService {
    /// 分页获取评论列表
    func listComments(byCount count: Int32, postId: String, pageToken: String) -> DetailApi.RxListComments

    /// 获取文章详情页数据，分页拉评论信息
    func getPostDetail(byId postID: String) -> Observable<(RawData.PostEntity, MomentsTrackerInfo?)>
}

extension RustApiService: DetailApiService {
    func getPostDetail(byId postID: String) -> Observable<(RawData.PostEntity, MomentsTrackerInfo?)> {
        var request = Moments_V1_GetPostDetailRequest()
        request.postID = postID
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_GetPostDetailResponse) -> (RawData.PostEntity, MomentsTrackerInfo) in
                let cost = CACurrentMediaTime() - start
                let post = response.post
                return (RustApiService.getPostEntity(post: post, entities: response.entities), MomentsTrackerInfo(timeCost: cost))
            }
    }

    func listComments(byCount count: Int32, postId: String, pageToken: String) -> DetailApi.RxListComments {
        var request = Moments_V1_ListCommentsRequest()
        request.count = count
        request.entityID = postId
        request.pageToken = pageToken
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListCommentsResponse) -> (nextPageToken: String, comments: [RawData.CommentEntity], post: RawData.PostEntity?, trackerInfo: MomentsTrackerInfo) in
                let cost = CACurrentMediaTime() - start
                var postEntity: RawData.PostEntity?
                if let post = response.entities.posts[postId] {
                    //最新的post信息会随commentList接口返回
                    postEntity = RustApiService.getPostEntity(post: post, entities: response.entities)
                }
                let comments = response.comments.map { (comment) -> RawData.CommentEntity in
                    return MomentsDataConverter.convertCommentToCommentEntitiy(entities: response.entities, comment: comment)
                }
                return (nextPageToken: response.nextPageToken, comments: comments, post: postEntity, trackerInfo: MomentsTrackerInfo(timeCost: cost))
            }
    }
}
