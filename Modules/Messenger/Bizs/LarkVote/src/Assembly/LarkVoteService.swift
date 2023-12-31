//
//  LarkVoteService.swift
//  LarkVote
//
//  Created by bytedance on 2022/4/18.
//

import Foundation
import RustPB
import RxSwift

public typealias VoteScopeType = Vote_V1_VoteScopeType

public protocol LarkVoteService {

    func sendAction(voteID: Int, scopID: String, params: [Int]) -> Observable<RustPB.Vote_V1_VoteResponse>

    func resendAction(voteID: Int) -> Observable<RustPB.Vote_V1_CloseVoteResponse>

    func closeAction(voteID: Int) -> Observable<RustPB.Vote_V1_CloseVoteResponse>

    func getVotedIndexInfo(voteID: Int, index: Int, startCuror: Int, size: Int, scopeID: String?, scopeType: VoteScopeType) -> Observable<RustPB.Vote_V1_GetVotedIndexInfoResponse>
}
