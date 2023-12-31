//
//  AtViewModelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/10.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface

final class AtViewModelDependencyImpl: AtViewModelDependency {
    let pushFeedFilterSettings: Observable<FiltersModel>

    private let feedAPI: FeedAPI

    init(pushFeedFilterSettings: Observable<FiltersModel>,
         feedAPI: FeedAPI) {
        self.pushFeedFilterSettings = pushFeedFilterSettings
        self.feedAPI = feedAPI
    }

    func getAtFilterSetting() -> Observable<Bool> {
        feedAPI.getFeedFilterSettings(needAll: false, tryLocal: true).map({ response in
            return response.showAtAllInAtFilter
        })
    }
}
