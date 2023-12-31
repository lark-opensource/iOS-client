//
//  NewExternalContactsViewModel.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import ThreadSafeDataStructure
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import RustPB

final class NewExternalContactsViewModel {
    static let logger = Logger.log(NewExternalContactsViewModel.self, category: "ExternalContacts")

    private let externalContactsAPI: ExternalContactsAPI
    var externalInviteEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "invite.union.enable")
            && userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
    }

    private let disposeBag = DisposeBag()

    private var datasource: [ContactInfo] = [] {
        didSet {
            self.datasourceSubject.onNext(datasource)
        }
    }
    // 首次加载本地数据是否完成
    private(set) var localRequestFinished: Bool = false
    // 首次加载服务端数据是否完成
    private(set) var serverRequestFinished: Bool = false

    private var allContactData: [ContactInfo] = []

    private(set) var hasMore: Bool = false
    private let datasourceSubject: BehaviorSubject<[ContactInfo]> = BehaviorSubject<[ContactInfo]>(value: [])
    let pageSize: Int = 20
    private var isLoading = false

    var datasourceObservable: Observable<[ContactInfo]> {
        // 跳过默认值
        return datasourceSubject.skip(1).asObservable().observeOn(MainScheduler.instance)
    }
    private let pushDriver: Driver<PushNewExternalContacts>
    private let userResolver: UserResolver
    private let passportUserService: PassportUserService
    private var inviteService: UnifiedInvitationService

    var isCurrentAccountInfoSimple: Bool {
        return passportUserService.user.type == .simple
    }
    var hasInviteEntry: Bool {
        return inviteService.hasExternalContactInviteEntry()
    }

    private var apprecibleTrackFlag = true

    init(externalContactsAPI: ExternalContactsAPI,
         pushDriver: Driver<PushNewExternalContacts>,
         resolver: UserResolver) throws {
        self.externalContactsAPI = externalContactsAPI
        self.pushDriver = pushDriver
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.inviteService = try resolver.resolve(assert: UnifiedInvitationService.self)
    }

    /// 1. preload all data in cache
    /// 2. judge count of size, page 20
    /// 3. load more of next page
    /// @params strategy: 拉取策略，支持本地local和server
    /// @params loadAll: 是否全部展示，否则按pageSize展示
    /// @params ignoreLoading: 是否忽略loading拦截
    func loadData(loadAll: Bool? = false) {
        // fetch for server
        fetchNewExternalData(strategy: .forceServer, loadAll: loadAll, ignoreLoading: true)
        // fetch SDK data first
        fetchNewExternalData(strategy: .local, loadAll: loadAll, ignoreLoading: true)
    }

    // loading策略：默认开始loading
    // 1.1 server 先到 - server接口成功 - 隐藏loading，显示空提示页
    // 1.2 server 先到 - server接口报错 - 隐藏loading，显示报错
    // 2.  local 先到 - local接口成功，并有数据 - 隐藏loading，并显示
    // 3.  其他，不处理
    func fetchNewExternalData(strategy: RustPB.Basic_V1_SyncDataStrategy,
                                   loadAll: Bool? = false,
                                   ignoreLoading: Bool = false) {
        NewExternalContactsViewModel.logger.debug("get NewExternalContacts",
                                                  additionalData: [
                                                    "isServer": "\(strategy == .forceServer)",
                                                    "loadAll": "\(String(describing: loadAll))",
                                                    "ignoreLoading": "\(ignoreLoading)"
                                                  ])

        if isLoading && (!ignoreLoading) { return }
        isLoading = true
        Tracer.trackStartExternalFetchTimingMs()
        let disposeKey = Tracer.trackStartAppReciableExternalFetchTimingMs()
        let startTime = CACurrentMediaTime()
        // 请求API
        self.externalContactsAPI.getNewExternalContactList(strategy: strategy, offset: nil, limitCount: nil)
            .subscribe(onNext: { [weak self] newExternalContacts in
                guard let self = self else { return }
                var shouldReloadData: Bool = false
                // 更新请求状态
                switch strategy {
                case .forceServer:
                    self.serverRequestFinished = true
                    // 如果server请求成功，需要刷新数据
                    shouldReloadData = true
                case .local:
                    self.localRequestFinished = true
                    // 如果server还未返回,local先请求成功，local数据不为空，则刷新
                    if !self.serverRequestFinished,
                       !newExternalContacts.contactInfos.isEmpty {
                        shouldReloadData = true
                    }
                @unknown default: break
                }

                self.allContactData = newExternalContacts.contactInfos
                if let showAll = loadAll, showAll {
                    if shouldReloadData {
                        self.datasource = self.allContactData
                        self.hasMore = false
                    }
                } else {
                    // first page
                    self.datasource = [ContactInfo](self.allContactData.prefix(self.pageSize))
                    self.hasMore = true
                    self.tryToTrackAppreciblePoint(cost: CACurrentMediaTime() - startTime,
                                                   memberCount: self.datasource.count)
                }
                Tracer.trackFetchExternalUserCount(count: self.allContactData.count)
                NewExternalContactsViewModel.logger.debug("获取 contact 成功",
                                                          additionalData: [
                                                            "allContactData count": "\(self.allContactData.count)",
                                                            "isServer": "\(strategy == .forceServer)"
                                                          ])
                Tracer.trackEndExternalFetchTimingMs()
                Tracer.trackEndAppReciableExternalFetchTimingMs(disposeKey: disposeKey)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }

                    // 更新请求状态
                    switch strategy {
                    case .forceServer:
                        self.serverRequestFinished = true
                        // server接口报错, 如果本地还未完成 / 数据为空，隐藏loading，显示报错
                        if !self.localRequestFinished || self.datasource.isEmpty {
                            self.datasourceSubject.onError(error)
                        }
                    case .local:
                        self.localRequestFinished = true
                        // local接口报错, 等server处理
                    @unknown default: break
                    }

                    if let error = error.underlyingError as? APIError {
                        Tracer.trackFetchExternalFailed(errorCode: error.code, errorMsg: error.debugDescription)
                        ExternalContactsAppReciableTrack.externalContactsPageError(isNewPage: true, errorCode: Int(error.code))
                    } else {
                        ExternalContactsAppReciableTrack.externalContactsPageError(isNewPage: true,
                                                                   errorCode: (error as NSError).code,
                                                                   errorMessage: (error as NSError).localizedDescription)
                    }
                    NewExternalContactsViewModel.logger.error("拉取外部联系人失败",
                                                              additionalData: [
                                                                "localRequestFinished": "\(self.localRequestFinished)",
                                                                "serverRequestFinished": "\(self.serverRequestFinished)"],
                                                              error: error)
                    Tracer.trackEndExternalFetchTimingMs()
            }).disposed(by: self.disposeBag)
    }

    // 监听推送
    func observePushData() {
        pushDriver
            .drive(onNext: { [weak self] (push) in
                guard let self = self else { return }
                var tmpDatasource = self.datasource
                // update datasouce
                push.contactPushInfos.forEach { (contactPushInfo) in
                    let contactInfo = contactPushInfo.contactInfo
                    if let index = tmpDatasource.firstIndex(where: {
                        $0.userID == contactInfo.userID
                    }) {
                        if contactPushInfo.isDeleted {
                            tmpDatasource.remove(at: index)
                        } else {
                            tmpDatasource[index] = contactInfo
                        }
                    } else if !contactPushInfo.isDeleted {
                        tmpDatasource.append(contactInfo)
                    }
                }
                self.datasource = tmpDatasource
                let pushUserId = push.contactPushInfos.first?.contactInfo.userID ?? ""
                let isPushUserDeleted: Bool = push.contactPushInfos.first?.isDeleted ?? false
                NewExternalContactsViewModel.logger.debug("new externals push",
                                                          additionalData: [
                                                            "pushUserId": "\(pushUserId)",
                                                            "isPushUserDeleted": "\(isPushUserDeleted)"
                                                          ])
            }).disposed(by: disposeBag)
    }

    private func tryToTrackAppreciblePoint(cost: CFTimeInterval, memberCount: Int) {
        guard apprecibleTrackFlag else { return }
        apprecibleTrackFlag = false
        ExternalContactsAppReciableTrack.updateExternalContactsPageTrackData(sdkCost: cost, memberCount: memberCount)
        ExternalContactsAppReciableTrack.externalContactsPageLoadingTimeEnd()
    }

    func removeData(deleteContactInfo: ContactInfo) {
        let userID = deleteContactInfo.userID
        let disposeKey = Tracer.trackStartAppReciableDeleteExternal()
        self.externalContactsAPI
            .deleteContact(userId: userID)
            .subscribe(onNext: { _ in
                Tracer.trackDeleteExternalSuccess()
                Tracer.trackEndAppReciableDeleteExternal(disposeKey: disposeKey)
            }, onError: { (error) in
                Tracer.trackEndAppReciableDeleteExternal(disposeKey: disposeKey)
                if let error = error.underlyingError as? APIError {
                    Tracer.trackDeleteExternalFailed(errorCode: error.code, errorMsg: error.debugDescription)
                }
                NewExternalContactsViewModel.logger.error("删除好友失败 userID = \(userID)", error: error)
            }).disposed(by: self.disposeBag)
    }
}
