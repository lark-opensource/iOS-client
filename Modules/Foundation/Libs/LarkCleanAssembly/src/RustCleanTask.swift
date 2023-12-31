//
//  RustCleanTask.swift
//  LarkCleanAssembly
//
//  Created by 7Up on 2023/7/9.
//

import Foundation
import LarkClean
import LarkRustClient
import RustPB
import RxSwift
import LarkContainer

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.RustSdk")
    public static func registerRustCleanTask() {
        registerTask(forName: "RustSdk") { context, subscriber in
            guard let rustClient = Container.shared.resolve(GlobalRustService.self) else {
                Self.logger.error("missing GlobalRustService")
                #if DEBUG || ALPHA
                fatalError("resolve GlobalRustService failed")
                #else
                subscriber.receive(completion: .finished)
                return
                #endif
            }

            var userInfo = Basic_V1_EraseUserDataRequest.EraseUserInfo()
            userInfo.userIds = context.userList.compactMap { user -> UInt64? in UInt64(user.userId) }
            if userInfo.userIds.count != context.userList.count {
                logger.error("unexpected. uid1: \(context.userList.map(\.userId)), uid2\(userInfo.userIds)")
            }
            var req =  RustPB.Basic_V1_EraseUserDataRequest()
            req.userIds = userInfo
            logger.info("rust sdk begin erase. userIds: \(userInfo.userIds)")
            let disposable = rustClient
                .sendAsyncRequest(req) { (_: Basic_V1_EraseUserDataResponse) -> Void in () }
                .subscribe(
                    onNext: {
                        Self.logger.info("rust sdk end erase without error")

                        #if !LARK_NO_DEBUG
                        if DebugSwitches.rustCleanFail {
                            subscriber.receive(completion: .failure(DebugCleanError("mock fail switch enabled")))
                            return
                        }
                        #endif

                        subscriber.receive(completion: .finished)
                    },
                    onError: { err in
                        Self.logger.info("rust sdk end erase with error: \(err)")
                        subscriber.receive(completion: .failure(err))
                    }
                )
            DispatchQueue.global().asyncAfter(deadline: .now() + LarkClean.kTaskTimeout) {
                disposable.dispose()
            }
        }
    }
}
