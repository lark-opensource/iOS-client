//
//  DataResetViewModel.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation

class DataResetViewModel {

    func startResetData(completionHandler: @escaping (Bool) -> Void) {
        UserDataEraserHelper.shared.resetAllData(completionHandler)
    }
}
