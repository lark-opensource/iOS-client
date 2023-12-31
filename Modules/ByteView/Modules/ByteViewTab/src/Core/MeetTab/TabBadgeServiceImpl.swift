//
//  TabBadgeServiceImpl.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/3/2.
//

import Foundation
import RxRelay
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewCommon

final class TabBadgeServiceImpl: TabBadgeService {
    static let logger = Logger.tabBadge
    private var disposeBag = DisposeBag()
    /// TabBadge专用Queue
    private let queue = DispatchQueue(label: "lark.byteview.tabBadge")

    private var unreadCountDidChangedCallBack: ((Int64) -> Void)?

    /// 记录当前总计未接数量
    private var totalMissedCalls: Int64 = 0
    /// 记录当前总计已确认数量
    private var confirmedMissedCalls: Int64 = 0

    private var tabReady = false
    private var contextReady = false
    /// 数据源
    private let totalMissedCallInfoSubject: PublishSubject<TabMissedCallInfo> = PublishSubject()

    let userId: String
    let httpClient: HttpClient

    init(userId: String, httpClient: HttpClient) {
        self.userId = userId
        self.httpClient = httpClient
    }

    /// VC-Tab启用，FG开则初始化数据
    func notifyTabEnabled() {
        Self.logger.info("notifyTabEnabled")
        tabReady = true
        setupContext()
    }

    func notifyTabContextEnabled() {
        Self.logger.info("notifyTabContextEnabled")
        contextReady = true
        setupContext()
    }

    func clearTabBadge() {
        Self.logger.debug("will clear vc tab count with totalMissed: \(self.totalMissedCalls), comfirmedMissed: \(self.confirmedMissedCalls)")
        let request = TabMissedCallConfirmRequest(confirmedMissedCalls: totalMissedCalls)
        httpClient.send(request, options: .retry(3, owner: self)) { [weak self] r in
            guard let self = self else { return }
            switch r {
            case .success:
                Self.logger.debug("clear vc tab count success")
                self.notifyBadgeChanged(totalMissedCalls: self.totalMissedCalls,
                                        confirmedMissedCalls: self.totalMissedCalls)
            case .failure(let error):
                Self.logger.warn("clear vc tab count error: \(error)")
            }
        }
    }

    func refreshTabUnreadCount() {
        getVCTabCount()
    }

    /// 红点计数改变时，回调给外部
    func registerUnreadCountDidChangedCallback(_ callBack: @escaping (Int64) -> Void) {
        unreadCountDidChangedCallBack = callBack
        notifyBadgeChanged(totalMissedCalls: self.totalMissedCalls,
                           confirmedMissedCalls: self.confirmedMissedCalls)
    }

    private func setupContext() {
        Self.logger.debug("setup context when tabReady: \(tabReady), contextReady: \(contextReady)")
        guard tabReady, contextReady else {
            return
        }
        Self.logger.debug("bind badge data with userId: \(userId)")
        disposeBag = DisposeBag()
        getVCTabCount()
        bindData()
    }

    private func getVCTabCount() {
        Self.logger.debug("will get VC Tab count")
        httpClient.getResponse(GetTabMissedCallRequest()) { [weak self] r in
            switch r {
            case .success(let resp):
                Self.logger.debug("did get VC Tab count")
                self?.totalMissedCallInfoSubject.onNext(resp.info)
            case .failure(let error):
                Self.logger.debug("get VC Tab count error: \(error)")
            }
        }
    }

    private func notifyBadgeChanged(totalMissedCalls: Int64, confirmedMissedCalls: Int64) {
        queue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            let count = totalMissedCalls - confirmedMissedCalls
            Self.logger.debug("notify badge change to count: \(count), totalMissed: \(totalMissedCalls), confirmed: \(confirmedMissedCalls)")
            self.totalMissedCalls = totalMissedCalls
            self.confirmedMissedCalls = confirmedMissedCalls
            self.unreadCountDidChangedCallBack?(count)
        }
    }

    func bindData() {
        TabServerPush.missedCalls.inUser(userId).addObserver(self) { [weak self] in
            self?.didNotifyTabMissedCalls($0)
        }
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                Self.logger.debug("willEnterForegroundNotification, fetch vc tab count")
                self?.refreshTabUnreadCount()
            }).disposed(by: disposeBag)

        totalMissedCallInfoSubject.asObservable()
            .subscribe(onNext: { [weak self] data in
                Self.logger.debug("VC Tab bagde info changed, total: \(data.totalMissedCalls), confirmed: \(data.confirmedMissedCalls)")
                self?.notifyBadgeChanged(totalMissedCalls: data.totalMissedCalls, confirmedMissedCalls: data.confirmedMissedCalls)
            })
            .disposed(by: disposeBag)
    }

    func didNotifyTabMissedCalls(_ info: TabMissedCallInfo) {
        Self.logger.debug("VC Tab badge info pushed, total: \(info.totalMissedCalls), confirmed: \(info.confirmedMissedCalls)")
        totalMissedCallInfoSubject.onNext(info)
    }
}
