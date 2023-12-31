//
//  DriveSDKIMLocalCacheServiceImpl.swift
//  CCMMod
//
//  Created by zenghao on 2023/12/11.
//

import Foundation
#if MessengerMod
    import LarkMessengerInterface
    import LarkSDKInterface
#endif
import LarkContainer
import RxSwift
import SKFoundation
import SpaceInterface
import Swinject
import LarkStorage

// 调用外部注入的本地文件预览能力，目前仅支持调用mail注入的eml预览能力，后续可扩展
class DriveSDKIMLocalCacheServiceImpl: DriveSDKIMLocalCacheServiceProtocol {
    private let resolver: Resolver?
    private var disposeBag = DisposeBag()

    init(resolver: Resolver?) {
        self.resolver = resolver
    }

    func getIMCache(fileID _: String, msgID: String, complete: @escaping (URL?) -> Void) {
        #if MessengerMod
            guard let r = resolver else {
                spaceAssertionFailure("resolver is nil")
                return complete(nil)
            }

            guard let messageAPI = r.resolve(MessageAPI.self) else {
                spaceAssertionFailure("DriveSDKIMLocalCacheServiceImpl: no MessageAPI impl")
                return complete(nil)
            }

            guard let fileMessageInfoService = r.resolve(FileMessageInfoService.self) else {
                spaceAssertionFailure("DriveSDKIMLocalCacheServiceImpl: no FileMessageInfoService impl")
                return complete(nil)
            }

            messageAPI.fetchLocalMessage(id: msgID)
                .subscribe(onNext: { message in
                    let messageInfo = fileMessageInfoService.getFileMessageInfo(message: message, downloadFileScene: nil)
                    let isFileExist = messageInfo.isFileExist
                    let fileLocalURL = messageInfo.safeLocalFilePath()

                    DocsLogger.info("DriveSDKIMLocalCacheServiceImpl get local message", extraInfo: ["isFileExist": isFileExist,
                                                                                                     "fileLocalURL": fileLocalURL])
                    if isFileExist {
                        complete(URL(fileURLWithPath: fileLocalURL.absoluteString))
                    } else {
                        complete(nil)
                    }

                }, onError: { error in
                    DocsLogger.warning("DriveSDKIMLocalCacheServiceImpl get local message failed: \(error)")
                    return complete(nil)
                }).disposed(by: disposeBag)
        #else
            return complete(nil)
        #endif
    }
}
