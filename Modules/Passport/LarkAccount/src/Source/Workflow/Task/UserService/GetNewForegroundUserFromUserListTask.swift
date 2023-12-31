//
//  getNewForegroundUserFromUserListTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/16.
//

import LarkAccountInterface

func getNewForegroundUserFromUserListTask(context: UniContextProtocol) -> Task<[V4UserInfo], V4UserInfo, Error> {
    return Task(runnable: { userList in

        if let userInfo = userList.first {
            return SideEffect(success: userInfo)
        } else {
            return SideEffect(failure: AccountError.notFoundTargetUser)
        }
    }) { _ in
        //无回滚逻辑，直接透传
        return SideEffect(success: ())
    }
}
