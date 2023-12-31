//
//  ContactApplicationViewModel.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/8/15.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LKCommonsLogging
import LarkSDKInterface
import LarkAccountInterface
import LarkContainer
import LarkMessengerInterface
import AppReciableSDK

final class ContactApplicationViewModel: UserResolverWrapper {
    static let logger = Logger.log(ContactApplicationViewModel.self, category: "ContactApplicationViewModel")

    @ScopedInjectedLazy private var chatApplicationAPI: ChatApplicationAPI?
    private lazy var externalInviteAPI: ExternalInviteAPI = {
        return ExternalInviteAPI(resolver: self.userResolver)
    }()

    private let disposeBag = DisposeBag()

    private var datasource: [ChatApplication] = [] {
        didSet {
            self.datasourceSubject.onNext(datasource)
        }
    }
    private let hasMoreSubject = PublishSubject<Bool>()
    private let datasourceSubject = PublishSubject<[ChatApplication]>()
    private let pushDriver: Driver<PushChatApplicationGroup>
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService

    private var inviteService: UnifiedInvitationService

    var isCurrentAccountInfoSimple: Bool {
        return passportUserService.user.type == .simple
    }
    var hasInviteEntry: Bool {
        return inviteService.hasExternalContactInviteEntry()
    }

    private var cursor: String = "0"

    private var isLoading = false

    var hasMoreDriver: Driver<Bool> {
        return hasMoreSubject.asDriver(onErrorJustReturn: true)
    }

    var datasourceDriver: Driver<[ChatApplication]> {
        return datasourceSubject.asDriver(onErrorJustReturn: [])
    }

    init(pushDriver: Driver<PushChatApplicationGroup>, resolver: UserResolver) throws {
        self.pushDriver = pushDriver
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.inviteService = try resolver.resolve(assert: UnifiedInvitationService.self)
    }

    func preloadData() {
        loadMore()
        pushDriver
            .asObservable()
            .subscribe(onNext: { [weak self] (chatApplicationGroup) in
                guard let `self` = self else {
                    return
                }
                ContactApplicationViewModel.logger.info("Push好友申请成功 self cursor: \(self.cursor) count \(chatApplicationGroup.applications.count)")
                var datasource = self.datasource
                chatApplicationGroup.applications.forEach({ (application) in
                    if let index = datasource.firstIndex(where: { $0.id == application.id }) {
                        if application.status == .deleted {
                            ContactApplicationViewModel.logger.info("push friend deleted success")
                            datasource.remove(at: index)
                        } else {
                            let isShowCertSign = application.contactSummary.certificationInfo.isShowCertSign
                            let certificateStatus = application.contactSummary.certificationInfo.certificateStatus
                            let tenantNameStatus = application.contactSummary.tenantNameStatus
                            ContactApplicationViewModel.logger.info("push friend update success isShowCertSign: \(isShowCertSign) certificateStatus:\(certificateStatus) tenantNameStatus:\(tenantNameStatus)")
                            datasource[index] = application
                        }
                    } else if application.status != .deleted {
                        datasource.append(application)
                    }
                })
                self.datasource = datasource
            }, onError: { (error) in
                ContactApplicationViewModel.logger.error("Push好友申请失败", error: error)
            }).disposed(by: self.disposeBag)
    }

    func loadMore() {
        if isLoading {
            return
        }
        isLoading = true

        if !datasource.isEmpty {
            if let chatApplication = datasource.last {
                cursor = chatApplication.id
            }
        }
        Tracer.trackStartContactApplicationsTimingms()
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .contactOptFetchApplications,
                                              page: nil)
        let timeStamp = CACurrentMediaTime()
        self.chatApplicationAPI?.getChatApplications(cursor: cursor,
                                                    count: 20,
                                                    type: .friend,
                                                    getType: .before,
                                                    chatId: "")
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self, let chatApplicationAPI = self.chatApplicationAPI else {
                    return
                }
                NewContactsAppReciableTrack.updateNewContactSdkCost(CACurrentMediaTime() - timeStamp)
                ContactApplicationViewModel.logger.info("拉取好友申请成功 self cursor: \(self.cursor) count \(res.applications.count) hasMore\(res.hasMore)")
                self.isLoading = false
                if self.datasource.isEmpty {
                    ContactTracker.New.View(newCount: res.applications.count, resolver: self.userResolver)
                }
                self.datasource.append(contentsOf: res.applications)
                self.hasMoreSubject.onNext(res.hasMore)

                chatApplicationAPI.updateChatApplicationMeRead().subscribe(onNext: { _ in
                    ContactApplicationViewModel.logger.info("updateChatApplicationMeRead success")
                }, onError: { (error) in
                    ContactApplicationViewModel.logger.error("updateChatApplicationMeRead error", error: error)
                }).disposed(by: self.disposeBag)

                Tracer.trackEndContactApplicationsTimingms()
                AppReciableSDK.shared.end(key: key)
            }, onError: { (error) in
                NewContactsAppReciableTrack.newContactPageLoadError(error: error)
                ContactApplicationViewModel.logger.error("拉取好友申请失败", error: error)
                if let apiError = error.underlyingError as? APIError {
                    Tracer.trackNewContactApplicationsFetchFail(errorCode: apiError.code, errorMsg: "\(apiError)")
                    AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                    scene: .Contact,
                                                                    event: .contactOptFetchApplications,
                                                                    errorType: .Network,
                                                                    errorLevel: .Exception,
                                                                    errorCode: Int(apiError.code),
                                                                    userAction: nil,
                                                                    page: nil,
                                                                    errorMessage: apiError.serverMessage))
                }
            }).disposed(by: self.disposeBag)
    }

    func removeData(index: Int) {
        self.chatApplicationAPI?
            .processChatApplication(id: datasource[index].id, result: .deleted, authSync: false)
            .subscribe(onError: { (error) in
                ContactApplicationViewModel.logger.error("删除申请失败", error: error)
            }).disposed(by: self.disposeBag)
    }

    func agreeApplication(index: Int) -> Observable<Void> {
        guard let chatApplicationAPI = self.chatApplicationAPI else { return .just(Void()) }
        return chatApplicationAPI
            .processChatApplication(id: datasource[index].id, result: .agreed, authSync: false)
    }

    // 获取邀请信息
    func fetchInviteLinkInfo() -> Observable<InviteAggregationInfo> {
        return self.externalInviteAPI.fetchInviteAggregationInfoFromServer()
    }
}
