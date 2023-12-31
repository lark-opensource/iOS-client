//
//  RobotViewModel.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/27.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RxRelay
import LarkSDKInterface

final class RobotViewModel {

    enum Status {
        case initial, empty, loading, loadedMore, finish, error
    }

    private let statusVariable = BehaviorRelay<Status>(value: .initial)
    private let robotsVariable = BehaviorRelay<[LarkModel.Chatter]>(value: [])
    private let userAPI: UserAPI
    private let chatAPI: ChatAPI

    lazy var statusObservable: Observable<Status> = self.statusVariable.asObservable()
    lazy var robotsObservable: Observable<[LarkModel.Chatter]> = self.robotsVariable.asObservable()

    private let disposeBag = DisposeBag()

    init(userAPI: UserAPI, chatAPI: ChatAPI) {
        self.userAPI = userAPI
        self.chatAPI = chatAPI
    }

    func isEmpty() -> Bool {
        return robotsVariable.value.isEmpty
    }

    func fetchLocalChatId(userId: String) -> Observable<String?> {
        return self.chatAPI.fetchLocalP2PChat(by: userId).map { $0?.id }
    }

    func trackEnterContactBots() {
        Tracer.trackEnterContactBots()
    }

    func loadRobotData() {
        self.statusVariable.accept(.loading)
        self.userAPI
            .pullBots(offset: Int32(self.robotsVariable.value.count), count: 20)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (robotsInfo) in
                guard let `self` = self else { return }
                if !robotsInfo.bots.isEmpty {
                    var temp = self.robotsVariable.value
                    temp += robotsInfo.bots
                    self.robotsVariable.accept(temp)
                }
                if robotsInfo.hasMore {
                    self.statusVariable.accept(.loadedMore)
                } else {
                    self.statusVariable.accept(self.robotsVariable.value.isEmpty ? .empty : .finish)
                }
            }, onError: { [weak self] (_) in
                self?.statusVariable.accept(.error)
            })
            .disposed(by: self.disposeBag)
    }
}
