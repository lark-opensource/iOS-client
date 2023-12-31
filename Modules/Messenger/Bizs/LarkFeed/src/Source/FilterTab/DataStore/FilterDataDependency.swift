//
//  FilterDataDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/2.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface
import LarkSDKInterface
import LarkContainer

protocol FilterDataDependency: UserResolverWrapper {
    var pushFeedFilterSettings: Observable<FiltersModel> { get }

    var pushFeedPreview: Observable<PushFeedPreview> { get }

    var addMuteGroupEnable: Bool { get }

    func updateShowMute(_ showMute: Bool)

    func getShowMute() -> Bool

    func getFilters(tryLocal: Bool) -> Observable<FiltersModel>

    func saveFeedRuleMd5(_ md5: String)

    func getFeedRuleMd5FromDisk() -> String?
}
