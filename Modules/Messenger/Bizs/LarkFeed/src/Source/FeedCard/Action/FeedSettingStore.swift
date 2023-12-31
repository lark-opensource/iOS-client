//
//  FeedSettingStore.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/10.
//

import Foundation
import RustPB
import LarkContainer
import LarkSDKInterface
import RxSwift
import RxCocoa

class FeedSettingStore {
    private let bag = DisposeBag()
    // MARK: DEPENDENCY
    private let feedAPI: FeedAPI
    private let pushActionSetting: Observable<FeedActionSettingData>

    // MARK: DATA
    var currentActionSetting: FeedActionSettingData {
        return actionSettingRelay.value
    }
    private lazy var actionSettingRelay: BehaviorRelay<FeedActionSettingData> = {
        let data = FeedActionSettingData(leftSlideSettings: [],
                                         rightSlideSettings: [],
                                         updateTime: 0,
                                         leftSlideOn: false,
                                         rightSlideOn: false)
        return BehaviorRelay<FeedActionSettingData>(value: data)
    }()

    init(feedAPI: FeedAPI, pushActionSetting: Observable<FeedActionSettingData>) {
        self.feedAPI = feedAPI
        self.pushActionSetting = pushActionSetting
        setupMonitor()
    }
    private func setupMonitor() {
        pushActionSetting.subscribe(onNext: {[weak self] data in
            guard let self = self else { return }
            self.updateDataIfNeed(data: data, isPush: true)
        }).disposed(by: bag)
    }

    func getFeedActionSetting(forceUpdate: Bool = false) -> Observable<FeedActionSettingData> {
        if forceUpdate {
            feedAPI.getFeedActionSetting(strategy: .forceServer).catchError({[weak self] error in
                guard let self = self else { return .empty() }
                FeedContext.log.error("feedlog/actionSetting/getFeedActionSetting forceServer", error: error)
                return self.feedAPI.getFeedActionSetting(strategy: .tryLocal)
            }).subscribe(onNext: {[weak self] response in
                guard let self = self else { return }
                let data = FeedActionSettingData.transform(response: response)
                self.updateDataIfNeed(data: data, isPush: false)
            }, onError: { error in
                FeedContext.log.error("feedlog/actionSetting/getFeedActionSetting", error: error)
            }).disposed(by: bag)
        }
        return actionSettingRelay.asObservable()
    }

    func updateFeedAction(settingData: FeedActionSettingData) -> Observable<(Feed_V1_UpdateFeedActionSettingResponse)> {
        var setting = Feed_V1_FeedSlideActionSetting()
        setting.leftSlideAction = settingData.leftSlideSettings
        setting.rightSlideAction = settingData.rightSlideSettings
        setting.leftSlideActionOn = settingData.leftSlideOn
        setting.rightSlideActionOn = settingData.rightSlideOn
        return feedAPI.updateFeedActionSetting(setting: setting)
    }

    private func updateDataIfNeed(data: FeedActionSettingData, isPush: Bool) {
        let current = self.actionSettingRelay.value.updateTime
        let message = "feedlog/actionSetting/getFeedActionSetting: "
        + "isPush: \(isPush),"
        + "leftSlideActions: \(data.leftSlideSettings), "
        + "rightSlideActions: \(data.rightSlideSettings), "
        + "updateTime: \(data.updateTime), "
        + "currentTime:: \(current)"
        FeedContext.log.info(message)
        if current <= data.updateTime {
            self.actionSettingRelay.accept(data)
        }
    }
}

struct FeedActionSettingData: Equatable {
    var leftSlideSettings: [Feed_V1_FeedSlideActionSetting.FeedSlideActionType]
    var rightSlideSettings: [Feed_V1_FeedSlideActionSetting.FeedSlideActionType]
    let updateTime: Int64
    var leftSlideOn: Bool
    var rightSlideOn: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.leftSlideSettings == rhs.leftSlideSettings &&
        lhs.rightSlideSettings == rhs.rightSlideSettings &&
        lhs.leftSlideOn == rhs.leftSlideOn &&
        lhs.rightSlideOn == rhs.rightSlideOn
    }

    static func transform(message: Feed_V1_PushFeedActionSetting) -> FeedActionSettingData {
        return FeedActionSettingData(leftSlideSettings: message.slideAction.leftSlideAction,
                                     rightSlideSettings: message.slideAction.rightSlideAction,
                                     updateTime: message.slideAction.updateTimeMs,
                                     leftSlideOn: message.slideAction.leftSlideActionOn,
                                     rightSlideOn: message.slideAction.rightSlideActionOn)
    }

    static func transform(response: Feed_V1_GetFeedActionSettingResponse) -> FeedActionSettingData {
        let leftSlideSettings = response.slideAction.leftSlideAction
        let rightSlideSettings = response.slideAction.rightSlideAction
        let updateTimes = response.slideAction.updateTimeMs
        return FeedActionSettingData(leftSlideSettings: leftSlideSettings,
                                     rightSlideSettings: rightSlideSettings,
                                     updateTime: updateTimes,
                                     leftSlideOn: response.slideAction.leftSlideActionOn,
                                     rightSlideOn: response.slideAction.rightSlideActionOn)
    }

}
