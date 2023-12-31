//
//  SwitchUserTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/16.
//

import LarkContainer
import LarkAccountInterface

func fastSwitchUserTask(context: UniContextProtocol, additionInfo: SwitchUserContextAdditionInfo? = nil) -> Task<V4UserInfo, Void, Error> {

    @Provider var newSwitchUserService: NewSwitchUserService

    return Task(runnable: { userInfo in
        return SideEffect { successCallback, failCallback in
            newSwitchUserService.fastSwitch(userInfo: userInfo, complete: { result in
                if result == true {
                    successCallback(())
                } else {
                    failCallback(AccountError.suiteLoginError(errorMessage: "switch user failed"))
                }
            }, additionInfo: additionInfo, context: context)
        }
    }) { _ in
        //无回滚逻辑，直接透传
        return SideEffect(success: ())
    }
}
