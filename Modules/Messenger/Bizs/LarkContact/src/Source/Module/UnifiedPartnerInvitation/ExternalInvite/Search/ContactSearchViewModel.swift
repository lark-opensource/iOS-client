//
//  ContactSearchViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/25.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import Homeric

enum SearchState: Int {
    case inital
    case searching
    case hasResult
    case none       // Local fake search state, prompting the user to click to display the invitation map
    case noneNext   // The invitation map is displayed, and the user clicks to invite
}

enum SearchContentType: Int {
    case phone
    case email
}

final class ContactSearchViewModel: VerificationBaseViewModel {
    var type: SearchContentType = .phone
    var searchStateSubject: BehaviorRelay<SearchState> = BehaviorRelay(value: .inital)
    // 推荐添加的联系人，会从dataSource中单独拿出来
    var recommandUser: UserProfile?
    var dataSource: [UserProfile] = []
    let isOversea: Bool
    let fromEntrance: ExternalInviteSourceEntrance
    private let monitor = InviteMonitor()
    private let chatApplicationAPI: ChatApplicationAPI
    private var lastDisposable: Disposable?
    private var lastSearchKey: String?

    init(chatApplicationAPI: ChatApplicationAPI, isOversea: Bool, fromEntrance: ExternalInviteSourceEntrance) {
        self.chatApplicationAPI = chatApplicationAPI
        self.isOversea = isOversea
        self.fromEntrance = fromEntrance
        super.init(isOversea: isOversea)
    }

    func fetchSearchResult(_ searchKey: String) -> Observable<[UserProfile]> {
        if searchKey.isEmpty {
            lastDisposable?.dispose()
            searchStateSubject.accept(.inital)
            return .just([])
        }
        let type = distinguishSearchType(searchKey: searchKey)
        var validSearchContent = searchKey
        /// if type == .phone, get pure number within search content
        if type == .phone {
            validSearchContent = getPurePhoneNumber(searchKey)
            if validSearchContent.isEmpty {
                lastDisposable?.dispose()
                searchStateSubject.accept(.noneNext)
                return .just([])
            }
        }
        /// Avoid duplicate search for the same keyword
        guard validSearchContent != lastSearchKey else {
            if dataSource.isEmpty {
                self.searchStateSubject.accept(self.recommandUser == nil ? .noneNext : .hasResult)
            } else {
                self.searchStateSubject.accept(.hasResult)
            }
            return .just(dataSource)
        }
        lastSearchKey = validSearchContent
        searchStateSubject.accept(.searching)
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_SEARCH,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationSearch
        )
        return Observable.create({ (ob) -> Disposable in
            self.lastDisposable?.dispose()
            self.lastDisposable = self.chatApplicationAPI
                .searchUserWithActiveUser(contactContent: validSearchContent)
                .observeOn(MainScheduler.instance)
                .do(onNext: { [weak self] (_) in
                    self?.monitor.endEvent(
                        name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_SEARCH,
                        indentify: String(startTimeInterval),
                        category: ["succeed": "true"],
                        extra: [:],
                        reciableState: .success,
                        reciableEvent: .externalOrientationSearch
                    )
                }, onError: { [weak self] (error) in
                    if let apiError = error.underlyingError as? APIError {
                        self?.monitor.endEvent(
                            name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_SEARCH,
                            indentify: String(startTimeInterval),
                            category: ["succeed": "false",
                                       "error_code": apiError.code],
                            extra: ["error_msg": apiError.localizedDescription],
                            reciableState: .failed,
                            reciableEvent: .externalOrientationSearch
                        )
                    }
                })
                .subscribe(onNext: { [weak self] (userProfiles, activeUserID) in
                    let uids = userProfiles.map { $0.userId }
                    ContactLogger.shared.info(module: .addExternalContact, event: "fetch external contacts success", parameters: "user = \(uids), active = \(activeUserID)")
                    self?.type = type
                    self?.dataSource = userProfiles
                    self?.filterRecommandedUser(activeUserID)
                    if userProfiles.isEmpty {
                        self?.searchStateSubject.accept(.noneNext)
                    } else {
                        self?.searchStateSubject.accept(.hasResult)
                    }
                    ob.onNext(userProfiles)
                }, onError: { [weak self] error in
                    self?.type = type
                    self?.searchStateSubject.accept(.noneNext)
                    ContactLogger.shared.error(module: .addExternalContact, event: "fetch external contacts success", parameters: "\(error.localizedDescription)")
                    ob.onNext([])
                    ob.onError(error)
                })
            return Disposables.create()
        }).observeOn(MainScheduler.instance)
    }

    func filterRecommandedUser(_ activeUserID: String) {
        var idx = -1
        for i in 0..<dataSource.count where dataSource[i].userId == activeUserID {
            idx = i
            recommandUser = dataSource[i]
            break
        }
        if idx != -1 {
            dataSource.remove(at: idx)
        } else {
            recommandUser = nil
        }
    }
}

private extension ContactSearchViewModel {
    func distinguishSearchType(searchKey: String) -> SearchContentType {
        if searchKey.contains("@") { return .email } else { return .phone }
    }
}
