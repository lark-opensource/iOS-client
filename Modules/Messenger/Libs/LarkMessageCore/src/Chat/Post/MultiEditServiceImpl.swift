//
//  MultiEditService.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/8/10.
//

import UIKit
import Foundation
import LarkFoundation
import LarkMessengerInterface
import LarkSDKInterface
import LarkSendMessage
import RustPB
import RxSwift
import RxCocoa
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface

final class MultiEditServiceImpl: MultiEditService, UserResolverWrapper {
    let userResolver: UserResolver

    private static let logger = Logger.log(MultiEditServiceImpl.self, category: "LarkMessageCore.Chat.Post")

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var fileAPI: SecurityFileAPI?
    @ScopedInjectedLazy var videoSendService: VideoMessageSendService?
    @ScopedInjectedLazy var sendingManager: SendingMessageManager?
    @ScopedInjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func multiEditMessage(messageId: Int64, chatId: String, type: Basic_V1_Message.TypeEnum,
                          richText: Basic_V1_RichText, title: String?, lingoInfo: Basic_V1_LingoOption) -> Observable<RustPB.Basic_V1_RichText> {
        return messageAPI?.multiEditMessage(messageId: messageId,
                                            chatId: chatId,
                                            type: type,
                                            richText: richText,
                                            title: title,
                                            lingoInfo: lingoInfo) { [weak self] media in
            guard let self = self else { return }
            self.sendingManager?.add(task: media.key)
            self.videoSendService?.transcode(key: media.key,
                                            form: media.originPath,
                                            to: media.compressPath,
                                            isOriginal: false,
                                            videoSize: CGSize(width: CGFloat(media.width), height: CGFloat(media.height)),
                                            extraInfo: [:],
                                            progressBlock: nil,
                                            dataBlock: nil,
                                            retryBlock: nil)
            .subscribe(onNext: { [weak self] arg in
                self?.sendingManager?.remove(task: media.key)
                // 只处理转码成功的状态
                guard case .finish = arg.status else {
                    return
                }

                let compressPath = media.compressPath
                let fileName = String(URL(string: compressPath)?.path.split(separator: "/").last ?? "")
                let fileSize = try? FileUtils.fileSize(compressPath)
                sendVideoCache(userID: self?.userResolver.userID ?? "").saveFileName(
                    fileName,
                    size: Int(fileSize ?? 0)
                )
                self?.uploadMedia(uploadID: media.mediaUploadID, chatID: chatId, filePath: compressPath)
            }, onError: { [weak self] error in
                self?.sendingManager?.remove(task: media.key)
                self?.cancelAsyncUpload(uploadId: media.mediaUploadID)
                Self.logger.error("videoSendService transcode error: \(error), uploadID: \(media.mediaUploadID)")
            }).disposed(by: self.disposeBag)
        } ?? .empty()
    }

    private func uploadMedia(uploadID: String, chatID: String, filePath: String) {
        self.fileAPI?.uploadResource(uploadID: uploadID,
                                              chatID: chatID,
                                              filePath: filePath,
                                              fileType: .media)
        .subscribe(onNext: { _ in },
                   onError: { error in
            Self.logger.error("uploadMedia error: \(error), uploadID: \(uploadID)")
        }).disposed(by: self.disposeBag)
    }

    private func cancelAsyncUpload(uploadId: String) {
        self.fileAPI?.cancelAsyncUpload(uploadIds: [uploadId])
            .subscribe(onNext: { _ in },
                       onError: { error in
                Self.logger.error("cancelAsyncUpload error: \(error), uploadID: \(uploadId)")
            }).disposed(by: self.disposeBag)
    }

    func reloadEditEffectiveTimeConfig() {
        tenantUniversalSettingService?.loadTenantMessageConf(forceServer: true, onCompleted: nil)
    }
}
