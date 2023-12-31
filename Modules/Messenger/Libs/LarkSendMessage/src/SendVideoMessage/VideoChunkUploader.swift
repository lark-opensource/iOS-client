//
//  VideoChunkUploader.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/1/8.
//

import Foundation
import LKCommonsLogging // Logger
import RustPB // Media_V1_ChunkyUploadRequest
import LarkRustClient // RequestPacket
import LarkSDKInterface // SDKRustService
import LarkContainer // InjectedLazy
import LarkModel // Message
import RxSwift // DisposeBag

public struct PushChunkyUploadStatus: PushMessage {
    public var uploadID: UInt64
    public var status: Media_V1_PushChunkyUploadStatusResponse.OneOf_Status?
    public init(
        uploadID: UInt64,
        status: Media_V1_PushChunkyUploadStatusResponse.OneOf_Status?
    ) {
        self.uploadID = uploadID
        self.status = status
    }
}

final class VideoChunkUploader {
    private static let logger = Logger.log(VideoChunkUploader.self, category: "Module.IM.VideoMessageSend")

    static let messageKey = "message"

    let uploadID: UInt64 = .random(in: 0...UInt64(UInt32.max))

    private var rustService: SDKRustService
    private var pushCenter: PushNotificationCenter

    /// cancel and  error
    var finishCallback: ((Bool, Error?) -> Void)?

    private(set) var uploading: Bool = false

    private(set) var finished: Bool = false

    private var message: LarkModel.Message?

    private var disposeBag = DisposeBag()

    init(userResolver: UserResolver) throws {
        self.rustService = try userResolver.resolve(assert: SDKRustService.self)
        self.pushCenter = try userResolver.userPushCenter
        Self.logger.info("video chunk uploader init \(self)")
    }

    deinit {
        Self.logger.info("video chunk uploader deinit \(self)")
    }

    func upload(task: TranscodeTask, data: Data, offset: Int64, size: Int32, isFinish: Bool, in queue: DispatchQueue) {
        guard !finished else { return }
        self.setupMessage(task: task)
        let request = self.uploadRequest(
            uploadID: self.uploadID,
            cid: message?.cid,
            chatID: message?.channel.id,
            data: data,
            offset: UInt64(offset),
            isFirst: self.uploading == false,
            isLast: isFinish
        )
        if !self.uploading {
            Self.logger.info("begin upload video chunk info uploadID \(self.uploadID)")
            self.uploading = true
            self.observePush()
        }
        if request.data.isFirst || request.data.isLast {
            Self.logger.info("send chunk request uploadID \(self.uploadID) isFirst \(request.data.isFirst), isLast \(request.data.isLast)")
        }
        self.send(request: request, in: queue)
    }

    func cancel(in queue: DispatchQueue) {
        guard !finished else { return }
        Self.logger.info("cancel chunky uploadID \(self.uploadID)")
        self.finish(cancel: true, error: nil)
        let request = self.cancelQequest(uploadID: self.uploadID, cid: message?.cid, chatID: message?.channel.id)
        self.send(request: request, in: queue)
    }

    private func finish(cancel: Bool, error: Error?) {
        Self.logger.info("finish chunky uploadID \(self.uploadID)")
        self.uploading = false
        self.finished = true
        if let finishCallback = self.finishCallback {
            finishCallback(cancel, error)
            self.finishCallback = nil
        }
        self.disposeBag = DisposeBag()
    }

    private func setupMessage(task: TranscodeTask) {
        guard message == nil else { return }
        if let message = task.extraInfo[Self.messageKey] as? LarkModel.Message {
            Self.logger.info("set up message cid \(message.cid)")
            self.message = message
        }
    }

    private func observePush() {
        pushCenter.observable(for: PushChunkyUploadStatus.self)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                guard push.uploadID == self.uploadID,
                      !self.finished else {
                    return
                }
                var rcError: Error?
                if let status = push.status {
                    switch status {
                    case .success:
                        Self.logger.info("receive video chunk upload success \(self.uploadID) cid \(self.message?.cid)")
                    case .error(let error):
                        Self.logger.error("receive video chunk upload failed \(self.uploadID) cid \(self.message?.cid) error \(error)")
                        rcError = NSError(domain: "video.send.chunky.error", code: Int(error.code), userInfo: ["error": error])
                    default:
                        break
                    }
                }
                self.finish(cancel: false, error: rcError)
            }).disposed(by: disposeBag)
    }

    /// 获取上传数据 request
    private func uploadRequest(
        uploadID: UInt64,
        cid: String?,
        chatID: String?,
        data: Data,
        offset: UInt64,
        isFirst: Bool,
        isLast: Bool
    ) -> Media_V1_ChunkyUploadRequest {
        var request = Media_V1_ChunkyUploadRequest()
        request.uploadID = uploadID
        if let cid = cid {
            request.cid = cid
        }
        if let chatID = chatID {
            request.chatID = chatID
        }
        var info = Media_V1_ChunkInfo()
        info.offset = offset
        info.isLast = isLast
        info.isFirst = isFirst
        info.chunk = data
        request.data = info
        return request
    }

    /// 获取 cancel request
    private func cancelQequest(
        uploadID: UInt64,
        cid: String?,
        chatID: String?
    ) -> Media_V1_ChunkyUploadRequest {
        var request = Media_V1_ChunkyUploadRequest()
        request.uploadID = uploadID
        if let cid = cid {
            request.cid = cid
        }
        if let chatID = chatID {
            request.chatID = chatID
        }
        request.cancel = 1
        return request
    }

    private func send(request: Media_V1_ChunkyUploadRequest, in queue: DispatchQueue) {
        queue.async { [weak self] in
            if let response: RustPB.Media_V1_ChunkyUploadResponse = try? self?.rustService.sendSyncRequest(request) {
                if response.code != .normal {
                    Self.logger.error("send request failed with code \(response.code)")
                    let error = NSError(domain: "video.send.chunky.error", code: response.code.rawValue, userInfo: nil)
                    self?.finish(cancel: false, error: error)
                }
            }
        }
    }
}
