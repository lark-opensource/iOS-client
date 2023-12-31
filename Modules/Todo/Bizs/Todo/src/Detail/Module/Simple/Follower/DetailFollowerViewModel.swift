//
//  DetailFollowerViewModel.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/4.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface

/// Detail - Follower - ViewModel

final class DetailFollowerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewData: BehaviorRelay<DetailFollowerViewDataType>

    /// 是否可以添加关注者
    var canAddFollow: Bool { store.state.permissions.follower.isEditable }

    private let store: DetailModuleStore
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?

    private var currentUserId: String { userResolver.userID }

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        self.rxViewData = .init(value: FollowerViewData(avatars: [], countText: ""))
    }

    func setup() {
        setupViewData()
    }

}

// MARK: - ViewData

extension DetailFollowerViewModel {
    private struct FollowerViewData: DetailFollowerViewDataType {
        var avatars: [AvatarSeed]
        var countText: String
    }

    private func setupViewData() {
        store.rxValue(forKeyPath: \.followers)
            .startWith(store.state.followers)
            .observeOn(MainScheduler.instance)
            .map { followers -> FollowerViewData in
                let followers = followers.lf_unique(by: \.identifier)
                let countText: String
                if followers.count > 1 {
                    countText = I18N.Todo_Task_NumFollower(followers.count)
                } else if followers.count == 1 {
                    countText = followers[0].name
                } else {
                    countText = ""
                }
                return .init(avatars: followers.map(\.avatar), countText: countText)
            }
            .bind(to: rxViewData)
            .disposed(by: disposeBag)
    }
}

// MARK: - Pick Followers

extension DetailFollowerViewModel {

    typealias ViewActionCallback = (UserResponse<Void>) -> Void

    func pickFollowersContext() -> (chatId: String?, selectedChatterIds: [String]) {
        let chatId = store.state.scene.chatId
        let chatterIds = store.state.followers.compactMap { $0.asUser()?.chatterId }
        return (chatId, chatterIds)
    }

    func appendPickedFollowers(by chatterIds: [String], callback: ViewActionCallback?) {
        guard !chatterIds.isEmpty else {
            callback?(.success(void))
            return
        }
        Detail.Track.clickAddFollower(with: store.state.todo?.guid ?? "")
        fetchApi?.getUsers(byIds: chatterIds)
            .map { $0.map { Follower(member: .user(User(pb: $0))) } }
            .take(1)
            .asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] followers in
                    self?.store.dispatch(.appendFollowers(followers), callback: callback)
                },
                onError: { callback?(.failure(Rust.makeUserError(from: $0))) }
            )
            .disposed(by: disposeBag)

        Detail.tracker(
            .todo_task_follow,
            params: [
                "source": store.state.scene.isForCreating ? "create" : "edit",
                "task_id": store.state.scene.todoId ?? ""
            ]
        )
    }

}

// MARK: - List Followers

extension DetailFollowerViewModel: MemberListViewModelDependency {
    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) { }
    func listFollowersContext() -> (input: MemberListViewModelInput, dependency: MemberListViewModelDependency) {
        let state = store.state
        let input = MemberListViewModelInput(
            todoId: state.todo?.guid ?? "",
            todoSource: state.todo?.source ?? .todo,
            chatId: state.scene.chatId,
            scene: state.scene.isForCreating ? .creating_follower : .editing_follower,
            selfRole: state.selfRole,
            canEditOther: state.permissions.follower.isEditable,
            members: state.followers.map { $0.asMember() }
        )
        return (input: input, dependency: self)
    }

    // MARK: MemberListViewModelDependency

    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: ((UserResponse<Void>) -> Void)?) {
        guard store.state.permissions.follower.isEditable else {
            completion?(.success(void))
            return
        }
        let followers = members.map(Follower.init(member:))
        Detail.Track.clickAddFollower(with: store.state.todo?.guid ?? "")
        store.dispatch(.appendFollowers(followers), callback: completion)
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: ((UserResponse<Void>) -> Void)?) {
        let followers = members.map(Follower.init(member:))
        guard !followers.isEmpty else {
            completion?(.success(void))
            return
        }

        Detail.Track.clickDeleteFollower(with: store.state.todo?.guid ?? "")
        if store.state.permissions.follower.isEditable {
            store.dispatch(.removeFollowers(followers), callback: completion)
        } else {
            guard followers.count == 1, followers[0].asUser()?.chatterId == currentUserId else {
                assertionFailure()
                completion?(.success(void))
                return
            }
            store.dispatch(.updateFollowing(false), onState: nil, callback: completion)
        }
    }

}
