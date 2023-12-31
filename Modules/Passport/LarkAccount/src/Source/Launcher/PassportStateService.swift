//
//  PassportStateService.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/8/8.
//

import Foundation
import LarkAccountInterface
import RxSwift
import RxRelay
import LarkContainer
import LKCommonsLogging
import EEAtomic

protocol PassportStateService {
    var state: Observable<PassportState> { get }

    func updateState(newState: PassportState)
}

class PassportStateServiceImpl: PassportStateService {
    private let logger = Logger.plog(PassportStateService.self, category: "PassportStateService")

    var state: Observable<PassportState> {
        return _state.asObservable()
    }

    private var _state = BehaviorRelay<PassportState>(value: PassportState(user: nil, loginState: .offline, action: .initialized))

    private var lock = UnfairLockCell()

    deinit { lock.deallocate() }

    private func resetUserStorage(_ currentUserID: String) {
        lock.withLocking {
            UserStorageManager.shared.makeStorage(userID: currentUserID)
            UserStorageManager.shared.currentUserID = currentUserID // 当前用户的兼容逻辑
            UserStorageManager.shared.keepStorages { $0 == currentUserID }
        }
    }

    /// online: create container -> (Rust online) -> stateDidChange -> didOnline
    /// offline: stateDidChange -> didOffline -> (Rust offline) -> destroy container
    func updateState(newState: PassportState) {
        logger.info("n_action_state_will_update", body: "\(newState)")

        let factories = PassportDelegateRegistry.factories()

        switch newState.loginState {
        case .offline:

            _state.accept(newState)
            factories
                .map { $0.delegate }
                .forEach {
                    $0.stateDidChange(state: newState)
                    if newState.user != nil {
                        $0.userDidOffline(state: newState)
                    }
                }
            logger.info("n_action_state_did_update", body: "\(newState)")

            if newState.user == nil {
                // 目前为了兼容性，避免没有当前用户对应容器
                logger.info("n_action_state_offline_reset_container", body: "\(newState)")
                resetUserStorage(UserManager.placeholderUser.userID)
            }
        case .online:
            if let user = newState.user {

                // 创建容器
                logger.info("n_action_state_online_reset_container", body: "\(newState)")
                resetUserStorage(user.userID)

                _state.accept(newState)
                factories
                    .map { $0.delegate }
                    .forEach {
                        $0.stateDidChange(state: newState)
                        if newState.user != nil {
                            $0.userDidOnline(state: newState)
                        }
                    }
                logger.info("n_action_state_did_update", body: "\(newState)")

            } else {
                _state.accept(newState)
            }
        }
    }
}
