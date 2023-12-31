//
//  SelectionExternalContactsViewModel.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/7/26.
//

import Foundation
import LKCommonsLogging
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkModel
import RustPB

final class SelectionExternalContactsViewModel {
    private static let logger = Logger.log(SelectionExternalContactsViewModel.self, category: "SelectionExternalContactsViewModel")

    public let externalContactsAPI: ExternalContactsAPI
    public let chatAPI: ChatAPI
    private let disposeBag = DisposeBag()

    private var datasource: [NewSelectExternalContact] = [] {
        didSet {
            self.datasourceSubject.onNext(datasource)
        }
    }

    private let hasMoreSubject = PublishSubject<Bool>()
    private let datasourceSubject = PublishSubject<[NewSelectExternalContact]>()
    private let pushDriver: Driver<NewPushExternalContactsWithChatterIds>
    private var offset = 0
    // 分页数
    private var pageSize = 20
    private var isLoading = false
    private let chatID: String?
    private let actionType: RustPB.Basic_V1_Auth_ActionType?
    private(set) var chattersIdsInChat: [String] = []

    var hasMoreDriver: Driver<Bool> {
        return hasMoreSubject.asDriver(onErrorJustReturn: true)
    }
    var datasourceDriver: Driver<[NewSelectExternalContact]> {
        return datasourceSubject.asDriver(onErrorJustReturn: [])
    }

    init(
        chatID: String?,
        actionType: RustPB.Basic_V1_Auth_ActionType?,
        externalContactsAPI: ExternalContactsAPI,
        chatAPI: ChatAPI,
        pushDriver: Driver<NewPushExternalContactsWithChatterIds>
    ) {
        self.externalContactsAPI = externalContactsAPI
        self.chatAPI = chatAPI
        self.pushDriver = pushDriver
        self.chatID = chatID
        self.actionType = actionType
    }

    func preloadData(onError: @escaping (Error) -> Void) {
        loadMore(onError: onError)

        pushDriver
            .asObservable()
            .flatMap { [weak self] (response) -> Observable<[NewSelectExternalContact]> in
                guard let self = self else {
                    return Observable.just([])
                }
                let selectExternalContacts = response.selectExternalContacts
                SelectionExternalContactsViewModel.logger.info("获取 contact 成功 offset \(self.offset) count \(selectExternalContacts.count) hasMore \(String(describing: response.hasMore))")

                self.chattersIdsInChat += response.chatterIDs

                return Observable<[NewSelectExternalContact]>.just(selectExternalContacts)
            }
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else {
                    return
                }
                self.datasource.append(contentsOf: response)
            }, onError: { (error) in
                SelectionExternalContactsViewModel.logger.error("拉取外部联系人失败", error: error)
            }).disposed(by: self.disposeBag)
    }

    func loadMore(onError: @escaping (Error) -> Void) {
        if isLoading {
            return
        }
        isLoading = true
        if !datasource.isEmpty {
            offset = datasource.count
        }

        self.externalContactsAPI.fetchExternalContactsWithCollaborationAuth(
            with: chatID,
            actionType: actionType,
            offset: offset,
            count: pageSize
        ).flatMap { [weak self] (response) -> Observable<[NewSelectExternalContact]> in
            guard let self = self else {
                return Observable.just([])
            }
            let selectExternalContacts = response.selectExternalContacts
            SelectionExternalContactsViewModel.logger.info("获取 contact 成功 offset \(self.offset) count \(selectExternalContacts.count) hasMore \(String(describing: response.hasMore))")
            self.chattersIdsInChat += response.chatterIDs
            self.isLoading = false
            self.hasMoreSubject.onNext(response.hasMore)
            return Observable<[NewSelectExternalContact]>.just(selectExternalContacts)
        }
        .subscribe(onNext: { [weak self] (response) in
            guard let self = self else {
                return
            }
            self.datasource.append(contentsOf: response)
        }, onError: { (error) in
            SelectionExternalContactsViewModel.logger.error("拉取外部联系人失败", error: error)
            onError(error)
        }).disposed(by: self.disposeBag)
    }
}
