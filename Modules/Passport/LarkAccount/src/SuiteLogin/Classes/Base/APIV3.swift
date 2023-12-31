//
//  APIV3.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/17.
//

import Foundation
import LarkContainer
import LKCommonsLogging

class APIV3 {

    static let logger = Logger.plog(APIV3.self, category: "LarkAccount.APIV3")

    @Provider var client: HTTPClient

    init() {}
}
