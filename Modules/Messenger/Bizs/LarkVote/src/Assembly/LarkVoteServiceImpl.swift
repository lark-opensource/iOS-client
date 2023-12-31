//
//  LarkVoteServiceImpl.swift
//  LarkVote
//
//  Created by bytedance on 2022/4/18.
//

import Foundation
import Swinject
import RxSwift
import RustPB
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkContainer

final class LarkVoteServiceImpl: LarkVoteService {

    private let resolver: UserResolver

    private static let logger = Logger.log(LarkVoteService.self, category: "LarkVote")

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func sendAction(voteID: Int, scopID: String, params: [Int]) -> Observable<RustPB.Vote_V1_VoteResponse> {
        var request = RustPB.Vote_V1_VoteRequest()
        request.voteID = Int64(voteID)
        request.scopeID = scopID
        request.indexes = params.map({ Int64($0) })
        let rustService = try? resolver.resolve(assert: RustService.self)
        Self.logger.info("Send vote action with voteID: \(voteID), params: \(params)")
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }

    func resendAction(voteID: Int) -> Observable<RustPB.Vote_V1_CloseVoteResponse> {
        var request = RustPB.Vote_V1_RetransmitVoteRequest()
        request.voteID = Int64(voteID)
        let rustService = try? resolver.resolve(assert: RustService.self)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_VOTE_CARD_CLICK, params: ["click": "resend_to_chat", "vote_id": "\(voteID)", "target": "none"]))
        Self.logger.info("resend vote action with voteID: \(voteID)")
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }

    func closeAction(voteID: Int) -> Observable<RustPB.Vote_V1_CloseVoteResponse> {
        var request = RustPB.Vote_V1_CloseVoteRequest()
        request.voteID = Int64(voteID)
        let rustService = try? resolver.resolve(assert: RustService.self)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_VOTE_CARD_CLICK, params: ["click": "end_vote", "vote_id": "\(voteID)", "target": "none"]))
        Self.logger.info("close vote action with voteID: \(voteID)")
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }

    func getVotedIndexInfo(voteID: Int, index: Int, startCuror: Int, size: Int, scopeID: String?, scopeType: VoteScopeType) -> Observable<RustPB.Vote_V1_GetVotedIndexInfoResponse> {
        var request = RustPB.Vote_V1_GetVotedIndexInfoRequest()
        request.voteID = Int64(voteID)
        var paginate = RustPB.Vote_V1_Paginate()
        paginate.startCursor = Int64(startCuror)
        paginate.size = Int32(size)
        var paginateIndex = RustPB.Vote_V1_PaginateIndex()
        paginateIndex.index = Int64(index)
        paginateIndex.paginate = paginate
        request.indexes = [paginateIndex]
        request.scopeID = scopeID ?? ""
        request.scopeType = scopeType
        let rustService = try? resolver.resolve(assert: RustService.self)
        Self.logger.info("Get vote index info action with voteID: \(voteID), index: \(index), startCuror: \(startCuror), size: \(size)")
        return rustService?.sendAsyncRequest(request) ?? .empty()
    }
}
