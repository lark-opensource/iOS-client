//
//  FileMessageNoAuthorizePushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class FileMessageNoAuthorizePushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return FileMessageNoAuthorizePushHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class FileMessageNoAuthorizePushHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushFileUnauthorized.self)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(messageIds: [push.messageId], doUpdate: { (data) -> PushData? in
                    if data.message.type == .file || data.message.type == .folder {
                        data.message.isFileDeleted = (push.fileDeletedStatus != .normal)
                        data.message.fileDeletedStatus = push.fileDeletedStatus
                        return data
                    }
                    return nil
                })
            }).disposed(by: disposeBag)
    }
}
