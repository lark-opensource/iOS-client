//
//  FeedBadgeConfigService.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/5/27.
//

import Foundation
import RxSwift
import RxRelay
import RustPB
import LKCommonsLogging
import LarkContainer
import LarkSDKInterface
import LarkFeedBase

// MARK: Feed Badge 配置
final class FeedBadgeConfig: FeedBadgeConfigService {
    private let disposeBag = DisposeBag()

    private let configAPI: ConfigurationAPI
    private let pushUserSetting: Observable<Settings_V1_PushUserSetting>

    // feed badge style
    static private(set) var badgeStyle: Settings_V1_BadgeStyle = .weakRemind
    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> {
        _badgeStyleSubject.asObservable()
    }
    private let _badgeStyleSubject: PublishSubject<Settings_V1_BadgeStyle> = PublishSubject()

    // 是否显示主导航免打扰badge
    static private(set) var showTabMuteBadge = true
    var tabMuteBadgeObservable: Observable<Bool> {
        _tabMuteBadgeSubject.asObservable()
    }
    private let _tabMuteBadgeSubject: PublishSubject<Bool> = PublishSubject()

    init(style: Settings_V1_BadgeStyle?,
         configAPI: ConfigurationAPI,
         pushUserSetting: Observable<Settings_V1_PushUserSetting>) {
        if let style = style {
            Self.badgeStyle = style
            FeedBadgeBaseConfig.badgeStyle = style
        }
        self.configAPI = configAPI
        self.pushUserSetting = pushUserSetting
        setup()
    }

    private func setup() {
        let getBadgeStyle = configAPI.getAndReviseBadgeStyle()
        let pushBadgeStyle = pushUserSetting.map { $0.badgeStyle }

        Observable.of(
            getBadgeStyle.0,
            getBadgeStyle.1,
            pushBadgeStyle)
        .merge()
        .distinctUntilChanged()
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] style in
            self?.updateBadgeStyle(style: style)
        }).disposed(by: disposeBag)

        let fetchShowTabMuteBadge = configAPI.fetchShowTabMuteBadge()
        let pushTabMuteBadge = pushUserSetting.map { $0.navigationShowMuteBadge }
        Observable.of(
            fetchShowTabMuteBadge,
            pushTabMuteBadge)
        .merge()
        .distinctUntilChanged()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] isShow in
            self?.updateTabBadgeMuteConfig(showTabMuteBadge: isShow)
        }).disposed(by: disposeBag)
    }

    // feed badge style
    private func updateBadgeStyle(style: Settings_V1_BadgeStyle) {
        guard style != Self.badgeStyle else { return }
        FeedContext.log.info("feedlog/config/badge/badgeStyle. new: \(style), old: \(Self.badgeStyle)")
        Self.badgeStyle = style
        FeedBadgeBaseConfig.badgeStyle = style
        _badgeStyleSubject.onNext(style)
    }

    // 是否显示主导航免打扰badge
    private func updateTabBadgeMuteConfig(showTabMuteBadge: Bool) {
        guard showTabMuteBadge != Self.showTabMuteBadge else { return }
        FeedContext.log.info("feedlog/config/badge/showTabMuteBadge. new: \(showTabMuteBadge), old: \(Self.showTabMuteBadge)")
        Self.showTabMuteBadge = showTabMuteBadge
        FeedBadgeBaseConfig.showTabMuteBadge = showTabMuteBadge
        _tabMuteBadgeSubject.onNext(showTabMuteBadge)
    }
}
