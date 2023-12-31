//
//  NickNameAndAnonymousApiService.swift
//  Moment
//
//  Created by zc09v on 2021/5/25.
//
import Foundation
import RxSwift
import ServerPB

protocol NickNameAndAnonymousService {
    //拉取花名列表
    func pullNickName(count: Int, mock: Bool) -> Observable<[RawData.AnonymousNickname]>
    //拉取花名头像
    func pullNickNameAvatar() -> Observable<String>
    //创建花名身份
    func createNickNameUser(circleId: String, avatarKey: String, nickName: RawData.AnonymousNickname, isRenewal: Bool) -> Observable<(momentUser: RawData.RustMomentUser, renewNicknameTime: Int64)>
    //是否还有匿名配额
    func getAnonymousQuota(postId: String?) -> Observable<Bool>
}

extension RustApiService: NickNameAndAnonymousService {
    func pullNickName(count: Int, mock: Bool) -> Observable<[RawData.AnonymousNickname]> {
        if mock {
            var result: [RawData.AnonymousNickname] = []
            let names = ["左目侦探", "澳洲坚果", "左目侦探1", "左目侦探1", "左目侦探1",
                         "左目侦探1", "左目侦探1", "啊哈哈",
                         "大萨达手打都是亮点卡死了的卡死了的喀斯柯达塑料袋卡死了大卡司六道口萨拉丁卡拉斯科都拉上收到了斯柯达拉斯柯达啦"]
            for (index, name) in names.enumerated() {
                var nickName = RawData.AnonymousNickname()
                nickName.nickname = name
                nickName.nicknameID = "\(index)"
                nickName.nicknameIdx = Int32(index)
                result.append(nickName)
            }
            return .just(result)
        }
        var request = ServerPB.ServerPB_Moments_PullNicknamesRequest()
        request.count = Int32(count)
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsPullNicknames)
            .map { (response: ServerPB_Moments_PullNicknamesResponse) -> [RawData.AnonymousNickname] in
                return response.nicknameList
            }
    }

    func pullNickNameAvatar() -> Observable<String> {
        let request = ServerPB.ServerPB_Moments_PullNicknameAvatarRequest()
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsPullNicknameAvatar)
            .map { (response: ServerPB_Moments_PullNicknameAvatarResponse) -> String in
                return response.avatarKey
            }
    }

    func createNickNameUser(circleId: String, avatarKey: String, nickName: RawData.AnonymousNickname, isRenewal: Bool) -> Observable<(momentUser: RawData.RustMomentUser, renewNicknameTime: Int64)> {
        var request = ServerPB.ServerPB_Moments_CreateNicknameUserRequest()
        request.circleID = circleId
        request.avatarKey = avatarKey
        request.nickname = nickName
        request.isRenewal = isRenewal
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsCreateNicknameUser)
        .map { (response: ServerPB_Moments_CreateNicknameUserResponse) -> (momentUser: RawData.RustMomentUser, renewNicknameTime: Int64) in
            var user = RawData.RustMomentUser()
            user.name = response.user.name
            user.avatarKey = response.user.avatarKey
            user.userID = response.user.userID
            return (user, response.nextRenewTimeSec)
        }
    }

    func getAnonymousQuota(postId: String?) -> Observable<Bool> {
        var request = ServerPB.ServerPB_Moments_GetAnonymousInfoRequest()
        if let postId = postId {
            request.postID = postId
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsGetAnonymousInfo)
            .map { (response: ServerPB_Moments_GetAnonymousInfoResponse) -> Bool in
                return response.hasQuota_p
            }
    }
}
