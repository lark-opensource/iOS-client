//
//  NewPostDotBadgeService.swift
//  Moment
//
//  Created by zc09v on 2021/6/15.
//
import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkRustClient
import LKCommonsLogging
import LarkBadge
import LarkContainer
import LarkFeatureGating

protocol RedDotNotifyService {
    var showDot: BehaviorSubject<Bool> { get }
    var settingEnable: Bool { get }
    func putTabDotUpdate()
    func dotNotify(enable: Bool)
    func setMuteRedDotNotify(_ mute: Bool)
}

final class RedDotNotifyServiceImpl: RedDotNotifyService, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(RedDotNotifyServiceImpl.self, category: "Module.Moments.RedDotNotify")
    private let client: RustService
    private let disposeBag: DisposeBag = DisposeBag()
    private var readTime: Int64?
    private var lastPostTime: Int64?
    private var enableDotNotify: Bool = true
    var showDot: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)
    @ScopedInjectedLazy var settingService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var settingNot: MomentsUserGlobalConfigAndSettingNotification?
    private var muteRedDotNotify: Bool = true
    private var adminEnableRedDotNotify: Bool = false
    var settingEnable: Bool {
        return adminEnableRedDotNotify && !muteRedDotNotify
    }

    init(userResolver: UserResolver, client: RustService, pushTabNotificationInfo: Observable<TabNotificationInfo>) {
        self.userResolver = userResolver
        self.client = client

        self.settingService?.getUserSettingWithFinish { [weak self] setting in
            guard let self = self else { return }
            self.adminEnableRedDotNotify = setting.adminEnableRedDotNotify
            self.muteRedDotNotify = setting.muteRedDotNotify
            self.pullTabDotBadgeInfo()
            Self.logger.info("get notify setting muteRedDotNotify: \(setting.muteRedDotNotify), adminEnableRedDotNotify: \(setting.adminEnableRedDotNotify)")
        } onError: { error in
            Self.logger.error("getUserSetting error", error: error)
        }

        pushTabNotificationInfo.subscribe(onNext: { [weak self] info in
            //如果仅是有新帖，不是自己读的，readPostTimestamp = 0
            if info.readPostTimestamp == 0, self?.readTime == nil {
                self?.update(newReadTime: nil, newLastPostTime: info.lastPostTimestamp)
            } else {
                self?.update(newReadTime: info.readPostTimestamp, newLastPostTime: info.lastPostTimestamp)
            }
            Self.logger.info("recive tabNof \(info.readPostTimestamp) \(info.lastPostTimestamp)")
        }).disposed(by: self.disposeBag)

        settingNot?.rxConfig.subscribe(onNext: { [weak self] nof in
            guard let self = self else { return }
            self.setSettingEnable(muteRedDotNotify: nof.userSetting.muteRedDotNotify,
                                  adminEnableRedDotNotify: nof.userSetting.adminEnableRedDotNotify)
            Self.logger.info("recive userSettingnNof muteRedDotNotify: \(nof.userSetting.muteRedDotNotify), adminEnableRedDotNotify: \(nof.userSetting.adminEnableRedDotNotify)")
        }).disposed(by: self.disposeBag)
    }

    func putTabDotUpdate() {
        let request = ServerPB_Moments_PutMomentsTabNotificationRequest()
        let ob: Observable<ServerPB.ServerPB_Moments_PutMomentsTabNotificationResponse> =
            client.sendPassThroughAsyncRequest(request, serCommand: .momentsPutTabNotification)
        ob.subscribe(onNext: { [weak self] res in
            self?.update(newReadTime: res.readPostTimestamp, newLastPostTime: nil)
            Self.logger.info("putTabDotUpdate \(res.readPostTimestamp)")
        }, onError: { error in
            Self.logger.error("putTabDotBadgeInfo error", error: error)
        }).disposed(by: self.disposeBag)
    }

    func dotNotify(enable: Bool) {
        self.enableDotNotify = enable
    }

    private func setSettingEnable(muteRedDotNotify: Bool, adminEnableRedDotNotify: Bool) {
        self.adminEnableRedDotNotify = adminEnableRedDotNotify
        setMuteRedDotNotify(muteRedDotNotify)
    }

    func setMuteRedDotNotify(_ mute: Bool) {
        self.muteRedDotNotify = mute
        if self.settingEnable {
            self.pullTabDotBadgeInfo()
        } else {
            self.showDot.onNext(false)
        }
    }

    private func pullTabDotBadgeInfo() {
        guard self.settingEnable else { return }
        let request = ServerPB_Moments_PullMomentsTabNotificationRequest()
        let ob: Observable<ServerPB.ServerPB_Moments_PullMomentsTabNotificationResponse> =
            client.sendPassThroughAsyncRequest(request, serCommand: .momentsPullTabNotification)
        ob.subscribe(onNext: { [weak self] res in
            self?.update(newReadTime: res.readPostTimestamp, newLastPostTime: res.lastPostTimestamp)
            Self.logger.info("pullTabDotBadgeInfo \(res.readPostTimestamp) \(res.lastPostTimestamp)")
        }, onError: { error in
            Self.logger.error("pullTabDotBadgeInfo error", error: error)
        }).disposed(by: self.disposeBag)
    }

    private func update(newReadTime: Int64?, newLastPostTime: Int64?) {
        DispatchQueue.main.async {
            if let readTime = self.readTime {
                if readTime < newReadTime ?? readTime {
                    self.readTime = newReadTime
                }
            } else {
                self.readTime = newReadTime
            }
            if let lastPostTime = self.lastPostTime {
                if lastPostTime < newLastPostTime ?? lastPostTime {
                    self.lastPostTime = newLastPostTime
                }
            } else {
                self.lastPostTime = newLastPostTime
            }
            guard let readTime = self.readTime, let lastPostTime = self.lastPostTime, self.settingEnable else {
                self.showDot.onNext(false)
                return
            }
            if readTime < lastPostTime {
                if self.enableDotNotify {
                    self.showDot.onNext(true)
                }
            } else {
                self.showDot.onNext(false)
            }
        }
    }
}
