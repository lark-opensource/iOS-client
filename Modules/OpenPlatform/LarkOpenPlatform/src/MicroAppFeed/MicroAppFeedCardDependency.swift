//
//  MicroAppFeedCardDependency.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2023/8/8.
//
#if MessengerMod
import Foundation
import RxSwift
import LarkContainer
import LarkRustClient
import RustPB

protocol MicroAppFeedCardDependency {
    func changeMute(feedId: String, to state: Bool) -> Single<Void>
}

final class MicroAppFeedCardDependencyImpl: MicroAppFeedCardDependency {
    let userResolver: UserResolver

    init(resolver: UserResolver) throws {
        userResolver = resolver
    }

    func changeMute(feedId: String, to state: Bool) -> Single<Void> {
        // 开启/关闭小程序的消息提醒
        guard let rustService = try? userResolver.resolve(assert: RustService.self) else {
            return .just(())
        }
        var request = RustPB.Openplatform_V1_SetAppNotificationSwitchRequest()
        request.appID = feedId
        request.notificationOn = state
        return rustService.sendAsyncRequest(request).map { _ in
        }.asSingle()
    }
}
#endif
