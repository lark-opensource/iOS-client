//
//  updateForegroundUserHasSideEffectTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/16.
//

import LarkAccountInterface
import LarkContainer


func updateForegroundUserHasSideEffectTask(context: UniContextProtocol, action: PassportUserAction) -> Task<V4UserInfo, V4UserInfo, Error> {
    return (rollbackRustForegroundHasSideEffectTask(context: context, action: action) -->
            internalUpdateForegroundUserHasSideEffectTask(context: context, action: action))
}

//用于回滚处理
private func rollbackRustForegroundHasSideEffectTask(context: UniContextProtocol, action: PassportUserAction) -> Task<V4UserInfo, V4UserInfo, Error> {

    return Task(runnable: { userInfo in

        //校验新的前台用户session是有效的
        if userInfo.isAnonymous {
            //TODO: 上报埋点, 不阻塞
            assertionFailure("something wrong, please contact passport")
        }

        //userInfo 先更新到Passport Store，移除由对应的业务场景处理
        UserManager.shared.addUserToStore(userInfo)
        return SideEffect(success: userInfo)
    }) { _ in

        @Provider var activityCoordinator: MultiUserActivityCoordinatable

        switch action {
        case .switch:
            //有前台用户
            if let foregroundUser = UserManager.shared.foregroundUser {

                //监控上报
                PassportMonitor.monitor(PassportMonitorMetaMonad.rollbackForegroundUserStart,
                                        type: .common,
                                        context: context,
                                        categoryValueMap: ["action": action.rawValue]).flush()

                return SideEffect { successCallback, failCallback in
                    activityCoordinator.stateWillUpdate(MultiUserActivityState(action: action, toForegroundUserID: foregroundUser.userID)) { result in
                        switch result {
                        case .success():
                            //成功
                            PassportMonitor.monitor(PassportMonitorMetaMonad.rollbackForegroundUserResult,
                                                    type: .success,
                                                    context: context,
                                                    categoryValueMap: ["action": action.rawValue]).flush()

                            successCallback(())
                        case .failure(let error):
                            //回滚更新失败
                            PassportMonitor.monitor(PassportMonitorMetaMonad.rollbackForegroundUserResult,
                                                    type: .failure(error),
                                                    context: context,
                                                    categoryValueMap: ["action": action.rawValue]).flush()
                            failCallback(AccountError.switchUserRollbackError(rawError: error))
                        }
                    }
                }

            } else {
                //无前台用户不回滚
                return SideEffect(success: ())
            }
        //其他场景不回滚rust
        case .initialized, .fastLogin, .login, .logout:
            return SideEffect(success: ())
        case .settingsMultiUserUpdating:
            return SideEffect(success: ())
        @unknown default:
            return SideEffect(success: ())
        }
    }
}

//更新activity user list
private func internalUpdateForegroundUserHasSideEffectTask(context: UniContextProtocol, action: PassportUserAction) -> Task<V4UserInfo, V4UserInfo, Error> {

    return Task(runnable: { userInfo in

        @Provider var activityCoordinator : MultiUserActivityCoordinatable

        //监控
        PassportMonitor.monitor(PassportMonitorMetaMonad.updateForegroundUserStart,
                                type: .common,
                                context: context,
                                categoryValueMap: ["action": action.rawValue]).flush()

        //更新前台用户
        //refresh activity 操作
        return SideEffect { successCallback, failCallback in
            activityCoordinator.stateWillUpdate(MultiUserActivityState(action: action, toForegroundUserID: userInfo.userID)) { result in
                switch result {
                case .success():
                    //监控成功
                    PassportMonitor.monitor(PassportMonitorMetaMonad.updateForegroundUserResult,
                                            type: .success,
                                            context: context,
                                            categoryValueMap: ["action": action.rawValue]).flush()

                    successCallback(userInfo)
                case .failure(let error):
                    //更新失败
                    PassportMonitor.monitor(PassportMonitorMetaMonad.updateForegroundUserResult,
                                            type: .failure(error),
                                            context: context,
                                            categoryValueMap: ["action": action.rawValue]).flush()
                    failCallback(error)
                }
            }
        }
    }) { _ in
        //回滚由rollbackRustForegroundHasSideEffectTask方法处理
        return SideEffect(success: ())
    }
}
