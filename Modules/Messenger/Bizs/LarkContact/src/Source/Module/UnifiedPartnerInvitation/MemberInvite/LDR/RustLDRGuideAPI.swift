//
//  RustLDRGuideAPI.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import Foundation
import RxSwift
import LarkContainer
import LarkRustClient
import ServerPB

final class RustLDRGuideAPI: LDRGuideAPI, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var rustService: RustService?
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func getLDRService() -> Observable<(GetLDRServiceAppLinkResponse)> {
        guard let rustService = self.rustService else { return .just(GetLDRServiceAppLinkResponse()) }
        let request = ServerPB_Flow_GetLDRServiceAppLinkRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getLdrServiceApplink)
    }

    func reportEvent(eventKeyList: [String]) -> Observable<(Void)> {
        guard let rustService = self.rustService else { return .just(Void()) }
        var request = ServerPB_Flow_BizEventReportRequest()
        request.eventKeyList = eventKeyList
        request.eventKey = ""
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .bizEventReport)
    }

    func getOperationLink() -> Observable<(GetOperationLinkResponse)> {
        guard let rustService = self.rustService else { return .just(GetOperationLinkResponse()) }
        let request = ServerPB_Retention_GetOperationLinkRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getRetentionOperationLink)
    }
}
