//
//  RustDisposableLoginConfigAPI.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/2/5.
//

import Foundation
import LKCommonsLogging
import RustPB
import LarkRustClient
import RxSwift
import LarkContainer

class RustDisposableLoginConfigAPI: DisposableLoginConfigAPI {
    static let logger = Logger.plog(RustDisposableLoginConfigAPI.self, category: "LarkAccount.RustDisposableLoginConfigAPI")

    private let rustService: RustService
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver?) throws {
        let r: UserResolver = resolver ?? PassportUserScope.getCurrentUserResolver() // user:current
        self.rustService = try r.resolve(assert: RustService.self)
    }

    func getDisposableLoginConfig() -> Observable<[Int: String]> {
        let request = RustPB.Basic_V1_GetAppConfigRequest()
        return rustService.sendAsyncRequest(request, transform: { (response: RustPB.Basic_V1_GetAppConfigResponse) -> [Int: String] in
            var result: [Int: String] = [:]
            let regexesMap =  response.appConfig.urlRegex.regexes
            for (k, v) in regexesMap {
                result[Int(k)] = v
            }
            return result
        }).subscribeOn(MainScheduler.instance)
    }
}
