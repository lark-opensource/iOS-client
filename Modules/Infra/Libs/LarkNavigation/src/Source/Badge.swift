//
//  Badge.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/2/18.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LKCommonsLogging
import LarkContainer

final class RustAccountBadgeAPI {

    private var client: RustService?
    private let userResolver: UserResolver
    static private let logger = Logger.log(RustAccountBadgeAPI.self)

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.client = try? userResolver.resolve(assert: RustService.self)
    }

    public func getAccountBadge() -> Observable<RustPB.Basic_V1_GetAccountBadgeResponse> {
        guard let client = self.client else { return .empty() }
        let request = RustPB.Basic_V1_GetAccountBadgeRequest()
        return client.sendAsyncRequest(request)
            .do(onNext: { (response) in
                RustAccountBadgeAPI.logger.info("userBadgeMap: \(response.userBadgeMap)")
            }, onError: { error in
                RustAccountBadgeAPI.logger.error("Get userBadgeMap failed.", error: error)
            })
    }

    public func updateRustClientTimeZone(timeZone: String) -> Observable<Settings_V1_UpdateTimezoneResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_UpdateTimezoneRequest()
        request.timezone = timeZone
        return client.sendAsyncRequest(request)
            .do(onNext: { _ in
                RustAccountBadgeAPI.logger.info("updateRustClientTimeZone: \(timeZone)")
            }, onError: { error in
                RustAccountBadgeAPI.logger.error("updateRustClientTimeZone failed.", error: error)
            })
    }
}
