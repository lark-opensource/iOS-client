//
//  UserListUpdatePushHandler.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2020/10/15.
//

import RustPB
import LarkRustClient
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import RxSwift

class UserListUpdatePushHandler: BaseRustPushHandler<RustPB.Passport_V1_PushUserListUpdateResponse> {

    private static let logger = Logger.plog(UserListUpdatePushHandler.self, category: "PushUserListUpdateResponse")

    private let pushCenter: PushNotificationCenter

    @Provider private var launcher: Launcher
    @Provider private var userManager: UserManager

    private let disposeBag: DisposeBag = DisposeBag()

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: RustPB.Passport_V1_PushUserListUpdateResponse) {
        Self.logger.info("Receive PushUserListUpdate", method: .local)
        userManager
            .updateUserList(nil) {[weak self] userList in
                self?.pushCenter.post(UserListUpdateInfo(userInfos: [], pendingUsers: [], userInfoList: userList))
            }
    }
}

final class ScopedUserListUpdatePushHandler: UserPushHandler {

    static let logger = Logger.log(ScopedUserListUpdatePushHandler.self, category: "LarkAccount.ScopedUserListUpdatePushHandler")

    @ScopedInjectedLazy var userManager: UserManager?

    func process(push: RustPB.Passport_V1_PushUserListUpdateResponse) throws {
        guard PassportUserScope.enableUserScopeTransitionRust else {
            Self.logger.warn("n_action_push_handler: disable user scoped rust handler PushUserListUpdate")
            return
        }
        Self.logger.info("n_action_push_handler: receive PushUserListUpdate")
        guard let userManager = userManager else {
            Self.logger.error("n_action_push_handler: PushUserListUpdate no user manager")
            return
        }
        userManager
            .updateUserList(nil) { [weak self] userList in
                do {
                    try self?.resolver.userPushCenter.post(UserListUpdateInfo(userInfos: [], pendingUsers: [], userInfoList: userList))
                } catch {
                    Self.logger.error("n_action_push_handler: PushUserListUpdate no user push center")
                }
            }
    }
}
