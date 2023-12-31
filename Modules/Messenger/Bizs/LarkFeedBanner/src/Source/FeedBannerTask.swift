//
//  FeedBannerTask.swift
//  LarkFeedBanner
//
//  Created by 袁平 on 2020/7/15.
//

import UIKit
import Foundation
import BootManager
import LarkContainer
import RunloopTools
import LarkFeatureGating
import LarkUIKit
import UGReachSDK
import RxSwift
import UserNotifications
import AppContainer

final class NewFeedBannerTask: UserFlowBootTask, Identifiable {
    static var identify = "FeedBannerTask"
    override class var compatibleMode: Bool { Feed.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    private var reachService: UGReachSDKService?
    private lazy var notificationDependency = NotificationBannerDependencyImp(userResolver: userResolver)
    private var oldAuthStatus: Bool?
    /// 设置deamon为true，task将不会被释放，此处需要监听Banner信号，不应该释放
    override var deamon: Bool { true }
    private static let exposeScenarioId = "SCENE_FEED"
    private static let exposeBizContextKey = "notificationAuth"

    override func execute(_ context: BootContext) {
        do {
            reachService = try userResolver.resolve(assert: UGReachSDKService.self)

            tryExpose()
            addAuthObserver()
        } catch {
            assertionFailure("shouldn't exception here \(error)")
            FeedBannerServiceImpV2.logger.error("FeedBannerTask run with exception", error: error)
        }
    }

    func shouldRefreshNoticeBanner() -> Bool {
        let lastTime = FeedBannerUserDefault(userResolver: userResolver).notifyReminderLastCheckTime
        let nowTime: TimeInterval = Date().timeIntervalSince1970
        let checkTime = Double(self.notificationDependency.notificationRefreshTime * 60)
        let refresh = (nowTime - lastTime) >= checkTime
        return refresh
    }

    /// 监听通知状态变化
    func addAuthObserver() {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.getNoticeAuthAndTryExpose()
            }).disposed(by: disposeBag)
    }

    func getNoticeAuthAndTryExpose() {
        getNotificationAuthStatus().subscribe(onNext: { [weak self] curAuthStatus in
            guard let self = self,
                  let authStatus = self.oldAuthStatus,
                  authStatus != curAuthStatus else { return }
            self.tryExpose()
        }).disposed(by: disposeBag)
    }

    func getNotificationAuthStatus() -> Observable<Bool> {
        return Observable<Bool>.create { (observer) -> Disposable in
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] (setting) in
                guard let `self` = self else { return }
                let currentState = setting.authorizationStatus == .authorized ? true : !self.shouldRefreshNoticeBanner()
                observer.onNext(currentState)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func tryExpose() {
        let bizContextProvider = UGAsyncBizContextProvider(
            scenarioId: NewFeedBannerTask.exposeScenarioId,
            contextProvider: { [weak self] () -> Observable<[String: String]> in
                guard let self = self else {
                    return Observable.just([:])
                }
                return self.getNotificationAuthStatus().map { [weak self] (status) -> [String: String] in
                    self?.oldAuthStatus = status
                    return [NewFeedBannerTask.exposeBizContextKey: "\(status)"]
                }
            }
        )
        reachService?.tryExpose(
            by: NewFeedBannerTask.exposeScenarioId,
            actionRuleContext: nil,
            bizContextProvider: bizContextProvider
        )
    }
}
