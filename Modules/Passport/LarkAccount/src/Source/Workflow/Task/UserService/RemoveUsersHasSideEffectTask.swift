//
//  RemoveUsersHasSideEffectTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/11/21.
//

import LarkAccountInterface
import LarkContainer

func removeUsersHasSideEffectTask(context: UniContextProtocol, action: PassportUserAction) -> Task<[String], [String], Error> {
    return Task { logoutUserIDList in

        @Provider var activityCoordinator : MultiUserActivityCoordinatable

        //监控
        PassportMonitor.monitor(PassportMonitorMetaMonad.removeUsersStart, 
                                type: .common,
                                context: context,
                                categoryValueMap: ["action": action.rawValue]).flush()

        //refresh activity 操作
        return SideEffect { successCallback, failCallback in

            let forgroundUser = UserManager.shared.foregroundUser
            let isLogoutForegroundUser: Bool
            if let user = forgroundUser {
                isLogoutForegroundUser = logoutUserIDList.contains(user.userID)
            } else {
                isLogoutForegroundUser = false
            }

            let activityState = MultiUserActivityState(action: action, toForegroundUserID: isLogoutForegroundUser ? nil : forgroundUser?.userID, droppedUserIDs: logoutUserIDList)
            activityCoordinator.stateWillUpdate(activityState) { result in
                switch result {
                case .success():
                    //监控成功
                    PassportMonitor.monitor(PassportMonitorMetaMonad.removeUsersStartResult, 
                                            type: .success,
                                            context: context,
                                            categoryValueMap: ["action": action.rawValue]).flush()

                    successCallback(logoutUserIDList)
                case .failure(let error):
                    //更新失败
                    PassportMonitor.monitor(PassportMonitorMetaMonad.removeUsersStartResult, 
                                            type: .failure(error),
                                            context: context,
                                            categoryValueMap: ["action": action.rawValue]).flush()
                    failCallback(error)
                }
            }
        }
    } rollback: { _ in
        return SideEffect(success: ())
    }
}




