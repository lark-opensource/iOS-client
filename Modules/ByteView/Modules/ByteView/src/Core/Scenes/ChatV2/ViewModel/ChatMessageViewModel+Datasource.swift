//
//  ChatMessageViewModel+Datasource.swift
//  ByteView
//
//  Created by wulv on 2020/12/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension ChatMessageViewModel {

    static let countPerPage = 30

    func pullMessage(position: Int, isPrevious: Bool, count: Int) -> Observable<([VideoChatInteractionMessage], expiredMsgPosition: Int32?)> {
        let meetingId = meeting.meetingId
        let httpClient = self.httpClient
        let request = PullInteractionMessagesRequest(meetingId: meeting.data.meetingIdForRequest, position: Int32(position),
                                                     isPrevious: isPrevious, count: Int32(count), role: meeting.myself.meetingRole)
        return RxTransform.single {
            httpClient.getResponse(request, completion: $0)
        }.flatMap { rsp in
            Self.updateName(meetingId: meetingId, messages: rsp.messages, httpClient: httpClient)
                .map { ($0, rsp.expiredMsgPosition) }
        }.asObservable()
    }

    func sendMessage(message: MessageRichText?) -> Observable<VideoChatInteractionMessage> {
        let meetingId = meeting.meetingId
        let httpClient = self.httpClient
        var content: SendInteractionMessageRequest.Content
        if meeting.isE2EeMeeing {
            content = .encrypted(encrytMessage(message))
        } else {
            content = .text(message)
        }
        let request = SendInteractionMessageRequest(meetingId: meeting.data.meetingIdForRequest, content: content,
                                                    role: meeting.myself.meetingRole)
        return RxTransform.single {
            httpClient.getResponse(request, completion: $0)
        }.flatMap { response in
            let message = response.message
            return Self.updateName(meetingId: meetingId, messages: [message], httpClient: httpClient).map { $0.first ?? message }
        }.asObservable()
    }

    private static func updateName(meetingId: String, messages: [VideoChatInteractionMessage], httpClient: HttpClient) -> Single<[VideoChatInteractionMessage]> {
        var messages = messages
        let participantService = httpClient.participantService
        return Single.create { single -> Disposable in
            participantService.participantInfo(pids: messages.map { $0.fromUser }, meetingId: meetingId) { infos in
                if messages.count == infos.count {
                    for idx in 0..<messages.count {
                        messages[idx].fromUser.name = infos[idx].name
                    }
                }
                single(.success(messages))
            }
            return Disposables.create()
        }
    }

    func pullMessages() {
        let position: Int
        let isPrevious: Bool
        if let defaultPosition = defaultAutoScrollPosition {
            // 向前拉取，指定位置
            position = defaultPosition
            isPrevious = true
        } else if messagesStore.messagesAllUnread {
            // 全部未读，向后拉取，第一页
            position = 0
            isPrevious = false
        } else {
            // 上次读过，拉取前后15条消息
            let lastPosition = messagesStore.currentScanningPosition
            position = max(0, lastPosition - Self.countPerPage / 2)
            isPrevious = false
        }

        self.pullMessage(position: position, isPrevious: isPrevious, count: Self.countPerPage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                let pullMessages = messages.0.map { self.constructCellModel(with: $0) }
                self.messagesStore.append(messages: pullMessages)
                self.messagesStore.updateExpiredMsgPosition(position: messages.1)
            }).disposed(by: disposeBag)
    }

    func pullLatestMessage() {
        self.pullMessage(position: -1, isPrevious: false, count: 1)
            .map { ($0.0.map { self.constructCellModel(with: $0) }, $0.1) }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                self.messagesStore.updateLatestMessage(messages.0.first)
                self.messagesStore.updateExpiredMsgPosition(position: messages.1)
            }).disposed(by: disposeBag)
    }

    func pullLatestPage(afterNext: @escaping (([VideoChatInteractionMessage]) -> Void)) {
        self.pullMessage(position: -1, isPrevious: true, count: Self.countPerPage)
            .observeOn(MainScheduler.instance)
            .do(afterNext: { afterNext($0.0) })
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                let lastPageMessages = messages.0.map { self.constructCellModel(with: $0) }
                self.messagesStore.append(messages: lastPageMessages)
                self.messagesStore.updateExpiredMsgPosition(position: messages.1)
            })
            .disposed(by: disposeBag)
    }

    func loadMoreMessages(direction: LoadDirection,
                          onSubscribe: (() -> Void)?,
                          afterNext: (([VideoChatInteractionMessage]) -> Void)?) {
        if messagesStore.firstPosition == 0, direction.isPrevious {
            // 已到顶，没有更早的消息，无需拉取
            onSubscribe?()
            afterNext?([])
            return
        }
        var queryPosition = messagesStore.firstPosition - 1
        if let lastPosition = messagesStore.lastPosition, !direction.isPrevious {
            queryPosition = lastPosition + 1
        }
        self.pullMessage(position: queryPosition, isPrevious: direction.isPrevious, count: Self.countPerPage)
            .observeOn(MainScheduler.instance)
            .do(afterNext: { afterNext?($0.0) }, onSubscribe: onSubscribe)
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                let loadMessages = messages.0.map { self.constructCellModel(with: $0) }
                self.messagesStore.append(messages: loadMessages)
                self.messagesStore.updateExpiredMsgPosition(position: messages.1)
            }).disposed(by: disposeBag)
    }

    func sendMessage(content: String) {
        ChatTracks.trackSendMessage()
        guard let richText = createRichText(content: content) else { return }
        self.sendMessage(message: richText)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self = self, let message = self.dencrytMessageIfNeeded(message) else { return }
                let chatMessage = self.constructCellModel(with: message)
                self.messagesStore.send(message: chatMessage)
                self.listeners.forEach { $0.didSendMessage(chatMessage) }
            }, onError: { error in
                Self.logger.info("用户输入失败: \(error)")
                let vcError = error.toVCError()
                if vcError == .notComplyUserAgreement {
                    Toast.show(vcError.description)
                } else {
                    Toast.show(I18n.View_M_CouldNotSendMessage)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension ChatMessageViewModel {
    func createRichText(content: String) -> MessageRichText? {
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)
        guard !trimmedContent.isEmpty else { return nil }
        var richText = self.service.messenger.stringToRichText(.init(string: trimmedContent))
        if richText?.innerText.isEmpty ?? false {
            richText?.innerText = trimmedContent
        }
        return richText
    }

    func constructCellModel(with message: VideoChatInteractionMessage) -> ChatMessageCellModel {
        let message = dencrytMessageIfNeeded(message) ?? message

        let model = ChatMessageModel(message: message)
        let cellModel = ChatMessageCellModel(model: model,
                                             meeting: meeting,
                                             profileConfigEnabled: profileEnable)
        return cellModel
    }
}

extension ChatMessageViewModel {
    private enum EncryptBufSize {
        static var bufMultiple: Double = 1.2
        static var extraSize: Int = 64
    }

    private func encrytMessage(_ message: MessageRichText?) -> Data? {
        guard let message = message,
              let inMeetingKey = meeting.inMeetingKey,
              let key = inMeetingKey.e2EeKey.meetingKey,
              let data = try? message.serializedData() else {
            return nil
        }
        var encryptSize = Int(Double(data.count) * EncryptBufSize.bufMultiple + 1)
        encryptSize = max(encryptSize, data.count + EncryptBufSize.extraSize)
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: encryptSize + encryptSize / 2)

        let resault = lark_sdk_resource_encrypt_aead_seal(inMeetingKey.encryptAlgorithm.rustValue, key.bytes, inMeetingKey.length, data.bytes, data.count, buf, &encryptSize)
        if resault == ResourceEncryptResult(0) {
            return Data(bytesNoCopy: buf, count: encryptSize, deallocator: .none)
        } else {
            Self.logger.error("encrypt message with error: \(resault)")
            meeting.inMeetKeyManager?.handleEncryptError(Int(resault.rawValue), type: .chat, isEncrypt: true)
        }
        return nil
    }

    private func dencrytMessageIfNeeded(_ message: VideoChatInteractionMessage) -> VideoChatInteractionMessage? {
        var decryptedMessage = message
        if message.type == .encrypted {
            guard case .encryptedContent(let content) = message.content,
                  let inMeetingKey = meeting.inMeetingKey,
                  let key = inMeetingKey.e2EeKey.meetingKey  else {
                return nil
            }
            let data = content.content
            var dencryptSize = Int(Double(data.count) * EncryptBufSize.bufMultiple + 1)
            dencryptSize = max(dencryptSize, data.count + EncryptBufSize.extraSize)
            let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: dencryptSize + dencryptSize / 2)
            let resault = lark_sdk_resource_encrypt_aead_open(inMeetingKey.encryptAlgorithm.rustValue, key.bytes, inMeetingKey.length, data.bytes, data.count, buf, &dencryptSize)
            if resault == ResourceEncryptResult(0) {
                let dencryptedData = Data(bytesNoCopy: buf, count: dencryptSize, deallocator: .none)
                if let text = try? MessageRichText(serializedData: dencryptedData) {
                    decryptedMessage.type = .text
                    decryptedMessage.content = .textContent(TextMessageContent(content: text))
                } else {
                    return nil
                }
            } else {
                Self.logger.error("decrypt message with error: \(resault)")
                meeting.inMeetKeyManager?.handleEncryptError(Int(resault.rawValue), type: .chat, isEncrypt: false)
                return nil
            }
        }
        return decryptedMessage
    }
}

extension ChatMessageViewModel: InteractionMessagePushObserver {
    func didReceiveInteractionMessage(_ message: VideoChatInteractionMessage, expiredMsgPosition: Int32?) {
        if meeting.setting.isUseImChat { return }

        guard message.type == .text || message.type == .system || message.type == .encrypted, message.meetingID == meeting.data.meetingIdForRequest else {
            return
        }

        let participantService = httpClient.participantService
        participantService.participantInfo(pid: message.fromUser, meetingId: meeting.meetingId) { info in
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                var message = message
                message.fromUser.name = info.name
                let cellModel = self.constructCellModel(with: message)
                self.appendPushMessage(cellModel)
                self.messagesStore.updateExpiredMsgPosition(position: expiredMsgPosition)
                self.handleIfMessageNonsequence(cellModel: cellModel)
                self.listeners.forEach { $0.didReceiveNewUnreadMessage(cellModel) }
            }
        }
    }
}

extension ChatMessageViewModel: ChatMessageStoreDelegate {
    func newMessagesDidAppend(messages: [ChatMessageCellModel]) {
        Util.runInMainThread {
            self.listeners.forEach { $0.messagesDidChange(messages: messages) }
        }
    }

    func unreadMessageDidChange() {
        if meeting.setting.isUseImChat { return }
        Self.logger.info("Unread message changed to \(messagesStore.unreadMessageCount)")
        unreadCountRelay.accept(messagesStore.unreadMessageCount)
        Util.runInMainThread {
            self.listeners.forEach { $0.numberOfUnreadMessagesDidChange(count: self.messagesStore.unreadMessageCount) }
        }
    }
}
