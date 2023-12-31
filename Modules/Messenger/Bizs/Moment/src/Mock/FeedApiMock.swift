//
//  FeedApiMocker.swift
//  Moment
//
//  Created by zhuheng on 2021/1/8.
//

import Foundation
import RustPB

final class FeedApiMocker {

    lazy var mockImages: [Basic_V1_ImageSet] = {
        let keys = [
            ("origin:img_ea28d870-30b2-4116-85d0-cf91ad844e2g", "img_f63bd0ce-4946-47c5-92fc-a871ca1218fg"),
            ("origin:img_ea28d870-30b2-4116-85d0-cf91ad844e2g", "img_f63bd0ce-4946-47c5-92fc-a871ca1218fg"),
            ("origin:img_6688dd53-eb02-4506-8ff5-4e46510d0d3g", "img_7cc48f06-3933-4b03-8821-2d821cd9680g")
        ]
        return keys.map { (key) -> Basic_V1_ImageSet in
            var image = Basic_V1_ImageSet()
            image.origin.key = key.0
            image.thumbnail.key = key.1
            return image
        }
    }()

    lazy var mockPostContent: RawData.PostContent = {
        var content = RawData.PostContent()
        content.imageSetList = self.mockImages
        content.content = Basic_V1_RichText()
        content.content.innerText = "当前小组是对群进行某种配置的产物，优势是群组的概念大家非常熟悉，距离用户很近，但相应的也提高了Lark内群组的认知成本成本www.baidu.com，优势是群组的概念大家非常熟悉，距离用户很近，但相应的也提高了Lark内群组的认知成本成本"
        return content
    }()

    lazy var mockPost: RawData.Post = {
        var post = RawData.Post()
        post.isAnonymous = false
        post.id = "\(UInt32.random(in: 0...UInt32.max))"
        post.canComment = true
        post.canDelete = true
        post.postContent = self.mockPostContent
        return post
    }()

    func mockUser(number: String) -> MomentUser {
        var user = RustPB.Moments_V1_MomentUser()
        user.userID = "6517781505131938052"
        user.avatarKey = "49f00d6f-f262-4a60-a37f-3176987bc75g"
        user.name = "测试用户\(number)"
        return user
    }

    func getRecommendFeed(byCount count: Int32, pageToken: String) -> FeedApi.RxGetFeed {
        var nextPageToken = (Int(pageToken) ?? 0) + 1

        let postEntitys = (0..<count).map { (_) -> RawData.PostEntity in
            nextPageToken += 1
            return RawData.PostEntity(post: mockPost,
                                      user: mockUser(number: "\(nextPageToken)"),
                                      userExtraFields: [],
                                      circle: RawData.Circle(),
                                      category: nil,
                                      comments: [],
                                      reactionListEntities: [],
                                      inlinePreviewEntities: [:])
        }
        return .just(FeedApiResponseData(nextPageToken: "\(nextPageToken)",
                                         lastNewRecommendPostID: "",
                                         posts: postEntitys,
                                         trackerInfo: MomentsTrackerInfo(timeCost: 0.0)))
    }
}
