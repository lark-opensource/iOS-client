//
//  FeedNavigationBarViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkMessengerInterface
import LarkSDKInterface
import RustPB
import LKCommonsLogging
import LarkPerf
import RunloopTools
import LarkOpenFeed

final class FeedNavigationBarViewModel {

    let titleText: BehaviorRelay<String>
    let needShowTitleArrow: BehaviorRelay<Bool>
    let subFilterTitleText: BehaviorRelay<String?>
    let isLoading: BehaviorRelay<Bool>
    let showPad3BarNaviStyle: BehaviorRelay<Bool>
    let showTabbarFocusStatus: BehaviorRelay<Bool>

    private let feedType: Basic_V1_FeedCard.FeedType = .inbox

    private var netStatus: Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent {
        didSet {
            FeedContext.log.info("feedlog/navi/syncStatus. netStatus: \(netStatus)")
            handleFeedSatus()
        }
    }

    private var isSyncing: Bool {
        didSet {
            FeedContext.log.info("feedlog/navi/syncStatus. isSyncing: \(isSyncing)")
            handleFeedSatus()
        }
    }

    private var chatterId: String

    private static var isLaunching = true
    private var lastStartTime: CFTimeInterval? = CACurrentMediaTime() // for 打点

    private let disposeBag = DisposeBag()
    private let chatterManager: ChatterManagerProtocol
    private let styleService: Feed3BarStyleService
    private let context: FeedContextService

    init(chatterId: String,
         pushDynamicNetStatus: Observable<PushDynamicNetStatus>,
         pushLoadFeedCardsStatus: Observable<Feed_V1_PushLoadFeedCardsStatus>,
         chatterManager: ChatterManagerProtocol,
         styleService: Feed3BarStyleService,
         context: FeedContextService) {
        self.chatterManager = chatterManager
        self.chatterId = chatterId
        self.styleService = styleService
        self.context = context
        titleText = BehaviorRelay(value: chatterManager.currentChatter.nameWithAnotherName)
        needShowTitleArrow = BehaviorRelay(value: false)
        subFilterTitleText = BehaviorRelay(value: nil)
        isLoading = BehaviorRelay(value: false)
        showPad3BarNaviStyle = BehaviorRelay(value: styleService.currentStyle == .padRegular)
        let showTabFocus = chatterManager.currentChatter.focusStatusList.topActive != nil
        showTabbarFocusStatus = BehaviorRelay(value: showTabFocus)
        let isLaunching = FeedNavigationBarViewModel.isLaunching
        let isFastLogin = AppStartupMonitor.shared.isFastLogin == true ? true : false
        let isSyncing = isLaunching && isFastLogin
        // 设置默认值：启动时默认为true，因为Rust push时机太早，端上没有收到.start
        self.isSyncing = isLaunching && isFastLogin
        FeedContext.log.info("feedlog/navi/syncStatus. default isSyncing: \(isSyncing), isLaunching: \(isLaunching), isFastLogin: \(isFastLogin)")

        // Feed加载状态
        pushLoadFeedCardsStatus.subscribe(onNext: { [weak self] push in
            guard let self = self, push.feedType == .inbox else { return }
            switch push.status {
            case .start: self.loadFeedStart()
            case .finished: self.loadFeedEnd()
            @unknown default: fatalError("Unknown case")
            }
        }).disposed(by: self.disposeBag)
        RunloopDispatcher.shared.addTask(priority: .emergency) {
            // 网络状态
            pushDynamicNetStatus.subscribe(onNext: { [weak self] push in
                self?.netStatus = push.dynamicNetStatus
            }).disposed(by: self.disposeBag)

            NotificationCenter.default.rx
                .notification(UIApplication.didEnterBackgroundNotification)
                .subscribe(onNext: { [weak self] _ in
                    self?.lastStartTime = nil
                    FeedNavigationBarViewModel.isLaunching = false
                }).disposed(by: self.disposeBag)

            chatterManager.currentChatterObservable
                .subscribe(onNext: { [weak self] chatter in
                    guard let self = self else { return }
                    let showTabFocus = chatter.focusStatusList.topActive != nil
                    self.showTabbarFocusStatus.accept(showTabFocus)
                    // 更新展示的名字
                    let currentChatter = self.chatterManager.currentChatter
                    guard currentChatter.id == self.chatterId else { return }
                    self.handleFeedSatus()
                    FeedContext.log.info("feedlog/navi/updateChatter. isSyncing: \(isSyncing), chatterId: \(currentChatter.id), length: \(currentChatter.nameWithAnotherName.count)")
                }).disposed(by: self.disposeBag)
        }
        bind()
    }

    private func loadFeedStart() {
        isSyncing = true
        self.lastStartTime = CACurrentMediaTime()
    }

    private func loadFeedEnd() {
        isSyncing = false

        // 冷启动到第一次Loading结束打点
        if Self.isLaunching {
            FeedTeaTrack.trackFirstLoadingFinished()
        }

        if let last = self.lastStartTime {
            let end = CACurrentMediaTime()
            // rust会推多个finish，只上报匹配start的
            self.lastStartTime = nil
            // 精度：s
            let interval = end - last
            FeedTeaTrack.trackSyncTimeInterval(isLaunching: Self.isLaunching, interval: interval)
            if interval > 3 {
                // 记录"加载中"持续时间超3s的case
                let errorMsg = "loadDelay, isLaunching \(Self.isLaunching), interval: \(interval)"
                let info = FeedBaseErrorInfo(type: .warning(track: true), errorMsg: errorMsg)
                FeedExceptionTracker.Navi.syncStatus(node: .loadFeed, info: info)
            }
        }
        Self.isLaunching = false
    }

    private func handleFeedSatus() {
        var isLoading = false
        switch netStatus {
        case .netUnavailable, .serviceUnavailable, .offline:
            updateNaviBar(BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderNotConnected, false)
        case .excellent, .evaluating, .weak:
            if self.isSyncing {
                isLoading = true
                updateNaviBar(BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderLoading, true)
            } else {
                showNavInfo()
            }
        @unknown default: fatalError("Unknown case")
        }
        FeedContext.log.info("feedlog/navi/syncStatus. result isLoading: \(isLoading)")
    }

    private func updateNaviBar(_ title: String, _ isLoading: Bool) {
        DispatchQueue.main.async {
            self.titleText.accept(title)
            self.isLoading.accept(isLoading)
        }
    }

    private func bind() {
        styleService.styleSubject.subscribe(onNext: { [weak self] style in
            if style == .padRegular || style == .padCompact {
                self?.handleFeedSatus()
            }
            self?.showPad3BarNaviStyle.accept(style == .padRegular)
        }).disposed(by: self.disposeBag)

        styleService.currentFilterText.subscribe(onNext: { [weak self] _ in
            self?.handleFeedSatus()
        }).disposed(by: self.disposeBag)
    }

    private func showNavInfo() {
        var title: String
        let currentTab = context.dataSourceAPI?.currentFilterType ?? .unknown
        let currentTabName = FeedFilterTabSourceFactory.source(for: currentTab)?.titleProvider() ?? ""
        let userName = chatterManager.currentChatter.nameWithAnotherName

        switch styleService.currentStyle {
        case .phone:    title = userName
        case .padRegular:  title = currentTabName
        case .padCompact:  title = userName
        @unknown default: title = userName
        }

        updateNaviBar(title, false)
    }
}
