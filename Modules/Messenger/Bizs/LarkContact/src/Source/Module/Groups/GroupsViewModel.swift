//
//  GroupsViewModel.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/10/12.
//

import Foundation
import LarkModel
import RxSwift
import RxRelay
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import LarkFeatureGating

final class GroupsViewModel {
    static let logger = Logger.log(GroupsViewModel.self, category: "Module.IM.GroupsViewModel")

    struct Cursor {
        var value: Int = 0
        var isLocal = false
        var currentIsLocal: Bool?
        var isEnd = false
    }
    private var createChatsSet: Set<String> {
        Set(createdGroupsVariable.value.map({ $0.id }))
    }
    private let createdGroupsVariable = BehaviorRelay<[Chat]>(value: [])
    private var joinedChatsSet: Set<String> {
        Set(joinedGroupsVariable.value.map({ $0.id }))
    }
    private let joinedGroupsVariable = BehaviorRelay<[Chat]>(value: [])
    private var myJoinGroupCursor = Cursor()
    private var myManageGroupCursor = Cursor()

    lazy var createdGroupsObservable: Observable<[Chat]> = self.createdGroupsVariable.asObservable()
    lazy var joinedGroupsObservable: Observable<[Chat]> = self.joinedGroupsVariable.asObservable()

    var pageCount = 30
    let userAPI: UserAPI
    let currentTenantId: String
    let currentUserType: AccountUserType
    private var apprecibleTrackFlag = true
    let chatId: String?

    init(userAPI: UserAPI,
         currentTenantId: String,
         chatId: String?,
         currentUserType: AccountUserType) {
        self.userAPI = userAPI
        self.currentTenantId = currentTenantId
        self.chatId = chatId
        self.currentUserType = currentUserType
    }

    func trackEnterContactGroups() {
        // 进入我的群组页面埋点
        Tracer.trackEnterContactGroups()
    }

    func trackClickEnterChat(groupId: String) {
        Tracer.trackClickEnterChat(groupId: groupId)
    }

    func trackClickGroupSegment(segment: String) {
        Tracer.trackClickGroupSegment(segment: segment)
    }

    func loadData() -> Observable<Void> {
        return Observable.merge(firstLoadManageGroup(), firstLoadJoinGroup())
    }

    func firstLoadManageGroup() -> Observable<Void> {
        let localOb = userAPI.getMyGroup(
            type: .administrate,
            nextCursor: myManageGroupCursor.value,
            count: pageCount,
            strategy: .local
        )
        let serverOb = userAPI.getMyGroup(
            type: .administrate,
            nextCursor: myManageGroupCursor.value,
            count: pageCount,
            strategy: .forceServer
        )
        return Observable.merge(localOb.materialize().map { (false, $0) },
                                serverOb.materialize().map { (true, $0) })
            .map({ [weak self] (isRemote, element) in
                guard let self = self else { return }
                switch element {
                case .next(let res):
                    if isRemote {
                        Self.logger.info("firstLoadManageGroup server accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
                        self.myManageGroupCursor = Cursor(
                            value: res.nextCursor,
                            isLocal: true,
                            currentIsLocal: true,
                            isEnd: res.hasMore
                        )
                        self.createdGroupsVariable.accept(res.chats)
                    } else if self.myManageGroupCursor.currentIsLocal == nil { // 避免本地比远端提前回来的case
                        Self.logger.info("firstLoadManageGroup local accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
                        self.myManageGroupCursor = Cursor(
                            value: res.nextCursor,
                            isLocal: false,
                            currentIsLocal: false,
                            isEnd: res.hasMore
                        )
                        self.createdGroupsVariable.accept(res.chats)
                    }
                    Self.logger.info("firstLoadManageGroup server faster than local")
                default:
                    break
                }
            })
    }

    func loadMoreManageGroup() -> Observable<Bool> {
        let serverOb = userAPI.getMyGroup(
            type: .administrate,
            nextCursor: myManageGroupCursor.value,
            count: pageCount,
            strategy: .forceServer
        )
        return serverOb.map { [weak self] res -> Bool in
            guard let self = self else { return true }

            Self.logger.info("loadMoreManageGroup server accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
            var temp = self.createdGroupsVariable.value
            temp.append(contentsOf: self.filterCreateChats(res.chats))
            self.myManageGroupCursor.value = res.nextCursor
            self.createdGroupsVariable.accept(temp)
            return !res.hasMore
        }
    }

    func firstLoadJoinGroup() -> Observable<Void> {
        let localOb = userAPI.getMyGroup(
            type: .join,
            nextCursor: myJoinGroupCursor.value,
            count: pageCount,
            strategy: .local
        )
        let serverOb = userAPI.getMyGroup(
            type: .join,
            nextCursor: myJoinGroupCursor.value,
            count: pageCount,
            strategy: .forceServer
        )
        return Observable.merge(localOb.materialize().map { (false, $0) },
                                serverOb.materialize().map { (true, $0) })
            .map({ [weak self] (isRemote, element) in
                guard let self = self else { return }
                switch element {
                case .next(let res):
                    if isRemote {
                        Self.logger.info("firstLoadJoinGroup server accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
                        self.myJoinGroupCursor = Cursor(
                            value: res.nextCursor,
                            isLocal: true,
                            currentIsLocal: true,
                            isEnd: res.hasMore
                        )
                        self.joinedGroupsVariable.accept(res.chats)
                    } else if self.myJoinGroupCursor.currentIsLocal == nil { // 避免本地比远端提前回来的case
                        Self.logger.info("firstLoadJoinGroup local accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
                        self.myJoinGroupCursor = Cursor(
                            value: res.nextCursor,
                            isLocal: false,
                            currentIsLocal: false,
                            isEnd: res.hasMore
                        )
                        self.joinedGroupsVariable.accept(res.chats)
                    }
                    Self.logger.info("firstLoadManageGroup server faster than local")
                default:
                    break
                }
            })
    }

    func loadMoreJoinGroup() -> Observable<Bool> {
        let serverOb = userAPI.getMyGroup(
            type: .join,
            nextCursor: myJoinGroupCursor.value,
            count: pageCount,
            strategy: .forceServer
        )
        return serverOb.map { [weak self] res -> Bool in
            guard let self = self else { return true }

            Self.logger.info("loadMoreJoinGroup server accept, chatsCount = \(res.chats.count), has more: \(res.hasMore)")
            var temp = self.joinedGroupsVariable.value
            temp.append(contentsOf: self.filterJoinedChats(res.chats))
            self.myJoinGroupCursor.value = res.nextCursor
            self.joinedGroupsVariable.accept(temp)
            return !res.hasMore
        }
    }

    private func filterCreateChats(_ chats: [Chat]) -> [Chat] {
        return chats.filter { (chat) -> Bool in
            return !self.createChatsSet.contains(chat.id)
        }
    }

    private func filterJoinedChats(_ chats: [Chat]) -> [Chat] {
        return chats.filter { (chat) -> Bool in
            return !self.joinedChatsSet.contains(chat.id)
        }
    }
}
