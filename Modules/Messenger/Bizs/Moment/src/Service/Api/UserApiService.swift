//
//  UserApiService.swift
//  Moment
//
//  Created by zhuheng on 2021/1/6.
//

import Foundation
import RustPB
import RxSwift

enum UserApi { }
extension UserApi {
    typealias RxListFollowers = Observable<(nextPageToken: String, followers: [RawData.Follower])>
    typealias RxListUserFollowings = Observable<(nextPageToken: String, followingUsers: [RawData.FollowingUser])>
}

/// USER 相关API
protocol UserApiService {
    /// 关注
    func followUser(byId userID: String) -> Observable<Void>

    /// 取关
    func unfollowUser(byId userID: String) -> Observable<Void>

    /// 分页获取用户粉丝列表
    func listUserFollowers(byCount count: Int32, userID: String, pageToken: String) -> UserApi.RxListFollowers

    /// 分页获取用户关注列表
    func listUserFollowings(byCount count: Int32, userID: String, pageToken: String) -> UserApi.RxListUserFollowings

    /// 获取可能at的人
    func getSuggestAtUser(useMock: Bool) -> Observable<[MomentUser]>
}

extension RustApiService: UserApiService {
    func followUser(byId userID: String) -> Observable<Void> {
        var request = Moments_V1_FollowUserRequest()
        request.userID = userID
        request.userType = .user
        return client.sendAsyncRequest(request)
    }

    func unfollowUser(byId userID: String) -> Observable<Void> {
        var request = Moments_V1_UnfollowUserRequest()
        request.userID = userID
        request.userType = .user
        return client.sendAsyncRequest(request)
    }

    func listUserFollowers(byCount count: Int32, userID: String, pageToken: String) -> UserApi.RxListFollowers {
        var request = Moments_V1_ListUserFollowersRequest()
        request.count = count
        request.userID = userID
        request.pageToken = pageToken
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListUserFollowersResponse) -> (nextPageToken: String, followers: [RawData.Follower]) in
                return (response.nextPageToken, response.followers)
            }
    }

    func listUserFollowings(byCount count: Int32, userID: String, pageToken: String) -> UserApi.RxListUserFollowings {
        var request = Moments_V1_ListUserFollowingsRequest()
        request.count = count
        request.userID = userID
        request.pageToken = pageToken
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_ListUserFollowingsResponse) -> (nextPageToken: String, followingUsers: [RawData.FollowingUser]) in
                return (response.nextPageToken, response.followingUsers)
            }
    }

    func getSuggestAtUser(useMock: Bool) -> Observable<[MomentUser]> {
        if useMock {
            let result: [MomentUser] = (0..<5).map { (i) -> MomentUser in
                return self.mockUser(number: i)
            }
            return .just(result)
        }
        let request = Moments_V1_GetRecommendAtListRequest()
        return client.sendAsyncRequest(request).map { (response: Moments_V1_GetRecommendAtListResponse) -> [MomentUser] in
            return response.momentUsers
        }
    }

    private func mockUser(number: Int) -> MomentUser {
        var user = RustPB.Moments_V1_MomentUser()
        user.userID = "6517781505131938052"
        user.avatarKey = "49f00d6f-f262-4a60-a37f-3176987bc75g"
        user.name = "测试用户\(number)"
        user.larkUser.fullDepartmentPath = "保密部门"
        return user
    }
}
