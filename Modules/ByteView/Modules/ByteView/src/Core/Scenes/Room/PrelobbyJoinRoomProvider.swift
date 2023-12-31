//
//  PrelobbyJoinRoomProvider.swift
//  ByteView
//
//  Created by kiri on 2022/5/17.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import LarkMedia
import AVFoundation

final class PrelobbyJoinRoomProvider: JoinRoomTogetherViewModelProvider {
    let initialRoom: ByteviewUser?
    let shareCodeFilter: GetShareCodeInfoRequest.RoomBindFilter
    var meetingId: String
    let httpClient: HttpClient
    let isInMeet: Bool = false

    init(room: ByteviewUser?, filter: GetShareCodeInfoRequest.RoomBindFilter, meetingId: String, httpClient: HttpClient) {
        self.initialRoom = room
        self.shareCodeFilter = filter
        self.meetingId = meetingId
        self.httpClient = httpClient
    }

    func prepareScan(completion: @escaping () -> Void) {
        completion()
    }

    func resetAfterScan() { }

    func connectRoom(_ room: ByteviewUser, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(Void()))
    }

    func disconnectRoom(_ room: ByteviewUser?, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(Void()))
    }

    func fetchRoomInfo(_ room: ByteviewUser, completion: @escaping (ParticipantUserInfo) -> Void) {
        httpClient.participantService.participantInfo(pid: room, meetingId: meetingId, completion: completion)
    }

    var shouldDoubleCheckDisconnection: Bool { false }

    var popoverFrom: JoinRoomPopoverFrom { .prelobby }

    var isSharingContent: Bool { false }

    var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
