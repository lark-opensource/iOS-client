//
//  NewVoteDetailInfoViewModel.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/28.
//

import Foundation
import LarkVote
import Swinject
import RxSwift
import LarkContainer
import RxCocoa
import LarkMessengerInterface
import EENavigator
import LarkRustClient
import UniverseDesignToast
import LKCommonsLogging
import LarkSetting

final class NewVoteDetailInfoViewModel {

    // 分页参数
    private static let PageSize = 20
    // 非管理员最大可见数量
    private static let MaxVisibleCount = 100

    static let logger = Logger.log(NewVoteDetailInfoViewModel.self, category: "NewVoteDetailInfoViewModel")

    private let voteService: LarkVoteService

    private var voteID: Int
    private var index: Int
    private var scopeID: String
    private var datasource: [Voter] = []
    private let datasourceSubject = PublishSubject<[Voter]>()
    private let haveMoreSubject = PublishSubject<Bool>()
    weak var targetVC: NewVoteDetailInfoViewController?
    var chatID: String
    var initiator: String
    var isLimitBySecurity: Bool = false
    var haveMoreDriver: Driver<Bool> {
        return haveMoreSubject.asDriver(onErrorJustReturn: false)
    }
    var datasourceDriver: Driver<[Voter]> {
        return datasourceSubject.asDriver(onErrorJustReturn: [])
    }
    public let nav: Navigatable
    init(voteID: Int,
         index: Int,
         scopeID: String,
         initiatorID: String,
         chatID: String,
         voteService: LarkVoteService,
         nav: Navigatable) {
        self.voteID = voteID
        self.index = index
        self.scopeID = scopeID
        self.initiator = initiatorID
        self.chatID = chatID
        self.voteService = voteService
        self.nav = nav
    }

    func loadMore() {
        voteService.getVotedIndexInfo(
            voteID: self.voteID,
            index: self.index,
            startCuror: self.datasource.count,
            size: Self.PageSize,
            scopeID: self.scopeID,
            scopeType: .imChat).subscribe { [weak self] resp in
            guard let self = self else { return }
            Self.logger.info("\(self.voteID)>>> get voted index success with index >>>>>>\(self.index)")
            // 获取uid
            guard let votedIndexInfo = resp.votedIndexInfos.first(where: {
                return $0.votedIndexInfo.index == self.index
            }) else { return }
            let users = votedIndexInfo.votedIndexInfo.users ?? []
            // 获取chatter
            let chatters = resp.entity.chatChatters[self.scopeID]?.chatters ?? resp.entity.chatters
            if users.isEmpty || chatters.isEmpty {
                return
            }
            for userID in users {
                if let voter = chatters[String(userID)] {
                    self.datasource.append(voter)
                }
            }
            self.datasourceSubject.onNext(self.datasource)
            let haveMore = votedIndexInfo.paginated.hasMore_p
            self.isLimitBySecurity = votedIndexInfo.paginated.isLimitedBySecurity
            self.haveMoreSubject.onNext(haveMore)
        } onError: { [weak self] error in
            guard let self = self else { return }
            if case .businessFailure(errorInfo: let info) = error as? RCError {
                DispatchQueue.main.async {
                    if let window = self.targetVC?.view {
                        UDToast.showFailure(with: info.displayMessage, on: window)
                    }
                }
            }
            Self.logger.error("\(self.voteID)>>> get voted index info failed with index >>>>>>\(self.index), error>>> \(error)")
        }
    }
}
