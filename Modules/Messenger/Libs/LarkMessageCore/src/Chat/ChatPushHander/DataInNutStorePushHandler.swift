//
//  DataInSpaceStorePushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class DataInSpaceStorePushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return DataInSpaceStorePushHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class DataInSpaceStorePushHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushSaveToSpaceStoreState.self)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(messageIds: [push.messageId], doUpdate: { (data) -> PushData? in
                    if var content = data.message.content as? FileContent {
                        content.isInMyNutStore = (push.state == .success)
                        data.message.content = content
                        return data
                    }
                    return nil
                })
            }).disposed(by: disposeBag)
    }
}
