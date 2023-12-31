//
//  saveUserListHasSideEffectTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/16.
//

import Foundation

func saveUserListHasSideEffectTask(context: UniContextProtocol) -> Task<[V4UserInfo], [V4UserInfo], Error> {
    return Task(runnable: { userList in
        UserManager.shared.setEnterAppUserList(userList)
        return SideEffect(success: userList)
    }) { state in
        UserManager.shared.removeUsersWithoutAddHiddenUser(by: state.0.compactMap{$0.userID})
        return SideEffect(success: ())
    }
}
