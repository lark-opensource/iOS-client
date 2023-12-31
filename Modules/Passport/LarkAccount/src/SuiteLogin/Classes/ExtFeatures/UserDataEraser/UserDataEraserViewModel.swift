//
//  UserDataEraserViewModel.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import LarkContainer

class UserDataEraserViewModel {

    init() {}

    func eraseUserData(process: @escaping (Float) -> Void , completionHandler: @escaping (Result<Void, UserDataEraseError>) -> Void) {
        UserDataEraserHelper.shared.startEraseTask(progress: process, callback: completionHandler)
    }
}

class UserDataEraseResumeViewModel: UserDataEraserViewModel {
    override func eraseUserData(process: @escaping (Float) -> Void , completionHandler: @escaping (Result<Void, UserDataEraseError>) -> Void) {
        UserDataEraserHelper.shared.resumeEraseTask(progress: process, callback: completionHandler)
    }
}
