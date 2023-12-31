//
//  LarkCouldPushUserListUploadImp.swift
//  LarkPushTokenUploader
//
//  Created by aslan on 2023/11/1.
//

import Foundation
import LarkContainer
import ServerPB
import LarkAccountInterface
import LKCommonsLogging
import RxSwift
import LarkRustClient

typealias UploadRequest = ServerPB_Improto_RegisterCrossTenantUserInfoRequest
typealias UploadResponse = ServerPB_Improto_RegisterCrossTenantUserInfoResponse
typealias UserInfo = ServerPB_Improto_UserInfos

final class LarkCouldPushUserListUploadImp: LarkCouldPushUserListService, UserResolverWrapper {

    let logger = Logger.log(LarkCouldPushUserListService.self, category: "LarkPushTokenUploader")

    let userResolver: LarkContainer.UserResolver

    private lazy var bag: DisposeBag = {
        DisposeBag()
    }()

    private var passportService: PassportService?
    private var client: RustService?

    /// - upload could push list API
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.passportService = try? self.userResolver.resolve(type: PassportService.self)
        self.client = try? self.userResolver.resolve(type: RustService.self)
    }

    func uploadCouldPushUserList(_ activityUserIDList: [String]) {
        guard let client = self.client else {
            return
        }

        guard let passportService = self.passportService else {
            return
        }
        var couldPushList: [UserInfo] = []
        activityUserIDList.forEach { userId in
            let user = passportService.getUser(userId)
            var uploadUserInfo = UserInfo()
            uploadUserInfo.userID = userId
            uploadUserInfo.deviceLoginID = user?.deviceLoginID ?? ""
            couldPushList.append(uploadUserInfo)
        }
        var allUserList: [UserInfo] = []
        let menuUserList = passportService.userList
        menuUserList.forEach { user in
            var uploadUserInfo = UserInfo()
            uploadUserInfo.userID = user.userID
            uploadUserInfo.deviceLoginID = user.deviceLoginID ?? ""
            allUserList.append(uploadUserInfo)
        }
        var request = UploadRequest()
        request.allPushUserInfos = allUserList
        request.allowPushUserInfos = couldPushList
        client.sendPassThroughAsyncRequest(request, serCommand: .registerCrossTenantUserInfo)
        .subscribe(onNext: { [weak self] (_: UploadResponse) in
            self?.logger.info("upload could push list success")
        }, onError: { [weak self] (error) in
            self?.logger.error("upload could push list failed", error: error)
        }).disposed(by: bag)
    }
}
