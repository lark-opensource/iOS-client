//
//  SpecialFocusListViewModel.swift
//  LarkContact
//
//  Created by panbinghua on 2021/11/2.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkModel
import LarkContainer

protocol ISpecialFocusListViewModel {
    func fetchMemberList()
    var memberList: Driver<[Chatter]?> { get }
    var idsOfSelfAndFocusing: Driver<[String]> { get }
    func subscribeChatters(ids: [String]) -> Observable<Void>
    func unsubscribeChatters(ids: [String]) -> Observable<Void>
}

final class SpecialFocusListViewModel: ISpecialFocusListViewModel, UserResolverWrapper {
    private let disposeBag = DisposeBag()
    private let fetchAction = PublishRelay<Void>()
    var userResolver: LarkContainer.UserResolver
    // 依赖
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    // output
    let memberList: Driver<[Chatter]?>

    init(resolver: UserResolver) {
        self.userResolver = resolver
        let chatterList = BehaviorRelay<[Chatter]?>(value: nil)
        memberList = chatterList.asDriver(onErrorJustReturn: [])
        fetchAction.flatMapLatest { [chatterAPI] in
            chatterAPI?.getSpecialFocusChatterList() ?? .just([])
        }
        .subscribe(onNext: {
            ContactLogger.shared.info(module: .special, event: "get special focus chatter", parameters: "\($0.map { $0.id })")
            chatterList.accept($0)
        }, onError: { _ in chatterList.accept([]) })
        .disposed(by: disposeBag)
        chatterAPI?.pushFocusChatter.subscribe(onNext: { msg in
            let chatters = (chatterList.value ?? [])
            ContactLogger.shared.info(module: .special, event: "push message", parameters: "chatters: \(chatters.map { $0.id }), add: \(msg.addChatters.map { $0.id }), delete: \(msg.deleteChatterIds)")
            // 新增的星标联系人有可能重复, 做一下去重, 避免出现两个同样的联系人
            var uniqueAddChatters = [Chatter]()
            for chatter in msg.addChatters {
                let notTnChatters = !chatters.contains(where: { $0.id == chatter.id })
                let notRepeat = !uniqueAddChatters.contains(where: { $0.id == chatter.id })
                if notTnChatters && notRepeat { // 已经在星标联系人里, 就不需要重复添加了
                    uniqueAddChatters.append(chatter)
                }
            }
            let listAfterAdd = chatters + uniqueAddChatters
            let listAfterDelete = listAfterAdd.filter { !msg.deleteChatterIds.contains($0.id) }
            chatterList.accept(listAfterDelete)
        }).disposed(by: disposeBag)
    }

    func fetchMemberList() {
        fetchAction.accept(())
    }

    var idsOfSelfAndFocusing: Driver<[String]> {
        let me = chatterManager?.currentChatter.id ?? ""
        return memberList.map { list -> [String] in
            guard let list = list else { return [me] }
            return list.map { $0.id } + [me]
        }
    }

    func subscribeChatters(ids: [String]) -> Observable<Void> {
        guard let chatterAPI = self.chatterAPI else { return .just(Void()) }
        let chatterIDs = ids.map { Int64($0) }.compactMap { $0 }
        return chatterAPI.updateSpecialFocusStatus(to: chatterIDs, operate: .add)
            .map { _ in () }
    }

    func unsubscribeChatters(ids: [String]) -> Observable<Void> {
        guard let chatterAPI = self.chatterAPI else { return .just(Void()) }
        let chatterIDs = ids.map { Int64($0) }.compactMap { $0 }
        return chatterAPI.updateSpecialFocusStatus(to: chatterIDs, operate: .delete)
            .map { _ in () }
    }
}
