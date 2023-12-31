//
//  VoteMembersVM.swift
//  SKCommon
//
//  Created by zhysan on 2022/9/13.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation
import SwiftyJSON
import SKInfra

enum VoteMemberError: Error {
    case request(_ error: Error)
    case decode(_ error: Error?)
    case inner(_ msg: String)
    case noMore
}

class VoteMembersViewModel {
    // MARK: - public vars
    
    private(set) var members: [DocVote.VoteMember] = []
    
    private(set) var voteTotalCount: Int64?
    
    // MARK: - private vars
    
    private let optionContext: DocVote.OptionContext
    
    private var latestOffset: String
    private let defaultOffset: String = ""
    
    private var voteRequest: DocsRequest<JSON>?
    
    // MARK: - lifecycle
    
    init(optionContext: DocVote.OptionContext) {
        self.optionContext = optionContext
        self.latestOffset = optionContext.offset ?? defaultOffset
        self.voteTotalCount = optionContext.voteCount
    }
    
    deinit {
        voteRequest?.cancel()
    }
    
    // MARK: - public funcs
    
    /// Load more vote members, need to be called in main thread
    /// - Parameter completion: callback in main thread
    func updateVoteMembers(_ completion: @escaping (VoteMemberError?) -> Void) {
        if let total = voteTotalCount, members.count >= total {
            completion(.noMore)
            return
        }
        let path = OpenAPI.APIPath.pollOptionData
        var param: [String: Any] = [
            "page_id": optionContext.pageId,
            "block_id": optionContext.blockId,
            "option_id": optionContext.optionId,
            "offset": latestOffset
        ]
        
        if optionContext.isVoteDesc {
            param["sort"] = "vote_time_desc"
        }
        
        DocsLogger.info("[VOTE] loadMoreVoteMembers start!")
        
        voteRequest?.cancel()
        voteRequest = DocsRequest<JSON>(path: path, params: param)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: true)
        
        voteRequest?.start { [weak self] object, error in
            guard let self = self else {
                DocsLogger.error("[VOTE] VoteMembersViewModel dealloced")
                DispatchQueue.main.async {
                    completion(.inner("VoteMembersViewModel dealloced"))
                }
                return
            }
            if let error = error {
                DocsLogger.error("[VOTE] loadMoreVoteMembers error", error: error)
                DispatchQueue.main.async {
                    completion(.request(error))
                }
                return
            }
            guard let json = object else {
                DocsLogger.error("[VOTE] loadMoreVoteMembers failed: no json object!")
                DispatchQueue.main.async {
                    completion(.decode(nil))
                }
                return
            }
            do {
                let data = try json["data"]["data"].rawData()
                let model = try JSONDecoder().decode(DocVote.OptionData.self, from: data)
                DocsLogger.info("[VOTE] loadMoreVoteMembers success, incrase count: \(model.votes.count)")
                DispatchQueue.main.async {
                    // NOTE: update data in main thread
                    self.latestOffset = model.offsetStr ?? self.defaultOffset
                    self.voteTotalCount = model.count
                    self.members += model.votes
                    completion(nil)
                }
            } catch let err {
                DocsLogger.error("[VOTE] loadMoreVoteMembers decode error", error: err)
                DispatchQueue.main.async {
                    completion(.decode(err))
                }
            }
        }
    }
}
