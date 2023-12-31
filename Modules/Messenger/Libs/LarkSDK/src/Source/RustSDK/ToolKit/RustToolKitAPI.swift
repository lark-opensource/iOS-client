//
//  RustToolKitAPI.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/6/21.
//

import RustPB
import RxSwift
import ServerPB
import Foundation
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging

final class RustToolKitAPI: LarkAPI, ToolKitAPI, UserResolverWrapper {
    static private let logger = Logger.log(RustToolKitAPI.self, category: "LarkSDK")
    @ScopedInjectedLazy private var rustService: RustService?

    let userResolver: UserResolver
    init(userResolver: UserResolver, client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.userResolver = userResolver
        super.init(client: client, onScheduler: onScheduler)
    }
}

extension RustToolKitAPI {
    // 拉取小组件实体
    func pullChatToolKitsRequest(chatId: String) -> Observable<PullChatToolKitsResponce> {
        var request = RustPB.Im_V1_GetChatToolkitsRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 触发小组件点击回调
    func toolKitActionRequest(cid: String,
                              userId: Int64,
                              appTenantID: Int64,
                              chatId: Int64,
                              toolKitId: Int64,
                              extra: [String: String]) -> Observable<ToolKitActionResponce> {
        var request = ServerPB.ServerPB_Im_oapi_ToolKitActionRequest()
        request.cid = cid
        request.userID = userId
        request.appTenantID = appTenantID
        request.chatID = chatId
        request.toolkitID = toolKitId
        request.extra = extra
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .toolkitAction) ?? .empty()
    }
}
