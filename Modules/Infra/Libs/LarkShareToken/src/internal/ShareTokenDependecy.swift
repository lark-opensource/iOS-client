//
//  ShareTokenDependecy.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/14.
//

import Foundation
import LarkRustClient
import LarkContainer

//import LarkAccountInterface
//
//struct ShareTokenDependecy {
//    @Provider var rustServive: RustService
//    @Provider var accountService: AccountService
//
//    var shareTokenAPI: ShareTokenAPI {
//        let shareTokenAPI = ShareTokenAPIImp(client: self.rustServive)
//        return shareTokenAPI
//    }
//
//    var currentAccountIsEmpty: Bool {
//        return self.accountService.currentAccountIsEmpty
//    }
//
//    init() {}
//}
