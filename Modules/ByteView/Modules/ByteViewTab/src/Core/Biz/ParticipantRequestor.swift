//
//  ParticipantRequestor.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/18.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import RxSwift

extension ParticipantService {
    func usersByIdsUsingCache(_ ids: [String]) -> Single<[ParticipantUserInfo]> {
        RxTransform.single(queue: .main) { completion in
            let pids = ids.map { ParticipantId(id: $0, type: .larkUser) }
            self.participantInfo(pids: pids, meetingId: "") { aps in
                completion(.success(aps))
            }
        }
    }

    func participantsByIdsUsingCache(_ pids: [ParticipantId], meetingId: String) -> Single<[ParticipantUserInfo]> {
        RxTransform.single(queue: .main) { completion in
            self.participantInfo(pids: pids, meetingId: meetingId, completion: { aps in
                completion(.success(aps))
            })
        }
    }

    func participantsByIdsUsingCache<T: ParticipantIdConvertible>(_ pids: [T], meetingId: String) -> Single<[ParticipantUserInfo]> {
        RxTransform.single(queue: .main) { completion in
            self.participantInfo(pids: pids, meetingId: meetingId, completion: { aps in
                completion(.success(aps))
            })
        }
    }

    func participantByIdUsingCache(_ pid: ParticipantId, meetingId: String) -> Single<ParticipantUserInfo?> {
        return participantsByIdsUsingCache([pid], meetingId: meetingId).map { $0.first }
    }

    func participantByIdUsingCache<T: ParticipantIdConvertible>(_ pid: T, meetingId: String) -> Single<ParticipantUserInfo?> {
        return participantsByIdsUsingCache([pid], meetingId: meetingId).map { $0.first }
    }
}
