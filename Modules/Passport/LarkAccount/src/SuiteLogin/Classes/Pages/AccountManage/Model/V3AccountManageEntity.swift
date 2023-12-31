//
//  AccountManageEntity.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/5/7.
//

import Foundation
import LKCommonsLogging

class AccountMessage: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let code: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
    }

    init(code: Int?, message: String?) {
        self.code = code
        self.message = message
    }
}
