//
//  PushDebug.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/15.
//

import Foundation
import ByteView
import LarkStorage

enum PushDebugError: Error {
    case meetingIDNotFound
    case openFileFailed
}
class PushDebug {

    static let shared = PushDebug()
    private var mockParticipant: MockParticipantPush?
    private var mockWebinarAttendee: MockParticipantPush?
    private var mockWebinarPanelList: MockParticipantPush?
    let pushRecorder = PushRecorder()

    func pushDir() throws -> IsoPath {
        let pushDir = IsoPath
            .in(space: .global)
            .in(domain: Domain.biz.byteView)
            .build(.document)
            .appendingRelativePath("byteview-push-record")
        if !pushDir.exists {
            try pushDir.createDirectory(withIntermediateDirectories: true)
        }
        return pushDir
    }

    private init() {}

    func startRecordPush() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 3600 * 8)
        let filename = formatter.string(from: Date())

        do {
            let pushDir = try self.pushDir()
            let path = pushDir.appendingRelativePath("\(filename).push")
            if !path.exists {
                try path.createFile()
            }
            let handle = try path.fileWritingHandle()
            log("start record at \(path.absoluteString)")
            pushRecorder.startRecord(writeHandle: handle)
        } catch {
            log("failed start recording \(error)")
        }
    }

    func stopRecordPush() {
        pushRecorder.stopRecord()
    }

    func listRecordFiles() -> [IsoPath] {
        do {
            let pushDir = try self.pushDir()
            return try pushDir.subpathsOfDirectory_()
                .filter { item in
                    item.hasSuffix(".push")
                }
                .sorted {
                    $0 > $1
                }
                .map { filename in
                    pushDir.appendingRelativePath(filename)
                }
        } catch {
            return []
        }
    }

    func replayRecord(_ path: IsoPath) throws {
        guard let meetingID = self.currentMeetingId else {
            throw PushDebugError.meetingIDNotFound
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            do {
                let readHandle = try path.fileReadingHandle()
                try self.pushRecorder.startReplay(readHandle: readHandle, meetingID: meetingID)
                log("replay record at \(path.absoluteString), for meeting: \(meetingID)")
            } catch {
                log("failed replay record, \(error)")
            }
        }
    }

    func stopReplayRecord() {
        self.pushRecorder.stopReplay()
    }

    private var currentMeetingId: String? {
        MeetingObserver().currentMeeting?.meetingId
    }

    func mockPartricipantChanges(intervalMS: Int, maxCount: Int, upsertCount: Int, removeCount: Int) throws {
        guard let meetingID = self.currentMeetingId else {
            throw PushDebugError.meetingIDNotFound
        }
        self.mockParticipant?.stop()
        self.mockParticipant = MockParticipantPush(userID: DebugConfig.shared.userId, meetingID: meetingID, count: maxCount)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.mockParticipant?.start(intervalMS: intervalMS, changeCount: upsertCount, removeCount: removeCount)
        }
    }

    func stopMockParticipantChanges() {
        self.mockParticipant?.stop()
        self.mockParticipant = nil
    }

    func mockWebinarAttendeeChanges(intervalMS: Int, maxCount: Int, upsertCount: Int, removeCount: Int) throws {
        guard let meetingID = self.currentMeetingId else {
            throw PushDebugError.meetingIDNotFound
        }
        self.mockWebinarAttendee?.stop()
        self.mockWebinarAttendee = MockParticipantPush(userID: DebugConfig.shared.userId,
                                                       meetingID: meetingID,
                                                       pushType: .webinarAttendee,
                                                       count: maxCount)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.mockWebinarAttendee?.start(intervalMS: intervalMS,
                                            changeCount: upsertCount,
                                            removeCount: removeCount)
        }
    }

    func stopMockWebinarAttendeeChanges() {
        self.mockWebinarAttendee?.stop()
        self.mockWebinarAttendee = nil
    }

    func mockWebinarPanelListChanges(intervalMS: Int, maxCount: Int, upsertCount: Int, removeCount: Int) throws {
        guard let meetingID = self.currentMeetingId else {
            throw PushDebugError.meetingIDNotFound
        }
        self.mockWebinarPanelList?.stop()
        self.mockWebinarPanelList = MockParticipantPush(userID: DebugConfig.shared.userId,
                                                        meetingID: meetingID,
                                                        pushType: .webinarPanelList,
                                                        count: maxCount)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.mockWebinarPanelList?.start(intervalMS: intervalMS,
                                             changeCount: upsertCount,
                                             removeCount: removeCount)
        }
    }

    func stopMockWebinarPanelListChanges() {
        self.mockWebinarPanelList?.stop()
        self.mockWebinarPanelList = nil
    }

}
