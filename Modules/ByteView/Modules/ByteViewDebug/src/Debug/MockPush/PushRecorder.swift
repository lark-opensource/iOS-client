//
//  PushRecorder.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/19.
//

import Foundation
import LarkRustClient
import RustPB
import ByteViewNetwork
import SwiftProtobuf

extension BinaryDecodingOptions {
    static let discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

class PushRecorder {
    private var userID: String {
        DebugConfig.shared.userId
    }
    private let lock = NSLock()
    private let replayQueue = DispatchQueue(label: "vc.push-replay")
    private var frameWriter: FramedWriter?
    private var replayToken: CancelToken?
    func handleMessage(_ packet: RustPushPacket<Data>) {
        lock.lock()
        guard let writer = self.frameWriter else {
            lock.unlock()
            return
        }
        lock.unlock()
        writer.appendMessage(cmd: packet.cmd.rawValue, payload: packet.payload)
    }
    func startRecord(writeHandle: FileHandle) {
        lock.lock()
        self.frameWriter = FramedWriter(fileHandle: writeHandle)
        lock.unlock()
    }

    func stopRecord() {
        lock.lock()
        self.frameWriter = nil
        lock.unlock()
    }

    func dispatchMsg(_ msg: FramedMessage, meetingID: String) throws {
        guard let command = Command(rawValue: msg.header.cmd) else {
            return
        }
        if command == .pushMeetingParticipantChange {
            var pb = try Videoconference_V1_MeetingParticipantChange(serializedData: msg.payload, options: .discardUnknownFieldsOption)
            pb.meetingID = meetingID
            Push.participantChange.consumePacket(PushPacket(userId: userID, contextId: "", command: .rust(command), message: MeetingParticipantChange(pb: pb)))
        } else if command == .pushMeetingInfo {
            var pb = try Videoconference_V1_InMeetingUpdateMessage(serializedData: msg.payload, options: .discardUnknownFieldsOption)
            pb.meetingID = meetingID
            Push.fullParticipants.consumePacket(PushPacket(userId: userID, contextId: "", command: .rust(command), message: InMeetingUpdateMessage(pb: pb)))
        }
    }

    class CancelToken {
        private let lock = NSLock()
        private var _isCancelled: Bool = false
        var isCancelled: Bool {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isCancelled
        }

        func cancel() {
            lock.lock()
            defer {
                lock.unlock()
            }
            _isCancelled = true
        }
    }

    func playNextMessage(handle: FileHandle,
                         firstMsgTime: Date,
                         meetingID: String,
                         token: CancelToken) throws {
        guard !token.isCancelled,
              let msg = try FramedMessage.from(handle) else {
            return
        }
        let elapsed = Int(msg.header.elapsedMS) - Int(1000 * Date().timeIntervalSince(firstMsgTime))
        self.replayQueue.asyncAfter(deadline: .now() + .milliseconds(max(elapsed, 1))) {
            if token.isCancelled {
                return
            }
            do {
                try self.dispatchMsg(msg, meetingID: meetingID)
                try self.playNextMessage(handle: handle,
                                         firstMsgTime: firstMsgTime,
                                         meetingID: meetingID,
                                         token: token)
            } catch {
                log("play next recorded message failed: \(error)")
            }
        }

    }

    func startReplay(readHandle: FileHandle, meetingID: String) throws {
//        guard let handle = FileHandle(forReadingAtPath: path) else {
//            throw PushDebugError.openFileFailed
//        }
        self.replayToken?.cancel()
        let cancelToken = CancelToken()
        self.replayToken = cancelToken
        try playNextMessage(handle: readHandle,
                            firstMsgTime: Date(),
                            meetingID: meetingID,
                            token: cancelToken)
    }

    func stopReplay() {
        self.replayToken?.cancel()
        self.replayToken = nil
    }
}
